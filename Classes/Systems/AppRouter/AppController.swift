//
//  AppController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/6/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import GitHubSession
import GitHubAPI
import GitHawkRoutes

final class AppController: NSObject,
LoginSplashViewControllerDelegate,
GitHubSessionListener,
RouterPropsSource {

    public private(set) lazy var router = {
        return Router(propsSource: self)
    }()

    private var splitViewController: AppSplitViewController!
    private let sessionManager = GitHubSessionManager()
    private weak var loginViewController: LoginSplashViewController?
    private var appClient: GithubClient?
    private var settingsNavigationController: UINavigationController?
    private var watchAppSync: WatchAppUserSessionSync?

    override init() {
        super.init()
        attachNotificationDelegate()
        sessionManager.addListener(listener: self)
    }

    func appDidFinishLaunching(with window: UIWindow?) {
        guard let controller = window?.rootViewController as? AppSplitViewController else {
            fatalError("App must be setup with a split view controller")
        }
        splitViewController = controller

        resetShortcuts()
        if let focused = sessionManager.focusedUserSession {
            resetViewControllers(userSession: focused)
            resetWatchSync(userSession: focused)
        }
    }

    func appDidBecomeActive() {
        // no need to login if there's a user session
        guard sessionManager.focusedUserSession == nil
        // avoid stacking logins
        && loginViewController == nil
            else { return }
        showLogin(animated: false)
    }

    func performFetch(
        application: UIApplication,
        with completion: @escaping (UIBackgroundFetchResult) -> Void
        ) {
        appClient?.badge.fetch(application: application, handler: completion)
    }

    private func resetWatchSync(userSession: GitHubUserSession) {
        watchAppSync = WatchAppUserSessionSync(userSession: userSession)
        watchAppSync?.start()
    }

    private func resetShortcuts() {
        ShortcutHandler.configure(sessionUsernames: sessionManager.userSessions.compactMap { $0.username })
    }

    private func resetViewControllers(userSession: GitHubUserSession, isSwitch: Bool = false) {
        let appClient = GithubClient(userSession: userSession)
        self.appClient = appClient
        settingsNavigationController = settingsNavigationController
            ?? newSettingsRootViewController(sessionManager: sessionManager)
        // keep settings up to date with the most recent client
        if let settings = settingsNavigationController?.viewControllers.first as? SettingsViewController {
            settings.client = appClient
        }

        splitViewController.reset(
            viewControllers: [
                newNotificationsRootViewController(client: appClient),
                newSearchRootViewController(client: appClient),
                newBookmarksRootViewController(client: appClient),
                settingsNavigationController ?? NavigationController() // satisfy compiler
            ],
            clearDetail: !isSwitch
        )
        // recursively update all new children
        splitViewController.router = router
    }

    private func showLogin(animated: Bool) {
        guard let controller = LoginSplashViewController.make(
            client: Client.make(),
            delegate: self
            )
            else { return }
        loginViewController = controller

        let present: () -> Void = {
            self.splitViewController.present(controller, animated: animated)
        }
        if let presented = splitViewController.presentedViewController {
            presented.dismiss(animated: animated, completion: present)
        } else {
            present()
        }

        // wipe underlying VCs clean. important for ipad (modal)
        splitViewController.resetEmpty()
    }

    // MARK: LoginSplashViewControllerDelegate

    func finishLogin(token: String, authMethod: GitHubUserSession.AuthMethod, username: String) {
        sessionManager.focus(
            GitHubUserSession(token: token, authMethod: authMethod, username: username)
        )
    }

    // MARK: GitHubSessionListener

    func didFocus(manager: GitHubSessionManager, userSession: GitHubUserSession, isSwitch: Bool) {
        resetViewControllers(userSession: userSession, isSwitch: isSwitch)

        splitViewController.presentedViewController?.dismiss(animated: trueUnlessReduceMotionEnabled)

        resetShortcuts()
        if let watch = watchAppSync {
            watch.sync(userSession: userSession)
        } else {
            resetWatchSync(userSession: userSession)
        }
    }

    func didLogout(manager: GitHubSessionManager) {
        showLogin(animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: RouterPropsSource

    func props(for router: Router) -> RoutePerformableProps? {
        guard let client = appClient else { return nil }
        return RoutePerformableProps(
            sessionManager: sessionManager,
            splitViewController: splitViewController,
            client: client
        )
    }

}
