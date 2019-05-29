//
//  IssueStatusEventCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/7/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import StringHelpers

protocol IssueStatusEventCellDelegate: class {
    func didTapActor(cell: IssueStatusEventCell)
    func didTapHash(cell: IssueStatusEventCell)
}

final class IssueStatusEventCell: UICollectionViewCell {

    weak var delegate: IssueStatusEventCellDelegate?

    private let actorButton = UIButton()
    private let hashButton = UIButton()
    private let statusButton = UIButton()
    private let dateLabel = ShowMoreDetailsLabel()

    private var dateConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        actorButton.addTarget(self, action: #selector(IssueStatusEventCell.onActor), for: .touchUpInside)
        contentView.addSubview(actorButton)
        actorButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        statusButton.setupAsLabel()
        contentView.addSubview(statusButton)
        statusButton.snp.makeConstraints { make in
            make.left.equalTo(actorButton.snp.right).offset(Styles.Sizes.inlineSpacing)
            make.centerY.equalToSuperview()
        }

        // courier has a little bit of a different kerning, manually adjust
        hashButton.titleLabel?.font = Styles.Text.secondaryCode.preferredFont
        hashButton.setTitleColor(Styles.Colors.Gray.dark.color, for: .normal)
        hashButton.addTarget(self, action: #selector(IssueStatusEventCell.onHash), for: .touchUpInside)
        contentView.addSubview(hashButton)
        hashButton.snp.makeConstraints { make in
            make.left.equalTo(statusButton.snp.right).offset(Styles.Sizes.inlineSpacing)
            make.centerY.equalToSuperview().offset(1)
        }

        dateLabel.font = Styles.Text.secondary.preferredFont
        dateLabel.textColor = Styles.Colors.Gray.medium.color
        dateLabel.backgroundColor = .clear
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            self.dateConstraint = make.left.equalTo(hashButton.snp.right).offset(Styles.Sizes.inlineSpacing).constraint
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    // MARK: Private API

    @objc func onActor() {
        delegate?.didTapActor(cell: self)
    }

    @objc func onHash() {
        delegate?.didTapHash(cell: self)
    }

    // MARK: Public API

    func configure(_ model: IssueStatusEventModel) {
        let actorAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Styles.Colors.Gray.dark.color,
            .font: Styles.Text.secondaryBold.preferredFont
        ]
        actorButton.setAttributedTitle(NSAttributedString(string: model.actor, attributes: actorAttributes), for: .normal)

        let title: String
        switch model.status {
        case .reopened: title = Constants.Strings.reopened // open event only happens when RE-opening
        case .closed: title = Constants.Strings.closed
        case .locked: title = Constants.Strings.locked
        case .unlocked: title = NSLocalizedString("Unlocked", comment: "")
        case .merged: title = Constants.Strings.merged
        }
        statusButton.setTitle(title, for: .normal)
        statusButton.config(pullRequest: model.pullRequest, state: model.status.buttonState)

        let hash = model.commitHash?.hashDisplay
        hashButton.setTitle(hash, for: .normal)

        dateConstraint?.update(offset: hash == nil ? -30 : Styles.Sizes.inlineSpacing)
        dateLabel.setText(date: model.date)
    }

}
