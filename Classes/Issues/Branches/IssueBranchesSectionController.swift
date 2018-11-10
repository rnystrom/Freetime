//
//  IssueBranchesSectionController.swift
//  Freetime
//
//  Created by Yury Bogdanov on 13/03/2018.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

final class IssueTargetBranchSectionController: ListSectionController {

    var object: IssueTargetBranchModel?

    override func didUpdate(to object: Any) {
        guard let object = object as? IssueTargetBranchModel else { return }
        self.object = object
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return collectionContext.cellSize(
            with: object?.targetBranchText.viewSize(in: collectionContext.safeContentWidth()).height ?? 0
        )
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let object = self.object,
            let cell = collectionContext?.dequeueReusableCell(of: IssueTargetBranchCell.self, for: self, at: index) as? IssueTargetBranchCell
            else { fatalError("Collection context must be set, missing object, or cell incorrect type") }
        cell.set(renderer: object.targetBranchText)
        return cell
    }
}
