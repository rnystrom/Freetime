//
//  IssueAutocomplete.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/14/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import GitHubAPI
import Squawk

final class IssueAutocomplete: AutocompleteType {

    private struct Issue {
        let number: Int
        let title: String
    }

    private let client: Client
    private let owner: String
    private let repo: String

    private var cachedResults = [String: [Issue]]()
    private var results = [Issue]()

    init(client: Client, owner: String, repo: String) {
        self.client = client
        self.owner = owner
        self.repo = repo
    }

    // MARK: AutocompleteType

    var prefix: String {
        return "#"
    }

    var resultsCount: Int {
        return results.count
    }

    func configure(cell: AutocompleteCell, index: Int) {
        let result = results[index]
        cell.configure(state: .issue(number: result.number, title: result.title))
    }

    func search(word: String, completion: @escaping (Bool) -> Void) {
        if let cached = cachedResults[word] {
            self.results = cached
            completion(cached.count > 0)
            return
        }

        // search gql for term or number

        client.query(
            IssueAutocompleteQuery(query: "repo:\(owner)/\(repo) \(word)", page_size: 20),
            result: { $0 },
            completion: { [weak self] result in
            switch result {
            case .failure(let error):
                Squawk.show(error: error)
                completion(false)
            case .success(let data):
                guard let strongSelf = self else { return }
                strongSelf.results.removeAll()
                for node in data.search.nodes ?? [] {
                    let issue: Issue?
                    if let asIssue = node?.asIssue {
                        issue = Issue(number: asIssue.number, title: asIssue.title)
                    } else if let asPR = node?.asPullRequest {
                        issue = Issue(number: asPR.number, title: asPR.title)
                    } else {
                        issue = nil
                    }
                    if let issue = issue {
                        strongSelf.results.append(issue)
                    }
                }
                completion(strongSelf.results.count > 0)
            }
        })
    }

    func accept(index: Int) -> String? {
        return prefix + "\(results[index].number)"
    }

    var highlightAttributes: [NSAttributedString.Key: Any]? { return nil }

}
