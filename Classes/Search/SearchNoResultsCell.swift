//
//  SearchNoResultsCell.swift
//  Freetime
//
//  Created by Sherlock, James on 29/07/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class SearchNoResultsCell: UICollectionViewCell {

    private let emoji = UILabel()
    private let label = UILabel()
    private let shadow = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityTraits.insert(.staticText)
        isAccessibilityElement = true

        emoji.text = "😞"
        emoji.textAlignment = .center
        emoji.backgroundColor = .clear
        emoji.font = UIFont.systemFont(ofSize: 60)
        contentView.addSubview(emoji)
        emoji.snp.makeConstraints { make in
            make.centerX.equalTo(contentView)
            make.centerY.equalTo(contentView).offset(-Styles.Sizes.tableSectionSpacing)
        }

        shadow.fillColor = UIColor(white: 0, alpha: 0.05).cgColor
        contentView.layer.addSublayer(shadow)

        label.text = NSLocalizedString("No Results Found", comment: "")
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.font = Styles.Text.body.preferredFont
        label.textColor = Styles.Colors.Gray.light.color
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalTo(emoji)
            make.top.equalTo(emoji.snp.bottom).offset(Styles.Sizes.tableSectionSpacing)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()

        let width: CGFloat = 30
        let height: CGFloat = 12
        shadow.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: width, height: height))).cgPath
        shadow.position = CGPoint(x: contentView.bounds.width/2 - 20, y: contentView.bounds.height/2 + 5)
    }

    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }

}
