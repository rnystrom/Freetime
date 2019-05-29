//
//  RepoInboxRowController.swift
//  FreetimeWatch Extension
//
//  Created by Ryan Nystrom on 4/27/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import WatchKit
import Foundation
import GitHubAPI
import DateAgo

final class RepoInboxRowController: NSObject {

    @IBOutlet var enclosingGroup: WKInterfaceGroup!
    @IBOutlet var typeImage: WKInterfaceImage!
    @IBOutlet var numberLabel: WKInterfaceLabel!
    @IBOutlet var dateLabel: WKInterfaceLabel!
    @IBOutlet var titleLabel: WKInterfaceLabel!

    func setup(with notification: V3Notification) {
        let title = notification.subject.title
        titleLabel.setText(title)
        dateLabel.setText(notification.updatedAt.agoString(.short))

        let imageName: String
        switch notification.subject.type {
        case .commit: imageName = "git-commit"
        case .invitation: imageName = "mail"
        case .issue: imageName = "issue-opened"
        case .pullRequest: imageName = "git-pull-request"
        case .release: imageName = "tag"
        case .repo: imageName = "repo"
        case .vulnerabilityAlert: imageName = "alert"
        }
        typeImage.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))

        let number: String?
        if let identifier = notification.subject.identifier {
            switch identifier {
            case .hash(let h):
                number = h.hashDisplay
            case .number(let num):
                number = "#\(num)"
            case .release(let r):
                number = r
            }
        } else {
            number = nil
        }

        if let number = number {
            numberLabel.setText(number)
        }

        let agoString = notification.updatedAt.agoString(.long)
        let elements = [number, agoString, title].compactMap { $0 }
        let accessibilityLabel: String

        // FIXME: Copied from Accessibility.swift; we should put this in a small library probably.
        if elements.count == 1, let elements = elements.first {
            accessibilityLabel = elements
        } else {
            accessibilityLabel = elements.reduce("") { "\($0).\n\($1)" }
        }

        [typeImage, titleLabel, dateLabel, numberLabel].forEach { $0.setIsAccessibilityElement(false) }
        enclosingGroup.setAccessibilityTraits(.staticText)
        enclosingGroup.setIsAccessibilityElement(true)
        enclosingGroup.setAccessibilityLabel(accessibilityLabel) // FIXME: We should add the notification type here, probably by using "NotificationType" (only available in GitHawk) or remove that completely and add the localization to V3NotificationType
    }

}
