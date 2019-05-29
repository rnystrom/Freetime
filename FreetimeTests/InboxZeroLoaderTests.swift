//
//  InboxZeroLoaderTests.swift
//  FreetimeTests
//
//  Created by Viktoras Laukevicius on 05/02/2019.
//  Copyright © 2019 Ryan Nystrom. All rights reserved.
//

import XCTest
@testable import Freetime

extension Date {
    static func date(from: [Calendar.Component: Int]) -> Date {
        var dc = DateComponents()
        dc.calendar = Calendar.current
        for (comp, val) in from {
            switch comp {
            case .year: dc.year = val
            case .month: dc.month = val
            case .day: dc.day = val
            case .hour: dc.hour = val
            case .minute: dc.minute = val
            case .second: dc.second = val
            default: break
            }
        }
        return dc.date!
    }
}

class InboxZeroLoaderTests: XCTestCase {

    private var loader: InboxZeroLoader!

    override func setUp() {
        loader = InboxZeroLoader(json: [
            "2019": [
                "2": [
                    "5": [
                        "emoji": "🐷",
                        "message": "新年好 / 新年好"
                    ]
                ]
            ],
            "fixed": [
                "4": [
                    "1": [
                        "emoji": "🤡",
                        "message": "Inbox ∞"
                    ]
                ]
            ]
        ])
    }

    override func tearDown() {
        loader = nil
    }

    func test_particularDate() {
        let date = Date.date(from: [.year: 2019, .month: 4, .day: 1, .hour: 13])
        let message = loader.message(date: date)
        XCTAssertEqual(message.emoji, "🤡")
    }

    func test_fixedDate() {
        let date = Date.date(from: [.year: 2019, .month: 2, .day: 5, .hour: 13])
        let message = loader.message(date: date)
        XCTAssertEqual(message.emoji, "🐷")
    }

    func test_defaultMessage() {
        let date = Date.date(from: [.year: 2019, .month: 4, .day: 2, .hour: 13])
        let message = loader.message(date: date)
        XCTAssertEqual(message.emoji, "🎉")
    }
}
