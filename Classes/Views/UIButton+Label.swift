//
//  UIButton+Label.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/8/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UIButton {

    enum IssueState {
        case merged
        case closed
        case open
        case locked
        case unlocked
    }

    func setupAsLabel(icon: Bool = true) {
        accessibilityTraits = .none
        tintColor = .white
        titleLabel?.font = Styles.Text.smallTitle.preferredFont
        layer.cornerRadius = Styles.Sizes.labelCornerRadius
        clipsToBounds = true

        let magnitude = Styles.Sizes.buttonTopPadding
        if icon {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -Styles.Sizes.columnSpacing, bottom: 0, right: 0)
            contentEdgeInsets = UIEdgeInsets(top: magnitude, left: Styles.Sizes.columnSpacing + magnitude, bottom: magnitude, right: magnitude * 2)
        } else {
            imageEdgeInsets = .zero
            contentEdgeInsets = UIEdgeInsets(top: magnitude, left: magnitude, bottom: magnitude, right: magnitude)
        }

    }

    func config(pullRequest: Bool, state: IssueState) {

        let prName = "git-pull-request-small"

        let icon: String
        let color: UIColor

        switch state {
        case .closed:
            icon = pullRequest ? prName : "issue-closed-small"
            color = Styles.Colors.Red.medium.color
        case .open:
            icon = pullRequest ? prName : "issue-opened-small"
            color = Styles.Colors.Green.medium.color
        case .merged:
            icon = "git-merge-small"
            color = Styles.Colors.purple.color
        case .locked:
            icon = "lock-small"
            color = Styles.Colors.Gray.dark.color
        case .unlocked:
            icon = "key-small"
            color = Styles.Colors.Gray.dark.color
        }
        setImage(UIImage(named: icon)?.withRenderingMode(.alwaysTemplate), for: .normal)
        backgroundColor = color
    }

}
