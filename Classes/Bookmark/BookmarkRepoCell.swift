//
//  BookmarkRepoCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/25/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class BookmarkRepoCell: SelectableCell {

    private let imageView = UIImageView(image: UIImage(named: "repo").withRenderingMode(.alwaysTemplate))
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityIdentifier = "bookmark-repo-cell"

        contentView.addSubview(imageView)
        contentView.addSubview(label)

        imageView.contentMode = .center
        imageView.tintColor = Styles.Colors.Blue.medium.color
        imageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(Styles.Sizes.icon)
            make.left.equalTo(Styles.Sizes.columnSpacing)
        }

        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(Styles.Sizes.columnSpacing)
            make.right.lessThanOrEqualTo(-Styles.Sizes.gutter)
        }

        addBorder(.bottom, left: Styles.Sizes.icon.width + Styles.Sizes.columnSpacing * 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    func configure(owner: String, name: String) {
        let textColor = Appearance.currentTheme == .light
            ? Styles.Colors.Gray.dark.color
            : Styles.Colors.Gray.light.color
        let text = NSMutableAttributedString(string: "\(owner)/", attributes: [
            .foregroundColor: textColor,
            .font: Styles.Text.body.preferredFont
            ])
        text.append(NSAttributedString(string: "\(name)", attributes: [
            .foregroundColor: textColor,
            .font: Styles.Text.bodyBold.preferredFont
            ]))
        label.attributedText = text
    }

}
