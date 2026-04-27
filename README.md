# OrbitalLayout

An Auto Layout DSL for Swift. Chainable, type-safe, wraps `NSLayoutConstraint` directly.

[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20%7C%20tvOS%2015%20%7C%20macOS%2012-blue)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen)](https://swift.org/package-manager)
[![CocoaPods](https://img.shields.io/cocoapods/v/OrbitalLayout)](https://cocoapods.org/pods/OrbitalLayout)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

```swift
view.orbit(add: label, [.top(16), .leading(16), .trailing(16)])
```

One call: `addSubview`, disable autoresizing mask, activate constraints.

iOS 15+ · tvOS 15+ · macOS 12+ · Swift 5.10+ · Xcode 15+

## Contents

- [Install](#install)
- [Adding subviews](#adding-subviews)
- [Constraints](#constraints)
- [Stored constraints](#stored-constraints)
- [Update & remake](#update--remake)
- [Activate / deactivate](#activate--deactivate)
- [Hugging & compression](#hugging--compression)
- [Debug labels](#debug-labels)
- [Sign convention](#sign-convention)
- [Multiple children](#multiple-children)
- [macOS](#macos)


## Install

**Swift Package Manager**

```swift
.package(url: "https://github.com/dimayurkovski/OrbitalLayout.git", from: "1.0.0")
```

**CocoaPods**

```ruby
pod 'OrbitalLayout'
```


## Adding subviews

```swift
// parent-side (array form — preferred)
view.orbit(add: label, [.top(16), .leading(16), .trailing(16)])

// parent-side (variadic shorthand)
view.orbit(add: label, .top(16), .leading(16), .trailing(16))

// child-side (array form — preferred)
label.orbit(to: view, [.top(16), .leading(16), .trailing(16)])

// child-side (variadic shorthand)
label.orbit(to: view, .top(16), .leading(16), .trailing(16))

// view controller — forwards to controller.view
controller.orbit(add: label, [.top(16), .leading(16), .trailing(16)])
label.orbit(to: controller, [.top(16), .leading(16), .trailing(16)])

// already in the hierarchy
contentView.orbital.layout(
    .top(8).to(header, .bottom),
    .leading(16), .trailing(16),
    .height(200)
)
```


## Constraints

```swift
// edges
view.orbital.layout(.edges(16))          // all 4 sides
view.orbital.layout(.horizontal(16))     // leading + trailing
view.orbital.layout(.vertical(24))       // top + bottom

// size
iconView.orbital.layout(.size(44))
bannerView.orbital.layout(.size(width: 320, height: 180))
videoView.orbital.layout(.aspectRatio(16.0 / 9.0))

// center
spinnerView.orbital.layout(.center())
badge.orbital.layout(.center(offset: CGPoint(x: 10, y: -5)))

// target another view
subtitle.orbital.layout(
    .top(8).to(titleLabel, .bottom),
    .leading.to(titleLabel, .leading)
)

// relations
descriptionLabel.orbital.layout(.height(120).orLess)
contentView.orbital.layout(.top(8).orMore.to(toolbar, .bottom))

// priority
view.orbital.layout(
    .top(16).priority(.high),
    .height(44).priority(.custom(600))
)

// multiplier
view.orbital.layout(.width.like(superview, 0.4))           // 40% of superview width
view.orbital.layout(.height.like(imageView, .width, 0.5))  // height == imageView.width × 0.5
view.orbital.layout(.height.like(.width, 1.0))             // square

// full chain → single constraint
let c = view.orbital.constraint(.top(16).to(header, .bottom).orMore.priority(.high))
c.constant = 24
```


## Stored constraints

Every constraint is stored by anchor. Named accessors return the `.equal` constraint.

```swift
view.orbital.layout(.top(16), .height(200))

view.orbital.heightConstraint?.constant = 300

// available: topConstraint, bottomConstraint, leadingConstraint, trailingConstraint,
//            widthConstraint, heightConstraint, centerXConstraint, centerYConstraint

// non-equal relations
view.orbital.constraint(for: .width, relation: .lessOrEqual)
```


## Update & remake

```swift
// update — change `constant` on existing constraints; no-op if anchor has no stored constraint
view.orbital.update(.top(24), .height(300))
view.orbital.update(.edges(24))

// remake — deactivate and replace constraints for the specified anchors; others untouched
view.orbital.remake(
    .top.to(navigationBar, .bottom),
    .height(120)
)
```


## Activate / deactivate

```swift
let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
constraints.deactivate()
constraints.activate()

// deferred activation — named accessors work even while inactive
let pending = view.orbital.prepareLayout(.top(8), .leading(16), .trailing(16))
pending.activate()
```


## Hugging & compression

```swift
titleLabel.orbital.hugging(.high, axis: .horizontal)
titleLabel.orbital.compression(.required, axis: .horizontal)
```


## Debug labels

Identifiers show up in Xcode's unsatisfiable-constraints log.

```swift
view.orbital.layout(
    .top(16).labeled("card.top"),
    .height(44).labeled("card.height")
)
```


## Sign convention

`trailing`, `bottom`, `right` — auto-negated on same-edge constraints. Always pass a positive value.

```swift
view.orbital.layout(
    .trailing(16),                                // view.trailing = superview.trailing − 16
    .bottom(16)                                   // view.bottom   = superview.bottom   − 16
)

// cross-anchor overrides
.trailing(8).to(avatar, .trailing).asOffset      // suppress negation
.bottom(16).to(header, .top).asInset             // force negation
```


## Multiple children

Every view is in the hierarchy before the closure runs, so cross-references work without ordering tricks.

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
        .leading(16), .trailing(16),
        .height(44)
    )
}

// view controller — same closure form, forwards to controller.view
controller.orbit(avatar, nameLabel) {
    avatar.orbital.layout(.top(24), .leading(16), .size(80))
    nameLabel.orbital.layout(.top.to(avatar, .top), .leading(12).to(avatar, .trailing))
}
```


## macOS

Identical API. `NSView` anchors are used automatically. `.firstBaseline` / `.lastBaseline` are UIKit-only — using them on macOS is a compile-time error.


## License

MIT. See [LICENSE](LICENSE).
