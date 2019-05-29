//
//  SearchRecentViewModelTests.swift
//  FreetimeTests
//
//  Created by Hesham Salman on 10/22/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import XCTest

@testable import Freetime
class SearchRecentViewModelTests: XCTestCase {

    var searchQuery: SearchQuery!
    var recentlyViewedQuery: SearchQuery!

    var searchViewModel: SearchRecentViewModel!
    var recentViewModel: SearchRecentViewModel!

    override func setUp() {
        super.setUp()
        searchQuery = SearchQuery.search("Pythonic")
        let kickstarter = RepositoryDetails(owner: "Kickstarter", name: "ios-oss")
        recentlyViewedQuery = SearchQuery.recentlyViewed(kickstarter)

        searchViewModel = SearchRecentViewModel(query: searchQuery)
        recentViewModel = SearchRecentViewModel(query: recentlyViewedQuery)
    }

    func test_displayText_searchQuery() {
        let expected = "Pythonic"
        let actual = searchViewModel.displayText.string

        XCTAssertEqual(expected, actual)
    }

    func test_displayText_searchQuery_styling() {
        let expected = NSAttributedString(string: "Pythonic", attributes: standardAttributes)
        let actual = searchViewModel.displayText
        XCTAssertEqual(expected, actual)
    }

    func test_displayText_recentlyViewed() {
        let expected = "Kickstarter/ios-oss"
        let actual = recentViewModel.displayText.string

        XCTAssertEqual(expected, actual)
    }

    func test_displayText_recentlyViewed_styling() {
        let expected = NSMutableAttributedString(string: "Kickstarter/", attributes: standardAttributes)
        expected.append(NSAttributedString(string: "ios-oss", attributes: boldAttributes))
        let actual = recentViewModel.displayText

        XCTAssertEqual(expected, actual)
    }

    func test_icon_search() {
        let expected = #imageLiteral(resourceName: "search")
        let actual = searchViewModel.icon

        XCTAssertEqual(expected, actual)
    }

    func test_icon_recentlyViewed() {
        let expected = #imageLiteral(resourceName: "repo")
        let actual = recentViewModel.icon

        XCTAssertEqual(expected, actual)
    }

    private var standardAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: Styles.Text.body.preferredFont,
            .foregroundColor: Styles.Colors.Gray.dark.color
        ]
    }

    private var boldAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: Styles.Text.bodyBold.preferredFont,
            .foregroundColor: Styles.Colors.Gray.dark.color
        ]
    }
}
