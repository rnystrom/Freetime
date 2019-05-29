//
//  RepositorySummaryCell.swift
//  Freetime
//
//  Created by Sherlock, James on 29/07/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import StyledTextKit
import DateAgo

final class RepositorySummaryCell: SelectableCell {

    static let titleInset = UIEdgeInsets(
        top: Styles.Sizes.gutter,
        left: Styles.Sizes.icon.width + 2*Styles.Sizes.columnSpacing,
        bottom: Styles.Sizes.rowSpacing,
        right: Styles.Sizes.gutter
    )

    private let reasonImageView = UIImageView()
    private let titleView = StyledTextView()
    private let detailsStackView = UIStackView()
    private let secondaryLabel = UILabel()
    private let labelListView = LabelListView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        backgroundColor = .white

        contentView.addSubview(reasonImageView)
        contentView.addSubview(titleView)
        contentView.addSubview(detailsStackView)

        reasonImageView.backgroundColor = .clear
        reasonImageView.contentMode = .scaleAspectFit
        reasonImageView.tintColor = Styles.Colors.Blue.medium.color
        reasonImageView.snp.makeConstraints { make in
            make.size.equalTo(Styles.Sizes.icon)
            make.centerY.equalToSuperview()
            make.left.equalTo(Styles.Sizes.columnSpacing)
        }

        detailsStackView.axis = .vertical
        detailsStackView.alignment = .leading
        detailsStackView.distribution = .fill
        detailsStackView.spacing = Styles.Sizes.rowSpacing
        detailsStackView.addArrangedSubview(secondaryLabel)
        detailsStackView.addArrangedSubview(labelListView)
        detailsStackView.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentView).offset(-Styles.Sizes.gutter)
            make.left.equalTo(reasonImageView.snp.right).offset(Styles.Sizes.columnSpacing)
            make.right.equalTo(contentView.snp.right).offset(-Styles.Sizes.columnSpacing)
        }

        secondaryLabel.numberOfLines = 1
        secondaryLabel.font = Styles.Text.secondary.preferredFont
        secondaryLabel.textColor = Styles.Colors.Gray.light.color

        labelListView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalTo(detailsStackView)
        }

        contentView.addBorder(.bottom, left: RepositorySummaryCell.titleInset.left)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleView.reposition(for: contentView.bounds.width)
        resizeLabelListView(labels: labelListView.labels, cacheKey: labelListView.labels.reduce("", {$0 + $1.name}))
    }

    private func resizeLabelListView(labels: [RepositoryLabel], cacheKey: String) {
        let width = contentView.frame.width - (Styles.Sizes.columnSpacing * 2)
        let height = LabelListView.height(width: width, labels: labels, cacheKey: cacheKey)
        //check if height has changed before updating
        if height != labelListView.frame.height {
            labelListView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
        }
    }

    // MARK: Public API

    func configure(_ model: RepositoryIssueSummaryModel) {
        titleView.configure(with: model.title, width: contentView.bounds.width)

        let format = NSLocalizedString("#%d opened %@ by %@", comment: "")
        secondaryLabel.text = String(format: format, arguments: [model.number, model.created.agoString(.long), model.author])

        let imageName: String
        let tint: UIColor
        switch model.status {
        case .closed:
            imageName = model.pullRequest ? "git-pull-request" : "issue-closed"
            tint = Styles.Colors.Red.medium.color
        case .open:
            imageName = model.pullRequest ? "git-pull-request" : "issue-opened"
            tint = Styles.Colors.Green.medium.color
        case .merged:
            imageName = "git-merge"
            tint = Styles.Colors.purple.color
        }

        reasonImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        reasonImageView.tintColor = tint

        if model.labels.count > 0 {
            labelListView.isHidden = false
            labelListView.configure(labels: model.labels)
            resizeLabelListView(labels: model.labels, cacheKey: model.labelSummary)
        } else {
            labelListView.isHidden = true
        }
    }

    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }

}
