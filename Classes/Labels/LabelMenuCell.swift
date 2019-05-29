//
//  LabelMenuCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 4/21/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class LabelMenuCell: SelectableCell {

    public let button = UIButton()
    public let checkedImageView = UIImageView(image: UIImage(named: "check-small").withRenderingMode(.alwaysTemplate))

    override init(frame: CGRect) {
        super.init(frame: frame)

        overlayColor = Styles.Colors.Gray.medium.color
        backgroundColor = nil
        contentView.backgroundColor = nil

        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        contentView.addSubview(checkedImageView)
        checkedImageView.tintColor = Styles.Colors.Blue.menu.color
        checkedImageView.snp.makeConstraints { make in
            make.right.equalTo(-Styles.Sizes.gutter)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(button)
        button.titleLabel?.font = Styles.Text.bodyBold.preferredFont
        button.layer.cornerRadius = Styles.Sizes.avatarCornerRadius
        button.clipsToBounds = true
        button.isUserInteractionEnabled = false
        button.contentEdgeInsets = UIEdgeInsets(
            top: Styles.Sizes.inlineSpacing,
            left: Styles.Sizes.columnSpacing,
            bottom: Styles.Sizes.inlineSpacing,
            right: Styles.Sizes.columnSpacing
        )
        button.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.right.lessThanOrEqualTo(checkedImageView.snp.left)
            make.centerY.equalToSuperview()
        }

        let border = contentView.addBorder(.bottom, left: Styles.Sizes.gutter, right: -Styles.Sizes.gutter)
        border.backgroundColor = Styles.Colors.Gray.medium.color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public API

    func setSelected(_ selected: Bool) {
        checkedImageView.isHidden = !selected
    }

    // MARK: Accessibility

    override var accessibilityLabel: String? {
        get { return AccessibilityHelper.generatedLabel(forCell: self) }
        set { }
    }

}
