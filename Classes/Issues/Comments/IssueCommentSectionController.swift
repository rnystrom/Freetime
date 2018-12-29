//
//  IssueCommentSectionController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/19/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit
import TUSafariActivity
import Squawk
import GitHubAPI
import ContextMenu

protocol IssueCommentSectionControllerDelegate: class {
    func didSelectReply(
        to sectionController: IssueCommentSectionController,
        commentModel: IssueCommentModel
    )
}

final class IssueCommentSectionController: ListBindingSectionController<IssueCommentModel>,
    ListBindingSectionControllerDataSource,
    ListBindingSectionControllerSelectionDelegate,
    IssueCommentDetailCellDelegate,
    IssueCommentReactionCellDelegate,
    EditCommentViewControllerDelegate,
    MarkdownStyledTextViewDelegate,
    IssueCommentDoubleTapDelegate,
    ContextMenuDelegate {

    private weak var issueCommentDelegate: IssueCommentSectionControllerDelegate?

    private var collapsed = true
    private let generator = UIImpactFeedbackGenerator()
    private let client: GithubClient
    private let model: IssueDetailsModel
    private var hasBeenDeleted = false
    private let autocomplete: IssueCommentAutocomplete

    private lazy var webviewCache: WebviewCellHeightCache = {
        return WebviewCellHeightCache(sectionController: self)
    }()
    private lazy var photoHandler: PhotoViewHandler = {
        return PhotoViewHandler(viewController: self.viewController)
    }()
    private lazy var imageCache: ImageCellHeightCache = {
        return ImageCellHeightCache(sectionController: self)
    }()

    // set when sending a mutation and override the original issue query reactions
    private var reactionMutation: IssueCommentReactionViewModel?

    // set after succesfully editing the body
    private var bodyEdits: (markdown: String, models: [ListDiffable])?

    private var currentMarkdown: String? {
        return bodyEdits?.markdown ?? object?.rawMarkdown
    }

    // empty space cell placeholders
    private let headModel = "headModel" as ListDiffable
    private let tailModel = "tailModel" as ListDiffable

    init(model: IssueDetailsModel,
         client: GithubClient,
         autocomplete: IssueCommentAutocomplete,
         issueCommentDelegate: IssueCommentSectionControllerDelegate? = nil
        ) {
        self.model = model
        self.client = client
        self.autocomplete = autocomplete
        super.init()
        self.dataSource = self
        self.selectionDelegate = self
        self.issueCommentDelegate = issueCommentDelegate
    }

    override func didUpdate(to object: Any) {
        super.didUpdate(to: object)
        inset = self.object?.commentSectionControllerInset ?? .zero
    }

    // MARK: Private API

    func shareAction(sender: UIView) -> UIAlertAction? {
        let attribute = object?.asReviewComment == true ? "discussion_r" : "issuecomment-"
        guard let number = object?.number,
            let url = URLBuilder.github()
                .add(paths: [model.owner, model.repo, "issues", model.number])
                .set(fragment: "\(attribute)\(number)")
                .url
        else { return nil }
        weak var weakSelf = self

        return AlertAction(AlertActionBuilder { $0.rootViewController = weakSelf?.viewController })
            .share([url], activities: [TUSafariActivity()], type: .shareUrl) { $0.popoverPresentationController?.sourceView = sender }
    }

    var deleteAction: UIAlertAction? {
        guard object?.viewerCanDelete == true else { return nil }

        return AlertAction.delete { [weak self] _ in
            let title = NSLocalizedString("Are you sure?", comment: "")
            let message = NSLocalizedString("Deleting this comment is irreversible, do you want to continue?", comment: "")
            let alert = UIAlertController.configured(title: title, message: message, preferredStyle: .alert)

            alert.addActions([
                AlertAction.cancel(),
                AlertAction.delete { [weak self] _ in
                    self?.deleteComment()
                }
            ])

            self?.viewController?.present(alert, animated: trueUnlessReduceMotionEnabled)
        }
    }

    var editAction: UIAlertAction? {
        guard object?.viewerCanUpdate == true else { return nil }
        return UIAlertAction(title: NSLocalizedString("Edit", comment: ""), style: .default, handler: { [weak self] _ in
            guard let strongSelf = self,
                let object = strongSelf.object,
                let number = object.number,
                let markdown = strongSelf.currentMarkdown
                else { return }

            let edit = EditCommentViewController(
                client: strongSelf.client,
                markdown: markdown,
                issueModel: strongSelf.model,
                commentID: number,
                isRoot: object.isRoot,
                autocomplete: strongSelf.autocomplete
            )
            edit.delegate = self
            let nav = NavigationController(rootViewController: edit)
            nav.modalPresentationStyle = .formSheet
            self?.viewController?.route_present(to: nav)
        })
    }

    var replyAction: UIAlertAction? {
        return UIAlertAction(
            title: NSLocalizedString("Reply", comment: ""),
            style: .default,
            handler: { [weak self] _ in
                guard let strongSelf = self,
                let commentModel = strongSelf.object
                else { return }

                strongSelf.issueCommentDelegate?.didSelectReply(
                    to: strongSelf,
                    commentModel: commentModel
                )
            }
        )
    }

    var viewMarkdownAction: UIAlertAction? {
        return UIAlertAction(
            title: NSLocalizedString("View Markdown", comment: ""),
            style: .default,
            handler: { [weak self] _ in
                guard let markdown = self?.object?.rawMarkdown else { return }
                let nav = NavigationController(
                    rootViewController: ViewMarkdownViewController(markdown: markdown)
                )
                self?.viewController?.route_present(to: nav)
            }
        )
    }

    private func clearCollapseCells() {
        // clear any collapse state before updating so we don't have a dangling overlay
        for cell in collectionContext?.visibleCells(for: self) ?? [] {
            if let cell = cell as? IssueCommentBaseCell {
                cell.collapsed = false
            }
        }
    }

    @discardableResult
    private func uncollapse() -> Bool {
        guard collapsed else { return false }
        collapsed = false
        clearCollapseCells()
        collectionContext?.invalidateLayout(for: self, completion: nil)
        update(animated: trueUnlessReduceMotionEnabled)
        return true
    }

    private func react(cell: IssueCommentReactionCell?, content: ReactionContent, isAdd: Bool) {
        guard let object = self.object else { return }

        let previousReaction = reactionMutation
        let result = IssueLocalReaction(
            fromServer: object.reactions,
            previousLocal: reactionMutation,
            content: content,
            add: isAdd
        )
        reactionMutation = result.viewModel

        cell?.perform(operation: result.operation, content: content)

        update(animated: trueUnlessReduceMotionEnabled)
        generator.impactOccurred()
        client.react(subjectID: object.id, content: content, isAdd: isAdd) { [weak self] result in
            if result == nil {
                self?.reactionMutation = previousReaction
                self?.update(animated: trueUnlessReduceMotionEnabled)
            }
        }
    }

    func edit(markdown: String) {
        let width = collectionContext.cellWidth()
        let bodyModels = MarkdownModels(
            // strip githawk signatures on edit
            CheckIfSentWithGitHawk(markdown: markdown).markdown,
            owner: model.owner,
            repo: model.repo,
            width: width,
            viewerCanUpdate: true,
            contentSizeCategory: UIContentSizeCategory.preferred,
            isRoot: self.object?.isRoot == true
        )
        bodyEdits = (markdown, bodyModels)
        collapsed = false
        clearCollapseCells()
        update(animated: trueUnlessReduceMotionEnabled)
    }

    func didTap(attribute: DetectedMarkdownAttribute) {
        if viewController?.handle(attribute: attribute) == true {
            return
        }
        switch attribute {
        case .issue(let issue):
            viewController?.route_push(to: IssuesViewController(client: client, model: issue))
        case .checkbox(let checkbox):
            didTapCheckbox(checkbox: checkbox)
        default: break
        }
    }

    /// Deletes the comment and optimistically removes it from the feed
    private func deleteComment() {
        guard let number = object?.number else { return }

        // Optimistically delete the comment
        hasBeenDeleted = true
        update(animated: trueUnlessReduceMotionEnabled)

        client.client.send(V3DeleteCommentRequest(
            owner: model.owner,
            repo: model.repo,
            commentID: "\(number)")
        ) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.hasBeenDeleted = false
                self?.update(animated: trueUnlessReduceMotionEnabled)
                Squawk.show(error: error)
            case .success: break // Don't need to handle success since updated optimistically
            }
        }
    }

    func didTapCheckbox(checkbox: MarkdownCheckboxModel) {
        guard object?.viewerCanUpdate == true,
            let commentID = object?.number,
            let isRoot = object?.isRoot,
            let originalMarkdown = currentMarkdown
            else { return }

        let range = checkbox.originalMarkdownRange
        let originalMarkdownNSString = originalMarkdown as NSString
        guard range.location + range.length < originalMarkdownNSString.length
            else { return }

        let invertedToken = checkbox.checked ? "[ ]" : "[x]"
        let edited = originalMarkdownNSString.replacingCharacters(in: range, with: invertedToken)
        edit(markdown: edited)

        client.client.send(V3EditCommentRequest(
            owner: model.owner,
            repo: model.repo,
            issueNumber: model.number,
            commentID: commentID,
            body: edited,
            isRoot: isRoot)
        ) { [weak self] result in
            switch result {
            case .success: break
            case .failure(let error):
                self?.edit(markdown: originalMarkdown)
                Squawk.show(error: error)
            }
        }
    }

    // MARK: ListBindingSectionControllerDataSource

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        viewModelsFor object: Any
        ) -> [ListDiffable] {
        guard let object = self.object else { return [] }
        guard !hasBeenDeleted else { return [] }

        var bodies = [ListDiffable]()
        let bodyModels = bodyEdits?.models ?? object.bodyModels
        for body in bodyModels {
            bodies.append(body)
            if collapsed && body === object.collapse?.model {
                break
            }
        }

        // if this is a PR comment, if this is the tail model, append an empty space cell at the end so there's a divider
        // otherwise append reactions
        let tail: [ListDiffable] = object.asReviewComment
            ? (object.threadState == .tail ? [tailModel] : [])
            : [ reactionMutation ?? object.reactions ]

//        return [ object.details, headModel ]
        return [ object.details ]
            + bodies
            + tail
    }

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        sizeForViewModel viewModel: Any,
        at index: Int
        ) -> CGSize {
        guard let viewModel = viewModel as? ListDiffable
            else { fatalError("Collection context must be set") }

        let height: CGFloat
        if collapsed && (viewModel as AnyObject) === object?.collapse?.model {
            height = object?.collapse?.height ?? 0
        } else if viewModel is IssueCommentReactionViewModel {
            height = 38.0
        } else if viewModel is IssueCommentDetailsViewModel {
            height = Styles.Sizes.rowSpacing * 2 + Styles.Sizes.avatar.height
        } else if viewModel === tailModel || viewModel === headModel {
            height = Styles.Sizes.rowSpacing
        } else {
            height = BodyHeightForComment(
                viewModel: viewModel,
                width: collectionContext.safeContentWidth(),
                webviewCache: webviewCache,
                imageCache: imageCache
            )
        }
        return collectionContext.cellSize(with: height)
    }

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        cellForViewModel viewModel: Any,
        at index: Int
        ) -> UICollectionViewCell & ListBindable {
        guard let context = self.collectionContext,
            let viewModel = viewModel as? ListDiffable
            else { fatalError("Collection context must be set") }

        if viewModel === tailModel {
            guard let cell = context.dequeueReusableCell(of: IssueReviewEmptyTailCell.self, for: self, at: index) as? UICollectionViewCell & ListBindable
                else { fatalError("Cell not bindable") }
            return cell
        } else if viewModel === headModel {
            guard let cell = context.dequeueReusableCell(of: IssueCommentEmptyCell.self, for: self, at: index) as? IssueCommentEmptyCell
                else { fatalError("Wrong cell type") }
            return cell
        }

        let cellClass: AnyClass
        switch viewModel {
        case is IssueCommentDetailsViewModel: cellClass = IssueCommentDetailCell.self
        case is IssueCommentReactionViewModel: cellClass = IssueCommentReactionCell.self
        default: cellClass = CellTypeForComment(viewModel: viewModel)
        }

        guard let cell = context.dequeueReusableCell(of: cellClass, for: self, at: index) as? UICollectionViewCell & ListBindable
            else { fatalError("Cell not bindable") }

        // extra config outside of bind API. applies to multiple cell types.
        if let cell = cell as? IssueCommentBaseCell {
            cell.collapsed = collapsed && (viewModel as AnyObject) === object?.collapse?.model
        }

        // connect specific cell delegates
        if let cell = cell as? IssueCommentDetailCell {
            cell.delegate = self
        } else if let cell = cell as? IssueCommentReactionCell {
            cell.delegate = self
        }

        if let object = self.object,
            !object.asReviewComment,
            let cell = cell as? IssueCommentBaseCell {
            cell.doubleTapDelegate = self
        }

        ExtraCommentCellConfigure(
            cell: cell,
            imageDelegate: photoHandler,
            htmlDelegate: webviewCache,
            htmlNavigationDelegate: viewController,
            htmlImageDelegate: photoHandler,
            markdownDelegate: self,
            imageHeightDelegate: imageCache
        )

        return cell
    }

    // MARK: ListBindingSectionControllerSelectionDelegate

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        didSelectItemAt index: Int,
        viewModel: Any
        ) {
        switch viewModel {
        case is IssueCommentReactionViewModel,
             is IssueCommentDetailsViewModel: return
        default: break
        }
        uncollapse()
    }

    // MARK: IssueCommentDoubleTapDelegate

    func didDoubleTap(cell: IssueCommentBaseCell) {
        guard let reaction = ReactionContent.defaultReaction else { return }
        guard let reactions = reactionMutation ?? self.object?.reactions,
            !reactions.viewerDidReact(reaction: reaction)
            else { return }

        react(
            cell: collectionContext?.cellForItem(at: numberOfItems() - 1, sectionController: self) as? IssueCommentReactionCell,
            content: reaction,
            isAdd: true
        )
    }

    // MARK: IssueCommentDetailCellDelegate

    func didTapProfile(cell: IssueCommentDetailCell) {
        guard let login = object?.details.login else {
            Squawk.showGenericError()
            return
        }

        viewController?.presentProfile(login: login)
    }

    // MARK: IssueCommentReactionCellDelegate

    func didAdd(cell: IssueCommentReactionCell, reaction: ReactionContent) {
        // don't add a reaction if already reacted
        guard let reactions = reactionMutation ?? self.object?.reactions,
            !reactions.viewerDidReact(reaction: reaction)
            else { return }

        react(cell: cell, content: reaction, isAdd: true)
    }

    func didRemove(cell: IssueCommentReactionCell, reaction: ReactionContent) {
        // don't remove a reaction if it doesn't exist
        guard let reactions = reactionMutation ?? self.object?.reactions,
            reactions.viewerDidReact(reaction: reaction)
            else { return }

        react(cell: cell, content: reaction, isAdd: false)
    }

    func didTapMore(cell: IssueCommentReactionCell, sender: UIView) {
        guard let login = object?.details.login else {
            Squawk.showGenericError()
            return
        }

        let alertTitle = NSLocalizedString("%@'s comment", comment: "Used in an action sheet title, eg. \"Basthomas's comment\".")

        let alert = UIAlertController.configured(
            title: String(format: alertTitle, login),
            preferredStyle: .actionSheet
        )
        alert.popoverPresentationController?.sourceView = sender
        alert.addActions([
            shareAction(sender: sender),
            viewMarkdownAction,
            editAction,
            replyAction,
            deleteAction,
            AlertAction.cancel()
            ])
        viewController?.present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    func didTapAddReaction(cell: IssueCommentReactionCell, sender: UIView) {
        guard let viewController = self.viewController else { return }
        ContextMenu.shared.show(
            sourceViewController: viewController,
            viewController: ReactionsMenuViewController(),
            options: ContextMenu.Options(
                durations: ContextMenu.AnimationDurations(present: 0.2),
                containerStyle: ContextMenu.ContainerStyle(
                    xPadding: -4,
                    yPadding: 8,
                    backgroundColor: Styles.Colors.menuBackgroundColor.color
                ),
                menuStyle: .minimal,
                hapticsStyle: .medium
            ),
            sourceView: sender,
            delegate: self
        )
    }

    // MARK: MarkdownStyledTextViewDelegate

    func didTap(cell: MarkdownStyledTextView, attribute: DetectedMarkdownAttribute) {
        didTap(attribute: attribute)
    }

    // MARK: EditCommentViewControllerDelegate

    func didEditComment(viewController: EditCommentViewController, markdown: String) {
        viewController.dismiss(animated: trueUnlessReduceMotionEnabled)
        edit(markdown: markdown)
    }

    func didCancel(viewController: EditCommentViewController) {
        viewController.dismiss(animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: ContextMenuDelegate

    func contextMenuWillDismiss(viewController: UIViewController, animated: Bool) {}

    func contextMenuDidDismiss(viewController: UIViewController, animated: Bool) {
        guard let reactionViewController = viewController as? ReactionsMenuViewController,
            let reaction = reactionViewController.selectedReaction,
            let reactions = reactionMutation ?? self.object?.reactions
            else { return }

        var index = -1
        for (i, model) in viewModels.reversed().enumerated() where model is IssueCommentReactionViewModel {
            index = viewModels.count - 1 - i
            break
        }

        guard index >= 0 else { return }
        react(
            cell: collectionContext?.cellForItem(at: index, sectionController: self) as? IssueCommentReactionCell,
            content: reaction,
            isAdd: !reactions.viewerDidReact(reaction: reaction)
        )
    }

}
