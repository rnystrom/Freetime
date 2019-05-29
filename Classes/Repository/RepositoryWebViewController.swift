//
//  RepositoryWebViewController.swift
//  Freetime
//
//  Created by Ivan Magda on 01/03/2018.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import WebKit

// MARK: RepositoryWebViewController: UIViewController

final class RepositoryWebViewController: UIViewController {

    // MARK: Types

    private enum State {
        case idle
        case fetching
        case error(String?)
    }

    // MARK: Instance Variables

    private let branch: String
    private let path: FilePath
    private let repo: RepositoryDetails

    private var state = State.idle {
        didSet {
            switch state {
            case .idle:
                activityIndicator.stopAnimating()
                emptyView.isHidden = true
                webView.isHidden = false
            case .fetching:
                activityIndicator.startAnimating()
                emptyView.isHidden = true
                webView.isHidden = false
            case .error(let message):
                activityIndicator.stopAnimating()
                webView.isHidden = true
                emptyView.isHidden = false
                emptyView.label.text = message
            }
        }
    }

    private var resourceURL: URL? {
        return URLBuilder.github()
            .add(paths: [repo.owner, repo.name, "raw", branch])
            .add(paths: path.components)
            .url
    }

    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.backgroundColor = .white

        return webView
    }()

    private let emptyView = EmptyView()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true

        return activityIndicator
    }()

    // MARK: Init

    init(
        repo: RepositoryDetails,
        branch: String,
        path: FilePath
        ) {
        self.repo = repo
        self.branch = branch
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        fetch()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        emptyView.frame = view.bounds
        activityIndicator.center = view.center

        if let tabBarController = tabBarController {
            webView.scrollView.contentInset.bottom = tabBarController.tabBar.bounds.height
        }
    }

}

// MARK: - RepositoryWebViewController (UIWebViewDelegate) -

extension RepositoryWebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        state = .fetching
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        state = .idle
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(cannotLoad: true)
    }

}

// MARK: - RepositoryWebViewController (EmptyViewDelegate) -

extension RepositoryWebViewController: EmptyViewDelegate {

    func didTapRetry(view: EmptyView) {
        fetch()
    }

}

// MARK: - RepositoryWebViewController (Fetch Data) -

extension RepositoryWebViewController {

    private func fetch() {
        guard let url = resourceURL else { return showError(cannotLoad: false) }
        state = .fetching

        URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                guard error == nil,
                    let data = data else { return strongSelf.showError(cannotLoad: true) }

                strongSelf.webView.load(
                    data,
                    mimeType: strongSelf.path.mimeType ?? "text/plain",
                    characterEncodingName: "UTF-8",
                    baseURL: url
                )
            }
        }.resume()
    }

}

// MARK: - RepositoryWebViewController (Actions) -

extension RepositoryWebViewController {

    @objc private func onFileNavigationTitle(sender: UIView) {
        showAlert(filePath: path, sender: sender)
    }

}

// MARK: - RepositoryWebViewController (Private Helpers) -

extension RepositoryWebViewController {

    private func setup() {
        makeBackBarItemEmpty()
        configureTitle(
            filePath: path,
            target: self,
            action: #selector(onFileNavigationTitle(sender:))
        )

        state = .idle
        emptyView.isHidden = true
        emptyView.delegate = self
        emptyView.button.isHidden = false

        view.backgroundColor = .white
        view.addSubview(emptyView)
        view.addSubview(webView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func showError(cannotLoad: Bool) {
        state = .error(cannotLoad
            ? NSLocalizedString("Cannot display file", comment: "")
            : NSLocalizedString("Error loading file", comment: "")
        )
    }

}
