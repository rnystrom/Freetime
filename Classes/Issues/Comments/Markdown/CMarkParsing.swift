//
//  CMarkParsing.swift
//  Freetime
//
//  Created by Ryan Nystrom on 3/31/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import StyledTextKit
import cmark_gfm_swift
import IGListKit
import HTMLString

private struct CMarkOptions {
    let owner: String
    let repo: String
    let branch: String?
    let width: CGFloat
    let viewerCanUpdate: Bool
    let contentSizeCategory: UIContentSizeCategory
    let isRoot: Bool
}

private struct CMarkContext {
    let inLink: Bool
    init(inLink: Bool = false) {
        self.inLink = inLink
    }
}

private extension TextElement {
    @discardableResult
    func build(
        _ builder: StyledTextBuilder,
        options: CMarkOptions,
        position: TextElementPosition,
        context: CMarkContext = CMarkContext()
        ) -> StyledTextBuilder {
        builder.save()
        defer { builder.restore() }

        switch self {
        case .text(let text):
            // if inside a link, attempt to shorten it if its an owner+repo+issue link
            if context.inLink, let shortlink = text.shortlinkInfo {
                let linkText: String
                // if the owner/repo match, just use "#123" shorthand
                if shortlink.owner.lowercased() == options.owner.lowercased(),
                    shortlink.repo.lowercased() == options.repo.lowercased() {
                    linkText = "#\(shortlink.number)"
                } else {
                    linkText = "\(shortlink.owner)/\(shortlink.repo)#\(shortlink.number)"
                }
                builder.add(text: linkText)
            } else {
                text.replacingGithubEmoji
                    .strippingHTMLComments
                    .removingHTMLEntities
                    .detectAndHandleCustomRegex(owner: options.owner, repo: options.repo, builder: builder)
            }
        case .softBreak:
            switch position {
            case .neck: builder.add(text: "\u{2028}")
            case .first, .last: break
            }
        case .lineBreak:
            builder.add(text: "\n")
        case .code(let text):
            builder.add(styledText: StyledText(
                text: text,
                style: Styles.Text.code.with(background: Styles.Colors.Gray.lighter.color)
            ))
        case .emphasis(let children):
            builder.add(traits: .traitItalic)
            children.build(builder, options: options, context: context)
        case .strong(let children):
            builder.add(traits: .traitBold)
            children.build(builder, options: options, context: context)
        case .strikethrough(let children):
            builder.add(attributes: [
                .strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                .strikethroughColor: builder.tipAttributes?[.foregroundColor] ?? Styles.Colors.Gray.dark.color
                ])
            children.build(builder, options: options, context: context)
        case .link(let children, _, let url):
            var attributes: [NSAttributedStringKey: Any] = [
                .foregroundColor: Styles.Colors.Blue.medium.color,
                .highlight: true
            ]
            if let shortlink = url?.shortlinkInfo {
                attributes[MarkdownAttribute.issue] = IssueDetailsModel(
                    owner: shortlink.owner,
                    repo: shortlink.repo,
                    number: shortlink.number
                )
            } else {
                attributes[MarkdownAttribute.url] = url ?? ""
            }
            builder.add(attributes: attributes)
            children.build(builder, options: options, context: CMarkContext(inLink: true))
        case .mention(let login):
            builder.add(text: "@\(login)", traits: .traitBold, attributes: [MarkdownAttribute.username: login])
        case .checkbox(let checked, let originalRange):
            builder.addCheckbox(checked: checked, range: originalRange, viewerCanUpdate: options.viewerCanUpdate)
        }
        return builder
    }
}

private enum TextElementPosition {
    case first
    case neck
    case last
}

private extension Array where Iterator.Element == TextElement {
    @discardableResult
    func build(
        _ builder: StyledTextBuilder,
        options: CMarkOptions,
        context: CMarkContext = CMarkContext()
        ) -> StyledTextBuilder {
        for (i, el) in enumerated() {
            let position: TextElementPosition
            switch i {
            case 0: position = .first
            case count - 1: position = .last
            default: position = .neck
            }
            el.build(
                builder,
                options: options,
                position: position,
                context: context
            )
        }
        return builder
    }
}

private extension ListElement {
    @discardableResult
    func build(_ builder: StyledTextBuilder, options: CMarkOptions) -> StyledTextBuilder {
        switch self {
        case .text(let text):
            text.build(builder, options: options)
        case .list(let children, let type, let level):
            children.build(builder, options: options, type: type, level: level)
        }
        return builder
    }
}

private extension Array {
    func forEach(_ body: (Element) -> Void, joined: (Element) -> Void) {
        for (i, e) in enumerated() {
            body(e)
            if i != count - 1 {
                joined(e)
            }
        }
    }
}

private extension Array where Iterator.Element == TextLine {
    @discardableResult
    func build(_ builder: StyledTextBuilder, options: CMarkOptions) -> StyledTextBuilder {
        forEach({ el in
            el.build(builder, options: options)
        }, joined: { _ in
            builder.add(text: "\n")
        })
        return builder
    }
}

private extension Array where Iterator.Element == [ListElement] {
    @discardableResult
    func build(
        _ builder: StyledTextBuilder,
        options: CMarkOptions,
        type: ListType,
        level: Int = 0
        ) -> StyledTextBuilder {
        builder.save()
        defer { builder.restore() }

        // unicode character to newline without creating a new paragraph to avoid NSParagraphStyle spacing
        let newline = "\u{2028}"

        for (i, c) in enumerated() {
            let tick: String
            switch type {
            case .ordered:
                tick = "\(i + 1)."
            case .unordered:
                tick = level % 2 == 0
                    ? Constants.Strings.bullet
                    : Constants.Strings.bulletHollow
            }

            var spaces = ""
            for _ in 0..<level {
                spaces += "  "
            }
            builder.add(text: "\(spaces)\(tick) ")

            c.forEach({ cc in
                cc.build(builder, options: options)
            }, joined: { _ in
                builder.add(text: newline)
            })

            // never append whitespace on the last element
            if i != count - 1 {
                builder.add(text: newline)
            }
        }
        return builder
    }
}

private extension TableRow {
    func build(options: CMarkOptions, greyBackground: Bool) -> [StyledTextRenderer] {
        let backgroundColor: UIColor = greyBackground ? Styles.Colors.Gray.lighter.color : Styles.Colors.background
        let builders: [StyledTextBuilder]
        switch self {
        case .header(let cells):
            builders = cells.map {
                $0.build(
                    StyledTextBuilder.markdownBase(isRoot: options.isRoot)
                        .add(traits: .traitBold),
                    options: options
                )
            }
        case .row(let cells):
            builders = cells.map {
                $0.build(
                    StyledTextBuilder.markdownBase(isRoot: options.isRoot)
                        .add(attributes: [.backgroundColor: backgroundColor]),
                    options: options
                )
            }
        }
        // don't warm, sized when building IssueCommentTableModel
        return builders.map {
            StyledTextRenderer(
                string: $0.build(),
                contentSizeCategory: options.contentSizeCategory,
                inset: IssueCommentTableCollectionCell.inset,
                backgroundColor: backgroundColor
            )
        }
    }
}

private extension Array where Iterator.Element == TableRow {
    func build(options: CMarkOptions) -> [(cells: [StyledTextRenderer], fill: Bool)] {
        var rowIndex = 0
        return map {
            let fill = rowIndex % 2 == 1
            if case .row = $0 { rowIndex += 1}
            return ($0.build(options: options, greyBackground: fill), fill)
        }
    }
}

private func makeModels(elements: [Element], options: CMarkOptions) -> [ListDiffable] {
    var models = [ListDiffable]()
    var runningBuilder: StyledTextBuilder?

    let makeBuilder: () -> StyledTextBuilder = {
        let builder: StyledTextBuilder
        if let current = runningBuilder {
            builder = current
                .add(text: "\n")
        } else {
            builder = StyledTextBuilder.markdownBase(isRoot: options.isRoot)
        }
        runningBuilder = builder
        return builder
    }

    let endRunningText: (Bool) -> Void = { isLast in
        if let builder = runningBuilder {
            models.append(StyledTextRenderer(
                string: builder.build(),
                contentSizeCategory: options.contentSizeCategory,
                inset: IssueCommentTextCell.inset(isLast: isLast)
            ).warm(width: options.width))
        }
        runningBuilder = nil
    }

    for (i, el) in elements.enumerated() {
        let isLast = i == elements.count - 1

        switch el {
        case .text(let items):
            items.build(makeBuilder(), options: options)
        case .heading(let text, let level):
            let style: TextStyle
            switch level {
            case 1: style = Styles.Text.h1
            case 2: style = Styles.Text.h2
            case 3: style = Styles.Text.h3
            case 4: style = Styles.Text.h4
            case 5: style = Styles.Text.h5
            default: style = Styles.Text.h6.with(foreground: Styles.Colors.Gray.medium.color)
            }

            let builder = makeBuilder()
                .save()
                .add(style: style)

            // add bottom spacing
            builder.add(attributes: [.baselineOffset: 12])
            text.build(builder, options: options)

            builder.restore()
        case .list(let items, let type):
            items.build(makeBuilder(), options: options, type: type)
        case .quote(let items, let level):
            endRunningText(isLast)

            let builder = StyledTextBuilder.markdownBase(isRoot: options.isRoot)
                .add(attributes: [.foregroundColor: Styles.Colors.Gray.medium.color])
            let string = StyledTextRenderer(
                string: items.build(builder, options: options).build(),
                contentSizeCategory: options.contentSizeCategory,
                inset: IssueCommentQuoteCell.inset(quoteLevel: level),
                backgroundColor: .white
                ).warm(width: options.width)
            models.append(IssueCommentQuoteModel(level: level, string: string))
        case .image(let title, let href):
            endRunningText(isLast)

            guard let url = URL(string: href) else { continue }
            if url.pathExtension.lowercased() == "svg" {
                // hack to workaround the SDWebImage not supporting svg images
                // just render it in a webview
                models.append(IssueCommentHtmlModel(html: "<img src=\(href) />"))
            } else {
                models.append(IssueCommentImageModel(url: url, title: title))
            }
        case .html(let text):
            endRunningText(isLast)

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let baseURL: URL?
            if let branch = options.branch {
                baseURL = URLBuilder.github().add(paths: [options.owner, options.repo, "raw", branch]).url
            } else {
                baseURL = nil
            }
            models.append(IssueCommentHtmlModel(html: trimmed, baseURL: baseURL))
        case .hr:
            endRunningText(isLast)

            models.append(IssueCommentHrModel())
        case .codeBlock(let text, let language):
            endRunningText(isLast)

            models.append(CodeBlockElement(
                text: text,
                language: language,
                contentSizeCategory: options.contentSizeCategory
            ))
        case .table(let rows):
            endRunningText(isLast)

            var buckets = [TableBucket]()
            var rowHeights = [CGFloat]()

            let results = rows.build(options: options)
            results.forEach {
                fillBuckets(rows: $0.cells, buckets: &buckets, rowHeights: &rowHeights, fill: $0.fill)
            }

            models.append(IssueCommentTableModel(buckets: buckets, rowHeights: rowHeights))
        }
    }

    endRunningText(true)

    return models
}

private func emptyDescription(options: CMarkOptions) -> ListDiffable {
    let builder = StyledTextBuilder.markdownBase(isRoot: options.isRoot)
        .add(
            text: NSLocalizedString("No description provided.", comment: ""),
            traits: .traitItalic,
            attributes: [.foregroundColor: Styles.Colors.Gray.medium.color]
    )
    return StyledTextRenderer(
        string: builder.build(),
        contentSizeCategory: options.contentSizeCategory,
        inset: IssueCommentTextCell.inset(isLast: true)
    ).warm(width: options.width)
}

func MarkdownModels(
    _ markdown: String,
    owner: String,
    repo: String,
    width: CGFloat,
    viewerCanUpdate: Bool,
    contentSizeCategory: UIContentSizeCategory,
    isRoot: Bool,
    branch: String = "master"
    ) -> [ListDiffable] {
    let cleaned = markdown
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let node = Node(markdown: cleaned) else { return [] }
    let options = CMarkOptions(
        owner: owner,
        repo: repo,
        branch: branch,
        width: width,
        viewerCanUpdate: viewerCanUpdate,
        contentSizeCategory: contentSizeCategory,
        isRoot: isRoot
    )

    let models = makeModels(elements: node.flatElements, options: options)
    if models.count == 0 {
        return [emptyDescription(options: options)]
    } else {
        return models
    }
}
