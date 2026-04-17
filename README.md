# OrbitalLayout

OrbitalLayout is an Auto Layout DSL for Swift. It wraps `NSLayoutConstraint` directly and provides a chainable API for expressing layout constraints on iOS, tvOS, and macOS.

[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20%7C%20tvOS%2015%20%7C%20macOS%2012-blue)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen)](https://swift.org/package-manager)
[![CocoaPods](https://img.shields.io/cocoapods/v/OrbitalLayout)](https://cocoapods.org/pods/OrbitalLayout)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

## Overview

Add a subview and lay it out in a single call. `orbit` handles `addSubview`, sets `translatesAutoresizingMaskIntoConstraints = false`, and activates the constraints.

Parent-side — the parent receives the child:

```swift
view.orbit(label, .top(16), .leading(16), .trailing(16))
```

Child-side — read naturally as "label is placed into `view`":

```swift
label.orbit(to: view, .top(16), .leading(16), .trailing(16))
```

Both forms are equivalent. Pick whichever reads better at the call site.

For multiple subviews, pass them all and use a closure to describe the layout. Every child is already in the hierarchy before the closure runs:

```swift
view.orbit(avatar, nameLabel, followButton) {
    avatar.orbital.layout(
        .top(24).to(view.safeAreaLayoutGuide, .top),
        .leading(16),
        .size(80)
    )
    nameLabel.orbital.layout(
        .top.to(avatar, .top),
        .leading(12).to(avatar, .trailing),
        .trailing(16)
    )
    followButton.orbital.layout(
        .top(16).to(nameLabel, .bottom),
        .leading(16),
        .trailing(16),
        .height(44)
    )
}
```

Every activated constraint is stored by anchor and accessible by name, so you can reach it later without keeping your own references:

```swift
view.orbital.layout(.top(16), .height(200))

// Animate later
view.orbital.heightConstraint?.constant = 300
UIView.animate(withDuration: 0.3) { view.superview?.layoutIfNeeded() }
```

---

## Requirements

| Platform | Minimum |
|----------|---------|
| iOS      | 15.0    |
| tvOS     | 15.0    |
| macOS    | 12.0    |

Swift 5.10+, Xcode 15+

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dimayurkovski/OrbitalLayout.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

### CocoaPods

```ruby
pod 'OrbitalLayout'
```

---

## Usage

### Adding a single subview

Two equivalent forms — parent-side and child-side:

```swift
// parent-side: "view receives label"
view.orbit(label, .top(16), .leading(16), .trailing(16))

// child-side: "label is placed into view"
label.orbit(to: view, .top(16), .leading(16), .trailing(16))
```

Both call `addSubview`, set `translatesAutoresizingMaskIntoConstraints = false`, and activate the given constraints.

### Adding multiple subviews

Pass the children and a closure. Every view is added to the hierarchy before the closure runs, so you can reference them freely inside:

```swift
view.orbit(header, content, footer) {
    header.orbital.layout(.top(16), .leading(16), .trailing(16), .height(44))
    content.orbital.layout(.top(8).to(header, .bottom), .leading(16), .trailing(16))
    footer.orbital.layout(.top(8).to(content, .bottom), .leading(16), .trailing(16), .bottom(16))
}
```

### Constraints on an existing view

```swift
contentView.orbital.layout(
    .top(8).to(header, .bottom),
    .leading(16),
    .trailing(16),
    .height(200)
)
```

---

## API

### Edge shortcuts

```swift
view.orbital.layout(.edges(16))          // all 4 sides
view.orbital.layout(.horizontal(16))     // leading + trailing
view.orbital.layout(.vertical(24))       // top + bottom
```

### Size shortcuts

```swift
iconView.orbital.layout(.size(44))
bannerView.orbital.layout(.size(width: 320, height: 180))
videoView.orbital.layout(.aspectRatio(16.0 / 9.0))
```

### Center shortcuts

```swift
spinnerView.orbital.layout(.center())
badge.orbital.layout(.center(offset: CGPoint(x: 10, y: -5)))
```

### Targeting another view with `.to()`

```swift
subtitle.orbital.layout(
    .top(8).to(titleLabel, .bottom),
    .leading.to(titleLabel, .leading)
)

view.orbital.layout(
    .top(16).to(view.safeAreaLayoutGuide, .top),
    .bottom(16).to(view.safeAreaLayoutGuide, .bottom)
)
```

### Relations

```swift
descriptionLabel.orbital.layout(.height(120).orLess)
contentView.orbital.layout(.top(8).orMore.to(toolbar, .bottom))
```

### Priority

```swift
view.orbital.layout(
    .top(16).priority(.high),
    .bottom(16).priority(.low),
    .height(44).priority(.custom(600))
)
```

### Multiplier

```swift
view.orbital.layout(.width.like(superview, 0.4))           // 40% of superview width
view.orbital.layout(.height.like(imageView, .width, 0.5))  // height == imageView.width * 0.5
view.orbital.layout(.height.like(.width, 1.0))             // square
```

### Full chain

```swift
let c = view.orbital.constraint(.top(16).to(header, .bottom).orMore.priority(.high))
c.constant = 24
```

---

## Stored Constraints

Every constraint is stored by anchor. Named accessors return the `.equal` constraint for that anchor:

```swift
view.orbital.topConstraint
view.orbital.bottomConstraint
view.orbital.leadingConstraint
view.orbital.trailingConstraint
view.orbital.widthConstraint
view.orbital.heightConstraint
view.orbital.centerXConstraint
view.orbital.centerYConstraint
```

For non-equal relations:

```swift
view.orbital.constraint(for: .width, relation: .lessOrEqual)
```

---

## Update & Remake

`update()` changes the `constant` on existing constraints. It is a no-op for anchors with no stored constraint.

```swift
view.orbital.update(.top(24), .height(300))
view.orbital.update(.edges(24))
```

`remake()` deactivates and replaces the constraints for the specified anchors. Other anchors are not affected.

```swift
view.orbital.remake(
    .top.to(navigationBar, .bottom),
    .height(120)
)
```

---

## Batch Activate / Deactivate

```swift
let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
constraints.deactivate()
constraints.activate()
```

---

## Deferred Activation

```swift
let constraints = view.orbital.prepareLayout(.top(8), .leading(16), .trailing(16))
constraints.activate()
```

Named accessors are available even while constraints are inactive.

---

## Content Hugging & Compression Resistance

```swift
titleLabel.orbital.hugging(.high, axis: .horizontal)
titleLabel.orbital.compression(.required, axis: .horizontal)
```

---

## Debug Labels

Constraint identifiers appear in Xcode's unsatisfiable-constraints log.

```swift
view.orbital.layout(
    .top(16).labeled("card.top"),
    .height(44).labeled("card.height")
)
```

---

## Sign Convention

`trailing`, `bottom`, and `right` constants are negated automatically on same-edge constraints. Pass a positive value in all cases.

```swift
view.orbital.layout(
    .trailing(16),   // view.trailing = superview.trailing − 16  ✓
    .bottom(16)      // view.bottom   = superview.bottom   − 16  ✓
)
```

To suppress or force negation on cross-anchor constraints:

```swift
.trailing(8).to(avatar, .trailing).asOffset   // suppress negation
.bottom(16).to(header, .top).asInset          // force negation
```

---

## macOS

The API is identical on macOS. `NSView` anchors are used automatically. Baseline anchors (`.firstBaseline`, `.lastBaseline`) are UIKit-only and produce a compile-time error on macOS.

---

## Source Stability

OrbitalLayout follows semantic versioning. Source-breaking changes will not be introduced within a major version.

---

## License

OrbitalLayout is available under the MIT license. See [LICENSE](LICENSE) for details.
