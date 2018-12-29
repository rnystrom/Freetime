//
//  SearchBarCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/14/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

protocol SearchBarCellDelegate: class {
    func didChangeSearchText(cell: SearchBarCell, query: String)
}

final class SearchBarCell: UICollectionViewCell, UISearchBarDelegate, ThemeChangeListener {

    weak var delegate: SearchBarCellDelegate?

    private let searchBar = UISearchBar(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        searchBar.returnKeyType = .search
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        contentView.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.centerY.equalTo(contentView)
        }

        searchBar.resignWhenKeyboardHides()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func themeDidChange(_ theme: Theme) {
        backgroundColor = Styles.Colors.background
        searchBar.barStyle = theme == .dark ? .black : .default
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentView()
    }

    // MARK: Public API

    func configure(query: String, placeholder: String) {
        searchBar.text = query
        searchBar.placeholder = placeholder
    }

    // MARK: Private API

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.didChangeSearchText(cell: self, query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
