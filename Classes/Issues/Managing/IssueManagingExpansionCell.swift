//
//  IssueManagingExpansionCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/13/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit
import SnapKit

final class IssueManagingRoundedBackgroundView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

final class IssueManagingExpansionCell: UICollectionViewCell, ListBindable {

    private let label = UILabel()
    private let chevron = UIImageView(image: UIImage(named: "chevron-down-small").withRenderingMode(.alwaysTemplate))
    private let backgroundHighlightView = IssueManagingRoundedBackgroundView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        backgroundHighlightView.backgroundColor = UIColor(white: 0, alpha: 0.07)
        backgroundHighlightView.alpha = 0
        contentView.addSubview(backgroundHighlightView)

        let tint = Styles.Colors.Blue.medium.color

        chevron.tintColor = tint
        contentView.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(1)
            make.right.equalToSuperview()
        }

        label.text = NSLocalizedString("Manage", comment: "")
        label.font = Styles.Text.secondaryBold.preferredFont
        label.textColor = tint
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(chevron.snp.left).offset(-Styles.Sizes.rowSpacing+3)
        }

        backgroundHighlightView.snp.makeConstraints { make in
            make.left.equalTo(label).offset(-Styles.Sizes.rowSpacing)
            make.right.equalTo(chevron).offset(Styles.Sizes.rowSpacing)
            make.height.equalTo(label).offset(4)
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
        chevron.alpha = alpha
    }

    // MARK: Public API

    func animate(expanded: Bool) {
        UIView.animate(
            withDuration: (0.8),
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0,
            animations: {
                self.expand(expanded: expanded)
        })
    }

    // MARK: Private API

    private func expand(expanded: Bool) {
        backgroundHighlightView.alpha = expanded ? 1 : 0
        // nudging the angles let's us control the animation direction
        chevron.transform = expanded
            ? CGAffineTransform(rotationAngle: CGFloat.pi + 0.00_001)
            : CGAffineTransform(rotationAngle: -0.00_001)
    }

    // MARK: ListBindable

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? IssueManagingExpansionModel else { return }
        expand(expanded: viewModel.expanded)
    }

    // MARK: Accessibility
    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }
}
