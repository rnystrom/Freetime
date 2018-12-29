//
//  SettingsAccountsViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/25/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import GitHubAPI
import GitHubSession

final class SettingsAccountsViewController: UITableViewController, GitHubSessionListener {

    private var client: Client!
    private var sessionManager: GitHubSessionManager!
    private var userSessions = [GitHubUserSession]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Accounts", comment: "")
        tableView.backgroundColor = Styles.Colors.background
    }

    // MARK: Public API

    func config(client: Client, sessionManager: GitHubSessionManager) {
        self.client = client
        self.sessionManager = sessionManager
        sessionManager.addListener(listener: self)
        updateUserSessions()
    }

    // MARK: Private API

    @IBAction func onAdd(_ sender: Any) {
        let alert = UIAlertController.configured(
            title: NSLocalizedString("Add Account", comment: ""),
            message: NSLocalizedString("To sign in with another account, please add a new Personal Access Token with user and repo scopes.", comment: ""),
            preferredStyle: .alert
        )

        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Personal Access Token", comment: "")
        }
        alert.addActions([
            AlertAction.cancel(),
            AlertAction.login({ [weak alert, weak self] _ in
                alert?.actions.forEach { $0.isEnabled = false }

                let token = alert?.textFields?.first?.text ?? ""
                self?.client.send(V3VerifyPersonalAccessTokenRequest(token: token)) { result in
                    switch result {
                    case .failure:
                        self?.handleError()
                    case .success(let user):
                        self?.finishLogin(token: token, authMethod: .pat, username: user.data.login)
                    }
                }
            })
        ])

        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    private func handleError() {
        let alert = UIAlertController.configured(
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("There was an error adding another account. Please try again.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(AlertAction.ok())
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    private func finishLogin(token: String, authMethod: GitHubUserSession.AuthMethod, username: String) {
        sessionManager.focus(
            GitHubUserSession(token: token, authMethod: authMethod, username: username)
        )
    }

    private func updateUserSessions() {
        userSessions = sessionManager.userSessions.sorted(by: { (left, right) -> Bool in
            return (left.username ?? "") < (right.username ?? "")
        })
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionManager.userSessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "account", for: indexPath)
        let session = userSessions[indexPath.row]
        cell.textLabel?.text = session.username ?? session.token
        cell.accessoryType = sessionManager.focusedUserSession == session ? .checkmark : .none
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: trueUnlessReduceMotionEnabled)

        let selectedSession = userSessions[indexPath.row]
        guard selectedSession != sessionManager.focusedUserSession else { return }
        sessionManager.focus(selectedSession)
    }

    // MARK: GitHubSessionListener

    func didFocus(manager: GitHubSessionManager, userSession: GitHubUserSession, isSwitch: Bool) {
        updateUserSessions()
        tableView.reloadData()
    }

    func didLogout(manager: GitHubSessionManager) {}

}
