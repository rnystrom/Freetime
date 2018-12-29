<p align="center">
    <img src="https://github.com/alexaubry/HTMLString/raw/swift4/.github/logo.png" alt="HTMLString" />
    <a>
        <img src="https://img.shields.io/badge/Swift-4.0-ee4f37.svg" alt="Swift 4.0" />
    </a>
    <a href="https://travis-ci.org/alexaubry/HTMLString">
        <img src="https://travis-ci.org/alexaubry/HTMLString.svg?branch=swift4" alt="Build Status" />
    </a>
    <a href="https://cocoapods.org/pods/HTMLString">
        <img src="https://img.shields.io/cocoapods/v/HTMLString.svg" alt="CocoaPods" />
    </a>
    <a href="https://github.com/Carthage/Carthage">
        <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" />
    </a>
    <a href="https://twitter.com/_alexaubry">
        <img src="https://github.com/alexaubry/HTMLString/raw/swift4/.github/contact-badge.svg?sanitize=true" alt="Contact : @_alexaubry" />
    </a>
</p>

`HTMLString` is a library written in Swift that allows your program to add and remove HTML entities in Strings.

|         | Main features |
----------|----------------
&#128271; | Adds entities for ASCII and UTF-8/UTF-16 encodings
&#128221; | Removes more than 2100 named entities (like `&amp;`)
&#128290; | Supports removing decimal and hexadecimal entities
&#128035; | Designed to support Swift Extended Grapheme Clusters (&#8594; 100% emoji-proof)
&#009989; | Fully unit tested
&#009889; | Fast
&#128218; | [Documented](https://alexaubry.github.io/HTMLString/)
&#129302; | [Compatible with Objective-C](https://github.com/alexaubry/HTMLString/tree/master/README.md#objective%2Dc-api)

## Supported Platforms

- iOS 8.0+
- macOS 10.10+
- tvOS 9.0+
- watchOS 2.0+
- Linux

## Installation

### HTMLString version vs Swift version

Below is a table that shows which version of HTMLString you should use for your Swift version.

| Swift version | HTMLString Version |
|---------------|--------------------|
| 4.X           | >= 4.0.0           |
| 3.X           | >= 3.0.0           |

### Swift Package Manager

Add this line to your `Package.swift` :

~~~swift
.Package(url: "https://github.com/alexaubry/HTMLString", majorVersion: 4, minor: 0)
~~~

### CocoaPods

Add this line to your `Podfile`:

~~~ruby
pod 'HTMLString', '~> 4.0'
~~~

### Carthage

Add this line to your Cartfile:

~~~
github "alexaubry/HTMLString" ~> 4.0
~~~

### Manual

Copy the `Sources/HTMLString/` directory into your project.

## Usage

`HTMLString` allows you to add and remove HTML entities from a String.

### &#128271; Adding HTML Entities (Escape)

When a character is not supported into the specified encoding, the library will replace it with a decimal entity (supported by all browsers supporting HTML 4 and later).

> For instance, the `&` character will be replaced by `&#038;`.

You can choose between ASCII and Unicode escaping:

- Use the `addingASCIIEntities` property to escape for ASCII-encoded content
- Use the `addingUnicodeEntities` property to escape for Unicode-compatible content

> &#128161; **Pro Tip**: When your content supports UTF-8 or UTF-16, use Unicode escaping as it is faster and produces a less bloated output.

#### Example

~~~swift
import HTMLString

let emoji = "My favorite emoji is 🙃"
let escapedEmoji = emoji.addingASCIIEntities // "My favorite emoji is &#128579;"
let noNeedToEscapeThatEmoji = emoji.addingUnicodeEntities // "My favorite emoji is 🙃"

let snack = "Fish & Chips"
let escapedSnack = snack.addingASCIIEntities // "Fish &#038; Chips"
let weAlsoNeedToEscapeThisSnack = snack.addingUnicodeEntities // "Fish &#038; Chips"
~~~

### &#128221; Removing HTML Entities (Unescape)

To remove all the HTML entities from a String, use the `removingHTMLEntities` property.

#### Example

~~~swift
import HTMLString

let escapedEmoji = "My favorite emoji is &#x1F643;"
let emoji = escapedEmoji.removingHTMLEntities // "My favorite emoji is 🙃"

let escapedSnack = "Fish &amp; Chips"
let snack = escapedSnack.removingHTMLEntities // "Fish & Chips"
~~~

## Objective-C API

With Obj-C Mix and Match, you can import and use the `HTMLString` module from in Objective-C code.

The library introduces a set of Objective-C specific APIs as categories on the `NSString` type:

- `-[NSString stringByAddingUnicodeEntities];` : Replaces every character incompatible with HTML Unicode encoding by a decimal HTML entitiy.
- `-[NSString stringByAddingASCIIEntities];` : Replaces every character incompatible with HTML ASCII encoding by a decimal HTML entitiy.
- `-[NSString stringByRemovingHTMLEntities];` : Replaces every HTML entity with the matching Unicode character.

### Escaping Examples

~~~objc
@import HTMLString;

NSString *emoji = @"My favorite emoji is 🙃";
NSString *escapedEmoji = [emoji stringByAddingASCIIEntities]; // "My favorite emoji is &#128579;"

NSString *snack = @"Fish & Chips";
NSString *escapedSnack = [snack stringByAddingUnicodeEntities]; // "Fish &#038; Chips"
~~~

### Unescaping Examples

~~~objc
@import HTMLString;

NSString *escapedEmoji = @"My favorite emoji is &#x1F643;";
NSString *emoji = [escapedEmoji stringByRemovingHTMLEntities]; // "My favorite emoji is 🙃"

NSString *escapedSnack = @"Fish &amp; Chips";
NSString *snack = [escapedSnack stringByRemovingHTMLEntities]; // "Fish & Chips"
~~~

## Author

- Alexis Aubry, me@alexaubry.fr
- You can find me on Twitter: [@_alexaubry](https://twitter.com/_alexaubry)

## License

HTMLString is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## &#128175; Acknowledgements

![Thanks @google](https://i.giphy.com/QBC5foQmcOkdq.gif)

This library was originally inspired by [**@google**'s Toolbox for Mac](https://github.com/google/google-toolbox-for-mac).
