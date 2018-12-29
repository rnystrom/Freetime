//
//  RepositoryFileCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/26/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import SnapKit

final class RepositoryFileCell: SelectableCell {

    private let imageView = UIImageView()
    private let label = UILabel()
    private let disclosure = UIImageView(image: UIImage(named: "chevron-right").withRenderingMode(.alwaysTemplate))

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton

        disclosure.tintColor = Styles.Colors.Gray.light.color
        disclosure.contentMode = .scaleAspectFit
        contentView.addSubview(disclosure)
        disclosure.snp.makeConstraints { make in
            make.right.equalTo(-Styles.Sizes.gutter)
            make.centerY.equalTo(contentView)
            make.size.equalTo(Styles.Sizes.icon)
        }

        imageView.tintColor = Styles.Colors.blueGray.color
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.size.equalTo(Styles.Sizes.icon)
            make.centerY.equalTo(contentView)
        }

        label.font = Styles.Text.body.preferredFont
        label.lineBreakMode = .byTruncatingHead
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(Styles.Sizes.rowSpacing)
            make.right.lessThanOrEqualTo(disclosure.snp.left).offset(-Styles.Sizes.rowSpacing)
            make.centerY.equalTo(contentView)
        }

        addBorder(.bottom, left: Styles.Sizes.gutter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func themeDidChange(_ theme: Theme) {
        super.themeDidChange(theme)
        switch theme {
        case .light:
            label.textColor = Styles.Colors.Gray.dark.color
        case .dark:
            label.textColor = Styles.Colors.Gray.light.color
        }
    }

    // MARK: Public API

    func configure(path: String, isDirectory: Bool) {
        label.text = path

        let fileType = isDirectory
            ? NSLocalizedString("Directory", comment: "Used to specify the code cell is a directory.")
            : NSLocalizedString("File", comment: "Used to specify the code cell is a file.")
        accessibilityLabel = AccessibilityHelper
            .generatedLabel(forCell: self)
            .appending(".\n\(fileType)")
        accessibilityHint = isDirectory
            ? NSLocalizedString("Shows the contents of the directory", comment: "")
            : NSLocalizedString("Shows the contents of the file", comment: "")

        let imageName = isDirectory ? "file-directory" : "file"
        imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)

        disclosure.isHidden = !isDirectory
    }

}
