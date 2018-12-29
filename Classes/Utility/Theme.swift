//
//  Theme.swift
//  Freetime
//
//  Created by Nathan Tannar on 2018-12-15.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation

private let kPreferredThemeRawValueKey = "kPreferredThemeRawValueKey"
private let kThemeDidChangeRawValue = "kThemeDidChange"
private let kThemeDidChange = NSNotification.Name(kThemeDidChangeRawValue)

enum Theme: Int {
    case light = 0
    case dark

    static var `default`: Theme {
        let rawValue = UserDefaults.standard.integer(forKey: kPreferredThemeRawValueKey)
        return Theme(rawValue: rawValue) ?? .light
    }
}

final class Appearance {
    private(set) static var currentTheme: Theme = .default

    static func setCurrentTheme(_ theme: Theme, animated: Bool) {
        UIView.animate(
            withDuration: animated ? 0.5 : 0.0,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [.transitionCrossDissolve],
            animations: {
                Appearance.currentTheme = theme
                UserDefaults.standard.set(theme.rawValue, forKey: kPreferredThemeRawValueKey)
                NotificationCenter.default.post(name: kThemeDidChange, object: theme)
        })
    }
}

class ThemeChangeNotifier: NSObject {
    private let block: (_ notification: Notification?) -> Void

    init(_ block: @escaping (_ notification: Notification?) -> Void) {
        self.block = block
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationReceived(_:)),
            name: kThemeDidChange,
            object: nil
        )
    }

    @objc private func notificationReceived(_ notification: Notification?) {
        block(notification)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol ThemeChangeListener: AnyObject {
    func themeDidChange(_ theme: Theme)
}

private struct AssociatedKeys {
    static var kThemeChangeNotifier = "kThemeChangeNotifier"
}

extension ThemeChangeListener where Self: NSObject {
    func registerForThemeChanges() {
        themeChangeNotifier = ThemeChangeNotifier { [weak self] notification in
            guard let theme = notification?.object as? Theme else {
                return
            }
            self?.themeDidChange(theme)
        }

        // Trigger a config cycle for the current theme
        themeDidChange(Appearance.currentTheme)
    }

    private var themeChangeNotifier: ThemeChangeNotifier? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.kThemeChangeNotifier) as? ThemeChangeNotifier
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.kThemeChangeNotifier, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
