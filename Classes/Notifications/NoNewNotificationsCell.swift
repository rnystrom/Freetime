//
//  NoNewNotificationsCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/30/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

protocol ReviewGithubAccessDelegate: class {
    func reviewGithubAccessButtonTapped()
}

final class NoNewNotificationsCell: UICollectionViewCell {

    let emojiLabel = UILabel()
    let messageLabel = UILabel()
    let reviewGithubAccessButton = UIButton()
    let shadow = CAShapeLayer()
    weak var reviewGithubAccessDelegate: ReviewGithubAccessDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        emojiLabel.isAccessibilityElement = false
        emojiLabel.textAlignment = .center
        emojiLabel.backgroundColor = .clear
        emojiLabel.font = .systemFont(ofSize: 60)
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints { make in
            make.centerX.equalTo(contentView)
            make.centerY.equalTo(contentView).offset(-Styles.Sizes.tableSectionSpacing)
        }

        shadow.fillColor = UIColor(white: 0, alpha: 0.05).cgColor
        contentView.layer.addSublayer(shadow)

        messageLabel.isAccessibilityElement = false
        messageLabel.textAlignment = .center
        messageLabel.backgroundColor = .clear
        messageLabel.font = Styles.Text.body.preferredFont
        messageLabel.textColor = Styles.Colors.Gray.light.color
        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.centerX.equalTo(emojiLabel)
            make.top.equalTo(emojiLabel.snp.bottom).offset(Styles.Sizes.tableSectionSpacing)
        }

        reviewGithubAccessButton.setTitle("Review GitHub access...", for: .normal)
        reviewGithubAccessButton.isAccessibilityElement = false
        reviewGithubAccessButton.titleLabel?.textAlignment = .center
        reviewGithubAccessButton.backgroundColor = .clear
        reviewGithubAccessButton.titleLabel?.font = Styles.Text.finePrint.preferredFont
        reviewGithubAccessButton.setTitleColor(Styles.Colors.Gray.light.color, for: .normal)
        reviewGithubAccessButton.addTarget(self, action: #selector(reviewGithubAccessButtonTapped), for: .touchUpInside)
        contentView.addSubview(reviewGithubAccessButton)
        let buttonWidth = (reviewGithubAccessButton.titleLabel?.intrinsicContentSize.width ?? 0) + Styles.Sizes.gutter
        let buttonHeight = (reviewGithubAccessButton.titleLabel?.intrinsicContentSize.height ?? 0) + Styles.Sizes.gutter
        reviewGithubAccessButton.snp.makeConstraints { make in
            make.centerX.equalTo(messageLabel)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(buttonHeight)
            make.bottom.equalTo(contentView.snp.bottom).offset(-Styles.Sizes.tableSectionSpacing)
        }
        
        resetAnimations()

        // CAAnimations will be removed from layers on background. restore when foregrounding.
        NotificationCenter.default
            .addObserver(self,
                selector: #selector(resetAnimations),
                name: .UIApplicationWillEnterForeground,
                object: nil
        )

        contentView.isAccessibilityElement = true
        contentView.accessibilityLabel = NSLocalizedString("You have no new notifications!", comment: "Inbox Zero Accessibility Label")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentViewForSafeAreaInsets()

        let width: CGFloat = 30
        let height: CGFloat = 12
        let rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        shadow.path = UIBezierPath(ovalIn: rect).cgPath

        let bounds = contentView.bounds
        shadow.bounds = rect
        shadow.position = CGPoint(
            x: bounds.width/2,
            y: bounds.height/2 + 15
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetAnimations()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resetAnimations()
    }

    // MARK: Public API

    func configure(emoji: String, message: String, delegate: ReviewGithubAccessDelegate?) {
        emojiLabel.text = emoji
        messageLabel.text = message
        reviewGithubAccessDelegate = delegate 
    }

    // MARK: Private API

    @objc private func resetAnimations() {
        guard trueUnlessReduceMotionEnabled else { return }
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        let duration: TimeInterval = 1

        let emojiBounce = CABasicAnimation(keyPath: "transform.translation.y")
        emojiBounce.toValue = -10
        emojiBounce.repeatCount = .greatestFiniteMagnitude
        emojiBounce.autoreverses = true
        emojiBounce.duration = duration
        emojiBounce.timingFunction = timingFunction

        emojiLabel.layer.add(emojiBounce, forKey: "nonewnotificationscell.emoji")

        let shadowScale = CABasicAnimation(keyPath: "transform.scale")
        shadowScale.toValue = 0.9
        shadowScale.repeatCount = .greatestFiniteMagnitude
        shadowScale.autoreverses = true
        shadowScale.duration = duration
        shadowScale.timingFunction = timingFunction

        shadow.add(shadowScale, forKey: "nonewnotificationscell.shadow")
    }
    
    @objc func reviewGithubAccessButtonTapped() {
        reviewGithubAccessDelegate?.reviewGithubAccessButtonTapped()
    }

}
