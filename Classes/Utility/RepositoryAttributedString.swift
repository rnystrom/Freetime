//
//  RepositoryAttributedString.swift
//  Freetime
//
//  Created by Hesham Salman on 10/24/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

func RepositoryAttributedString(owner: String, name: String) -> NSAttributedString {
    let ownerAttributes: [NSAttributedString.Key: Any] = [
        .font: Styles.Text.body.preferredFont,
        .foregroundColor: Styles.Colors.Gray.dark.color
    ]

    let nameAttributes: [NSAttributedString.Key: Any] = [
        .font: Styles.Text.bodyBold.preferredFont,
        .foregroundColor: Styles.Colors.Gray.dark.color
    ]

    let text = NSMutableAttributedString(string: owner + "/", attributes: ownerAttributes)
    text.append(NSAttributedString(string: name, attributes: nameAttributes))
    return text
}
