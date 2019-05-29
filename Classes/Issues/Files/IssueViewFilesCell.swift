//
//  IssueViewFilesCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/11/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class IssueViewFilesCell: UICollectionViewCell {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    // MARK: Public API

    func configure(changes: FileChanges) {
        let attributedText = NSMutableAttributedString()

        let actionFormat = NSLocalizedString("View Files (%d) ", comment: "")
        attributedText.append(NSAttributedString(
            string: String(format: actionFormat, changes.changedFiles),
            attributes: [
                .font: Styles.Text.secondary.preferredFont,
                .foregroundColor: Styles.Colors.Blue.medium.color
            ]
        ))
        if changes.additions > 0 {
            attributedText.append(NSAttributedString(
                string: "+\(changes.additions) ", // note trailing space
                attributes: [
                    .font: Styles.Text.secondaryBold.preferredFont,
                    .foregroundColor: Styles.Colors.Green.medium.color
                ]
            ))
        }
        if changes.deletions > 0 {
            attributedText.append(NSAttributedString(
                string: "-\(changes.deletions)",
                attributes: [
                    .font: Styles.Text.secondaryBold.preferredFont,
                    .foregroundColor: Styles.Colors.Red.medium.color
                ]
            ))
        }
        label.attributedText = attributedText

        accessibilityLabel = NSLocalizedString(
            "View Files",
            comment: "The accessibility label for the View Files button in a pull request.")
        let hintFormat = NSLocalizedString(
            "View %zi files with %zi additions and %zi deletions.",
            comment: "The accessibility hint with details of the View Files button.")
        accessibilityHint = String(format: hintFormat, arguments: [changes.changedFiles, changes.additions, changes.deletions])
    }

}
