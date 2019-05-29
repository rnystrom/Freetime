//
//  UIViewController+Routing.swift
//  Freetime
//
//  Created by Ryan Nystrom on 3/17/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UIViewController {

    @discardableResult
    func handle(attribute: DetectedMarkdownAttribute) -> Bool {
        switch attribute {
        case .url(let url): presentSafari(url: url)
        case .email(let email):
            if let url = URL(string: "mailTo:\(email)") {
                UIApplication.shared.open(url)
            }
        case .username(let username): presentProfile(login: username)
        case .commit(let commit): presentCommit(owner: commit.owner, repo: commit.repo, hash: commit.hash)
        default: return false
        }
        return true
    }

}
