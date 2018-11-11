//
//  IssueReviewSectionController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/5/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

final class IssueReviewSectionController: ListBindingSectionController<IssueReviewModel>,
    ListBindingSectionControllerDataSource,
IssueReviewDetailsCellDelegate,
IssueReviewViewCommentsCellDelegate,
MarkdownStyledTextViewDelegate {

    private lazy var webviewCache: WebviewCellHeightCache = {
        return WebviewCellHeightCache(sectionController: self)
    }()
    private lazy var imageCache: ImageCellHeightCache = {
        return ImageCellHeightCache(sectionController: self)
    }()
    private lazy var photoHandler: PhotoViewHandler = {
        return PhotoViewHandler(viewController: self.viewController)
    }()

    private let model: IssueDetailsModel
    private let viewCommentsModel = "viewComments" as ListDiffable
    private let tailModel = "tail" as ListDiffable
    private let client: GithubClient
    private let autocomplete: IssueCommentAutocomplete

    init(model: IssueDetailsModel, client: GithubClient, autocomplete: IssueCommentAutocomplete) {
        self.model = model
        self.client = client
        self.autocomplete = autocomplete
        super.init()
        self.dataSource = self
    }

    // MARK: Private API

    func didTap(attribute: DetectedMarkdownAttribute) {
        if viewController?.handle(attribute: attribute) == true {
            return
        }
        switch attribute {
        case .issue(let issue):
            viewController?.route_push(to: IssuesViewController(client: client, model: issue))
        default: break
        }
    }

    // MARK: ListBindingSectionControllerDataSource

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        viewModelsFor object: Any
        ) -> [ListDiffable] {
        guard let object = self.object else { fatalError("Wrong model object") }
        return [object.details]
            + object.bodyModels
            + [object.commentCount > 0 ? viewCommentsModel : tailModel]
    }

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        sizeForViewModel viewModel: Any,
        at index: Int
        ) -> CGSize {
        guard let viewModel = viewModel as? ListDiffable
            else { fatalError("Missing context") }
        // use default if IssueReviewDetailsModel
        let height: CGFloat
        if viewModel === tailModel {
            height = Styles.Sizes.rowSpacing
        } else if viewModel === viewCommentsModel {
            height = Styles.Sizes.tableCellHeight
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
            else { fatalError("Missing context") }

        if viewModel === tailModel {
            guard let cell = context.dequeueReusableCell(of: IssueReviewEmptyTailCell.self, for: self, at: index) as? UICollectionViewCell & ListBindable
                else { fatalError("Cell not bindable") }
            return cell
        } else if viewModel === viewCommentsModel {
            guard let cell = context.dequeueReusableCell(of: IssueReviewViewCommentsCell.self, for: self, at: index) as? IssueReviewViewCommentsCell
                else { fatalError("Cell not bindable") }
            cell.delegate = self
            return cell
        }

        let cellClass: AnyClass
        switch viewModel {
        case is IssueReviewDetailsModel: cellClass = IssueReviewDetailsCell.self
        default: cellClass = CellTypeForComment(viewModel: viewModel)
        }
        guard let cell = context.dequeueReusableCell(of: cellClass, for: self, at: index) as? UICollectionViewCell & ListBindable
            else { fatalError("Cell not bindable") }

        ExtraCommentCellConfigure(
            cell: cell,
            imageDelegate: photoHandler,
            htmlDelegate: webviewCache,
            htmlNavigationDelegate: viewController,
            htmlImageDelegate: photoHandler,
            markdownDelegate: self,
            imageHeightDelegate: imageCache
        )

        if let cell = cell as? IssueReviewDetailsCell {
            cell.delegate = self
        }

        return cell
    }

    // MARK: IssueReviewDetailsCellDelegate

    func didTapActor(cell: IssueReviewDetailsCell) {
        guard let actor = object?.details.actor else { return }
        viewController?.presentProfile(login: actor)
    }

    // MARK: MarkdownStyledTextViewDelegate

    func didTap(cell: MarkdownStyledTextView, attribute: DetectedMarkdownAttribute) {
        didTap(attribute: attribute)
    }

    // MARK: IssueReviewViewCommentsCellDelegate

    func didTapViewComments(cell: IssueReviewViewCommentsCell) {
        viewController?.route_push(to: PullRequestReviewCommentsViewController(
            model: model,
            client: client,
            autocomplete: autocomplete
        ))
    }

}
