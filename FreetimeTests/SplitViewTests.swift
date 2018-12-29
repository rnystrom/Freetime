//
//  SplitViewTests.swift
//  Freetime
//
//  Created by Ryan Nystrom on 9/10/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import XCTest
@testable import Freetime

class RootViewController: UIViewController, PrimaryViewController {}

class SplitViewTests: XCTestCase {

    func test_whenSeparating_withPrimaryAndOtherVCs_thatSplitVCIsSeparated_andResultHasNonPrimary() {
        let masterTab = TabBarController()

        let leftNav = NavigationController()
        let left = UIViewController()
        leftNav.pushViewController(left, animated: false)

        let rightNav = NavigationController()
        let right1 = RootViewController()
        let right2 = RootViewController()
        let right3 = UIViewController()
        let right4 = UIViewController()
        right2.hidesBottomBarWhenPushed = true
        rightNav.pushViewController(right1, animated: false)
        rightNav.pushViewController(right2, animated: false)
        rightNav.pushViewController(right3, animated: false)
        rightNav.pushViewController(right4, animated: false)
        masterTab.viewControllers = [leftNav, rightNav]
        masterTab.selectedIndex = 1

        let split = UISplitViewController()
        split.viewControllers = [masterTab]

        let delegate = SplitViewControllerDelegate()

        let result = delegate.splitViewController(split, separateSecondaryFrom: masterTab)

        let resultTab = (split.viewControllers[0] as! UITabBarController)
        let resultLeft = resultTab.viewControllers![0] as! UINavigationController
        let resultRight = resultTab.viewControllers![1] as! UINavigationController
        XCTAssertEqual(resultTab, masterTab)
        XCTAssertEqual(resultLeft, leftNav)
        XCTAssertEqual(resultRight, rightNav)
        XCTAssertEqual(resultTab.selectedViewController, rightNav)
        XCTAssertEqual(resultRight.viewControllers.count, 2)
        XCTAssertEqual(resultRight.viewControllers[0], right1)
        XCTAssertEqual(resultRight.viewControllers[1], right2)

        let resultDetailVCs = (result as! UINavigationController).viewControllers
        XCTAssertEqual(resultDetailVCs.count, 2)
        XCTAssertEqual(resultDetailVCs[0], right3)
        XCTAssertEqual(resultDetailVCs[1], right4)
    }

    func test_whenSeparating_withSinglePrimary_thatSplitVCIsSeparated_andResultHasPlaceholder() {
        let masterTab = TabBarController()

        let leftNav = NavigationController()
        let left = UIViewController()
        leftNav.pushViewController(left, animated: false)

        let rightNav = NavigationController()
        let right1 = RootViewController()
        rightNav.pushViewController(right1, animated: false)
        masterTab.viewControllers = [leftNav, rightNav]
        masterTab.selectedIndex = 1

        let split = UISplitViewController()
        split.viewControllers = [masterTab]

        let delegate = SplitViewControllerDelegate()

        let result = delegate.splitViewController(split, separateSecondaryFrom: masterTab)

        let resultTab = (split.viewControllers[0] as! UITabBarController)
        let resultLeft = resultTab.viewControllers![0] as! UINavigationController
        let resultRight = resultTab.viewControllers![1] as! UINavigationController
        XCTAssertEqual(resultTab, masterTab)
        XCTAssertEqual(resultLeft, leftNav)
        XCTAssertEqual(resultRight, rightNav)
        XCTAssertEqual(resultTab.selectedViewController, rightNav)
        XCTAssertEqual(resultRight.viewControllers.count, 1)
        XCTAssertEqual(resultRight.viewControllers[0], right1)

        let resultDetailVCs = (result as! UINavigationController).viewControllers
        XCTAssertEqual(resultDetailVCs.count, 1)
        XCTAssert(resultDetailVCs[0] is SplitPlaceholderViewController)
    }

    func test_whenCollapsing_withVCsStackedOnMasterAndDetail_thatVCsStackedOnSelectedNav() {
        let masterTab = TabBarController()

        let leftNav = NavigationController()
        let left = UIViewController()
        leftNav.pushViewController(left, animated: false)

        let rightNav = NavigationController()
        let right1 = RootViewController()
        let right2 = RootViewController()
        rightNav.pushViewController(right1, animated: false)
        rightNav.pushViewController(right2, animated: false)
        masterTab.viewControllers = [leftNav, rightNav]
        masterTab.selectedIndex = 1

        let detailNav = NavigationController()

        let detail1 = RepositoryViewController(
            client: GithubClient(userSession: nil),
            repo: RepositoryDetails(
                owner: "Foo",
                name: "Bar"
        ))

        let detail2 = IssuesViewController(
            client: GithubClient(userSession: nil),
            model: IssueDetailsModel(
                owner: "Foo",
                repo: "Bar",
                number: 0
        ))

        detailNav.pushViewController(detail1, animated: false)
        detailNav.pushViewController(detail2, animated: false)

        let split = UISplitViewController()
        split.viewControllers = [masterTab, detailNav]

        let delegate = SplitViewControllerDelegate()

        _ = delegate.splitViewController(split, collapseSecondary: detailNav, onto: masterTab)

        let resultTab = split.viewControllers[0] as! UITabBarController
        XCTAssertEqual(resultTab.viewControllers?.count, 2)
        XCTAssertEqual(resultTab.selectedViewController, rightNav)
        XCTAssertEqual(rightNav.viewControllers.count, 4)
        XCTAssertEqual(rightNav.viewControllers[0], right1)
        XCTAssertEqual(rightNav.viewControllers[1], right2)
        XCTAssertEqual(rightNav.viewControllers[2], detail1)
        XCTAssertEqual(rightNav.viewControllers[3], detail2)

        XCTAssertFalse(rightNav.viewControllers[0].hidesBottomBarWhenPushed)
        XCTAssertFalse(rightNav.viewControllers[1].hidesBottomBarWhenPushed)

        // RepositoryViewController should not hide bottom bar
        XCTAssertTrue(!rightNav.viewControllers[2].hidesBottomBarWhenPushed)

        // IssueViewController should not hide bottom bar
        XCTAssertTrue(rightNav.viewControllers[3].hidesBottomBarWhenPushed)

    }

    func test_whenCollapsing_withPlaceholderStackedOnDetail_thatVCsStackedWithoutPlaceholder() {
        let masterTab = TabBarController()

        let leftNav = NavigationController()
        let left = UIViewController()
        leftNav.pushViewController(left, animated: false)

        let rightNav = NavigationController()
        let right1 = RootViewController()
        let right2 = RootViewController()
        rightNav.pushViewController(right1, animated: false)
        rightNav.pushViewController(right2, animated: false)
        masterTab.viewControllers = [leftNav, rightNav]
        masterTab.selectedIndex = 1

        let detailNav = NavigationController()
        let detail1 = SplitPlaceholderViewController()
        detailNav.pushViewController(detail1, animated: false)

        let split = UISplitViewController()
        split.viewControllers = [masterTab, detailNav]

        let delegate = SplitViewControllerDelegate()

        _ = delegate.splitViewController(split, collapseSecondary: detailNav, onto: masterTab)

        let resultTab = split.viewControllers[0] as! UITabBarController
        XCTAssertEqual(resultTab.viewControllers?.count, 2)
        XCTAssertEqual(resultTab.selectedViewController, rightNav)
        XCTAssertEqual(rightNav.viewControllers.count, 2)
        XCTAssertEqual(rightNav.viewControllers[0], right1)
        XCTAssertEqual(rightNav.viewControllers[1], right2)
    }

}
