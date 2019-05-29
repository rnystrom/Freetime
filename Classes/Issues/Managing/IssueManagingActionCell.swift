//
//  IssueManagingActionCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/13/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit
import SnapKit

final class IssueManagingActionCell: UICollectionViewCell, ListBindable {

    private let label = UILabel()
    private let imageView = UIImageView()

    static let iconHeight = Styles.Sizes.buttonIcon.height + Styles.Sizes.rowSpacing * 2
    static let height = ceil(iconHeight + Styles.Sizes.rowSpacing * 2.5 + Styles.Text.secondary.preferredFont.lineHeight)

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        let tint = Styles.Colors.Blue.medium.color

        contentView.layer.cornerRadius = Styles.Sizes.cardCornerRadius

        let iconSize = IssueManagingActionCell.iconHeight
        imageView.contentMode = .bottom
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: iconSize, height: iconSize))
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-iconSize/2)
        }

        label.textColor = tint
        label.font = Styles.Text.secondaryBold.preferredFont
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalTo(imageView)
            make.top.equalTo(imageView.snp.bottom).offset(Styles.Sizes.rowSpacing/2 + 2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            highlight(isSelected)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            highlight(isHighlighted)
        }
    }

    // MARK: Private API

    func highlight(_ highlight: Bool) {
        let alpha: CGFloat = highlight ? 0.5 : 1
        label.alpha = alpha
        imageView.alpha = alpha
    }

    // MARK: ListBindable

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? IssueManagingActionModel else { return }
        label.text = viewModel.label
        imageView.image = UIImage(named: viewModel.imageName)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = viewModel.color
        contentView.backgroundColor = viewModel.color.withAlphaComponent(0.2)
        label.textColor = viewModel.color
    }

    // MARK: Accessibility
    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }
}
