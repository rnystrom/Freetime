//
//  MergeButton.swift
//  Freetime
//
//  Created by Ryan Nystrom on 2/12/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

protocol MergeButtonDelegate: class {
    func didSelect(button: MergeButton)
    func didSelectOptions(button: MergeButton)
}

final class MergeButton: UIControl {

    weak var delegate: MergeButtonDelegate?

    // public to use as source view for popover
    let optionButton = UIButton()

    private let mergeLabel = UILabel()
    private let optionBorder = UIView()
    private let activityView = UIActivityIndicatorView(style: .gray)
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addTouchEffect()

        addSubview(mergeLabel)
        addSubview(optionButton)
        addSubview(optionBorder)
        addSubview(activityView)

        addTarget(self, action: #selector(onMainTouch), for: .touchUpInside)
        layer.cornerRadius = Styles.Sizes.avatarCornerRadius

        let image = UIImage(named: "chevron-down").withRenderingMode(.alwaysTemplate)
        let optionButtonWidth = image.size.width + 2 * Styles.Sizes.gutter
        // more exagerated than the default given the small button size
        optionButton.addTouchEffect(UIControlEffect(
            alpha: 0.5,
            transform: CGAffineTransform(scaleX: 0.85, y: 0.85)
        ))
        optionButton.adjustsImageWhenHighlighted = false
        optionButton.imageView?.contentMode = .center
        optionButton.setImage(image, for: .normal)
        optionButton.isAccessibilityElement = true
        optionButton.accessibilityTraits = .button
        optionButton.addTarget(self, action: #selector(onOptionsTouch), for: .touchUpInside)
        optionButton.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.width.equalTo(optionButtonWidth)
        }

        mergeLabel.font = Styles.Text.bodyBold.preferredFont
        mergeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-optionButtonWidth/2)
        }

        optionBorder.alpha = 0.7
        optionBorder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Styles.Sizes.rowSpacing/2)
            make.bottom.equalToSuperview().offset(-Styles.Sizes.rowSpacing/2)
            make.width.equalTo(1/UIScreen.main.scale)
            make.right.equalTo(optionButton.snp.left)
        }

        activityView.hidesWhenStopped = true
        activityView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(mergeLabel.snp.left).offset(-Styles.Sizes.columnSpacing)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: Public

    func configure(title: String, enabled: Bool, loading: Bool) {
        isUserInteractionEnabled = enabled && !loading

        backgroundColor = (enabled
            ? (loading ? Styles.Colors.Green.medium.color : .clear)
            : Styles.Colors.Gray.light.color)
            .withAlphaComponent(loading ? 0.2 : 1)
        alpha = enabled ? 1 : 0.3

        if enabled && !loading {
            guard gradientLayer.superlayer == nil else { return }
            gradientLayer.cornerRadius = layer.cornerRadius
            gradientLayer.colors = [
                UIColor.fromHex("34d058").cgColor,
                Styles.Colors.Green.medium.color.cgColor
            ]
            layer.addSublayer(gradientLayer)

            [mergeLabel, optionButton, optionBorder, activityView].forEach {
                bringSubviewToFront($0)
            }
        } else {
            gradientLayer.removeFromSuperlayer()
        }

        let titleColor = enabled ? .white : Styles.Colors.Gray.dark.color
        mergeLabel.textColor = titleColor
        optionButton.imageView?.tintColor = titleColor
        optionBorder.backgroundColor = titleColor

        mergeLabel.text = title

        if loading {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }

        let mergeButtonElement = mergeElement(withAccessibilityLabel: title)
        accessibilityElements = [mergeButtonElement, optionButton]
        optionButton.accessibilityLabel = NSLocalizedString(
            "More merging options",
            comment: "More options button for merging"
        )
    }

    // MARK: Private API

    private func mergeElement(withAccessibilityLabel accessibilityLabel: String) -> UIAccessibilityElement {
        let element = UIAccessibilityElement(accessibilityContainer: self)
        element.accessibilityLabel = accessibilityLabel
        element.accessibilityFrameInContainerSpace = CGRect(
            origin: bounds.origin,
            size: CGSize(
                width: bounds.size.width - optionButton.bounds.size.width,
                height: bounds.size.height
            )
        )
        element.accessibilityTraits.insert(.button)
        return element
    }

    @objc func onMainTouch() {
        delegate?.didSelect(button: self)
    }

    @objc func onOptionsTouch() {
        delegate?.didSelectOptions(button: self)
    }

}
