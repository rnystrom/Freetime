//
//  NotificationCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/8/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import StyledTextKit

protocol NotificationCellDelegate: class {
    func didTapRead(cell: NotificationCell)
    func didTapWatch(cell: NotificationCell)
    func didTapMore(cell: NotificationCell, sender: UIView)
}

final class NotificationCell: SelectableCell, CAAnimationDelegate {

    public static let inset = UIEdgeInsets(
        top: NotificationCell.topInset + NotificationCell.headerHeight + Styles.Sizes.rowSpacing,
        left: Styles.Sizes.icon.width + 2*Styles.Sizes.columnSpacing,
        bottom: NotificationCell.actionsHeight,
        right: Styles.Sizes.gutter
    )
    public static let topInset = Styles.Sizes.rowSpacing
    public static let headerHeight = ceil(Styles.Text.secondary.preferredFont.lineHeight)
    public static let actionsHeight = Styles.Sizes.gutter + 4*Styles.Sizes.rowSpacing

    private weak var delegate: NotificationCellDelegate?
    private let iconImageView = UIImageView()
    private let dateLabel = ShowMoreDetailsLabel()
    private let detailsLabel = UILabel()
    private let textView = StyledTextView()
    private let stackView = UIStackView()
    private let commentButton = HittableButton()
    private let readButton = HittableButton()
    private let watchButton = HittableButton()
    private let moreButton = HittableButton()
    private let readOverlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityTraits |= UIAccessibilityTraitButton
        isAccessibilityElement = true

        clipsToBounds = true

        contentView.addSubview(iconImageView)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(textView)
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(commentButton)
        stackView.addArrangedSubview(readButton)
        stackView.addArrangedSubview(watchButton)
        stackView.addArrangedSubview(moreButton)

        let grey = Styles.Colors.Gray.light.color
        let font = Styles.Text.secondary.preferredFont
        let inset = NotificationCell.inset
        let actionsHeight = NotificationCell.actionsHeight

        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.snp.makeConstraints { make in
            make.left.equalTo(inset.left)
            make.right.equalTo(-inset.right)
            make.bottom.equalToSuperview()
            make.height.equalTo(actionsHeight)
        }

        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(inset.top)
            make.centerX.equalTo(inset.left / 2)
        }

        dateLabel.font = font
        dateLabel.textColor = grey
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

        commentButton.titleLabel?.font = font
        commentButton.isUserInteractionEnabled = false
        commentButton.tintColor = grey
        commentButton.setTitleColor(grey, for: .normal)
        commentButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -2, right: 0)
        commentButton.titleEdgeInsets = UIEdgeInsets(top: -4, left: 2, bottom: 0, right: 0)
        commentButton.setImage(UIImage(named: "comment-small").withRenderingMode(.alwaysTemplate), for: .normal)
        commentButton.contentHorizontalAlignment = .left
        commentButton.snp.makeConstraints { make in
            make.width.equalTo(actionsHeight)
        }

        watchButton.tintColor = grey
        watchButton.addTarget(self, action: #selector(onWatch(sender:)), for: .touchUpInside)
        watchButton.contentHorizontalAlignment = .center
        watchButton.snp.makeConstraints { make in
            make.width.equalTo(actionsHeight)
        }

        readButton.tintColor = grey
        readButton.setImage(UIImage(named: "check-small").withRenderingMode(.alwaysTemplate), for: .normal)
        readButton.addTarget(self, action: #selector(onRead(sender:)), for: .touchUpInside)
        readButton.contentHorizontalAlignment = .center
        readButton.snp.makeConstraints { make in
            make.width.equalTo(actionsHeight)
        }

        moreButton.tintColor = grey
        moreButton.setImage(UIImage(named: "bullets-small").withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.addTarget(self, action: #selector(onMore(sender:)), for: .touchUpInside)
        moreButton.contentHorizontalAlignment = .right
        moreButton.snp.makeConstraints { make in
            make.width.equalTo(actionsHeight)
        }

        contentView.addBorder(.bottom, left: inset.left)

        readOverlayView.backgroundColor = Styles.Colors.Gray.light.color.withAlphaComponent(0.08)
        readOverlayView.isHidden = true
        addSubview(readOverlayView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.reposition(for: contentView.bounds.width)
        readOverlayView.frame = bounds
    }

    override func themeDidChange(_ theme: Theme) {
        super.themeDidChange(theme)
        backgroundColor = theme == .light ? .white : .black
    }

    override var accessibilityLabel: String? {
        get { return AccessibilityHelper.generatedLabel(forCell: self) }
        set {}
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    public func configure(with model: NotificationViewModel, delegate: NotificationCellDelegate?) {
        textView.configure(with: model.title, width: contentView.bounds.width)
        dateLabel.setText(date: model.date, format: .short)
        self.delegate = delegate

        var titleAttributes = [
            NSAttributedStringKey.font: Styles.Text.title.preferredFont,
            NSAttributedStringKey.foregroundColor: Styles.Colors.Gray.light.color
        ]
        let title = NSMutableAttributedString(string: "\(model.owner)/\(model.repo) ", attributes: titleAttributes)
        titleAttributes[.font] = Styles.Text.secondary.preferredFont
        switch model.number {
        case .number(let number): title.append(NSAttributedString(string: "#\(number)", attributes: titleAttributes))
        default: break
        }
        detailsLabel.attributedText = title

        let tintColor: UIColor
        switch model.state {
        case .closed: tintColor = Styles.Colors.Red.medium.color
        case .merged: tintColor = Styles.Colors.purple.color
        case .open: tintColor = Styles.Colors.Green.medium.color
        case .pending: tintColor = Styles.Colors.Blue.medium.color
        }
        iconImageView.tintColor = tintColor
        iconImageView.image = model.type.icon(merged: model.state == .merged)?
            .withRenderingMode(.alwaysTemplate)

        let hasComments = model.comments > 0
        commentButton.alpha = hasComments ? 1 : 0.3
        commentButton.setTitle(hasComments ? model.comments.abbreviated : "", for: .normal)

        let watchingImageName = model.watching ? "mute" : "unmute"
        watchButton.setImage(UIImage(named: "\(watchingImageName)-small")?.withRenderingMode(.alwaysTemplate), for: .normal)

        dimViews(dim: model.read)
        readOverlayView.isHidden = !model.read

        let watchAccessibilityAction = UIAccessibilityCustomAction(
            name: model.watching ?
                NSLocalizedString("Unwatch notification", comment: "") :
                NSLocalizedString("Watch notification", comment: ""),
            target: self,
            selector: #selector(onWatch(sender:))
        )
        let readAccessibilityAction = UIAccessibilityCustomAction(
            name: Constants.Strings.markRead,
            target: self,
            selector: #selector(onRead(sender:))
        )
        let moreOptionsAccessibilityAction = UIAccessibilityCustomAction(
            name: Constants.Strings.moreOptions,
            target: self,
            selector: #selector(onMore(sender:))
        )

        var customActions = [watchAccessibilityAction, moreOptionsAccessibilityAction]

        if model.read == false {
            customActions.append(readAccessibilityAction)
        }
        accessibilityCustomActions = customActions
    }

    @objc func onRead(sender: UIView) {
        delegate?.didTapRead(cell: self)
    }

    @objc func onWatch(sender: UIView) {
        delegate?.didTapWatch(cell: self)
    }

    @objc func onMore(sender: UIView) {
        delegate?.didTapMore(cell: self, sender: sender)
    }

    func animateRead() {
        UIView.animate(withDuration: 0.1) {
            self.dimViews(dim: true)
        }

        readOverlayView.isHidden = false

        if readOverlayView.layer.mask == nil {
            let mask = CAShapeLayer()
            mask.fillColor = UIColor.black.cgColor
            let smallest = min(readButton.bounds.width, readButton.bounds.height)
            let position = convert(readButton.center, from: readButton.superview)
            let longestEdge = max(self.bounds.width - position.x, position.x)
            let ratio = ceil(longestEdge / (smallest / 2.0)) + 5
            let bounds = CGRect(x: 0, y: 0, width: smallest, height: smallest)
            mask.path = UIBezierPath(ovalIn: bounds).cgPath
            mask.bounds = bounds
            mask.position = position
            mask.transform = CATransform3DMakeScale(ratio, ratio, ratio)
            readOverlayView.layer.mask = mask
        }

        let scaleDuration: TimeInterval = 0.25

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1
        scale.duration = scaleDuration
        scale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.duration = 0.05
        fade.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        let group = CAAnimationGroup()
        group.duration = scaleDuration
        group.animations = [scale, fade]

        readOverlayView.layer.mask?.add(group, forKey: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + scaleDuration) {
            self.readOverlayView.layer.mask?.removeFromSuperlayer()
        }
    }

    private func dimViews(dim: Bool) {
        let alpha: CGFloat = dim ? 0.7 : 1
        [iconImageView, detailsLabel, dateLabel, textView].forEach { view in
            view.alpha = alpha
        }
        readButton.alpha = dim ? 0.2 : 1
    }

}
