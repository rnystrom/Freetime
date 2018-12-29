//
//  StyledTextViewCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 3/17/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import StyledTextKit

class StyledTextViewCell: UICollectionViewCell, ThemeChangeListener {

    private let textView = MarkdownStyledTextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        textView.gesturableAttributes = MarkdownAttribute.all
        contentView.addSubview(textView)
        isAccessibilityElement = true
        registerForThemeChanges()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
        textView.reposition(for: contentView.bounds.width)
    }

    func themeDidChange(_ theme: Theme) {
        backgroundColor = Styles.Colors.background
    }

    override var accessibilityLabel: String? {
        get { return AccessibilityHelper.generatedLabel(forCell: self)}
        set {}
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    var delegate: MarkdownStyledTextViewDelegate? {
        get { return textView.tapDelegate }
        set { textView.tapDelegate = newValue }
    }

    // MARK: Public API

    final func set(renderer: StyledTextRenderer) {
        textView.configure(with: renderer, width: contentView.bounds.width)
    }

}
