//
//  RepositoryImageViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/17/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import SDWebImage
import SnapKit
import TUSafariActivity

final class RepositoryImageViewController: UIViewController,
EmptyViewDelegate,
UIScrollViewDelegate {

    private let branch: String
    private let path: FilePath
    private let repo: RepositoryDetails
    private let client: GithubClient
    private let emptyView = EmptyView()
    private let scrollView = UIScrollView()
    private let imageView = FLAnimatedImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    private var imageUrl: URL? {
        let builder = URLBuilder.github()
            .add(path: repo.owner)
            .add(path: repo.name)
            .add(path: "raw")
            .add(path: branch)
        path.components.forEach { builder.add(path: $0) }
        return builder.url
    }

    private lazy var moreOptionsItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(named: "bullets-hollow"),
            target: self,
            action: #selector(RepositoryImageViewController.onShare(sender:)))
        barButtonItem.accessibilityLabel = Constants.Strings.moreOptions
        barButtonItem.isEnabled = false
        return barButtonItem
    }()

    init(repo: RepositoryDetails, branch: String, path: FilePath, client: GithubClient) {
        self.branch = branch
        self.path = path
        self.repo = repo
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        configureTitle(filePath: path, target: self, action: #selector(onFileNavigationTitle(sender:)))
        makeBackBarItemEmpty()
        navigationItem.rightBarButtonItem = moreOptionsItem

        emptyView.isHidden = true
        emptyView.label.text = NSLocalizedString("Error loading image", comment: "")
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.maximumZoomScale = 4
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        fetch()
    }

    // MARK: Private API

    @objc func onFileNavigationTitle(sender: UIView) {
        showAlert(filePath: path, sender: sender)
    }

    private func fetch() {
        emptyView.isHidden = true
        activityIndicator.startAnimating()
        imageView.sd_setImage(with: imageUrl) { [weak self] (_, error, _, _) in
            self?.handle(success: error == nil)
        }
    }

    private func handle(success: Bool) {
        moreOptionsItem.isEnabled = success
        emptyView.isHidden = success

        activityIndicator.stopAnimating()

        if let size = imageView.image?.size {
            // centered later in UIScrollViewDelegate
            imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            scrollView.contentSize = size
            let bounds = view.bounds
            let scale = min(bounds.width / size.width, bounds.height / size.height)

            // min must be set before zoom
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
        }
    }

    @objc func onShare(sender: UIButton) {
        let alertTitle = "\(repo.owner)/\(repo.name):\(branch)"
        let alert = UIAlertController.configured(title: alertTitle, preferredStyle: .actionSheet)

        let alertBuilder = AlertActionBuilder { [weak self] in $0.rootViewController = self }
        var actions = [
            viewHistoryAction(owner: repo.owner, repo: repo.name, branch: branch, client: client, path: path),
            AlertAction(alertBuilder).share([path.path], activities: nil, type: .shareFilePath) {
                $0.popoverPresentationController?.setSourceView(sender)
            }
        ]

        if let image = imageView.image {
            actions.append(AlertAction(alertBuilder).share([image], activities: nil, type: .shareContent) {
                $0.popoverPresentationController?.setSourceView(sender)
            })
        }

        if let url = imageUrl {
            actions.append(AlertAction(alertBuilder).share([url], activities: [TUSafariActivity()], type: .shareUrl) {
                $0.popoverPresentationController?.setSourceView(sender)
            })
        }
        actions.append(AlertAction.cancel())

        if let name = self.path.components.last {
            actions.append(AlertAction(alertBuilder).share([name], activities: nil, type: .shareFileName) {
                $0.popoverPresentationController?.setSourceView(sender)
            })
        }

        alert.addActions(actions)
        alert.popoverPresentationController?.setSourceView(sender)
        present(alert, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: EmptyViewDelegate

    func didTapRetry(view: EmptyView) {
        fetch()
    }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }

}
