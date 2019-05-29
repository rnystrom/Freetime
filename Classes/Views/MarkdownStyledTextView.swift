//
//  MarkdownStyledTextView.swift
//  Freetime
//
//  Created by Ryan Nystrom on 3/19/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import StyledTextKit
import TUSafariActivity

protocol MarkdownStyledTextViewDelegate: class {
    func didTap(cell: MarkdownStyledTextView, attribute: DetectedMarkdownAttribute)
}

class MarkdownStyledTextView: StyledTextView, StyledTextViewDelegate {

    weak var tapDelegate: MarkdownStyledTextViewDelegate?

    override var delegate: StyledTextViewDelegate? {
        get { return self }
        set {}
    }

    // MARK: Private API

    private func show(url: URL) {
        let activityController = UIActivityViewController(
            activityItems: [url, url.absoluteString],
            applicationActivities: [TUSafariActivity()]
        )
        activityController.popoverPresentationController?.sourceView = self
        UIApplication.shared.keyWindow?.rootViewController?
            .present(activityController, animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: StyledTextViewDelegate

    func didTap(view: StyledTextView, attributes: [NSAttributedString.Key: Any], point: CGPoint) {
        if let details = attributes[MarkdownAttribute.details] as? String {
            showDetailsInMenu(details: details, point: point)
        }
        guard let detected = DetectMarkdownAttribute(attributes: attributes) else { return }
        tapDelegate?.didTap(cell: self, attribute: detected)
    }

    func didLongPress(view: StyledTextView, attributes: [NSAttributedString.Key: Any], point: CGPoint) {
        if let urlString = attributes[MarkdownAttribute.url] as? String, let url = URL(string: urlString) {
            show(url: url)
        }
    }

}
