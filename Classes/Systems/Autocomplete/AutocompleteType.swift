//
//  AutocompleteType.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/23/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

protocol AutocompleteType {

    var prefix: String { get }

    var resultsCount: Int { get }

    func configure(cell: AutocompleteCell, index: Int)

    func search(word: String, completion: @escaping (Bool) -> Void)

    func accept(index: Int) -> String?

    var highlightAttributes: [NSAttributedString.Key: Any]? { get }

}
