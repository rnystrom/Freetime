//
//  MarkdownAttributeHandling.swift
//  Freetime
//
//  Created by Ryan Nystrom on 3/17/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation

enum DetectedMarkdownAttribute {
    case url(URL)
    case username(String)
    case email(String)
    case issue(IssueDetailsModel)
    case label(LabelDetails)
    case commit(CommitDetails)
    case checkbox(MarkdownCheckboxModel)
}

func DetectMarkdownAttribute(attributes: [NSAttributedString.Key: Any]?) -> DetectedMarkdownAttribute? {
    guard let attributes = attributes else { return nil }
    if let urlString = attributes[MarkdownAttribute.url] as? String, let url = URL(string: urlString) {
        return .url(url)
    } else if let usernameString = attributes[MarkdownAttribute.username] as? String {
        return .username(usernameString)
    } else if let emailString = attributes[MarkdownAttribute.email] as? String {
        return .email(emailString)
    } else if let issue = attributes[MarkdownAttribute.issue] as? IssueDetailsModel {
        return .issue(issue)
    } else if let label = attributes[MarkdownAttribute.label] as? LabelDetails {
        return .label(label)
    } else if let commit = attributes[MarkdownAttribute.commit] as? CommitDetails {
        return .commit(commit)
    } else if let checkbox = attributes[MarkdownAttribute.checkbox] as? MarkdownCheckboxModel {
        return .checkbox(checkbox)
    }
    return nil
}
