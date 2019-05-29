//
//  UIFont+MutableTraits.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/17/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UIFont {

    func addingTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let newTraits = fontDescriptor.symbolicTraits.union(traits)
        guard let descriptor = fontDescriptor.withSymbolicTraits(newTraits)
            else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }

}
