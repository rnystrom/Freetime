//
//  AppSplitViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/6/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

final class AppSplitViewController: UISplitViewController, ThemeChangeListener {

    private var statusBarStyle: UIStatusBarStyle = {
        Appearance.currentTheme == .light ? .default : .lightContent
    }()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    private let tabDelegateController = TabBarControllerDelegate()
    private let appSplitViewDelegateController = SplitViewControllerDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForThemeChanges()
        masterTabBarController?.delegate = tabDelegateController
        delegate = appSplitViewDelegateController
        preferredDisplayMode = .allVisible
    }

    func themeDidChange(_ theme: Theme) {
        statusBarStyle = theme == .light ? .default : .lightContent
        Styles.setupAppearance()
        setNeedsStatusBarAppearanceUpdate()
    }

    var detailNavigationController: UINavigationController? {
        return viewControllers.last as? UINavigationController
    }

    var masterTabBarController: UITabBarController? {
        return viewControllers.first as? UITabBarController
    }

    func resetEmpty() {
        let controller = UIViewController()
        controller.view.backgroundColor = Styles.Colors.background
        reset(
            viewControllers: [NavigationController(rootViewController: controller)],
            clearDetail: true
        )
    }

    func reset(viewControllers: [UIViewController], clearDetail: Bool) {
        masterTabBarController?.viewControllers = viewControllers
        if clearDetail {
            detailNavigationController?.viewControllers = [SplitPlaceholderViewController()]
        }
    }

}
