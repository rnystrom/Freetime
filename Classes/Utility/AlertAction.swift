//
//  AlertActions.swift
//  Freetime
//
//  Created by Ivan Magda on 25/09/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

typealias AlertActionBlock = (UIAlertAction) -> Void

// MARK: AlertActions -

struct AlertAction {

    // MARK: Properties

    let rootViewController: UIViewController?
    let title: String?
    let style: UIAlertAction.Style

    enum AlertShareType {
        case shareUrl
        case shareContent
        case shareFilePath
        case shareFileName
        case `default`

        var localizedString: String {
            switch self {
            case .shareUrl: return NSLocalizedString("Share URL", comment: "")
            case .shareContent: return NSLocalizedString("Share Content", comment: "")
            case .shareFilePath: return NSLocalizedString("Copy Path", comment: "")
            case .shareFileName: return NSLocalizedString("Copy Name", comment: "")
            case .default: return NSLocalizedString("Share", comment: "")
            }
        }
    }

    // MARK: Init

    init(_ builder: AlertActionBuilder) {
        rootViewController = builder.rootViewController
        title = builder.title
        style = builder.style ?? .default
    }

    // MARK: Public

    func get(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: self.title, style: self.style, handler: handler)
    }

    func share(_ items: [Any],
               activities: [UIActivity]?,
               type: AlertShareType = .default,
               buildActivityBlock: ((UIActivityViewController) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: type.localizedString, style: .default) { _ in
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: activities)
            buildActivityBlock?(activityController)
            self.rootViewController?.present(activityController, animated: trueUnlessReduceMotionEnabled)
        }
    }

    func view(client: GithubClient, repo: RepositoryDetails, icon: UIImage) -> UIAlertAction {
        return UIAlertAction(title: repo.name, image: icon, style: .default) { _ in
            self.rootViewController?.route_push(to: RepositoryViewController(
                client: client,
                repo: repo
            ))
        }
    }

    func view(owner: String, icon: UIImage) -> UIAlertAction {
        return UIAlertAction(title: "@\(owner)", image: icon, style: .default) { _ in
            guard let url = URLBuilder.github().add(path: owner).url else { return }
            self.rootViewController?.presentSafari(url: url)
        }
    }

    func newIssue(issueController: NewIssueTableViewController) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.newIssue, style: .default) { _ in
            let nav = UINavigationController(rootViewController: issueController)
            nav.modalPresentationStyle = .formSheet
            self.rootViewController?.route_present(to: nav)
        }
    }

    // MARK: Static

    static func cancel(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.cancel, style: .cancel, handler: handler)
    }

    static func ok(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.ok, style: .default, handler: handler)
    }

    static func no(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.no, style: .cancel, handler: handler)
    }

    static func yes(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.yes, style: .default, handler: handler)
    }

    static func goBack(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: NSLocalizedString("Go back", comment: ""), style: .cancel, handler: handler)
    }

    static func discard(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: NSLocalizedString("Discard", comment: ""), style: .destructive, handler: handler)
    }

    static func delete(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: handler)
    }

    static func login(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.signin, style: .default, handler: handler)
    }

    static func clearAll(_ handler: AlertActionBlock? = nil) -> UIAlertAction {
        return UIAlertAction(title: Constants.Strings.clearAll, style: .destructive, handler: handler)
    }

}
