//
//  Feed.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/15/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

protocol FeedDelegate: class {
    func loadFromNetwork(feed: Feed)
    func loadNextPage(feed: Feed) -> Bool
}

final class Feed: NSObject, UIScrollViewDelegate {

    enum Status {
        case initial
        case idle
        case loading
        case loadingNext
    }

    let swiftAdapter: ListSwiftAdapter
    let collectionView: UICollectionView

    public private(set) var status: Status = .initial
    private weak var delegate: FeedDelegate?
    private let feedRefresh = FeedRefresh()
    private let managesLayout: Bool
    private let loadingView = EmptyLoadingView()

    private let backgroundThreshold: CFTimeInterval?
    private var backgroundTime: CFTimeInterval?

    init(
        viewController: UIViewController,
        delegate: FeedDelegate,
        collectionView: UICollectionView? = nil,
        managesLayout: Bool = true,
        backgroundThreshold: CFTimeInterval? = nil
        ) {
        self.swiftAdapter = ListSwiftAdapter(viewController: viewController)
        self.delegate = delegate
        self.managesLayout = managesLayout
        self.collectionView = collectionView
            ?? UICollectionView(frame: .zero, collectionViewLayout: ListCollectionViewLayout.basic())
        self.backgroundThreshold = backgroundThreshold

        super.init()

        self.adapter.scrollViewDelegate = self

        self.collectionView.alwaysBounceVertical = true
        self.collectionView.backgroundColor = Styles.Colors.background
        self.collectionView.refreshControl = feedRefresh.refreshControl
        self.collectionView.keyboardDismissMode = .onDrag
        self.collectionView.accessibilityIdentifier = "feed-collection-view"
        feedRefresh.refreshControl.addTarget(self, action: #selector(Feed.onRefresh(sender:)), for: .valueChanged)

        self.loadingView.accessibilityIdentifier = "feed-loading-view"

        if backgroundThreshold != nil {
            let center = NotificationCenter.default
            center.addObserver(
                self,
                selector: #selector(didBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            center.addObserver(
                self,
                selector: #selector(willResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }
    }

    // MARK: Public API

    var adapter: ListAdapter {
        return swiftAdapter.listAdapter
    }

    func refreshHead() {
        refresh()
        feedRefresh.beginRefreshing()
    }

    func setLoadingSpinnerColor(to color: UIColor) {
        loadingView.setSpinnerColor(to: color)
    }

    func viewDidLoad() {
        guard let view = adapter.viewController?.view else { return }

        view.backgroundColor = .white

        adapter.collectionView = collectionView

        if collectionView.superview == nil {
            view.addSubview(collectionView)
        }

        view.addSubview(loadingView)

        // avoid app launch in the background triggering viewDidLoad-based network calls
        if UIApplication.shared.applicationState != .background {
            refresh()
        }
    }

    func viewWillLayoutSubviews(view: UIView) {
        let bounds = view.bounds

        loadingView.frame = bounds

        let changed = bounds != collectionView.frame
        if managesLayout && changed {
            collectionView.frame = bounds
        }
        if changed {
            collectionView.collectionViewLayout.invalidateForOrientationChange()
        }
    }

    func finishLoading(dismissRefresh: Bool, animated: Bool = true, completion: (() -> Void)? = nil) {
        status = .idle
        loadingView.isHidden = true

        adapter.performUpdates(animated: animated) { _ in
            if dismissRefresh {
                self.feedRefresh.endRefreshing(completion: {
                    completion?()
                })
            } else {
                completion?()
            }
        }
    }

    // MARK: Private API

    private func refresh() {
        guard status == .idle || status == .initial else { return }
        status = .loading
        delegate?.loadFromNetwork(feed: self)
    }

    @objc private func onRefresh(sender: Any) {
        refresh()
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.bounds.height
        let currentTopOffset = scrollView.contentOffset.y
        let topTargetOffset = targetContentOffset.pointee.y

        guard status == .idle, // dont page if already loading something
            topTargetOffset - currentTopOffset > 0 // only page when scrolling to the bottom
            else { return }

        if topTargetOffset > contentHeight - viewHeight * 2 {
            if delegate?.loadNextPage(feed: self) == true {
                status = .loadingNext
            }
        }
    }

    // MARK: Notifications

    @objc func willResignActive() {
        backgroundTime = CACurrentMediaTime()
    }

    @objc func didBecomeActive() {
        defer { backgroundTime = nil }

        let refresh: (Bool) -> Void = { head in
            // there seems to be a bug where refreshing while still becoming active messes up the iOS 11 header and
            // refresh control. put an artificial delay to let the system cool down?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                if head {
                    self.refreshHead()
                } else {
                    self.refresh()
                }
            })
        }

        // if foreground and haven't done an initial load, refresh
        // can occur when process is still alive after a background fetch
        if status == .initial {
            // dont refresh head since spinner will still be shown
            refresh(false)
        } else if let backgroundTime = self.backgroundTime,
            let backgroundThreshold = self.backgroundThreshold,
            CACurrentMediaTime() - backgroundTime > backgroundThreshold {
            refresh(true)
        }
    }

}
