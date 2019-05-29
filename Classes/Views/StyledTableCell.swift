//
//  StyledTableCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/12/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

class StyledTableCell: UITableViewCell {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    private func configure() {
        textLabel?.font = Styles.Text.body.preferredFont

        let background = UIView()
        background.backgroundColor = Styles.Colors.Gray.alphaLighter
        selectedBackgroundView = background
    }

}
