//
//  InboxDashboardCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 12/3/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import StyledTextKit

final class InboxDashboardCell: SelectableCell {

    public static let inset = UIEdgeInsets(
        top: NotificationCell.inset.top,
        left: NotificationCell.inset.left,
        bottom: Styles.Sizes.rowSpacing * 2,
        right: NotificationCell.inset.right
    )

    private let iconImageView = UIImageView()
    private let dateLabel = ShowMoreDetailsLabel()
    private let detailsLabel = UILabel()
    private let textView = StyledTextView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        backgroundColor = .white

        contentView.addSubview(iconImageView)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(textView)

        let inset = InboxDashboardCell.inset

        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(inset.top - 3)
            make.centerX.equalTo(inset.left / 2)
        }

        dateLabel.font = Styles.Text.secondary.preferredFont
        dateLabel.textColor = Styles.Colors.Gray.light.color
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(NotificationCell.topInset)
            make.right.equalTo(-inset.right)
        }

        detailsLabel.lineBreakMode = .byTruncatingMiddle
        detailsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailsLabel.snp.makeConstraints { make in
            make.top.equalTo(Styles.Sizes.rowSpacing)
            make.left.equalTo(NotificationCell.inset.left)
            make.right.lessThanOrEqualTo(dateLabel.snp.left).offset(-Styles.Sizes.columnSpacing)
        }

        addBorder(.bottom, left: inset.left)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.reposition(for: contentView.bounds.width)
    }

    override var accessibilityLabel: String? {
        get { return AccessibilityHelper.generatedLabel(forCell: self) }
        set {}
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    public func configure(with model: InboxDashboardModel) {
        textView.configure(with: model.text, width: contentView.bounds.width)
        dateLabel.setText(date: model.date, format: .short)

        var titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Styles.Text.title.preferredFont,
            .foregroundColor: Styles.Colors.Gray.light.color
        ]
        let title = NSMutableAttributedString(string: "\(model.owner)/\(model.name) ", attributes: titleAttributes)
        titleAttributes[.font] = Styles.Text.secondary.preferredFont
        title.append(NSAttributedString(string: "#\(model.number)", attributes: titleAttributes))
        detailsLabel.attributedText = title

        let tintColor: UIColor
        switch model.state {
        case .closed: tintColor = Styles.Colors.Red.medium.color
        case .merged: tintColor = Styles.Colors.purple.color
        case .open: tintColor = Styles.Colors.Green.medium.color
        case .pending: tintColor = Styles.Colors.Blue.medium.color
        }
        iconImageView.tintColor = tintColor

        let imageName: String
        if case .merged = model.state {
            imageName = "git-merge"
        } else {
            imageName = model.isPullRequest ? "git-pull-request" : "issue-opened"
        }
        iconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
    }

}
