//
//  RepositoryAttributedString.swift
//  Freetime
//
//  Created by Hesham Salman on 10/24/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

func RepositoryAttributedString(owner: String, name: String) -> NSAttributedString {
    let textColor = Appearance.currentTheme == .light
        ? Styles.Colors.Gray.dark.color
        : Styles.Colors.Gray.light.color
    let ownerAttributes: [NSAttributedStringKey: Any] = [
        .font: Styles.Text.body.preferredFont,
        .foregroundColor: textColor
    ]

    let nameAttributes: [NSAttributedStringKey: Any] = [
        .font: Styles.Text.bodyBold.preferredFont,
        .foregroundColor: textColor
    ]

    let text = NSMutableAttributedString(string: owner + "/", attributes: ownerAttributes)
    text.append(NSAttributedString(string: name, attributes: nameAttributes))
    return text
}
