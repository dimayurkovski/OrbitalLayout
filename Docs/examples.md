# OrbitalLayout — Examples

Practical usage examples covering all API surface areas.

---

## 1. Basic: Single Child + Inline Constraints

```swift
// Add label as subview of view with constraints to superview (variadic)
view.orbit(add: label, .top(16), .leading(16), .trailing(16))

// Same, array form
view.orbit(add: label, [.top(16), .leading(16), .trailing(16)])
```

```swift
// Pin all edges flush
view.orbit(add: imageView, .edges(4))
view.orbit(add: imageView, .edges)     // same, shorthand
```

```swift
// Fixed size, centered
view.orbit(add: avatarView, .size(80), .center())
```

---

## 2. Multiple Children + Closure Layout

```swift
// Variadic form
view.orbit(avatar, nameLabel, bioLabel, followButton) {
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

    bioLabel.orbital.layout(
        .top(4).to(nameLabel, .bottom),
        .leading.to(nameLabel, .leading),
        .trailing(16),
        .height(60).orLess
    )

    followButton.orbital.layout(
        .top(16).to(bioLabel, .bottom),
        .leading(16),
        .trailing(16),
        .height(44),
        .bottom(16).to(view.safeAreaLayoutGuide, .bottom).priority(.low)
    )
}

// Array form — useful when children are built dynamically
let subviews: [OrbitalView] = [avatar, nameLabel, bioLabel, followButton]
view.orbit(subviews) {
    // same layout closure
}
```

---

## 3. Batch Layout (constraints only, no addSubview)

```swift
// View already added as subview elsewhere
view.orbital.layout(
    .top(8).to(header, .bottom),
    .leading(16),
    .trailing(16),
    .height(200)
)
```

---

## 4. Single Constraint Shortcuts

```swift
// Discard result (layout only)
view.orbital.top(16)
view.orbital.bottom(16)
view.orbital.leading(16)
view.orbital.trailing(16)

// Capture for later use (animate, toggle, update)
let topConstraint = view.orbital.top(16)
let heightConstraint = view.orbital.height(44)

topConstraint.constant = 32
UIView.animate(withDuration: 0.3) { view.superview?.layoutIfNeeded() }

// Size
view.orbital.width(100)
view.orbital.height(44)

// Center
view.orbital.centerX()
view.orbital.centerY(8)     // offset 8pt downward
```

---

## 5. Single Constraint with Chaining (`constraint()`)

```swift
// When you need modifiers on a single constraint
let c = view.orbital.constraint(.top(16).to(header, .bottom).orMore.priority(.high))

// Update later
c.constant = 24
```

---

## 6. Target Anchor — `.to()`

```swift
// Pin to another view's anchor
subtitle.orbital.layout(
    .top(8).to(titleLabel, .bottom),
    .leading.to(titleLabel, .leading)
)

// Pin to layout guide
// same-anchor → auto-negated: top = +16, bottom = -16 (insets from safe area edges)
view.orbital.layout(
    .top(16).to(view.safeAreaLayoutGuide, .top),
    .bottom(16).to(view.safeAreaLayoutGuide, .bottom)
)

// Leading to trailing (side by side)
badge.orbital.layout(
    .leading(8).to(icon, .trailing),
    .centerY.to(icon, .centerY)
)

// Width equal to another view (anchor inferred)
thumbnailView.orbital.layout(
    .width.to(headerView)              // width == headerView.width
)

// Width equal — explicit anchor
thumbnailView.orbital.layout(
    .width.to(headerView, .width)      // same result, explicit
)

// Width equal to another view's height (cross-dimension)
thumbnailView.orbital.layout(
    .width.to(headerView, .height)     // width == headerView.height
)

// Width equal to another view's width + offset
thumbnailView.orbital.layout(
    .width(40).to(headerView, .width)  // width == headerView.width + 40
)
```

---

## 7. Relations: `.orLess` / `.orMore`

```swift
// Max height
descriptionLabel.orbital.layout(
    .height(120).orLess
)

// Min top spacing
contentView.orbital.layout(
    .top(8).orMore.to(toolbar, .bottom)
)

// Min width
button.orbital.layout(
    .width(100).orMore,
    .height(44)
)
```

---

## 8. Priority

```swift
view.orbital.layout(
    .top(16).priority(.high),          // 750
    .bottom(16).priority(.low),        // 250
    .height(44).priority(.required),   // 1000 (default)
    .width(200).priority(.custom(600))
)
```

```swift
// Flexible bottom — won't break required constraints
scrollView.orbital.layout(
    .bottom(16).to(view.safeAreaLayoutGuide, .bottom).priority(.low)
)
```

---

## 9. Multiplier — `.like()`

```swift
// Width = 40% of superview
view.orbital.layout(
    .width.like(superview, 0.4)
)

// Height = twice another view
view.orbital.layout(
    .height.like(otherView, 2)
)

// Equal width to another view
view.orbital.layout(
    .width.like(referenceView)
)

// Height = 50% of another view's width
view.orbital.layout(
    .height.like(imageView, .width, 0.5)
)

// Square: height = own width * 0.4
view.orbital.layout(
    .height.like(.width, 0.4)
)
```

---

## 10. Edge Shortcuts

```swift
// Pin all 4 edges with equal inset
view.orbital.layout(.edges(16))

// Horizontal only
view.orbital.layout(.horizontal(16))

// Vertical only
view.orbital.layout(.vertical(24))

// Flush to superview
view.orbital.layout(.edges)
view.orbital.layout(.edges)         // same, shorthand
view.orbital.edges                  // proxy shorthand
```

---

## 11. Size Shortcuts

```swift
// Square
iconView.orbital.layout(.size(44))

// Explicit width and height
bannerView.orbital.layout(.size(width: 320, height: 180))

// Aspect ratio: width = height * 16/9
videoView.orbital.layout(
    .aspectRatio(16.0 / 9.0),
    .leading,
    .trailing
)

// .width / .height without args = match superview's dimension
childView.orbital.layout(.width)   // width == superview.width
childView.orbital.layout(.height)  // height == superview.height
```

---

## 12. Center Shortcuts

```swift
// Center in superview
spinnerView.orbital.layout(.center())

// Center with offset
badge.orbital.layout(.center(offset: CGPoint(x: 10, y: -5)))

// Horizontal center only
view.orbital.layout(.centerX(), .top(24))

// Center relative to another view
label.orbital.layout(
    .centerX.to(imageView, .centerX),
    .top(8).to(imageView, .bottom)
)
```

---

## 13. Stored Constraints + Animation

```swift
// Setup
view.orbital.layout(
    .top,
    .leading,
    .trailing,
    .height(200)
)

// Animate height change
view.orbital.heightConstraint?.constant = 300
UIView.animate(withDuration: 0.3) {
    view.superview?.layoutIfNeeded()
}
```

```swift
// Toggle visibility via constraint
panel.orbital.layout(
    .top.to(header, .bottom),
    .leading,
    .trailing,
    .height(60)
)

func collapse() {
    panel.orbital.heightConstraint?.constant = 0
    UIView.animate(withDuration: 0.2) {
        panel.superview?.layoutIfNeeded()
    }
}
```

---

## 14. Activate / Deactivate

```swift
// Batch toggle
let constraints = view.orbital.layout(
    .top(8),
    .leading(16),
    .trailing(16)
)
constraints.deactivate()
constraints.activate()
```

```swift
// Individual toggle
view.orbital.topConstraint?.isActive = false
view.orbital.topConstraint?.isActive = true
```

---

## 15. Create Without Activation

```swift
// Create but don't activate yet
let constraints = view.orbital.prepareLayout(
    .top(8),
    .leading(16),
    .trailing(16)
)

// Named accessors still work while inactive
print(view.orbital.topConstraint)  // not nil, but inactive

// Activate when ready
constraints.activate()
```

---

## 16. Update Constraints

```swift
// Initial layout
view.orbital.layout(
    .top(16),
    .height(200)
)

// Update constants only — no new constraints created
view.orbital.update(
    .top(24),
    .height(300)
)
```

```swift
// Update does nothing silently if anchor has no stored constraint
view.orbital.update(.width(100))   // no crash, just skipped
```

```swift
// Update with groups — updates all 4 edge constants at once
view.orbital.update(.edges(24))

// update() reads ONLY anchor + constant — all other modifiers are ignored:
view.orbital.update(.top(24).priority(.low))  // priority ignored, only constant updated
```

---

## 17. Remake Constraints

```swift
// Replace only matching anchors — others untouched
view.orbital.layout(
    .top(16), .leading(16), .trailing(16), .height(200)
)

// Replaces top and height, leading/trailing unchanged
view.orbital.remake(
    .top(8),
    .height(120)
)
```

```swift
// Remake with different target
contentView.orbital.remake(
    .top.to(navigationBar, .bottom)
)
```

---

## 18. Baseline Anchors (iOS / tvOS only)

```swift
// Align labels by baseline
valueLabel.orbital.layout(
    .firstBaseline.to(titleLabel, .firstBaseline),
    .leading(8).to(titleLabel, .trailing)
)
```

```swift
// With constant offset
footnote.orbital.layout(
    .lastBaseline(4).to(mainLabel, .lastBaseline)
)
```

```swift
// Via constraint() for single constraint
let c = view.orbital.constraint(.firstBaseline.to(referenceLabel, .firstBaseline))
```

---

## 19. Sign Convention: `.asOffset` / `.asInset`

Auto-negation applies when source and target anchor are the **same edge** — regardless of whether `.to()` was used.

```swift
// Same-anchor → auto-negated, constant is internally negative
// (works identically with or without .to())
view.orbital.layout(
    .trailing(16),                                      // view.trailing = superview.trailing − 16
    .bottom(16),                                        // view.bottom   = superview.bottom   − 16
    .bottom(16).to(view.safeAreaLayoutGuide, .bottom),  // view.bottom   = safeArea.bottom    − 16
    .trailing(8).to(avatar, .trailing)                  // view.trailing = avatar.trailing    − 8
)

// Cross-anchor → constant applied as-is (positive)
view.orbital.layout(
    .bottom(16).to(header, .top),     // view.bottom  = header.top      + 16
    .leading(8).to(avatar, .trailing) // view.leading = avatar.trailing + 8
)

// .asOffset — suppress auto-negation on same-anchor
// use when you want the view to extend *beyond* the referenced edge
view.orbital.layout(
    .trailing(8).to(avatar, .trailing).asOffset  // view.trailing = avatar.trailing + 8 (extends right)
)

// .asInset — force negative on cross-anchor
view.orbital.layout(
    .bottom(16).to(header, .top).asInset  // view.bottom = header.top − 16
)
```

---

## 20. Debug Labels

```swift
view.orbital.layout(
    .top(16).labeled("card.top"),
    .height(44).labeled("card.height"),
    .leading(16).labeled("card.leading"),
    .trailing(16).labeled("card.trailing")
)
// Identifiers appear in Xcode's "Unsatisfiable Constraints" log
```

---

## 21. Content Hugging / Compression Resistance

```swift
// Prevent label from stretching horizontally
titleLabel.orbital.hugging(.high, axis: .horizontal)
titleLabel.orbital.compression(.required, axis: .horizontal)

// Allow subtitle to compress before title
subtitleLabel.orbital.hugging(.low, axis: .horizontal)
subtitleLabel.orbital.compression(.low, axis: .horizontal)
```

---

## 22. Safe Area

```swift
view.orbital.layout(
    .top.to(view.safeAreaLayoutGuide, .top),
    .bottom.to(view.safeAreaLayoutGuide, .bottom),
    .leading,
    .trailing
)
```

```swift
// Note: .edges().to(safeArea) is NOT supported — group descriptors don't support .to().
// Use individual descriptors to pin all edges to a layout guide:
view.orbital.layout(
    .top.to(view.safeAreaLayoutGuide),
    .bottom.to(view.safeAreaLayoutGuide),
    .leading.to(view.safeAreaLayoutGuide),
    .trailing.to(view.safeAreaLayoutGuide)
)
```

---

## 23. macOS (AppKit)

```swift
// Same API, uses NSView anchors automatically
containerView.orbit(add: contentView, .edges(20))

contentView.orbital.layout(
    .top(16),
    .leading(16),
    .trailing(16),
    .height(200)
)

// Baseline anchors are NOT available on macOS — compile-time error, not a runtime crash.
// .firstBaseline / .lastBaseline are guarded by #if canImport(UIKit),
// so they do not exist in the enum on macOS. Use only on iOS / tvOS.
```

---

## 24. UIStackView

```swift
// Orbital positions the stack view itself, not its arranged subviews
view.orbit(add: stackView, .top(16), .leading(16), .trailing(16))
stackView.orbital.layout(.bottom(16))
```

---

## 25. Practical: Card with Shadow

```swift
view.orbit(card) {
    card.orbital.layout(
        .top(16).to(view.safeAreaLayoutGuide, .top),
        .leading(20),
        .trailing(20),
        .height(120)
    )
}

card.orbit(titleLabel, subtitleLabel) {
    titleLabel.orbital.layout(
        .top(16),
        .leading(16),
        .trailing(16)
    )
    subtitleLabel.orbital.layout(
        .top(8).to(titleLabel, .bottom),
        .leading(16),
        .trailing(16),
        .bottom(16).priority(.low)
    )
}
```

---

## 26. Practical: Expandable Panel

```swift
class ExpandablePanel: UIView {
    let contentView = UIView()

    func setup(in parent: UIView) {
        parent.orbit(add: self, .top, .leading, .trailing)
        orbit(contentView, .edges)
        orbital.layout(.height(60))
    }

    func expand() {
        orbital.update(.height(200))
        UIView.animate(withDuration: 0.3) {
            self.superview?.layoutIfNeeded()
        }
    }

    func collapse() {
        orbital.update(.height(60))
        UIView.animate(withDuration: 0.3) {
            self.superview?.layoutIfNeeded()
        }
    }
}
```

---

## 27. Practical: Dynamic Leading Constraint Swap

```swift
// Setup: leading to superview
iconView.orbital.layout(
    .leading(16),
    .centerY
)

// On some event: remake to align with another view
iconView.orbital.remake(
    .leading(8).to(badgeView, .trailing)
)
```
