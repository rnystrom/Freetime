//
//  HistoryGraphQLToPathCommitModel.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/20/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import StyledTextKit

extension RepoFileHistoryQuery.Data {

    func commits(
        width: CGFloat,
        contentSizeCategory: UIContentSizeCategory
        ) -> [PathCommitModel] {
        guard let nodes = repository?.object?.asCommit?.history.nodes
            else { return [] }

        return nodes.compactMap {
            guard let model = $0,
                let author = model.author?.user?.login,
                let date = model.committedDate.githubDate,
                let url = URL(string: model.url)
                else { return nil }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 12
            paragraphStyle.lineSpacing = 2
            let attributes: [NSAttributedStringKey: Any] = [
                .foregroundColor: Styles.Colors.Gray.dark.color,
                .paragraphStyle: paragraphStyle,
                .backgroundColor: UIColor.white
            ]

            let builder = StyledTextBuilder(styledText: StyledText(
                style: Styles.Text.bodyBold.with(attributes: attributes)
            ))
                .add(text: "\(model.message.firstLine)\n")
                .add(style: Styles.Text.secondary.with(foreground: Styles.Colors.Gray.medium.color))
                .save()
                .add(text: author, traits: [.traitBold])
                .restore()

            if let committer = model.committer?.user?.login {
                builder.add(text: NSLocalizedString(" authored and ", comment: ""))
                    .save()
                    .add(text: committer, traits: [.traitBold])
                    .restore()
            }

            builder.add(text: NSLocalizedString(" committed ", comment: ""))
                .save()
                .add(styledText: StyledText(
                    text: model.oid.hashDisplay,
                    style: Styles.Text.secondaryCodeBold.with(foreground: Styles.Colors.Blue.medium.color)
                ))
                .restore()
                .add(text: " \(date.agoString(.long))")

            return PathCommitModel(
                oid: model.oid,
                text: StyledTextRenderer(
                    string: builder.build(),
                    contentSizeCategory: contentSizeCategory,
                    inset: PathCommitCell.inset
                ).warm(width: width),
                commitURL: url
            )
        }
    }

}
