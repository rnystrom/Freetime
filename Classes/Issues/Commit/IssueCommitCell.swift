//
//  IssueCommitCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/26/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage

protocol IssueCommitCellDelegate: class {
    func didTapAvatar(cell: IssueCommitCell)
}

final class IssueCommitCell: UICollectionViewCell {

    weak var delegate: IssueCommitCellDelegate?

    private let commitImageView = UIImageView(image: UIImage(named: "git-commit-small").withRenderingMode(.alwaysTemplate))
    private let avatarImageView = UIImageView()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .button

        commitImageView.contentMode = .scaleAspectFit
        commitImageView.tintColor = Styles.Colors.Gray.light.color
        contentView.addSubview(commitImageView)
        commitImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.size.equalTo(Styles.Sizes.icon)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = Styles.Colors.Gray.lighter.color
        avatarImageView.layer.cornerRadius = Styles.Sizes.avatarCornerRadius
        avatarImageView.layer.borderColor = Styles.Colors.Gray.light.color.cgColor
        avatarImageView.layer.borderWidth = 1.0 / UIScreen.main.scale
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(IssueCommitCell.onAvatar))
        )
        avatarImageView.accessibilityIgnoresInvertColors = true

        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(commitImageView.snp.right).offset(Styles.Sizes.columnSpacing)
            make.size.equalTo(Styles.Sizes.icon)
        }

        messageLabel.backgroundColor = .clear
        messageLabel.font = Styles.Text.secondaryCode.preferredFont
        messageLabel.textColor = Styles.Colors.Gray.medium.color
        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarImageView.snp.right).offset(Styles.Sizes.columnSpacing)
            make.right.lessThanOrEqualToSuperview()
        }

        // always collapse and truncate
        messageLabel.lineBreakMode = .byTruncatingMiddle
        messageLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    // MARK: Public API

    func configure(_ model: IssueCommitModel) {
        avatarImageView.sd_setImage(with: model.avatarURL)
        messageLabel.text = model.message

        let labelFormat = NSLocalizedString("%@ committed \"%@\"", comment: "")
        accessibilityLabel = String(format: labelFormat, arguments: [model.login, model.message])
    }

    // MARK: Private API

    @objc func onAvatar() {
        delegate?.didTapAvatar(cell: self)
    }

}
