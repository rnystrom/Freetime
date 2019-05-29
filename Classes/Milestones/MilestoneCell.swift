//
//  MilestoneCell2.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/3/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class MilestoneCell2: SelectableCell {

    public let label = UILabel()
    public let detailLabel = UILabel()
    private let checkedImageView = UIImageView(image: UIImage(named: "check-small").withRenderingMode(.alwaysTemplate))

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

        contentView.addSubview(label)
        label.font = Styles.Text.bodyBold.preferredFont
        label.textColor = .white
        label.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.right.lessThanOrEqualTo(checkedImageView.snp.left)
            make.bottom.equalTo(contentView.snp.centerY)
        }

        contentView.addSubview(detailLabel)
        detailLabel.font = Styles.Text.secondary.preferredFont
        detailLabel.textColor = Styles.Colors.Gray.light.color
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(label)
            make.right.lessThanOrEqualTo(checkedImageView.snp.left)
            make.top.equalTo(label.snp.bottom)
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
