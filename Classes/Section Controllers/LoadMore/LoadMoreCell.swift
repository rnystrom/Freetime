//
//  LoadMoreCell.swift
//  Freetime
//
//  Created by Sherlock, James on 28/07/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import IGListKit

final class LoadMoreCell: SelectableCell {

    private let activity = UIActivityIndicatorView(style: .gray)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityTraits.insert(.button)
        isAccessibilityElement = true
        label.font = Styles.Text.button.preferredFont
        label.textColor = Styles.Colors.Blue.medium.color
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalTo(contentView)
        }
        activity.hidesWhenStopped = true
        contentView.addSubview(activity)
        activity.snp.makeConstraints { make in
            make.center.equalTo(contentView)
        }
        label.text = NSLocalizedString("Load More", comment: "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    override var accessibilityLabel: String? {
        get { return NSLocalizedString("Load More", comment: "") }
        set { }
    }

    func configure(loading: Bool) {
        label.isHidden = loading
        loading
            ? activity.startAnimating()
            : activity.stopAnimating()
    }
}
