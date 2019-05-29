//
//  ReadAllRowController.swift
//  FreetimeWatch Extension
//
//  Created by Ryan Nystrom on 4/27/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import WatchKit

final class ReadAllRowController: NSObject {
    
    @IBOutlet var readAllLabel: WKInterfaceLabel!
    @IBOutlet var group: WKInterfaceGroup!

    func setup() {
        let readAll = NSLocalizedString("Read All", comment: "")
        readAllLabel.setText(readAll)
        readAllLabel.setIsAccessibilityElement(false)
        group.setIsAccessibilityElement(true)
        group.setAccessibilityLabel(readAll)
        group.setAccessibilityTraits(.button)
    }

}
