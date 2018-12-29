//
//  SplitViewControllerDelegate.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/25/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

// add this shell protocol onto a view controller that should remain part of a tab's root nav VC when splitting out
// detail VCs from primary on split VC expansion
protocol PrimaryViewController {}

private func fixBackground(for splitViewController: UISplitViewController, collapsing: Bool) {
    splitViewController.view.backgroundColor = collapsing
    ? .white
    : Styles.Colors.splitViewBackground
}

final class SplitViewControllerDelegate: UISplitViewControllerDelegate {

    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
        ) -> Bool {
        fixBackground(for: splitViewController, collapsing: true)

        if let tab = primaryViewController as? UITabBarController,
            let primaryNav = tab.selectedViewController as? UINavigationController,
            let secondaryNav = secondaryViewController as? UINavigationController {

            let collapsedControllers = secondaryNav.viewControllers.filter {

                // remove any placeholder VCs from the stack
                return ($0 is SplitPlaceholderViewController) == false
            }
            // avoid setting view controllers b/c can result in viewDidLoad being called
            // https://github.com/GitHawkApp/GitHawk/issues/2230
            if collapsedControllers.count > 0 {
                primaryNav.viewControllers += collapsedControllers
            }
        }

        return true
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        separateSecondaryFrom primaryViewController: UIViewController
        ) -> UIViewController? {
        fixBackground(for: splitViewController, collapsing: false)

        guard let tab = primaryViewController as? UITabBarController,
            let primaryNav = tab.selectedViewController as? UINavigationController
            else { return nil }

        var detailVCs = [UIViewController]()

        // for each tab VC that is a nav controller, pluck everything that isn't marked as a primary VC off of
        // the nav stack. if the nav is the currently selected tab VC, then move all non-primary VCs to
        for tabVC in tab.viewControllers ?? [] {
            // they should all be navs, but just in case
            guard let nav = tabVC as? UINavigationController else { continue }

            // pop until hitting a VC marked as "primary"
            while let top = nav.topViewController,
                top !== nav.viewControllers.first,
                (top is PrimaryViewController) == false {
                if nav === primaryNav {
                    detailVCs.insert(top, at: 0)
                }
                nav.popViewController(animated: false)
            }
        }

        if detailVCs.count > 0 {
            // if there are active VCs, push them onto the new nav stack
            let nav = NavigationController()
            nav.setViewControllers(detailVCs, animated: false)
            return nav
        } else {
            // otherwise use a placeholder VC
            return NavigationController(rootViewController: SplitPlaceholderViewController())
        }
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        showDetail vc: UIViewController,
        sender: Any?
        ) -> Bool {
        guard let tab = splitViewController.viewControllers.first as? UITabBarController
            else { return false }

        // isCollapsed can be false even when showing a single view controller on iPhone.
        // We check viewControllers.count as well to ensure we don't skip showing view controllers on the nav stack that we'd like to.
        // https://github.com/GitHawkApp/GitHawk/issues/2450
        if splitViewController.isCollapsed || splitViewController.viewControllers.count == 1 {
            if let nav = vc as? UINavigationController, let first = nav.viewControllers.first {
                tab.selectedViewController?.show(first, sender: sender)
            } else {
                tab.selectedViewController?.show(vc, sender: sender)
            }
        } else {
            splitViewController.viewControllers = [tab, vc]
        }

        return true
    }

}
