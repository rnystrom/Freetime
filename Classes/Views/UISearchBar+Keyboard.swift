//
//  UISearchBar+Keyboard.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/7/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UISearchBar {

    // MARK: Public API

    func resignWhenKeyboardHides() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resignFirstResponder),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

}
