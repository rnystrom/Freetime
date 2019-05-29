//
//  AlertActionBuilder.swift
//  Freetime
//
//  Created by Ivan Magda on 27/09/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

// MARK: AlertActionBuilder -

class AlertActionBuilder {

    typealias BuilderClosure = (AlertActionBuilder) -> Void

    // MARK: Properties

    var rootViewController: UIViewController?
    var title: String?
    var style: UIAlertAction.Style?

    // MARK: Init

    init(_ buildClosure: BuilderClosure) {
        buildClosure(self)
    }

}
