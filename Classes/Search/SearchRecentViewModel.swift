//
//  SearchRecentViewModel.swift
//  Freetime
//
//  Created by Hesham Salman on 10/21/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import IGListKit

private enum Keys {
    static let search = "search"
    static let viewed = "viewed"
}

final class SearchRecentViewModel: NSObject, ListDiffable {

    let query: SearchQuery

    init(query: SearchQuery) {
        self.query = query
    }

    var displayText: NSAttributedString {
        switch query {
        case .search(let text):
            return NSAttributedString(string: text, attributes: standardAttributes)
        case .recentlyViewed(let repoDetails):
            return RepositoryAttributedString(owner: repoDetails.owner, name: repoDetails.name)
        }
    }

    var icon: UIImage {
        switch query {
        case .search:
            return #imageLiteral(resourceName: "search")
        case .recentlyViewed:
            return #imageLiteral(resourceName: "repo")
        }
    }

    // MARK: ListDiffable

    func diffIdentifier() -> NSObjectProtocol {
        var identifier: String
        switch query {
        case .recentlyViewed:
            identifier = Keys.viewed
        case .search:
            identifier = Keys.search
        }
        return (identifier + displayText.string) as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }

    // MARK: Private API

    private var standardAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: Styles.Text.body.preferredFont,
            .foregroundColor: Styles.Colors.Gray.dark.color
        ]
    }
}
