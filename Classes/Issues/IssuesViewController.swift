//
//  IssuesViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/17/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit
import TUSafariActivity
import SnapKit
import FlatCache
import MessageViewController
import Squawk
import ContextMenu
import GitHubAPI
import ImageAlertAction
import DropdownTitleView

extension ListDiffable {
    var needsSpacer: Bool {
        return self is IssueCommentModel || self is IssueReviewModel
    }
}

final class IssuesViewController: MessageViewController,
    ListAdapterDataSource,
    FeedDelegate,
    AddCommentListener,
    FeedSelectionProviding,
    IssueNeckLoadSectionControllerDelegate,
    FlatCacheListener,
    IssueCommentSectionControllerDelegate,
    IssueTextActionsViewSendDelegate,
    EmptyViewDelegate,
    MessageTextViewListener,
    IssueLabelTapSectionControllerDelegate,
    IssueManagingContextControllerDelegate,
    ThemeChangeListener {

    private let client: GithubClient
    private let model: IssueDetailsModel
    private let addCommentClient: AddCommentClient
    private let textActionsController = TextActionsController()
    private var bookmarkNavController: BookmarkNavigationController?
    private var autocompleteController: AutocompleteController!
    private let manageController: IssueManagingContextController
    private let threadInset = UIEdgeInsets(
        top: Styles.Sizes.rowSpacing / 2,
        left: Styles.Sizes.gutter,
        bottom: 2 * Styles.Sizes.rowSpacing + Styles.Sizes.tableCellHeight,
        right: Styles.Sizes.gutter
    )

    private var needsScrollToBottom = false
    private var lastTimelineElement: ListDiffable?
    private var actions: IssueTextActionsView?
    private var issueType: RepositoryIssuesType?

    // must fetch collaborator info from API before showing editing controls
    private var viewerIsCollaborator = false

    lazy private var feed: Feed = {
        let f = Feed(viewController: self, delegate: self, managesLayout: false)
        f.collectionView.contentInset = threadInset
        return f
    }()

    private var resultID: String? = nil {
        didSet {
            let hidden: Bool
            if let id = resultID,
                let result = self.client.cache.get(id: id) as IssueResult? {
                hidden = result.labels.locked && !viewerIsCollaborator

                self.bookmarkNavController = BookmarkNavigationController(
                    store: client.bookmarkCloudStore,
                    graphQLID: id
                )
                self.configureNavigationItems()
            } else {
                hidden = true
            }
            self.setMessageView(hidden: hidden, animated: trueUnlessReduceMotionEnabled)

            self.manageController.resultID = resultID
        }
    }

    var result: IssueResult? {
        guard let id = resultID else { return nil }
        return client.cache.get(id: id) as IssueResult?
    }

    var moreOptionsItem: UIBarButtonItem {
        let rightItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(IssuesViewController.onMore(sender:))
        )
        rightItem.accessibilityLabel = NSLocalizedString("Share", comment: "")
        return rightItem
    }

    init(
        client: GithubClient,
        model: IssueDetailsModel,
        scrollToBottom: Bool = false
        ) {
        self.client = client
        self.model = model
        self.addCommentClient = AddCommentClient(client: client)
        self.needsScrollToBottom = scrollToBottom
        self.manageController = IssueManagingContextController(model: model, client: client)

        super.init(nibName: nil, bundle: nil)

        self.autocompleteController = AutocompleteController(
            messageAutocompleteController: messageAutocompleteController,
            autocomplete: IssueCommentAutocomplete(autocompletes: [
                EmojiAutocomplete(),
                IssueAutocomplete(client: client.client, owner: model.owner, repo: model.repo)
                ])
        )

        self.hidesBottomBarWhenPushed = true
        self.addCommentClient.addListener(listener: self)

        cacheKey = "issue.\(model.owner).\(model.repo).\(model.number)"

        manageController.viewController = self
        manageController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForThemeChanges()
        makeBackBarItemEmpty()

        let labelFormat = NSLocalizedString("#%d in repository %@ by %@", comment: "Accessibility label for an issue/pull request navigation item")
        let labelString = String(format: labelFormat, arguments: [model.number, model.repo, model.owner])

        let navigationTitle = DropdownTitleView()
        navigationTitle.addTarget(self, action: #selector(onNavigationTitle(sender:)), for: .touchUpInside)
        navigationTitle.configure(
            title: "#\(model.number)",
            subtitle: "\(model.owner)/\(model.repo)",
            accessibilityLabel: labelString,
            accessibilityHint: NSLocalizedString(
                "Gives the option to view the repository's overview or owner",
                comment: "The hint for tapping the navigationBar's repository information.")
        )
        navigationItem.titleView = navigationTitle

        feed.viewDidLoad()
        feed.adapter.dataSource = self

        // setup after feed is lazy loaded
        setup(scrollView: feed.collectionView)
        setMessageView(hidden: true, animated: false)

        // setup message view properties
        configure()

        let getMarkdownBlock = { [weak self] () -> (String) in
            return self?.messageView.text ?? ""
        }
        let actions = IssueTextActionsView.forMarkdown(
            viewController: self,
            getMarkdownBlock: getMarkdownBlock,
            repo: model.repo,
            owner: model.owner,
            addBorder: false,
            supportsImageUpload: true,
            showSendButton: true
        )
        // text input bar uses UIVisualEffectView, don't try to match it
        actions.backgroundColor = .clear
        actions.sendDelegate = self
        self.actions = actions

        actions.sendButtonEnabled = !messageView.textView.text.isEmpty
        messageView.textView.add(listener: self)

        textActionsController.configure(client: client, textView: messageView.textView, actions: actions)
        textActionsController.viewController = self

        actions.frame = CGRect(x: 0, y: 0, width: 0, height: 32)
        messageView.add(contentView: actions)

        //show disabled bookmark button until issue has finished loading
        navigationItem.rightBarButtonItems = [ moreOptionsItem, BookmarkNavigationController.disabledNavigationItem ]

        // insert below so button doesn't appear above autocomplete
        view.insertSubview(manageController.manageButton, belowSubview: messageView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let url = externalURL {
            setupUserActivity(with: HandoffInformator(
                activityName: "viewIssue",
                activityTitle: "\(model.owner)/\(model.repo)#\(model.number)",
                url: url
            ))
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        invalidateUserActivity()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        feed.viewWillLayoutSubviews(view: view)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        feed.collectionView.updateSafeInset(container: view, base: threadInset)
    }

    override func didLayout() {
        let manageButtonSize = manageController.manageButton.bounds.size
        manageController.manageButton.frame = CGRect(
            origin: CGPoint(
                x: view.bounds.width - manageButtonSize.width - Styles.Sizes.gutter - view.safeAreaInsets.right,
                y: messageView.frame.minY - manageButtonSize.height - Styles.Sizes.gutter),
            size: manageButtonSize
        )
    }

    func themeDidChange(_ theme: Theme) {
        view.backgroundColor = Styles.Colors.background
        messageView.backgroundColor = theme == .light ? .white : .black
        messageView.textView.textColor = theme == .light ? .black : .white
    }

    // MARK: Private API

    var externalURL: URL? {
        return URLBuilder.github().add(paths: [model.owner, model.repo, "issues", model.number]).url
    }

    var bookmark: Bookmark? {
        guard let result = result else { return nil }
        return Bookmark(
            type: result.pullRequest ? .pullRequest : .issue,
            name: model.repo,
            owner: model.owner,
            number: model.number,
            title: result.title.string.allText
        )
    }

    func configureNavigationItems() {
        guard let rightbarButtonItems = navigationItem.rightBarButtonItems else { return }
        guard let bookmarkItem = rightbarButtonItems.last else { return }
        bookmarkNavController?.configureNavigationItem(bookmarkItem)
    }

    func viewRepoAction() -> UIAlertAction? {
        return action(
            owner: model.owner,
            repo: model.repo,
            icon: #imageLiteral(resourceName: "repo"),
            client: client
        )
    }

    @objc func onMore(sender: UIBarButtonItem) {
        guard let url = externalURL else { return }
        let activityController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: [TUSafariActivity()]
        )
        activityController.popoverPresentationController?.barButtonItem = sender
        present(activityController, animated: trueUnlessReduceMotionEnabled)
    }

    func fetch(previous: Bool) {
        if !previous {
            client.fetchViewerCollaborator(
                owner: model.owner,
                repo: model.repo
            ) { [weak self] (result) in
                switch result {
                case .success(let permission):
                    let collab: Bool
                    switch permission {
                    case .admin, .write: collab = true
                    case .read, .none: collab = false
                    }
                    self?.viewerIsCollaborator = collab
                    if collab {
                        self?.manageController.permissions = .collaborator
                    }
                    // avoid finishLoading() so empty view doesn't appear
                    self?.feed.adapter.performUpdates(animated: trueUnlessReduceMotionEnabled)
                case .error(let error):
                    Squawk.show(error: error)
                }
            }
        }

        client.fetch(
            owner: model.owner,
            repo: model.repo,
            number: model.number,
            width: view.safeContentWidth(with: feed.collectionView),
            prependResult: previous ? result : nil
        ) { [weak self] resultType in
            guard let strongSelf = self else { return }

            let isFirstUpdate = strongSelf.resultID == nil

            switch resultType {
            case .success(let result, let mentionableUsers):
                strongSelf.autocompleteController.autocomplete.add(
                    UserAutocomplete(mentionableUsers: mentionableUsers)
                )
                strongSelf.client.cache.add(listener: strongSelf, value: result)
                strongSelf.resultID = result.id
                strongSelf.issueType = result.pullRequest ? .pullRequests : .issues
            default: break
            }

            // subsequent updates are handled by the FlatCacheListener
            if isFirstUpdate {
                strongSelf.updateAndScrollIfNeeded()
            }
        }
    }

    func updateAndScrollIfNeeded(dismissRefresh: Bool = true) {
        feed.finishLoading(dismissRefresh: dismissRefresh) { [weak self] in
            self?.scrollToLastContentElement()
        }
    }

    func scrollToLastContentElement() {
        guard needsScrollToBottom == true else { return }
        needsScrollToBottom = false

        guard let lastTimeline = lastTimelineElement else { return }

        // assuming the last element is the "actions" when collaborator
        feed.adapter.scroll(to: lastTimeline, padding: Styles.Sizes.rowSpacing)
    }

    func onPreview() {
        route_push(to: IssuePreviewViewController(
            markdown: messageView.text,
            owner: model.owner,
            repo: model.repo,
            title: Constants.Strings.preview
        ))
    }

    @objc func onNavigationTitle(sender: UIView) {
        let alert = UIAlertController.configured(preferredStyle: .actionSheet)
        alert.addActions([
            action(owner: model.owner, icon: #imageLiteral(resourceName: "organization")),
            viewRepoAction(),
            AlertAction.cancel()
            ])
        alert.popoverPresentationController?.setSourceView(sender)
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: ListAdapterDataSource

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard let current = self.result else { return [] }

        var objects = [ListDiffable]()

        // BEGIN collect metadata that lives between title and root comment
        var metadata = [ListDiffable]()
        metadata.append(current.labels)
        if let milestone = current.milestone {
            metadata.append(milestone)
        }
        if current.assignee.users.count > 0 {
            metadata.append(current.assignee)
        }
        if let reviewers = current.reviewers {
            metadata.append(reviewers)
        }
        if let changes = current.fileChanges {
            metadata.append(IssueFileChangesModel(changes: changes))
        }
        // END metadata collection

        objects.append(IssueTitleModel(string: current.title))
        objects += metadata

        if let targetBranch = current.targetBranch {
            objects.append(targetBranch)
        }

        if let rootComment = current.rootComment {
            objects.append(rootComment)
            objects.append(SpacerModel(position: objects.count))
        }

        if current.hasPreviousPage {
            objects.append(IssueNeckLoadModel())
        }

        let timelineViewModels = current.timelineViewModels
        for (i, model) in timelineViewModels.enumerated() {
            let needsSpacer = model.needsSpacer

            // append a spacer if the previous timeline element wasn't a comment
            if needsSpacer, i > 0
                && !(timelineViewModels[i-1].needsSpacer || timelineViewModels[i-1].needsSpacer) {
                objects.append(SpacerModel(position: objects.count))
            }

            objects.append(model)

            // always append a spacer unless its the last item in the timeline
            if needsSpacer, i < timelineViewModels.count - 1 {
                objects.append(SpacerModel(position: objects.count))
            }
        }

        // side effect so to jump to the last element when auto scrolling
        lastTimelineElement = objects.last

        if current.labels.status.status == .open,
            let merge = current.mergeModel {
            objects.append(merge)
        }

        return objects
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        switch object {
        // header and metadata
        case is IssueTitleModel: return IssueTitleSectionController()
        case is IssueLabelsModel: return IssueLabelsSectionController(issue: model, tapDelegate: self)
        case is IssueAssigneesModel: return IssueAssigneesSectionController()
        case is Milestone: return IssueMilestoneSectionController(issueModel: model)
        case is IssueFileChangesModel: return IssueViewFilesSectionController(issueModel: model, client: client)
        case is IssueTargetBranchModel: return IssueTargetBranchSectionController()

        // timeline
        case is IssueCommentModel:
            return IssueCommentSectionController(
                model: model,
                client: client,
                autocomplete: autocompleteController.autocomplete.copy,
                issueCommentDelegate: self
            )
        case is IssueLabeledModel: return IssueLabeledSectionController(issueModel: model, tapDelegate: self)
        case is IssueStatusEventModel: return IssueStatusEventSectionController(issueModel: model)
        case is IssueReferencedModel: return IssueReferencedSectionController(client: client)
        case is IssueReferencedCommitModel: return IssueReferencedCommitSectionController()
        case is IssueRenamedModel: return IssueRenamedSectionController()
        case is IssueRequestModel: return IssueRequestSectionController()
        case is IssueMilestoneEventModel: return IssueMilestoneEventSectionController()
        case is IssueCommitModel: return IssueCommitSectionController(issueModel: model)
        case is SpacerModel: return SpacerSectionController()

        // controls
        case is IssueNeckLoadModel: return IssueNeckLoadSectionController(delegate: self)
        case is IssueMergeModel: return IssueMergeSectionController(
            model: model,
            client: client,
            mergeCapable: viewerIsCollaborator,
            resultID: resultID
            )

        // deprecated
        case is IssueDiffHunkModel: return IssueDiffHunkSectionController()
        case is IssueReviewModel: return IssueReviewSectionController(
            model: model,
            client: client,
            autocomplete: autocompleteController.autocomplete.copy
            )

        default: fatalError("Unhandled object: \(object)")
        }
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        switch feed.status {
        case .idle:
            let emptyView = EmptyView()
            emptyView.label.text = NSLocalizedString("Issue cannot be found", comment: "")
            emptyView.delegate = self
            emptyView.button.isHidden = false
            return emptyView
        case .loading, .loadingNext, .initial:
            return nil
        }
    }

    // MARK: FeedDelegate

    func loadFromNetwork(feed: Feed) {
        fetch(previous: false)
    }

    func loadNextPage(feed: Feed) -> Bool {
        return false
    }

    // MARK: AddCommentListener

    func didSendComment(
        client: AddCommentClient,
        id: String,
        commentFields: CommentFields,
        reactionFields: ReactionFields,
        viewerCanUpdate: Bool,
        viewerCanDelete: Bool
        ) {
        self.actions?.isProcessing = false
        guard let previous = result,
            let comment = createCommentModel(
                id: id,
                commentFields: commentFields,
                reactionFields: reactionFields,
                contentSizeCategory: UIContentSizeCategory.preferred,
                width: view.safeContentWidth(with: feed.collectionView),
                owner: model.owner,
                repo: model.repo,
                threadState: .single,
                viewerCanUpdate: viewerCanUpdate,
                viewerCanDelete: viewerCanDelete,
                isRoot: false
            )
            else { return }

        needsScrollToBottom = true

        let newResult = previous.updated(
            timelinePages: previous.timelinePages(appending: [comment])
        )
        self.client.cache.set(value: newResult)
    }

    func didFailSendingComment(client: AddCommentClient, subjectId: String, body: String) {
        self.actions?.isProcessing = false
        messageView.text = body
    }

    // MARK: FeedSelectionProviding

    var feedContainsSelection: Bool {
        return feed.collectionView.indexPathsForSelectedItems?.count != 0
    }

    // MARK: IssueNeckLoadSectionControllerDelegate

    func didSelect(sectionController: IssueNeckLoadSectionController) {
        fetch(previous: true)
    }

    // MARK: FlatCacheListener

    func flatCacheDidUpdate(cache: FlatCache, update: FlatCache.Update) {
        switch update {
        case .item(let item):
            guard item is IssueResult else { break }
            updateAndScrollIfNeeded()
        case .list, .clear: break
        }
    }

    // MARK: IssueCommentSectionControllerDelegate

    func didSelectReply(to sectionController: IssueCommentSectionController, commentModel: IssueCommentModel) {
        setMessageView(hidden: false, animated: true)
        messageView.textView.becomeFirstResponder()
        let quote = getCommentUntilNewLine(from: commentModel.rawMarkdown)
        messageView.text = "\(messageView.text)\n>\(quote)\n\n@\(commentModel.details.login) "

        feed.adapter.scroll(to: commentModel, padding: Styles.Sizes.rowSpacing)
    }

    private func getCommentUntilNewLine(from string: String) -> String {
        let substring = string.components(separatedBy: .newlines)[0]
        if string == substring {
            return string
        }
        return substring + " ..."
    }

    // MARK: IssueTextActionsViewSendDelegate

    func didSend(for actionsView: IssueTextActionsView) {
        // get text before calling super b/c it will clear it
        let text = messageView.text
        messageView.text = ""
        actions?.sendButtonEnabled = false

        if let id = resultID {
            addCommentClient.addComment(
                subjectId: id,
                body: text
            )
        }
    }

    // MARK: EmptyViewDelegate

    func didTapRetry(view: EmptyView) {
        feed.refreshHead()
    }

    // MARK: MessageTextViewListener

    func didChange(textView: MessageTextView) {
        actions?.sendButtonEnabled = !textView.text.isEmpty
    }

    func didChangeSelection(textView: MessageTextView) {}
    func willChangeRange(textView: MessageTextView, to range: NSRange) {}

    // MARK: IssueLabelsSectionControllerDelegate

    func didTapIssueLabel(owner: String, repo: String, label: String) {
        guard let issueType = self.issueType else { return }
        presentLabels(client: client, owner: owner, repo: repo, label: label, type: issueType)
    }

    // MARK: IssueManagingContextControllerDelegate

    func willMutateModel(from controller: IssueManagingContextController) {
        needsScrollToBottom = true
    }

}
