//
//  RepositoryViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 9/20/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import TUSafariActivity
import Squawk
import ContextMenu
import DropdownTitleView

final class RepositoryViewController: ButtonBarPagerTabStripViewController,
NewIssueTableViewControllerDelegate,
ContextMenuDelegate,
EmptyViewDelegate,
ThemeChangeListener {

    private struct Details {
        let hasIssuesEnabled: Bool
        let defaultBranch: String
        let graphQLID: String
    }

    private enum State {
        case loading
        case error
        case value(Details)
    }

    private let repo: RepositoryDetails
    private let client: GithubClient
    private var controllers = [UIViewController]()
    private var bookmarkNavController: BookmarkNavigationController?
    public private(set) var branch: String?
    private var state: State = .loading {
        didSet {
            if case .value(let details) = state {
                branch = branch ?? details.defaultBranch
                bookmarkNavController = BookmarkNavigationController(
                    store: client.bookmarkCloudStore,
                    graphQLID: details.graphQLID
                )
                updateRightBarItems()
            }
        }
    }

    init(client: GithubClient, repo: RepositoryDetails) {
        self.repo = repo
        self.client = client
        super.init(nibName: nil, bundle: nil)
        buildViewControllers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        settings.style.selectedBarBackgroundColor = Styles.Colors.Blue.medium.color
        settings.style.buttonBarItemFont = Styles.Text.body.preferredFont
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarHeight = 44

        pagerBehaviour = .progressive(skipIntermediateViewControllers: true, elasticIndicatorLimit: true)
        changeCurrentIndex = { (oldCell, newCell, animated) in
            oldCell?.label.textColor = Styles.Colors.Gray.medium.color
            newCell?.label.textColor = Styles.Colors.Blue.medium.color
        }

        edgesForExtendedLayout = []
        registerForThemeChanges()
        
        super.viewDidLoad()

        makeBackBarItemEmpty()
        delegate = self

        updateRightBarItems()

        let navigationTitle = DropdownTitleView()
        navigationItem.titleView = navigationTitle
        navigationTitle.addTarget(self, action: #selector(onNavigationTitle(sender:)), for: .touchUpInside)
        let labelFormat = NSLocalizedString(
            "Repository %@ by %@",
            comment: "Accessibility label for a repository navigation item"
        )
        let accessibilityLabel = String(format: labelFormat, arguments: [repo.name, repo.owner])
        navigationTitle.configure(title: repo.name, subtitle: repo.owner, accessibilityLabel: accessibilityLabel)

        fetchDetails()
    }

    func themeDidChange(_ theme: Theme) {
        switch theme {
        case .light:
            settings.style.buttonBarBackgroundColor = .white
            settings.style.buttonBarItemBackgroundColor = .white
            settings.style.buttonBarItemTitleColor = Styles.Colors.Gray.medium.color
        case .dark:
            settings.style.buttonBarBackgroundColor = Styles.Colors.Gray.dark.color
            settings.style.buttonBarItemBackgroundColor = Styles.Colors.Gray.dark.color
            settings.style.buttonBarItemTitleColor = .white
        }
        view.backgroundColor = Styles.Colors.background
    }

    // MARK: Private API

    private func updateRightBarItems() {
        let moreItem = UIBarButtonItem(
            image: UIImage(named: "bullets-hollow"),
            target: self,
            action: #selector(RepositoryViewController.onMore(sender:))
        )
        moreItem.accessibilityLabel = Constants.Strings.moreOptions
        var items = [moreItem]
        if let bookmarkItem = bookmarkNavController?.navigationItem {
            items.append(bookmarkItem)
        }
        navigationItem.rightBarButtonItems = items
    }

    private func buildViewControllers() {
        var controllers = [UIViewController]()

        switch state {
        case .error:
            let controller = RepositoryErrorViewController()
            controller.delegate = self
            controllers.append(controller)
        case .value(let details):
            controllers.append(RepositoryOverviewViewController(
                client: client,
                repo: repo,
                branch: branch ?? details.defaultBranch
            ))
            if details.hasIssuesEnabled {
                controllers.append(RepositoryIssuesViewController(
                    client: client,
                    owner: repo.owner,
                    repo: repo.name,
                    type: .issues
                ))
            }
            controllers += [
                RepositoryIssuesViewController(
                    client: client,
                    owner: repo.owner,
                    repo: repo.name,
                    type: .pullRequests
                ),
                RepositoryCodeDirectoryViewController.createRoot(
                    client: client,
                    repo: repo,
                    branch: branch ?? details.defaultBranch
                )
            ]
        case .loading:
            controllers.append(RepositoryLoadingViewController())
        }

        self.controllers = controllers
    }

    func fetchDetails() {
        state = .loading
        buildViewControllers()
        reloadPagerTabStripView()

        client.client.query(
            RepositoryInfoQuery(owner: repo.owner, name: repo.name),
            result: { $0 },
            completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.state = .error
                    Squawk.show(error: error)
                case .success(let data):
                    if let repo = data.repository {
                        let details = Details(
                            hasIssuesEnabled: repo.hasIssuesEnabled,
                            defaultBranch: repo.defaultBranchRef?.name ?? "master",
                            graphQLID: repo.id
                        )
                        self?.state = .value(details)
                    } else {
                        self?.state = .error
                    }
                }
                self?.buildViewControllers()
                self?.reloadPagerTabStripView()
            })
    }

    @objc func onNavigationTitle(sender: UIView) {
        let alert = UIAlertController.configured(preferredStyle: .actionSheet)
        weak var weakSelf = self
        alert.addActions([
            AlertAction(AlertActionBuilder { $0.rootViewController = weakSelf })
                .view(owner: repo.owner, icon: #imageLiteral(resourceName: "organization")),
            AlertAction.cancel()
            ])
        alert.popoverPresentationController?.setSourceView(sender)
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    var repoUrl: URL? {
        return URLBuilder.github().add(paths: [repo.owner, repo.name]).url
    }

    var switchBranchAction: UIAlertAction? {
        guard case .value(let details) = self.state else { return nil }

        return UIAlertAction(
            title: NSLocalizedString("Switch Branch", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let `self` = self,
                let branch = self.branch
                else { return }
            let viewController =
                RepositoryBranchesViewController(
                    defaultBranch: details.defaultBranch,
                    selectedBranch: branch,
                    owner: self.repo.owner,
                    repo: self.repo.name,
                    client: self.client
            )

            self.showContextualMenu(
                viewController,
                options: ContextMenu.Options(
                    containerStyle: ContextMenu.ContainerStyle(
                        backgroundColor: Styles.Colors.menuBackgroundColor.color
                    )
                ),
                delegate: self
            )
        }
    }

    func newIssueAction() -> UIAlertAction? {
        guard case .value(let details) = state,
            details.hasIssuesEnabled,
            let newIssueViewController = NewIssueTableViewController.create(
            client: client,
            owner: repo.owner,
            repo: repo.name,
            signature: .sentWithGitHawk)
        else {
            return nil
        }

        newIssueViewController.delegate = self
        weak var weakSelf = self

        return AlertAction(AlertActionBuilder { $0.rootViewController = weakSelf })
            .newIssue(issueController: newIssueViewController)
    }

    func workingCopyAction() -> UIAlertAction? {
        guard let remote = repoUrl?.absoluteString
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
            else { return nil}

        guard let url = URL(string: "working-copy://show?remote=\(remote)")
            else { return nil }
        guard UIApplication.shared.canOpenURL(url) else { return nil }

        let title = NSLocalizedString("Working Copy", comment: "")
        let action = UIAlertAction(title: title, style: .default,
                                   handler: { _ in
            UIApplication.shared.open(url)
        })
        return action
    }

    @objc func onMore(sender: UIButton) {
        guard let branch = self.branch else { return }

        let alertTitle = "\(repo.owner)/\(repo.name):\(branch)"
        let alert = UIAlertController.configured(title: alertTitle, preferredStyle: .actionSheet)

        weak var weakSelf = self
        let alertBuilder = AlertActionBuilder { $0.rootViewController = weakSelf }

        alert.addActions([
            viewHistoryAction(owner: repo.owner, repo: repo.name, branch: branch, client: client),
            newIssueAction()
        ])
        if let url = repoUrl {
            alert.add(action: AlertAction(alertBuilder).share([url], activities: [TUSafariActivity()], type: .shareUrl) {
                $0.popoverPresentationController?.setSourceView(sender)
            })
        }
        alert.addActions([
            switchBranchAction,
            workingCopyAction(),
            AlertAction.cancel()
            ])
        alert.popoverPresentationController?.setSourceView(sender)

        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: ButtonBarPagerTabStripViewController Overrides

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return controllers
    }

    // MARK: NewIssueTableViewControllerDelegate

    func didDismissAfterCreatingIssue(model: IssueDetailsModel) {
        route_push(to: IssuesViewController(client: client, model: model))
    }

    // MARK: ContextMenuDelegate

    func contextMenuWillDismiss(viewController: UIViewController, animated: Bool) {
        guard let viewController = viewController as? RepositoryBranchesViewController else { return }
        self.branch = viewController.selectedBranch
        controllers.forEach {
            if let branchUpdatable = $0 as? RepositoryBranchUpdatable {
                branchUpdatable.updateBranch(to: viewController.selectedBranch)
            }
        }
    }

    func contextMenuDidDismiss(viewController: UIViewController, animated: Bool) {}

    // MARK: EmptyViewDelegate

    func didTapRetry(view: EmptyView) {
        fetchDetails()
    }

}
