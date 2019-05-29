//
//  Router.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/1/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import GitHawkRoutes
import Crashlytics

private func register<T: Routable & RoutePerformable>(
    route: T.Type,
    map: inout [String: (Routable & RoutePerformable).Type]
    ) {
    map[T.path] = T.self
}

private var hasSwizzledChildViewController = false

private func logMissingRouter() {
    let trace = Thread.callStackSymbols.joined(separator: "\n")
    print("ERROR: Router not wired up. Callsite:")
    print(trace)
    Answers.logCustomEvent(
        withName: "missing-router",
        customAttributes: ["trace": trace]
    )
}

extension UIViewController {

    fileprivate class func swizzleChildViewController() {
        // make sure this isn't a subclass
        if self !== UIViewController.self,
            hasSwizzledChildViewController == false {
            return
        }

        let originalSelector = #selector(addChild)
        let swizzledSelector = #selector(swizzle_addChildViewController(_:))

        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            else { return }

        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc func swizzle_addChildViewController(_ controller: UIViewController) {
        self.swizzle_addChildViewController(controller)
        controller.router = router
    }

    private static var RouterAssocObjectKey = "RouterAssocObjectKey"
    var router: Router? {
        get {
            return objc_getAssociatedObject(
                self,
                &UIViewController.RouterAssocObjectKey
            ) as? Router
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.RouterAssocObjectKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            // recursively set to all VCs
            children.forEach { $0.router = newValue }
        }
    }

    func route(_ route: Routable & RoutePerformable) {
        router?.handle(route: route, from: self)
    }

    // MARK: Remove after migration

    func route_push(to controller: UIViewController) {
        if router == nil { logMissingRouter() }
        router?.push(from: self, to: controller)
    }

    func route_detail(to controller: UIViewController) {
        if router == nil { logMissingRouter() }
        router?.detail(controller: controller)
    }

    func route_present(to controller: UIViewController) {
        if router == nil { logMissingRouter() }
        router?.present(from: self, to: controller)
    }

}

protocol RouterPropsSource: class {
    func props(for router: Router) -> RoutePerformableProps?
}

final class Router: NSObject {

    private weak var propsSource: RouterPropsSource?
    private let routes: [String: (Routable & RoutePerformable).Type]

    init(propsSource: RouterPropsSource) {
        var routes = [String: (Routable & RoutePerformable).Type]()
        register(route: BookmarkShortcutRoute.self, map: &routes)
        register(route: SwitchAccountShortcutRoute.self, map: &routes)
        register(route: SearchShortcutRoute.self, map: &routes)
        register(route: IssueRoute.self, map: &routes)
        register(route: RepoRoute.self, map: &routes)
        self.routes = routes
        self.propsSource = propsSource

        UIViewController.swizzleChildViewController()
    }

    func handle(url: URL) -> RoutePerformableResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host
            else { return .error }
        var params = [String: String]()
        for item in components.queryItems ?? [] {
            params[item.name] = item.value
        }
        return handle(path: host, params: params)
    }

    @discardableResult
    func handle(path: String, params: [String: String]) -> RoutePerformableResult {
        guard let routeType = routes[path],
            let route = routeType.from(params: params)
            else { return .error }
        return handle(route: route)
    }

    // returning .show(controller) displays the controller in the detail view
    func handle(route: Routable & RoutePerformable) -> RoutePerformableResult {
        return handle(route: route, from: nil)
    }

    // returning the .show(controller) pushes the controller onto the nav stack
    // if a from controller is present
    @discardableResult
    func handle(
        route: Routable & RoutePerformable,
        from controller: UIViewController?
        ) -> RoutePerformableResult {
        guard let props = propsSource?.props(for: self) else { return .error }
        let result = route.perform(props: props)
        switch result {
        case .custom, .error: break
        case .push(let toController):
            // if trying to push but not given an origin, fallback to detail
            if let controller = controller,
                // do not allow pushing onto the master tab VC
                controller.tabBarController != props.splitViewController.masterTabBarController {
                push(from: controller, to: toController)
            } else {
                detail(controller: toController, split: props.splitViewController)
            }
        case .present(let toController):
            present(from: controller ?? props.splitViewController, to: toController)
        case .setDetail(let toController):
            detail(controller: toController, split: props.splitViewController)
        }
        return result
    }

    func push(from: UIViewController, to: UIViewController) {
        to.router = self
        from.navigationController?.pushViewController(
            to,
            animated: trueUnlessReduceMotionEnabled
        )
    }

    func present(from: UIViewController, to: UIViewController) {
        to.router = self
        from.present(to, animated: trueUnlessReduceMotionEnabled)
    }

    func detail(controller: UIViewController) {
        guard let split = propsSource?.props(for: self)?.splitViewController
            else { return }
        detail(controller: controller, split: split)
    }

    private func detail(controller: UIViewController, split: UISplitViewController) {
        let wrapped: UINavigationController
        if let controller = controller as? UINavigationController {
            wrapped = controller
        } else {
            wrapped = UINavigationController(rootViewController: controller)
        }
        controller.router = self
        split.showDetailViewController(wrapped, sender: nil)
    }

}
