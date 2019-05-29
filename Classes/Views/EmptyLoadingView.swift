//
//  EmptyLoadingView.swift
//  Freetime
//
//  Created by Ryan Nystrom on 4/15/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

final class EmptyLoadingView: UIView {

    private let activity = UIActivityIndicatorView(style: .gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        activity.startAnimating()
        addSubview(activity)
    }

    func setSpinnerColor(to color: UIColor) {
        activity.color = color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        activity.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
    }

}
