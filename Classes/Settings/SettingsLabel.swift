//
//  SettingsLabel.swift
//  Freetime
//
//  Created by Ryan Nystrom on 12/9/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

final class SettingsLabel: UILabel, ThemeChangeListener {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    func configure() {
        registerForThemeChanges()
        font = Styles.Text.body.preferredFont
    }

    func themeDidChange(_ theme: Theme) {
        textColor = theme == .light
            ? Styles.Colors.Gray.dark.color
            : Styles.Colors.Gray.light.color
    }

}
