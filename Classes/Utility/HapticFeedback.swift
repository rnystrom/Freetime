//
//  HapticFeedback.swift
//  Freetime
//
//  Created by Bas Broek on 24/10/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

enum Haptic {

    static private let selectionGenerator = UISelectionFeedbackGenerator()
    static private let notificationGenerator = UINotificationFeedbackGenerator()

    static func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func triggerSelection() {
        selectionGenerator.selectionChanged()
    }

    static func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
}
