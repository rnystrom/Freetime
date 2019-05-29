//
//  UserAutocomplete.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/24/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

struct AutocompleteUser {
    let avatarURL: URL
    let login: String
}

final class UserAutocomplete: AutocompleteType {

    private var cachedResults = [String: [AutocompleteUser]]()
    private var results = [AutocompleteUser]()
    private let mentionableUsers: [AutocompleteUser]

    init(mentionableUsers: [AutocompleteUser]) {
        self.mentionableUsers = mentionableUsers
    }

    // MARK: AutocompleteType

    var prefix: String {
        return "@"
    }

    var resultsCount: Int {
        return results.count
    }

    func configure(cell: AutocompleteCell, index: Int) {
        let result = results[index]
        cell.configure(state: .user(avatarURL: result.avatarURL, login: result.login))
    }

    func search(word: String, completion: @escaping (Bool) -> Void) {
        if let cached = cachedResults[word] {
            self.results = cached
            completion(cached.count > 0)
            return
        }

        var results = [AutocompleteUser]()

        let lowerword = word.lowercased()
        for u in mentionableUsers {
            if u.login.lowercased().hasPrefix(lowerword) {
                results.append(u)
            }
        }

        self.results = results
        cachedResults[word] = results

        completion(results.count > 0)
    }

    func accept(index: Int) -> String? {
        return prefix + results[index].login
    }

    var highlightAttributes: [NSAttributedString.Key: Any]? {
        return [
            .foregroundColor: Styles.Colors.Blue.medium.color,
            .backgroundColor: Styles.Colors.Blue.medium.color.withAlphaComponent(0.1)
        ]
    }

}
