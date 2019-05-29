//
//  AutocompleteCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/23/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage
import StyledTextKit

final class AutocompleteCell: StyledTableCell {

    enum State {
        case emoji(emoji: String, term: String)
        case user(avatarURL: URL, login: String)
        case issue(number: Int, title: String)
    }

    private let thumbnailImageView = UIImageView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.backgroundColor = Styles.Colors.Gray.lighter.color
        thumbnailImageView.layer.cornerRadius = Styles.Sizes.avatarCornerRadius
        thumbnailImageView.layer.borderColor = Styles.Colors.Gray.light.color.cgColor
        thumbnailImageView.layer.borderWidth = 1.0 / UIScreen.main.scale
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.isUserInteractionEnabled = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.size.equalTo(Styles.Sizes.avatar)
            make.centerY.equalTo(contentView)
        }

        emojiLabel.font = UIFont.systemFont(ofSize: 20)
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.size.equalTo(Styles.Sizes.avatar)
            make.centerY.equalTo(contentView)
        }

        titleLabel.font = Styles.Text.body.preferredFont
        titleLabel.textColor = Styles.Colors.Gray.dark.color
        titleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(Styles.Sizes.gutter)
            make.right.lessThanOrEqualTo(-Styles.Sizes.gutter)
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public API

    func configure(state: State) {

        let emojiHidden: Bool
        let thumbnailHidden: Bool

        let builder = StyledTextBuilder(styledText: StyledText(style: Styles.Text.body))

        switch state {
        case .emoji(let emoji, let term):
            emojiHidden = false
            thumbnailHidden = true
            emojiLabel.text = emoji
            builder.add(attributes: [.foregroundColor: Styles.Colors.Gray.dark.color])
                .add(text: term)
        case .user(let avatarURL, let login):
            emojiHidden = true
            thumbnailHidden = false
            thumbnailImageView.sd_setImage(with: avatarURL)
            builder.add(attributes: [.foregroundColor: Styles.Colors.Gray.dark.color])
                .add(text: login)
        case .issue(let number, let title):
            emojiHidden = true
            thumbnailHidden = true
            builder.add(attributes: [.foregroundColor: Styles.Colors.Gray.light.color])
                .add(text: "#\(number) ")
                .add(attributes: [.foregroundColor: Styles.Colors.Gray.dark.color])
                .add(text: title, traits: [.traitBold])
        }

        emojiLabel.isHidden = emojiHidden
        thumbnailImageView.isHidden = thumbnailHidden
        titleLabel.attributedText = builder.build()
            .render(contentSizeCategory: UIContentSizeCategory.preferred)

        let left = emojiHidden && thumbnailHidden
            ? Styles.Sizes.gutter
            : Styles.Sizes.gutter + Styles.Sizes.avatar.width + Styles.Sizes.columnSpacing
        titleLabel.snp.updateConstraints { make in
            make.left.equalTo(left)
        }
    }

}
