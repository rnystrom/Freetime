//
//  RepositoryEmptyResultsCell.swift
//  Freetime
//
//  Created by Sherlock, James on 01/08/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import IGListKit

final class RepositoryEmptyResultsCell: UICollectionViewCell {

    private let icon = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityTraits.insert(.staticText)
        isAccessibilityElement = true

        let tint = Styles.Colors.Gray.light.color

        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        contentView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalTo(contentView)
            make.centerY.equalTo(contentView).offset(-Styles.Sizes.tableCellHeight)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.font = Styles.Text.body.preferredFont
        label.textColor = tint
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalTo(icon)
            make.width.lessThanOrEqualTo(contentView).offset(-2*Styles.Sizes.gutter)
            make.top.equalTo(icon.snp.bottom).offset(Styles.Sizes.rowSpacing)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }

    // MARK: Public API

    func configure(_ type: RepositoryEmptyResultsType) {
        icon.image = type.icon?.withRenderingMode(.alwaysTemplate)
        label.text = type.text
    }

}
