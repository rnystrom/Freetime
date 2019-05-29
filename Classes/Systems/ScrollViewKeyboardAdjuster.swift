//
//  ScrollViewKeyboardAdjuster.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/7/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

final class ScrollViewKeyboardAdjuster {

    private let scrollView: UIScrollView
    private var originalContentInset: UIEdgeInsets = .zero
    private weak var viewController: UIViewController?
    private var keyboardIsShowing = false

    init(scrollView: UIScrollView, viewController: UIViewController) {
        self.scrollView = scrollView
        self.viewController = viewController

        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(onKeyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(onKeyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: Notifications

    @objc func onKeyboardWillShow(notification: NSNotification) {
        guard !keyboardIsShowing,
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let viewController = self.viewController
            else { return }

        keyboardIsShowing = true

        var inset = scrollView.contentInset
        originalContentInset = inset

        let converted = viewController.view.convert(frame, from: nil)
        let intersection = converted.intersection(frame)
        let bottomInset = intersection.height - viewController.view.safeAreaInsets.bottom

        inset.bottom = bottomInset

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.scrollView.contentInset = inset
            self.scrollView.scrollIndicatorInsets = inset
        })
    }

    @objc func onKeyboardWillHide(notification: NSNotification) {
        guard keyboardIsShowing,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }

        keyboardIsShowing = false

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.scrollView.contentInset = self.originalContentInset
            self.scrollView.scrollIndicatorInsets = self.originalContentInset
        })
    }

}
