//
//  UINavigationItem+TitleSubtitle.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/26/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UINavigationItem {

    func configure(filePath: FilePath) {
        let accessibilityLabel: String?
        switch (filePath.current, filePath.basePath) {
        case (.some(let current), .some(let basePath)):
            let isCurrentAFile = filePath.fileExtension != nil
            let currentType = isCurrentAFile ? "File" : "Folder"
            accessibilityLabel = .localizedStringWithFormat("%@: %@, file path: %@", currentType, current, basePath)
        case (.some(let current), .none):
            // NOTE: This is currently unused, as we early-exit
            // and set the navigationItem's title, but not it's titleView -
            // and thus we can't set an accessibility label.
            let isFile = filePath.fileExtension != nil
            let type = isFile ? "File" : "File path"
            accessibilityLabel = .localizedStringWithFormat("%@: %@", type, current)
        case (.none, .some(let basePath)):
            assert(false, "We should never have just a base path; this should always be accompanied by a current path!")
            accessibilityLabel = .localizedStringWithFormat("File path: %@", basePath)
        case (.none, .none):
            accessibilityLabel = nil
        }
        configure(title: filePath.current, subtitle: filePath.basePath, accessibilityLabel: accessibilityLabel)
    }

    func configure(title: String?, subtitle: String?, accessibilityLabel: String? = nil) {
        guard let title = title else { return }

        guard let subtitle = subtitle, !subtitle.isEmpty else {
            self.title = title
            return
        }

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Styles.Text.bodyBold.preferredFont,
            .foregroundColor: Styles.Colors.Gray.dark.color
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: Styles.Text.secondaryBold.preferredFont,
            .foregroundColor: Styles.Colors.Gray.light.color
        ]

        let attributedTitle = NSMutableAttributedString(string: title, attributes: titleAttributes)
        attributedTitle.append(NSAttributedString(string: "\n"))
        attributedTitle.append(NSAttributedString(string: subtitle, attributes: subtitleAttributes))

        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = attributedTitle
        label.lineBreakMode = .byTruncatingHead
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()

        titleView = label
        if let accessibilityLabel = accessibilityLabel { // prevent from setting to nil if we don't provide anything, use default instead
            titleView?.accessibilityLabel = accessibilityLabel
        }
    }

    func configure(title: NSAttributedString, accessibilityLabel: String? = nil) {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = title
        label.lineBreakMode = .byTruncatingHead
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()

        titleView = label
        if let accessibilityLabel = accessibilityLabel { // prevent from setting to nil if we don't provide anything, use default instead
            titleView?.accessibilityLabel = accessibilityLabel
        }
    }

}
