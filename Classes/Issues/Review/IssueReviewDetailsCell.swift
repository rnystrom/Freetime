//
//  IssueReviewDetailsCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/5/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import IGListKit

protocol IssueReviewDetailsCellDelegate: class {
    func didTapActor(cell: IssueReviewDetailsCell)
}

final class IssueReviewDetailsCell: IssueCommentBaseCell, ListBindable {

    weak var delegate: IssueReviewDetailsCellDelegate?

    let icon = UIImageView()
    let actorButton = UIButton()
    let dateLabel = ShowMoreDetailsLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let iconSize = Styles.Sizes.icon
        icon.clipsToBounds = true
        icon.layer.cornerRadius = iconSize.width/2
        icon.contentMode = .center
        contentView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }

        actorButton.addTarget(self, action: #selector(IssueReviewDetailsCell.onActorTapped), for: .touchUpInside)
        contentView.addSubview(actorButton)
        actorButton.snp.makeConstraints { make in
            make.centerY.equalTo(icon)
            make.left.equalTo(icon.snp.right).offset(Styles.Sizes.columnSpacing)
        }

        contentView.addSubview(dateLabel)
        dateLabel.font = Styles.Text.secondary.preferredFont
        dateLabel.textColor = Styles.Colors.Gray.medium.color
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(actorButton)
            make.left.equalTo(actorButton.snp.right).offset(Styles.Sizes.columnSpacing/2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private API

    @objc func onActorTapped() {
        delegate?.didTapActor(cell: self)
    }

    // MARK: ListBindable

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? IssueReviewDetailsModel else { return }

        dateLabel.setText(date: viewModel.date)

        let action: String
        let iconBackgroundColor: UIColor
        let iconTintColor: UIColor
        let iconName: String
        switch viewModel.state {
        case .commented, .__unknown:
            action = NSLocalizedString("commented", comment: "")
            iconBackgroundColor = Styles.Colors.Gray.lighter.color
            iconTintColor = Styles.Colors.Gray.medium.color
            iconName = "eye-small"
        case .changesRequested:
            action = NSLocalizedString("requested changes", comment: "")
            iconBackgroundColor = Styles.Colors.Red.medium.color
            iconTintColor = .white
            iconName = "request-changes"
        case .approved:
            action = NSLocalizedString("approved", comment: "")
            iconBackgroundColor = Styles.Colors.Green.medium.color
            iconTintColor = .white
            iconName = "check-small"
        case .pending:
            action = NSLocalizedString("pending review", comment: "")
            iconBackgroundColor = Styles.Colors.Yellow.light.color
            iconTintColor = Styles.Colors.Gray.medium.color
            iconName = "eye-small"
        case .dismissed:
            action = NSLocalizedString("dismissed a review", comment: "")
            iconBackgroundColor = Styles.Colors.Gray.light.color
            iconTintColor = Styles.Colors.Gray.medium.color
            iconName = "x-small"
        }

        icon.backgroundColor = iconBackgroundColor
        icon.tintColor = iconTintColor
        icon.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)

        var attributes: [NSAttributedString.Key: Any] = [
            .font: Styles.Text.title.preferredFont,
            .foregroundColor: Styles.Colors.Gray.medium.color
        ]
        let mActorString = NSMutableAttributedString(string: viewModel.actor, attributes: attributes)

        attributes[.font] = Styles.Text.secondary.preferredFont
        mActorString.append(NSAttributedString(string: " \(action)", attributes: attributes))
        actorButton.setAttributedTitle(mActorString, for: .normal)
    }

}
