//
//  SettingsViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/31/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import GitHubAPI
import GitHubSession
import Squawk

final class SettingsViewController: UITableViewController,
    NewIssueTableViewControllerDelegate,
    DefaultReactionDelegate,
GitHubSessionListener {

    // must be injected
    var sessionManager: GitHubSessionManager! {
        didSet {
            sessionManager.addListener(listener: self)
        }
    }

    var client: GithubClient!

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var reviewAccessCell: StyledTableCell!
    @IBOutlet weak var githubStatusCell: StyledTableCell!
    @IBOutlet weak var reviewOnAppStoreCell: StyledTableCell!
    @IBOutlet weak var tryTestFlightBetaCell: StyledTableCell!
    @IBOutlet weak var reportBugCell: StyledTableCell!
    @IBOutlet weak var viewSourceCell: StyledTableCell!
    @IBOutlet weak var setDefaultReaction: StyledTableCell!
    @IBOutlet weak var signOutCell: StyledTableCell!
    @IBOutlet weak var badgeSwitch: UISwitch!
    @IBOutlet weak var badgeSettingsButton: UIButton!
    @IBOutlet weak var badgeCell: UITableViewCell!
    @IBOutlet weak var markReadSwitch: UISwitch!
    @IBOutlet weak var accountsCell: StyledTableCell!
    @IBOutlet weak var apiStatusLabel: UILabel!
    @IBOutlet weak var apiStatusView: UIImageView!
    @IBOutlet weak var signatureSwitch: UISwitch!
    @IBOutlet weak var defaultReactionLabel: UILabel!
    @IBOutlet weak var pushSwitch: UISwitch!
    @IBOutlet weak var pushCell: UITableViewCell!
    @IBOutlet weak var pushSettingsButton: UIButton!
    @IBOutlet weak var openExternalLinksSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        versionLabel.text = Bundle.main.prettyVersionString
        markReadSwitch.isOn = NotificationModelController.readOnOpen
        apiStatusView.layer.cornerRadius = 7
        apiStatusView.image = .from(color: Styles.Colors.Gray.border.color)
        signatureSwitch.isOn = Signature.enabled
        openExternalLinksSwitch.isOn = UserDefaults.standard.shouldOpenExternalLinksInSafari
        pushSettingsButton.accessibilityLabel = NSLocalizedString("How we send push notifications in GitHawk", comment: "")

        updateBadge()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SettingsViewController.updateBadge),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateDefaultReaction()

        rz_smoothlyDeselectRows(tableView: tableView)
        updateActiveAccount()

        client.client.send(GitHubAPIStatusRequest()) { [weak self] result in
            guard let strongSelf = self else { return }

            switch result {
            case .failure:
                strongSelf.apiStatusView.isHidden = true
                strongSelf.apiStatusLabel.text = NSLocalizedString("error", comment: "")
            case .success(let response):
                let text = response.data.status.description
                let color: UIColor
                switch response.data.status.indicator {
                case .none: color = Styles.Colors.Green.medium.color
                case .minor: color = Styles.Colors.Yellow.medium.color
                case .major: color = Styles.Colors.Red.medium.color
                case .critical: color = Styles.Colors.Red.dark.color
                }
                strongSelf.apiStatusView.isHidden = false
                strongSelf.apiStatusView.image = .from(color: color)
                strongSelf.apiStatusLabel.text = text
                strongSelf.apiStatusLabel.textColor = color
            }
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: trueUnlessReduceMotionEnabled)
        let cell = tableView.cellForRow(at: indexPath)

        switch cell {
        case reviewAccessCell: onReviewAccess()
        case accountsCell: onAccounts()
        case githubStatusCell: onGitHubStatus()
        case reviewOnAppStoreCell: onReviewOnAppStore()
        case reportBugCell: onReportBug()
        case viewSourceCell: onViewSource()
        case setDefaultReaction: onSetDefaultReaction()
        case signOutCell: onSignOut()
        case tryTestFlightBetaCell: onTryTestFlightBeta()
        default: break
        }
    }

    // MARK: Private API

    private func updateDefaultReaction() {
        defaultReactionLabel.text = ReactionContent.defaultReaction?.emoji
            ?? NSLocalizedString("Off", comment: "")
    }

    private func onReviewAccess() {
        UIApplication.shared.openReviewAccess()
    }

    private func onAccounts() {
        if let navigationController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "accountsNavigationController") as? UINavigationController,
            let accountsController = navigationController.topViewController as? SettingsAccountsViewController,
            let client = self.client {
            accountsController.config(client: client.client, sessionManager: sessionManager)
            route_detail(to: navigationController)
        }
    }

    private func onGitHubStatus() {
        guard let url = URLBuilder(host: "www.githubstatus.com").url
            else { return }
        presentSafari(url: url)
    }

    private func onReviewOnAppStore() {
        UIApplication.shared.openWriteReview()
    }

    private func onReportBug() {
        guard let viewController = NewIssueTableViewController.create(
                client: GithubClient(userSession: sessionManager.focusedUserSession),
                owner: "GitHawkApp",
                repo: "GitHawk",
                signature: .bugReport
            ) else {
                Squawk.showGenericError()
                return
        }
        viewController.delegate = self
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .formSheet
        route_present(to: navController)
    }

    private func onViewSource() {
        guard let client = client else {
            Squawk.showGenericError()
            return
        }

        let repo = RepositoryDetails(
            owner: "GitHawkApp",
            name: "GitHawk"
        )
        route_detail(to: RepositoryViewController(client: client, repo: repo))
    }

    private func onSetDefaultReaction() {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "DefaultReactionDetailController") as? DefaultReactionDetailController else {
            fatalError("Cannot instantiate DefaultReactionDetailController instance")
        }
        viewController.delegate = self
        route_detail(to: viewController)
    }

    private func onTryTestFlightBeta() {
        #if TESTFLIGHT
        Squawk.showAlreadyOnBeta()
        #else
        guard let url = URLBuilder.init(host: "testflight.apple.com").add(paths: ["join", "QIVXLkkn"]).url
            else { return }
        presentSafari(url: url)
        #endif
    }

    private func onSignOut() {
        let title = NSLocalizedString("Are you sure?", comment: "")
        let message = NSLocalizedString("You will be signed out from all of your accounts. Do you want to sign out?", comment: "")
        let alert = UIAlertController.configured(title: title, message: message, preferredStyle: .actionSheet)
        alert.addActions([
            AlertAction.cancel(),
            AlertAction(AlertActionBuilder {
                $0.title = Constants.Strings.signout
                $0.style = .destructive
            }).get { [weak self] _ in
                self?.signout()
            }
        ])
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = signOutCell
            popoverPresentationController.sourceRect = signOutCell.bounds
        }
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    private func signout() {
        sessionManager.logout()
    }

    @objc private func updateBadge() {
        BadgeNotifications.check { result in
            let showSwitches: Bool
            let pushEnabled: Bool
            let badgeEnabled: Bool

            switch result {
            case .error:
                showSwitches = false
                pushEnabled = false
                badgeEnabled = false
            case .success(let badge, let push):
                showSwitches = true
                pushEnabled = push
                badgeEnabled = badge
            }

            self.badgeCell.accessoryType = showSwitches ? .none : .disclosureIndicator
            self.badgeSettingsButton.isHidden = showSwitches
            self.badgeSwitch.isHidden = !showSwitches
            self.badgeSwitch.isOn = badgeEnabled

            self.pushCell.accessoryType = showSwitches ? .none : .disclosureIndicator
            self.pushSettingsButton.isHidden = showSwitches
            self.pushSwitch.isHidden = !showSwitches
            self.pushSwitch.isOn = pushEnabled
        }
    }

    private func updateActiveAccount() {
        accountsCell.detailTextLabel?.text = sessionManager.focusedUserSession?.username ?? Constants.Strings.unknown
    }

    @IBAction private func onBadgeChanged() {
        BadgeNotifications.isBadgeEnabled = badgeSwitch.isOn
        BadgeNotifications.configure { _ in
            self.updateBadge()
        }
    }

    @IBAction private func onPushChanged() {
        BadgeNotifications.isLocalNotificationEnabled = pushSwitch.isOn
        BadgeNotifications.configure { _ in
            self.updateBadge()
        }
    }

    @IBAction private func onSettings(_ sender: Any) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @IBAction private func onMarkRead(_ sender: Any) {
        NotificationModelController.setReadOnOpen(open: markReadSwitch.isOn)
    }

    @IBAction private func onSignature(_ sender: Any) {
        Signature.enabled = signatureSwitch.isOn
    }

    @IBAction private func onPushNotificationsInfo(_ sender: Any) {
        showContextualMenu(PushNotificationsDisclaimerViewController())
    }

    @IBAction private func onOpenExternalLinks(_ sender: Any) {
        UserDefaults.standard.shouldOpenExternalLinksInSafari = openExternalLinksSwitch.isOn
    }

    // MARK: NewIssueTableViewControllerDelegate

    func didDismissAfterCreatingIssue(model: IssueDetailsModel) {
        route_detail(to: IssuesViewController(client: client, model: model))
    }

    // MARK: DefaultReactionDelegate

    func didUpdateDefaultReaction() {
        updateDefaultReaction()
    }

    // MARK: GitHubSessionListener

    func didFocus(manager: GitHubSessionManager, userSession: GitHubUserSession, isSwitch: Bool) {
        updateActiveAccount()
    }

    func didLogout(manager: GitHubSessionManager) {}

}
