//
//  TabBarController.swift
//  Freetime
//
//  Created by Nathan Tannar on 2018-12-16.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

final class TabBarController: UITabBarController, ThemeChangeListener {

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForThemeChanges()
    }

    func themeDidChange(_ theme: Theme) {
        switch theme {
        case .light:
            tabBar.barStyle = .default
            tabBar.barTintColor = Styles.Colors.lightBarTint
        case .dark:
            tabBar.barStyle = .black
            tabBar.barTintColor = UIColor.black
        }
    }
}
