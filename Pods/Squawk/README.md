# Squawk

Show important alerts from the bottom of the screen with full customization control.

![Example](readme.png)

## Installation

Just add `Squawk` to your Podfile and pod install. Done!

```
pod 'Squawk'
```

## Usage

After installing `Squawk`, you can start displaying alerts immediately:

```swift
import Squawk

func onError() {
  Squawk.shared.show(config: Squawk.Configuration(
    text: "Something went wrong!"
  ))
}
```

Use the `view` param if you want to show the alert within a specific view.

```swift
func viewDidAppear() {
  super.viewDidAppear()
  Squawk.shared.show(
    in: view,
    config: Squawk.Configuration(
      text: "Peek-a-boo"
    )
  )
}
```

### Configuration

`Squawk.Configuration` comes with _loads_ of options:

- `text` - The text in the alert
- `textColor` - The color of the text 🙄
- `backgroundColor` - Background color of the view (note: will be blurred)
- `insets` - Inset the text and button within the alert view
- `maxWidth` - The max width of the alert view
- `hintMargin` - Margin between the "hint" (top pill) and text
- `hintSize` - The size of the hint pill
- `cornerRadius` - Corner radius of the alert view
- `bottomPadding` - Extra padding to add to subtract from the final `y` of the alert view
- `borderColor` - Border color of the alert view
- `dismissDuration` - How long, in seconds, to wait before automatically dismissing
- `buttonVisible` - Set to `true` to show the "info" button
- `buttonLeftMargin` - The margin between the button and text
- `buttonTapHandler` - A closure to execute when the "info" button is tapped

## Acknowledgements

- Created with ❤️ by [Ryan Nystrom](https://twitter.com/_ryannystrom)
