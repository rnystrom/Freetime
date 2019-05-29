//
//  IssueFileCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/12/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class IssueFileCell: SelectableCell {

    private let changeLabel = UILabel()
    private let pathLabel = UILabel()
    private let disclosure = UIImageView(image: UIImage(named: "chevron-right").withRenderingMode(.alwaysTemplate))

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        disclosure.tintColor = Styles.Colors.Gray.light.color
        disclosure.contentMode = .scaleAspectFit
        contentView.addSubview(disclosure)
        disclosure.snp.makeConstraints { make in
            make.right.equalTo(-Styles.Sizes.gutter)
            make.centerY.equalToSuperview()
            make.size.equalTo(Styles.Sizes.icon)
        }

        contentView.addSubview(changeLabel)
        changeLabel.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.bottom.equalTo(contentView.snp.centerY)
            make.right.lessThanOrEqualTo(disclosure.snp.left).offset(-Styles.Sizes.rowSpacing)
        }

        pathLabel.font = Styles.Text.body.preferredFont
        pathLabel.textColor = Styles.Colors.Gray.dark.color
        pathLabel.lineBreakMode = .byTruncatingHead
        contentView.addSubview(pathLabel)
        pathLabel.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.top.equalTo(changeLabel.snp.bottom)
            make.right.lessThanOrEqualTo(disclosure.snp.left).offset(-Styles.Sizes.rowSpacing)
        }

        addBorder(.bottom, left: Styles.Sizes.gutter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public API

    func configure(path: String, additions: Int, deletions: Int, disclosureHidden: Bool) {
        let changeString = NSMutableAttributedString()
        var attributes: [NSAttributedString.Key: Any] = [
            .font: Styles.Text.secondaryBold.preferredFont
        ]

        if additions > 0 {
            attributes[.foregroundColor] = Styles.Colors.Green.medium.color
            changeString.append(NSAttributedString(string: "+\(additions) ", attributes: attributes))
        }

        if deletions > 0 {
            attributes[.foregroundColor] = Styles.Colors.Red.medium.color
            changeString.append(NSAttributedString(string: "-\(deletions)", attributes: attributes))
        }

        changeLabel.attributedText = changeString
        disclosure.isHidden = disclosureHidden
        pathLabel.text = path
    }

}
