//
//  AppDelegate.swift
//  Freetime
//
//  Created by Ryan Nystrom on 4/30/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireNetworkActivityIndicator
import Fabric
import Crashlytics
import GitHubSession

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let flexController = FlexController()
    private let appController = AppController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        appController.appDidFinishLaunching(with: window)

        // setup fabric
        Fabric.with([Crashlytics.self])

        // send rating prompt app load event
        RatingController.applicationDidLaunch()

        // setup FLEX
        flexController.configureWindow(window)

        // use Alamofire status bar network activity helper
        NetworkActivityIndicatorManager.shared.isEnabled = true

        // setup UIAppearance overrides
        Styles.setupAppearance()

        // setup app icon badging
        BadgeNotifications.configure(application: application)

        // log device environment information
        LogEnvironmentInformation(application: application)

        // setup content size category change handler
        UIContentSizeCategoryChangeHandler.shared.setup()

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        appController.router.handle(path: shortcutItem.type, params: shortcutItem.params)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        appController.appDidBecomeActive()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appController.performFetch(application: application, with: completionHandler)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appController.router.handle(url: url).wasHandled
    }

}
