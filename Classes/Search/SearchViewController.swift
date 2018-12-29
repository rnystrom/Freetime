//
//  SearchViewController.swift
//  Freetime
//
//  Created by Sherlock, James on 28/07/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit
import Apollo

class SearchViewController: UIViewController,
    ListAdapterDataSource,
    PrimaryViewController,
    UISearchBarDelegate,
    EmptyViewDelegate,
    InitialEmptyViewDelegate,
    SearchRecentSectionControllerDelegate,
    SearchRecentHeaderSectionControllerDelegate,
    TabNavRootViewControllerType,
    SearchResultSectionControllerDelegate,
    ThemeChangeListener {

    private let client: GithubClient
    private let noResultsKey = "com.freetime.SearchViewController.no-results-key" as ListDiffable
    private let recentHeaderKey = "com.freetime.SearchViewController.recent-header-key" as ListDiffable
    private var recentStore = SearchRecentStore()
    private let debouncer = Debouncer()
    private var keyboardAdjuster: ScrollViewKeyboardAdjuster?

    enum State {
        case idle
        case loading(Cancellable, SearchQuery)
        case results([ListDiffable])
        case error
    }
    private var state: State = .idle {
        willSet {
            // To facilitate side-effect free state transition, we should cancel any on-going networking.
            // The `loading` => `loading` state transition can only be triggered through search while typing.
            // In that case, we don't want to store partial searches in the store.
            guard case let .loading(request, query) = state else { return }
            request.cancel()
            if case .loading = newValue {
                recentStore.remove(query)
            }
        }
    }

    private let searchBar = UISearchBar()
    private lazy var adapter: ListAdapter = { ListAdapter(updater: ListAdapterUpdater(), viewController: self) }()
    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: ListCollectionViewLayout.basic())
        view.alwaysBounceVertical = true
        view.backgroundColor = .clear
        return view
    }()

    init(client: GithubClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForThemeChanges()

        keyboardAdjuster = ScrollViewKeyboardAdjuster(
            scrollView: collectionView,
            viewController: self
        )

        makeBackBarItemEmpty()

        view.backgroundColor = Styles.Colors.background

        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self

        searchBar.delegate = self
        searchBar.placeholder = Constants.Strings.searchGitHub
        searchBar.backgroundColor = .clear
        searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchBar

        searchBar.resignWhenKeyboardHides()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rz_smoothlyDeselectRows(collectionView: collectionView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // https://stackoverflow.com/a/47976999
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let bounds = view.bounds
        if bounds != collectionView.frame {
            collectionView.frame = bounds
            collectionView.collectionViewLayout.invalidateForOrientationChange()
        }
    }

    func themeDidChange(_ theme: Theme) {
        view.backgroundColor = Styles.Colors.background
    }

    func searchBarBecomeFirstResponder() {
        searchBar.becomeFirstResponder()
    }

    // MARK: Data Loading/Paging

    private func update(animated: Bool) {
        adapter.performUpdates(animated: animated)
    }

    private func handle(resultType: GithubClient.SearchResultType, animated: Bool) {
        switch resultType {
        case let .error(error) where isCancellationError(error):
            return
        case .error:
            self.state = .error
        case .success(_, let results):
            self.state = .results(results)
        }
        self.update(animated: animated)
    }

    func search(term: String, includeForks: Bool = true) {

        let searchTerm = includeForks
            ? "fork:true " + term
            : term

        let query: SearchQuery = .search(searchTerm)

        guard canSearch(query: query) else { return }

        let request = client.search(
            query: searchTerm,
            containerWidth: view.safeContentWidth(with: collectionView)
        ) { [weak self] resultType in
            guard let state = self?.state, case .loading = state else { return }
            self?.handle(resultType: resultType, animated: trueUnlessReduceMotionEnabled)
        }
        state = .loading(request, query)

        update(animated: false)
    }

    // MARK: ListAdapterDataSource

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        switch state {
        case .idle:
            var recents: [ListDiffable] = recentStore.values.compactMap { SearchRecentViewModel(query: $0) }
            if recents.count > 0 {
                recents.insert(recentHeaderKey, at: 0)
            }
            return recents
        case .error, .loading:
            return []
        case .results(let models):
            return models.isEmpty ? [noResultsKey] : models
        }
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        guard let object = object as? ListDiffable else { fatalError("Object does not conform to ListDiffable") }

        let controlHeight = Styles.Sizes.tableCellHeight
        if object === noResultsKey {

            return SearchNoResultsSectionController(
                topInset: controlHeight,
                layoutInsets: view.safeAreaInsets
            )
        } else if object === recentHeaderKey {
            return SearchRecentHeaderSectionController(delegate: self)
        } else if object is SearchRepoResult {
            return SearchResultSectionController(client: client, delegate: self)
        } else if object is SearchRecentViewModel {
            return SearchRecentSectionController(delegate: self)
        }

        fatalError("Could not find section controller for object")
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        switch state {
        case .idle:
            let view = InitialEmptyView()
            view.configure(
                imageName: "search-large",
                title: Constants.Strings.searchGitHub,
                description: NSLocalizedString("Find your favorite repositories.\nRecent searches are saved.", comment: "")
            )
            view.delegate = self
            return view
        case .loading:
            return SearchLoadingView()
        case .error:
            let view = EmptyView()
            view.label.text = NSLocalizedString("Error finding results", comment: "")
            view.delegate = self
            view.button.isHidden = false
            return view
        case .results:
            return nil
        }
    }

    // MARK: UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let term = searchTerm(for: searchBar.text) else {
            state = .idle
            update(animated: false)
            return
        }

        debouncer.action = { [weak self] in self?.search(term: term) }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: trueUnlessReduceMotionEnabled)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let term = searchTerm(for: searchBar.text) else { return }
        search(term: term)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: trueUnlessReduceMotionEnabled)
        searchBar.text = ""
        searchBar.resignFirstResponder()

        state = .idle
        update(animated: false)
    }

    // MARK: EmptyViewDelegate

    func didTapRetry(view: EmptyView) {
        searchBar.resignFirstResponder()

        guard let term = searchTerm(for: searchBar.text) else { return }
        search(term: term)
    }

    // MARK: InitialEmptyViewDelegate

    func didTap(emptyView: InitialEmptyView) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: SearchRecentSectionControllerDelegate

    func didSelect(recentSectionController: SearchRecentSectionController, viewModel: SearchRecentViewModel) {
        searchBar.resignFirstResponder()

        if case let .search(text) = viewModel.query {
            didSelectSearch(text: text)
        } else if case let .recentlyViewed(repo) = viewModel.query {
            didSelectRepo(repo: repo)
        }
    }

    private func didSelectSearch(text: String) {
        searchBar.setShowsCancelButton(true, animated: false)
        searchBar.text = text
        search(term: text)
    }

    private func didSelectRepo(repo: RepositoryDetails) {
        recentStore.add(.recentlyViewed(repo))

        // always animate this transition b/c IGListKit disables global animations
        // otherwise pushing the next view controller wont be animated
        update(animated: trueUnlessReduceMotionEnabled)

        route_detail(to: RepositoryViewController(client: client, repo: repo))
    }

    // MARK: SearchRecentHeaderSectionControllerDelegate

    func didTapClear(sectionController: SearchRecentHeaderSectionController) {
        let alert = UIAlertController.configured(
            title: NSLocalizedString("Recent Searches", comment: ""),
            message: NSLocalizedString("Remove all recent searches?", comment: ""),
            preferredStyle: .alert
        )

        alert.addActions([
            AlertAction.clearAll({ [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.recentStore.clear()
                strongSelf.adapter.performUpdates(animated: trueUnlessReduceMotionEnabled)
            }),
            AlertAction.cancel()
        ])

        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: TabNavRootViewControllerType

    func didSingleTapTab() {
        collectionView.scrollToTop(animated: trueUnlessReduceMotionEnabled)
    }

    func didDoubleTapTab() {
        searchBar.becomeFirstResponder()
    }

    // MARK: SearchResultSectionControllerDelegate

    func didSelect(sectionController: SearchResultSectionController, repo: RepositoryDetails) {
        recentStore.add(.recentlyViewed(repo))
        update(animated: trueUnlessReduceMotionEnabled)
        searchBar.resignFirstResponder()
    }

    func didDelete(recentSectionController: SearchRecentSectionController, viewModel: SearchRecentViewModel) {
        recentStore.remove(viewModel.query)
        update(animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: Private API

    private func searchTerm(for searchBarText: String?) -> String? {
        guard let term = searchBarText?.trimmingCharacters(in: .whitespacesAndNewlines),
            !term.isEmpty else { return nil }
        return term
    }

    private func canSearch(query: SearchQuery) -> Bool {
        // if making a request where the term is identical to `query`
        if case let .loading(_, activeQuery) = state, activeQuery == query {
            return false
        }
        return true
    }
}
