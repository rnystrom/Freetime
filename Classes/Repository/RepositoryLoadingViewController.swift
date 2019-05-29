//
//  RepositoryLoadingViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/27/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import XLPagerTabStrip

final class RepositoryLoadingViewController: UIViewController,
IndicatorInfoProvider {

    private let spinner = UIActivityIndicatorView(style: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.Strings.overview
        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: IndicatorInfoProvider

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: title)
    }

}
