//
//  UIAlertAction+Image.swift
//
//  Created by Bas Broek on 09/07/2018.
//  Copyright © 2018 Bas Broek. All rights reserved.
//

import UIKit

@available(tvOS 8.0, *)
public extension UIAlertAction {

    private var imageKey: String { return "image" }

    /// Create and return an action with the specified title and behavior.
    ///
    /// - warning: The size of the image will not be scaled to fit,
    /// which means the size of the button may grow based on the image size.
    /// An image size of about 25 points is recommended.
    ///
    /// - parameter title: The text to use for the button title.
    /// The value you specify should be localized for the user’s current language.
    /// This parameter must not be nil, except in a tvOS app where a nil title
    /// may be used with [UIAlertAction.Style.cancel](https://developer.apple.com/documentation/uikit/uialertaction/style/cancel).
    /// - parameter image: An image to display on the left side of the button.
    /// Use this to visually convey the action's purpose.
    /// - parameter style: Additional styling information to apply to the button.
    /// Use the style information to convey the type of action that is performed by the button.
    /// For a list of possible values, see the constants in
    /// [UIAlertAction.Style](https://developer.apple.com/documentation/uikit/uialertaction/style).
    /// - parameter handler: A block to execute when the user selects the action.
    /// This block has no return value and takes the selected action object as
    /// its only parameter.
    ///
    /// - returns: A new alert action object.
    public convenience init(
        title: String? = nil,
        image: UIImage,
        style: UIAlertAction.Style,
        handler: ((UIAlertAction) -> Void)? = nil
    ) {
        self.init(title: title, style: style, handler: handler)
        setValue(image, forKey: imageKey)
    }

    /// The image of the action's button.
    public var image: UIImage? { return value(forKey: imageKey) as? UIImage }
}
