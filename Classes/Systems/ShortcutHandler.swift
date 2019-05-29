//
//  ShortcutHandler.swift
//  Freetime
//
//  Created by Viktor Gardart on 2017-10-08.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import GitHubSession
import GitHawkRoutes

extension UIApplicationShortcutItem {

    var params: [String: String] {
        var params = [String: String]()
        userInfo?.forEach {
            if let value = $1 as? String {
                params[$0] = value
            }
        }
        return params
    }

    static func from<T: Routable>(
        route: T,
        localizedTitle: String,
        localizedSubtitle: String? = nil,
        icon: UIApplicationShortcutIcon? = nil
        ) -> UIApplicationShortcutItem {
        return UIApplicationShortcutItem(
            type: T.path,
            localizedTitle: localizedTitle,
            localizedSubtitle: localizedSubtitle,
            icon: icon,
            userInfo: route.encoded as [String: NSSecureCoding]
        )
    }

}

struct ShortcutHandler {

    static func configure(sessionUsernames: [String]) {
        UIApplication.shared.shortcutItems = generateItems(sessionUsernames: sessionUsernames)
    }

    private static func generateItems(sessionUsernames: [String]) -> [UIApplicationShortcutItem] {
        guard sessionUsernames.count > 0 else { return [] }

        var items = [
            UIApplicationShortcutItem.from(
                route: SearchShortcutRoute(),
                localizedTitle: Constants.Strings.search,
                icon: UIApplicationShortcutIcon(templateImageName: "search")
            ),
            UIApplicationShortcutItem.from(
                route: BookmarkShortcutRoute(),
                localizedTitle: Constants.Strings.bookmarks,
                icon: UIApplicationShortcutIcon(templateImageName: "bookmark")
            )
        ]

        if sessionUsernames.count > 1 {
            let username = sessionUsernames[1]
            items.append(UIApplicationShortcutItem.from(
                route: SwitchAccountShortcutRoute(username: username),
                localizedTitle: NSLocalizedString("Switch Account", comment: ""),
                localizedSubtitle: username,
                icon: UIApplicationShortcutIcon(templateImageName: "organization")
            ))
        }

        return items
    }

}
