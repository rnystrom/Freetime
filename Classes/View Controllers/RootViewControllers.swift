//
//  RootViewControllers.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/17/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import GitHubSession

func newSettingsRootViewController(
    sessionManager: GitHubSessionManager
    ) -> UINavigationController {
    guard let nav = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as? UINavigationController
        else { fatalError("Could not unpack settings storyboard") }

    if let first = nav.viewControllers.first as? SettingsViewController {
        first.sessionManager = sessionManager
        nav.tabBarItem.title = NSLocalizedString("Settings", comment: "")
        nav.tabBarItem.image = UIImage(named: "tab-gear").withRenderingMode(.alwaysOriginal)
        nav.tabBarItem.selectedImage = UIImage(named: "tab-gear-selected").withRenderingMode(.alwaysOriginal)
    }

    return nav
}

func newNotificationsRootViewController(client: GithubClient) -> UIViewController {
    let controller = NotificationsViewController(
        modelController: NotificationModelController(githubClient: client)
    )
    let title = NSLocalizedString("Inbox", comment: "")
    controller.title = title
    let nav = NavigationController(rootViewController: controller)
    nav.tabBarItem.title = title
    nav.tabBarItem.image = UIImage(named: "tab-inbox").withRenderingMode(.alwaysOriginal)
    nav.tabBarItem.selectedImage = UIImage(named: "tab-inbox-selected").withRenderingMode(.alwaysOriginal)
    return nav
}

func newSearchRootViewController(client: GithubClient) -> UIViewController {
    let controller = SearchViewController(client: client)
    let nav = NavigationController(rootViewController: controller)
    nav.tabBarItem.title = Constants.Strings.search
    nav.tabBarItem.image = UIImage(named: "tab-search").withRenderingMode(.alwaysOriginal)
    nav.tabBarItem.selectedImage = UIImage(named: "tab-search-selected").withRenderingMode(.alwaysOriginal)
    return nav
}

func newBookmarksRootViewController(client: GithubClient) -> UIViewController {
    guard let cloudStore = client.bookmarkCloudStore else {
        fatalError("Cannot init a bookmark VC without setting up storage")
    }

    let oldBookmarks: [Bookmark]
    if let token = client.userSession?.token {
        oldBookmarks = BookmarkStore(token: token).values
    } else {
        oldBookmarks = []
    }

    let title = Constants.Strings.bookmarks
    let controller = BookmarkViewController(
        client: client,
        cloudStore: cloudStore,
        oldBookmarks: oldBookmarks
    )
    controller.makeBackBarItemEmpty()
    controller.title = title
    let nav = NavigationController(rootViewController: controller)
    nav.tabBarItem.image = UIImage(named: "tab-bookmark").withRenderingMode(.alwaysOriginal)
    nav.tabBarItem.selectedImage = UIImage(named: "tab-bookmark-selected").withRenderingMode(.alwaysOriginal)
    nav.tabBarItem.title = title
    return nav
}
