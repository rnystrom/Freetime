//
//  MarkdownName.swift
//  Freetime
//
//  Created by Ryan Nystrom on 9/5/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

enum MarkdownAttribute {
    static let url = NSAttributedString.Key(rawValue: "com.freetime.Markdown.url-name")
    static let email = NSAttributedString.Key(rawValue: "com.freetime.Markdown.email-name")
    static let username = NSAttributedString.Key(rawValue: "com.freetime.Markdown.username-name")
    static let usernameDisabled = NSAttributedString.Key(rawValue: "com.freetime.Markdown.username-disabled-name")
    static let linkShorteningDisabled = NSAttributedString.Key(rawValue: "com.freetime.Markdown.link-shortening-disabled-name")
    static let issue = NSAttributedString.Key(rawValue: "com.freetime.Markdown.issue")
    static let details = NSAttributedString.Key(rawValue: "com.freetime.Markdown.details")
    static let label = NSAttributedString.Key(rawValue: "com.freetime.Markdown.label")
    static let commit = NSAttributedString.Key(rawValue: "com.freetime.Markdown.commit")
    static let checkbox = NSAttributedString.Key(rawValue: "com.freetime.Markdown.checkbox")

    static let all = Set<NSAttributedString.Key>([
        url,
        email,
        username,
        usernameDisabled,
        linkShorteningDisabled,
        issue,
        details,
        label,
        commit,
        checkbox
        ])
}
