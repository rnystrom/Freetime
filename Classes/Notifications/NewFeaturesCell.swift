//
//  NewFeaturesCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/22/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

protocol NewFeaturesCellDelegate: class {
    func didTapClose(for cell: NewFeaturesCell)
}

final class NewFeaturesCell: UICollectionViewCell {

    static let inset = UIEdgeInsets(
        top: Styles.Sizes.rowSpacing,
        left: Styles.Sizes.gutter,
        bottom: Styles.Sizes.rowSpacing,
        right: Styles.Sizes.gutter
    )

    weak var delegate: NewFeaturesCellDelegate?

    private let label = UILabel()
    private let closeButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true

        backgroundColor = .white
        contentView.backgroundColor = Styles.Colors.Blue.light.color
        contentView.layer.cornerRadius = Styles.Sizes.cardCornerRadius
        contentView.layer.borderWidth = 1 / UIScreen.main.scale
        contentView.layer.borderColor = Styles.Colors.blueGray.color.cgColor

        contentView.addSubview(label)
        contentView.addSubview(closeButton)

        let tint = Styles.Colors.Blue.medium.color
        label.textColor = tint
        label.font = Styles.Text.secondaryBold.preferredFont
        label.isAccessibilityElement = false

        let closeButtonSize = Styles.Sizes.icon.width
        closeButton.setImage(UIImage(named: "x-small").withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = tint
        closeButton.layer.cornerRadius = closeButtonSize / 2
        closeButton.addTarget(self, action: #selector(onCloseButton), for: .touchUpInside)
        closeButton.accessibilityLabel = NSLocalizedString("Dismiss new feature modal", comment: "")

        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(Styles.Sizes.gutter)
            make.right.lessThanOrEqualTo(closeButton.snp.left).offset(-Styles.Sizes.columnSpacing)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-Styles.Sizes.gutter)
            make.size.equalTo(closeButtonSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = CGRect(
            x: safeAreaInsets.left,
            y: bounds.minY,
            width: bounds.width - safeAreaInsets.left - safeAreaInsets.right,
            height: bounds.height
        ).inset(by: NewFeaturesCell.inset)
    }

    @objc private func onCloseButton() {
        delegate?.didTapClose(for: self)
    }

    func configure(with version: String) {
        label.text = String.localizedStringWithFormat(
            NSLocalizedString("New features in %@!", comment: ""),
            version
        )
    }

    override func accessibilityPerformEscape() -> Bool {
        delegate?.didTapClose(for: self)
        return true
    }

}
