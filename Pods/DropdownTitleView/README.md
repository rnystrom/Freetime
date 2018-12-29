# DropdownTitleView

A simple and configurable "dropdown" view built for `UINavigationItem.titleView`.

## Installation

Just add `DropdownTitleView` to your Podfile and pod install. Done!

```
pod 'DropdownTitleView'
```

## Usage

Create an instance of `DropdownTitleView`, configure it, and set it as a `UINavigationItem`'s `titleView`:

```swift
func viewDidLoad() {
  super.viewDidLoad()
  let titleView = DropdownTitleView()
  titleView.configure(title: "Hello world!", subtitle: "Is this thing on?")
  navigationItem.titleView = titleView
}
```

![Example](readme.png)

Add touch handling like you would any other `UIControl`:

```swift
func viewDidLoad() {
  super.viewDidLoad()
  // setup and set titleView
  titleView.addTarget(
    self, 
    action: #selector(onTitle), 
    for: .touchUpInside
  )
}

@objc func onTitle() {
  print("do something")
}
```

### Configuration

`DropdownTitleView` has several appearance options:

- `titleFont` and `titleColor` - `UIFont` and `UIColor` of the top title label
- `subtitleFont` and `subtitleColor` - `UIFont` and `UIColor` of the bottom subtitle label
- `chevronTintColor` - `UIColor` tint of the chevron image

All of these values are configurable via `UIAppearance` as well!

```swift
DropdownTitleView.appearance().chevronTintColor = .blue
DropdownTitleView.appearance().titleColor = .black
DropdownTitleView.appearance().subtitleColor = .lightGray
DropdownTitleView.appearance().titleFont = .systemFontOfSize(18)
DropdownTitleView.appearance().subtitleFont = .systemFontOfSize(13)
```

You can also control the features of the view with params in `configure(...)` function:

- `subtitle` - Leave `nil` to remove the subtitle and vertically center the title
- `chevronEnabled` - Set to `false` to remove the chevron
- `accessibilityLabel` and `accessibilityHint` - Set Accessibility features on the control

## Acknowledgements

- Created with ❤️ by [Ryan Nystrom](https://twitter.com/_ryannystrom)
