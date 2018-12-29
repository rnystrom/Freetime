//
//  NavigationController.swift
//  Freetime
//
//  Created by Nathan Tannar on 2018-12-16.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

final class NavigationController: UINavigationController, ThemeChangeListener {

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForThemeChanges()
    }

    func themeDidChange(_ theme: Theme) {
        switch theme {
        case .light:
            navigationBar.barStyle = .default
            navigationBar.barTintColor = Styles.Colors.lightBarTint
            navigationBar.titleTextAttributes = [.foregroundColor: Styles.Colors.Gray.dark.color]
        case .dark:
            navigationBar.barStyle = .black
            navigationBar.barTintColor = UIColor.black
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}
