//
//  SearchLoadingView.swift
//  Freetime
//
//  Created by Ryan Nystrom on 9/4/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class SearchLoadingView: UIView {

    private let activity = UIActivityIndicatorView(style: .gray)

    override init(frame: CGRect) {
        super.init(frame: frame)

        activity.startAnimating()
        addSubview(activity)
        activity.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
