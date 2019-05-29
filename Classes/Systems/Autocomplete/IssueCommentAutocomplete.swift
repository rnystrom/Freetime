//
//  IssueCommentAutocomplete.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/23/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

protocol IssueCommentAutocompleteDelegate: class {
    func didChangeStore(autocomplete: IssueCommentAutocomplete)
    func didFinish(autocomplete: IssueCommentAutocomplete, hasResults: Bool)
}

final class IssueCommentAutocomplete {

    let cellHeight = Styles.Sizes.tableCellHeight

    private weak var delegate: IssueCommentAutocompleteDelegate?
    private let identifier = "identifier"

    private var map: [String: AutocompleteType]

    init(autocompletes: [AutocompleteType]) {
        var map = [String: AutocompleteType]()
        for autocomplete in autocompletes {
            map[autocomplete.prefix] = autocomplete
        }
        self.map = map
    }

    // MARK: Public APIs

    func add(_ autocomplete: AutocompleteType) {
        map[autocomplete.prefix] = autocomplete
        delegate?.didChangeStore(autocomplete: self)
    }

    func configure(tableView: UITableView, delegate: IssueCommentAutocompleteDelegate) {
        self.delegate = delegate
        tableView.register(AutocompleteCell.self, forCellReuseIdentifier: identifier)
    }

    var prefixes: [String] {
        return map.map { $0.key }
    }

    func highlightAttributes(prefix: String) -> [NSAttributedString.Key: Any]? {
        return map[prefix]?.highlightAttributes
    }

    func resultCount(prefix: String?) -> Int {
        guard let prefix = prefix, let autocomplete = map[prefix] else { return 0 }
        return autocomplete.resultsCount
    }

    func resultHeight(prefix: String?) -> CGFloat {
        return CGFloat(resultCount(prefix: prefix)) * cellHeight
    }

    func didChange(tableView: UITableView, prefix: String?, word: String) {
        guard let prefix = prefix, let autocomplete = map[prefix] else {
            delegate?.didFinish(autocomplete: self, hasResults: false)
            return
        }

        autocomplete.search(word: word) { hasResults in
            self.delegate?.didFinish(autocomplete: self, hasResults: hasResults)
        }
    }

    func cell(tableView: UITableView, prefix: String?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        if let cell = cell as? AutocompleteCell,
            let prefix = prefix,
            let autocomplete = map[prefix] {
            autocomplete.configure(cell: cell, index: indexPath.item)
        }

        return cell
    }

    func accept(prefix: String?, indexPath: IndexPath) -> String? {
        guard let prefix = prefix, let autocomplete = map[prefix] else {
            return nil
        }
        return autocomplete.accept(index: indexPath.item)
    }

    var copy: IssueCommentAutocomplete {
        return IssueCommentAutocomplete(autocompletes: Array(map.values))
    }

}
