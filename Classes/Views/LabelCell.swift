//
//  LabelCell.swift
//  Freetime
//
//  Created by Sherlock, James on 15/07/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class LabelCell: UICollectionViewCell {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        accessibilityTraits.insert(.staticText)

        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = Styles.Text.button.preferredFont
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

}
