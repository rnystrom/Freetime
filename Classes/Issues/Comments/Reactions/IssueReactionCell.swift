//
//  IssueReactionCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/1/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class IssueReactionCell: UICollectionViewCell {

    private static var cache = [String: CGFloat]()
    private static let spacing: CGFloat = 4
    private static var emojiFont: UIFont { return UIFont.systemFont(ofSize: Styles.Text.body.size + 2) }
    private static var countFont: UIFont { return Styles.Text.body.preferredFont }

    static func width(emoji: String, count: Int) -> CGFloat {
        let key = "\(emoji)\(count)"
        if let cached = cache[key] {
            return cached
        }

        let emojiWidth = (emoji as NSString).size(withAttributes: [.font: emojiFont]).width
        let countWidth = ("\(count)" as NSString).size(withAttributes: [.font: countFont]).width
        let width = emojiWidth + countWidth + 3 * spacing
        cache[key] = width
        return width
    }

    private let emojiLabel = UILabel()
    private let countLabel = ShowMoreDetailsLabel()
    private var detailText = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        emojiLabel.textAlignment = .center
        emojiLabel.backgroundColor = .clear
        // hint bigger emoji than labels
        emojiLabel.font = UIFont.systemFont(ofSize: Styles.Text.body.size + 2)
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(IssueReactionCell.spacing)
        }

        countLabel.textAlignment = .center
        countLabel.backgroundColor = .clear
        countLabel.font = Styles.Text.body.preferredFont
        countLabel.textColor = Styles.Colors.Blue.medium.color
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(emojiLabel)
            make.left.equalTo(emojiLabel.snp.right).offset(IssueReactionCell.spacing)
        }

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(IssueReactionCell.showMenu(recognizer:))
        )
        isUserInteractionEnabled = true
        addGestureRecognizer(longPress)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // required for UIMenuController
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(IssueReactionCell.empty)
    }

    // MARK: Public API

    func configure(emoji: String, count: Int, detail: String, isViewer: Bool) {
        emojiLabel.text = emoji
        countLabel.text = "\(count)"
        detailText = detail
        contentView.backgroundColor = isViewer ? Styles.Colors.Blue.light.color : .clear
        accessibilityHint = isViewer
            ? NSLocalizedString("Tap to remove your reaction", comment: "")
            : NSLocalizedString("Tap to react with this emoji", comment: "")
    }

    func popIn() {
        emojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        emojiLabel.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2, options: [.curveEaseInOut], animations: {
            self.emojiLabel.transform = .identity
            self.emojiLabel.alpha = 1
        })

        countLabel.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, animations: {
            self.countLabel.alpha = 1
        })
    }

    func pullOut() {
        // hack to prevent changing to "0"
        countLabel.text = "1"

        countLabel.alpha = 1
        emojiLabel.transform = .identity
        emojiLabel.alpha = 1
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            self.countLabel.alpha = 0
            self.emojiLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            self.emojiLabel.alpha = 0
        })
    }

    func iterate(add: Bool) {
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = .push
        animation.subtype = add ? .fromTop : .fromBottom
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        countLabel.layer.add(animation, forKey: "text-change")
    }

    // MARK: Private API

    @objc func showMenu(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .began,
            !detailText.isEmpty else { return }

        becomeFirstResponder()

        let menu = UIMenuController.shared
        menu.menuItems = [
            UIMenuItem(title: detailText, action: #selector(IssueReactionCell.empty))
        ]
        menu.setTargetRect(contentView.bounds, in: self)
        menu.setMenuVisible(true, animated: trueUnlessReduceMotionEnabled)
    }

    @objc func empty() {}

    // MARK: Accessibility

    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }

}
