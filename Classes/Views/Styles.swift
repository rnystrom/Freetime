//
//  Layout.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/12/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import StyledTextKit
import DropdownTitleView
import NYTPhotoViewer

enum Styles {

    enum Sizes {
        static let gutter: CGFloat = 15
        static let cardGutter: CGFloat = 8
        static let icon = CGSize(width: 20, height: 20)
        static let buttonMin = CGSize(width: 44, height: 44)
        static let buttonIcon = CGSize(width: 25, height: 25)
        static let buttonTopPadding: CGFloat = 2
        static let barButton = CGRect(x: 0, y: 0, width: 30, height: 44)
        static let avatarCornerRadius: CGFloat = 3
        static let labelCornerRadius: CGFloat = 3
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 8
        static let cellSpacing: CGFloat = 15
        static let tableCellHeight: CGFloat = 44
        static let tableCellHeightLarge: CGFloat = 55
        static let tableSectionSpacing: CGFloat = 35
        static let avatar = CGSize(width: 30, height: 30)
        static let inlineSpacing: CGFloat = 4
        static let listInsetLarge = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        static let listInsetLargeHead = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        static let listInsetLargeTail = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        static let listInsetTight = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        static let textViewInset = UIEdgeInsets(
            top: rowSpacing,
            left: gutter,
            bottom: rowSpacing,
            right: gutter
        )
        static let labelEventHeight: CGFloat = 30
        static let labelSpacing: CGFloat = 8
        static let labelTextPadding: CGFloat = 4
        static let cardCornerRadius: CGFloat = 6
        static let maxImageHeight: CGFloat = 300
        static let contextMenuSize: CGSize = CGSize(width: 280, height: 240)
        static let contextMenuSmallSize: CGSize = CGSize(width: 180, height: 240)

        enum HTML {
            static let boldWeight = 600
            static let spacing = 16
        }
    }

    enum Text {

        static let body = TextStyle(size: 16)
        static let bodyBold = TextStyle(font: .system(.bold), size: 16)
        static let rootBody = TextStyle(size: 18)
        static let commentBody = TextStyle(size: 15)
        static let secondary = TextStyle(size: 13)
        static let secondaryBold = TextStyle(font: .system(.bold), size: 13)
        static let title = TextStyle(font: .system(.bold), size: 14)
        static let button = TextStyle(size: 16)
        static let headline = TextStyle(font: .system(.bold), size: 24)
        static let smallTitle = TextStyle(font: .system(.bold), size: 12)
        static let code = TextStyle(font: .name("Courier"), size: 16)
        static let codeBold = TextStyle(font: .name("Courier-Bold"), size: 16)
        static let secondaryCode = TextStyle(font: .name("Courier"), size: 13)
        static let secondaryCodeBold = TextStyle(font: .name("Courier-Bold"), size: 13)
        static let finePrint = TextStyle(size: 12)

        static let h1 = TextStyle(font: .system(.bold), size: 24)
        static let h2 = TextStyle(font: .system(.bold), size: 20)
        static let h3 = TextStyle(font: .system(.bold), size: 20)
        static let h4 = TextStyle(font: .system(.bold), size: 18)
        static let h5 = TextStyle(font: .system(.bold), size: 16)
        static let h6 = TextStyle(font: .system(.bold), size: 16)

    }

    enum Colors {

        static var background: UIColor {
            return Appearance.currentTheme == .light
                ? Styles.Colors.Gray.lighter.color
                : Styles.Colors.Gray.dark.color
        }
        static var barTint: UIColor {
            return Appearance.currentTheme == .light
                ? Styles.Colors.lightBarTint
                : UIColor.black
        }
        static let purple = "6f42c1"
        static let blueGray = "8697af"
        static let menuBackgroundColor = "292D35"
        static let splitViewBackground = UIColor(red: 0.556863, green: 0.556863, blue: 0.576471, alpha: 1)
        static let lightBarTint = UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0)

        enum Red {
            static let medium = "cb2431"
            static let light = "ffeef0"
        }

        enum Green {
            static let medium = "28a745"
            static let light = "e6ffed"
        }

        enum Blue {
            static let medium = "0366d6"
            static let light = "f1f8ff"
            static let menu = "5d9cf4"
        }

        enum Gray {
            static let dark = "24292e"
            static let medium = "586069"
            static let light = "a3aab1"
            static let lighter = "f6f8fa"
            static let border = "bcbbc1"

            static let alphaLighter = UIColor(white: 0, alpha: 0.10)
        }

        enum Yellow {
            static let medium = "f29d50"
            static let light = "fff5b1"
        }

    }

    static func setupAppearance() {
        UITabBar.appearance().barTintColor = Styles.Colors.barTint
        UINavigationBar.appearance().barTintColor = Styles.Colors.barTint
        UINavigationBar.appearance().tintColor =  Styles.Colors.Blue.medium.color
        let titleTextColor = Appearance.currentTheme == .light
            ? Styles.Colors.Gray.dark.color
            : UIColor.white
        UINavigationBar.appearance().titleTextAttributes =
            [NSAttributedStringKey.foregroundColor: titleTextColor]
        UISwitch.appearance().onTintColor = Styles.Colors.Blue.medium.color
        UISearchBar.appearance().tintColor = Styles.Colors.Blue.medium.color
        DropdownTitleView.appearance().chevronTintColor = Styles.Colors.Gray.medium.color
        DropdownTitleView.appearance().titleColor = titleTextColor
        DropdownTitleView.appearance().subtitleColor = Styles.Colors.Gray.light.color
        DropdownTitleView.appearance().titleFont = Styles.Text.bodyBold.preferredFont
        DropdownTitleView.appearance().subtitleFont = Styles.Text.secondaryBold.preferredFont
        UINavigationBar.appearance(whenContainedInInstancesOf: [NYTPhotosOverlayView.self]).tintColor = .white
    }

}

extension TextStyle {

    var preferredFont: UIFont {
        return self.font(contentSizeCategory: UIContentSizeCategory.preferred)
    }

    func with(attributes: [NSAttributedStringKey: Any]) -> TextStyle {
        var newAttributes = self.attributes
        for (key, value) in attributes {
            newAttributes[key] = value
        }
        return TextStyle(font: font, size: size, attributes: newAttributes, minSize: minSize, maxSize: maxSize)
    }

    func with(foreground: UIColor? = nil, background: UIColor? = nil) -> TextStyle {
        var attributes = self.attributes
        attributes[.foregroundColor] = foreground ?? attributes[.foregroundColor]
        attributes[.backgroundColor] = background ?? attributes[.backgroundColor]
        return TextStyle(font: font, size: size, attributes: attributes, minSize: minSize, maxSize: maxSize)
    }

}

extension String {

    public var color: UIColor {
        return UIColor.fromHex(self)
    }

}
