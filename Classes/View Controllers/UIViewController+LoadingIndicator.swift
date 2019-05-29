//
//  UIViewController+LoadingIndicator.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/7/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UIViewController {

    func setRightBarItemSpinning() {
        let activity = UIActivityIndicatorView(style: .gray)
        activity.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activity)
    }

    func setLeftBarItemSpinning() {
        let activity = UIActivityIndicatorView(style: .gray)
        activity.startAnimating()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activity)
    }

}
