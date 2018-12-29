//
//  LoginSplashViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/8/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SafariServices
import GitHubAPI
import GitHubSession

private let loginURL = URLBuilder.github()
    .add(paths: ["login", "oauth", "authorize"])
    .add(item: "client_id", value: Secrets.GitHub.clientId)
    .add(item: "scope", value: "user+repo+notifications")
    .url!
private let callbackURLScheme = "freetime://"

protocol LoginSplashViewControllerDelegate: class {
    func finishLogin(token: String, authMethod: GitHubUserSession.AuthMethod, username: String)
}

final class LoginSplashViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Appearance.currentTheme == .light
            ? .default
            : .lightContent
    }

    enum State {
        case idle
        case fetchingToken
    }

    private var client: Client!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var splashView: SplashView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private weak var delegate: LoginSplashViewControllerDelegate?

    @available(iOS 11.0, *)
    private var authSession: SFAuthenticationSession? {
        get {
            return _authSession as? SFAuthenticationSession
        }
        set {
            _authSession = newValue
        }
    }
    private var _authSession: Any?

    var state: State = .idle {
        didSet {
            let hideSpinner: Bool
            switch state {
            case .idle: hideSpinner = true
            case .fetchingToken: hideSpinner = false
            }
            signInButton.isEnabled = hideSpinner
            activityIndicator.isHidden = hideSpinner

            let title = hideSpinner
                ? NSLocalizedString("Sign in with GitHub", comment: "")
                : NSLocalizedString("Signing in...", comment: "")
            signInButton.setTitle(title, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        state = .idle
        signInButton.layer.cornerRadius = Styles.Sizes.cardCornerRadius
        switch Appearance.currentTheme {
        case .light:
            view.backgroundColor = .white
            titleLabel.textColor = .black
            subtitleLabel.textColor = .black
        case .dark:
            view.backgroundColor = Styles.Colors.Gray.dark.color
            titleLabel.textColor = .white
            subtitleLabel.textColor = .white
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupSplashView()
    }

    // MARK: Public API

    static func make(client: Client, delegate: LoginSplashViewControllerDelegate) -> LoginSplashViewController? {
        let controller = UIStoryboard(
            name: "OauthLogin",
            bundle: Bundle(for: AppDelegate.self))
            .instantiateInitialViewController() as? LoginSplashViewController
        controller?.client = client
        controller?.delegate = delegate
        controller?.modalPresentationStyle = .formSheet
        return controller
    }

    // MARK: Private API

    @IBAction func onSignInButton(_ sender: Any) {
        self.authSession = SFAuthenticationSession(url: loginURL, callbackURLScheme: callbackURLScheme, completionHandler: { [weak self] (callbackUrl, error) in
            guard error == nil, let callbackUrl = callbackUrl else {
                switch error! {
                case SFAuthenticationError.canceledLogin: break
                default: self?.handleError()
                }
                return
            }

            guard let items = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false)?.queryItems,
                let index = items.index(where: { $0.name == "code" }),
                let code = items[index].value
                else { return }

            self?.state = .fetchingToken

            self?.client.requestAccessToken(code: code) { [weak self] result in
                switch result {
                case .error:
                    self?.handleError()
                case .success(let user):
                    self?.delegate?.finishLogin(token: user.token, authMethod: .oauth, username: user.username)
                }
            }
        })
        self.authSession?.start()
    }

    @IBAction func onPersonalAccessTokenButton(_ sender: Any) {
        let alert = UIAlertController.configured(
            title: NSLocalizedString("Personal Access Token", comment: ""),
            message: NSLocalizedString("Sign in with a Personal Access Token with both repo and user scopes.", comment: ""),
            preferredStyle: .alert
        )

        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Personal Access Token", comment: "")
        }

        alert.addActions([
            AlertAction.cancel(),
            AlertAction.login({ [weak alert, weak self] _ in
                alert?.actions.forEach { $0.isEnabled = false }

                self?.state = .fetchingToken

                let token = alert?.textFields?.first?.text ?? ""
                self?.client.send(V3VerifyPersonalAccessTokenRequest(token: token)) { result in
                    switch result {
                    case .failure:
                        self?.handleError()
                    case .success(let user):
                        self?.delegate?.finishLogin(token: token, authMethod: .pat, username: user.data.login)
                    }
                }
            })
        ])

        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    private func handleError() {
        state = .idle

        let alert = UIAlertController.configured(
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("There was an error signing in to GitHub. Please try again.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(AlertAction.ok())
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    private func setupSplashView() {
        splashView.configureView()
    }

}
