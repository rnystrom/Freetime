//
//  StyledTextBuilder+NewBase.swift
//  Freetime
//
//  Created by Ryan Nystrom on 4/1/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import StyledTextKit

extension StyledTextBuilder {
    static func markdownBase(isRoot: Bool) -> StyledTextBuilder {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.lineSpacing = 2
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Styles.Colors.Gray.dark.color,
            .paragraphStyle: paragraphStyle,
            .backgroundColor: UIColor.white
        ]
        let style = isRoot
            ? Styles.Text.rootBody
            : Styles.Text.commentBody
        return StyledTextBuilder(styledText: StyledText(
            style: style.with(attributes: attributes)
        ))
    }
}
