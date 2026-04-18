# OrbitalLayout — API Reference

iOS Auto Layout constraint library for Swift.

```swift
import OrbitalLayout
```

---

## 1. Adding Subviews + Constraints

### Single child — inline constraints

```swift
view.orbit(label, .top(16), .leading(16), .trailing(16))
```

Performs: `addSubview`, `translatesAutoresizingMaskIntoConstraints = false`, activates constraints to `view`.

### Multiple children — closure layout

```swift
view.orbit(label, subtitle, button) {
    label.orbital.layout(.top(16), .leading(16), .trailing(16))
    subtitle.orbital.layout(.top(8).to(label, .bottom), .leading(16))
    button.orbital.layout(.bottom(16), .centerX())
}
```

All views listed before the closure are added as subviews of `view`.  
Inside the closure, constraints default to the parent (`view`) unless `.to(...)` specifies another anchor.

---

## 2. Batch Layout (constraints only, no addSubview)

```swift
@discardableResult
view.orbital.layout(_ descriptors: OrbitalDescriptor...) -> [OrbitalConstraint]
```

Creates, activates, and returns constraints. Does **not** call `addSubview`.

If a constraint for the same **anchor + relation** combination already exists (from a previous `layout()` or single-constraint call), the previous one is **deactivated and replaced**. Constraints with different relations coexist — e.g. `.width == 200` (`.equal`) and `.width <= 300` (`.lessOrEqual`) are separate entries. See Section 11 for details on storage keying.

Callers who captured the old constraint still hold the object, but it will be inactive and no longer managed by OrbitalLayout.

```swift
view.orbital.layout(
    .top(8).to(header, .bottom),
    .leading(16),
    .trailing(16),
    .height(200)
)
```

---

## 3. Single Constraints

Each returns `OrbitalConstraint` (activated, stored for later access).

These are convenience shortcuts for simple cases. Chaining (`.to()`, `.orMore`, `.priority()`) is **not** available here — use `constraint()` or `layout()` when chaining is needed. Note: calling `.to()` on a proxy shortcut result (e.g. `view.orbital.top(16).to(...)`) will not compile — proxy shortcuts return `OrbitalConstraint`, not `OrbitalDescriptor`.

### Edges

```swift
@discardableResult view.orbital.top(_ constant: CGFloat = 0)      -> OrbitalConstraint
@discardableResult view.orbital.bottom(_ constant: CGFloat = 0)    -> OrbitalConstraint
@discardableResult view.orbital.leading(_ constant: CGFloat = 0)   -> OrbitalConstraint
@discardableResult view.orbital.trailing(_ constant: CGFloat = 0)  -> OrbitalConstraint
@discardableResult view.orbital.left(_ constant: CGFloat = 0)      -> OrbitalConstraint
@discardableResult view.orbital.right(_ constant: CGFloat = 0)     -> OrbitalConstraint
```

### Size

```swift
@discardableResult view.orbital.width(_ constant: CGFloat)   -> OrbitalConstraint
@discardableResult view.orbital.height(_ constant: CGFloat)  -> OrbitalConstraint
```

### Center

```swift
@discardableResult view.orbital.centerX(_ offset: CGFloat = 0) -> OrbitalConstraint
@discardableResult view.orbital.centerY(_ offset: CGFloat = 0) -> OrbitalConstraint
```

### Single Constraint with Chaining

When you need modifiers (`.to()`, `.orMore`, `.priority()`, etc.) on a single constraint, use `constraint()`:

```swift
@discardableResult
view.orbital.constraint(_ descriptor: OrbitalDescriptor) -> OrbitalConstraint
```

```swift
let c = view.orbital.constraint(.top(16).to(header, .bottom).orMore.priority(.high))
c.constant = 10
```

---

## 4. Edge Shortcuts

```swift
.edges                           // inset = 0
.edges(_ inset: CGFloat)
```
All four sides with equal inset. Uses `leading`/`trailing`/`top`/`bottom` — RTL-safe.

```swift
.horizontal                      // inset = 0
.horizontal(_ inset: CGFloat)   // leading + trailing
.vertical                        // inset = 0
.vertical(_ inset: CGFloat)     // top + bottom
```

---

## 5. Size Shortcuts

```swift
.size(_ side: CGFloat)                              // width == height == side
.size(width: CGFloat, height: CGFloat)               // explicit width and height
.aspectRatio(_ ratio: CGFloat)                       // self.width == self.height * ratio
.width.to(otherView)                                 // width == other view's width
.height.to(otherView)                                // height == other view's height
```

---

## 6. Center Shortcuts

```swift
.center()                                            // centerX + centerY to superview
.center(offset: CGPoint(x: 10, y: 5))               // with offset
.centerX()
.centerX(_ offset: CGFloat)
.centerY()
.centerY(_ offset: CGFloat)
```

---

## 7. `.to(...)` — Target Anchor

Redirects a constraint to another view or anchor.

```swift
.top(8).to(header, .bottom)          // view.top = header.bottom + 8
.bottom(16).to(view.safeAreaLayoutGuide, .bottom)
.leading(8).to(avatar, .trailing)    // view.leading = avatar.trailing + 8
.width().to(otherView)               // width == otherView.width
```

### Anchor names

| Anchor      | Applicable to           |
|-------------|-------------------------|
| `.top`      | vertical edges          |
| `.bottom`   | vertical edges          |
| `.leading`  | horizontal edges        |
| `.trailing` | horizontal edges        |
| `.left`     | horizontal edges (non-RTL) |
| `.right`    | horizontal edges (non-RTL) |
| `.centerX`  | horizontal              |

> **RTL note:** `.edges`, `.horizontal` shortcuts use `leading`/`trailing` (RTL-safe). Avoid mixing `left`/`right` with `leading`/`trailing` on the same view — both will be stored (different anchor keys) and may create conflicting constraints.
| `.centerY`  | vertical                |
| `.width`    | dimension               |
| `.height`   | dimension               |

When `.to(view)` is called without an explicit anchor, the matching anchor is inferred:  
`.leading(8).to(avatar)` → `avatar.leadingAnchor`.

If `.to()` is called multiple times on the same descriptor, the last call wins:  
`.top(8).to(view1).to(view2)` → targets `view2`.

---

## 8. Relations

```swift
.height(200).orLess                  // <=
.width(100).orMore                   // >=
.top(8).orMore.to(header, .bottom)
```

Default relation is `.equal`.

---

## 9. Priority

```swift
.height(200).priority(.high)         // UILayoutPriority.defaultHigh (750)
.top(16).priority(.custom(750))      // custom Float value
.width(100).orLess.priority(.low)    // UILayoutPriority.defaultLow (250)
```

Predefined values: `.required` (1000), `.high` (750), `.low` (250), `.custom(Float)` for arbitrary values.

---

## 10. Multiplier

```swift
.width.like(superview, 0.4)
.height.like(otherView, 2)
.width.like(otherView)
.height.like(imageView)
.height.like(otherView, .width, 0.5)   // height == otherView.width * 0.5
.height.like(.width, 0.4)             // height == self.width * 0.4
```

Only meaningful with `.like(...)` — multiplies the target value.

`.like()` works with **any anchor type**, not only dimensions. For `.width` / `.height`, uses the type-safe `NSLayoutDimension` API. For all other anchors (edges, center), falls back to `NSLayoutConstraint(item:attribute:relatedBy:toItem:attribute:multiplier:constant:)` internally. This is a rare use case but fully supported.

---

## 11. Stored Constraints (Auto-storage)

Constraints are stored per `anchor + relation` combination. Named accessors return the `.equal` relation constraint (the most common case). Multiple constraints on the same anchor coexist as long as they have different relations — e.g. `.width == 200` and `.width <= 300` can exist simultaneously.

```swift
view.orbital.topConstraint          // OrbitalConstraint? — .equal relation
view.orbital.bottomConstraint
view.orbital.leadingConstraint
view.orbital.trailingConstraint
view.orbital.leftConstraint
view.orbital.rightConstraint
view.orbital.widthConstraint
view.orbital.heightConstraint
view.orbital.centerXConstraint
view.orbital.centerYConstraint
```

To access a non-equal constraint:

```swift
view.orbital.constraint(for: .width, relation: .lessOrEqual)    // OrbitalConstraint?
view.orbital.constraint(for: .width, relation: .greaterOrEqual)
```

### Multiple constraints on same anchor

```swift
// Both coexist — different keys in ConstraintStorage
view.orbital.layout(
    .width(200),               // width == 200  (.equal)
    .width(300).orLess         // width <= 300  (.lessOrEqual)
)

// Access individually
view.orbital.widthConstraint                                    // == 200
view.orbital.constraint(for: .width, relation: .lessOrEqual)   // <= 300
```

### Animation example

```swift
view.orbital.heightConstraint?.constant = 300
UIView.animate(withDuration: 0.3) {
    view.superview?.layoutIfNeeded()
}
```

---

## 12. Safe Area

```swift
.top(16).to(view.safeAreaLayoutGuide, .top)
.bottom(16).to(view.safeAreaLayoutGuide, .bottom)
```

---

## 13. Activate / Deactivate

Batch result supports toggle:

```swift
let constraints = view.orbital.layout(
    .top(8), .leading(16), .trailing(16)
)
constraints.deactivate()    // OrbitalConstraint.deactivate(constraints)
constraints.activate()      // OrbitalConstraint.activate(constraints)
```

Individual via stored references:

```swift
view.orbital.topConstraint?.isActive = false
```

---

## 14. Chaining Order

```
.<attribute>(<constant>)
    .to(<view/guide>, <anchor>)     // optional
    .orLess / .orMore               // optional, default: .equal
    .priority(<priority>)           // optional, default: .required
```

Order is flexible for `.orLess`/`.orMore`, `.priority()`, and `.labeled()` — these are independent and commutative.

`.to()` and `.like()` both write the target view. **Do not use them together on the same descriptor** — only one target can apply. If both are called, the last one wins. `#if DEBUG`: ConstraintFactory prints a warning when `.like()` was called and then overwritten by `.to()` (detected via `likeWasCalled` flag on `OrbitalDescriptor`).

Constraints are activated at the point of creation (`.orbital(...)`, `.orbital.layout(...)`, or single-constraint calls).

---

## 15. Full Example

```swift
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
```

## 16. typealias

```swift
public typealias OrbitalConstraint = NSLayoutConstraint
```

---

## 17. Baseline Anchors

```swift
.firstBaseline()
.lastBaseline()
.firstBaseline().to(otherLabel, .firstBaseline)
.lastBaseline(8).to(titleLabel, .lastBaseline)
```

> **iOS and tvOS only.** Baseline anchors are not available on macOS — `NSView` has no equivalent anchors. The `.firstBaseline` / `.lastBaseline` cases in `OrbitalAnchor` and the corresponding factory methods are wrapped in `#if canImport(UIKit)`, so using them on macOS is a **compile-time error**, not a runtime crash.

Used to align text-containing views (UILabel, UITextField, UITextView) by their text baselines.

---

## 18. Update / Remake Constraints

### Update — changes only constants of existing constraints

```swift
view.orbital.update(
    .height(300),
    .top(24)
)
```

Finds previously created constraints by anchor and updates their `constant`. Does not create new constraints. **Only `anchor` and `constant` are read from each descriptor** — all other fields (`relation`, `priority`, `target`, `label`, `multiplier`) are ignored. To change anything other than constant, use `remake()` instead.

Accepts `OrbitalConstraintConvertible`, so groups work: `update(.edges(24))` updates all 4 edge constants at once.

### Remake — replaces matching constraints by anchor type

```swift
view.orbital.remake(
    .top(8),
    .leading(16),
    .trailing(16),
    .height(200)
)
```

For each provided descriptor: deactivates the existing constraint for that `anchor + relation` (if any), then creates and activates a new one. If no previous constraint exists for a given anchor, a new one is created regardless — `remake()` works as "layout() scoped to the specified anchors, with automatic cleanup of prior constraints". Other Orbital constraints on this view are not affected.

Replaced constraints are deactivated and removed from `ConstraintStorage`. If they were captured by the caller, the objects remain in memory but are no longer managed by OrbitalLayout.

---

## 19. Constant Sign Convention

`trailing`, `bottom`, and `right` constants are **auto-negated** internally when source and target anchor are the same (same-edge constraint). You always pass a positive value — the library applies the correct sign.

`top`, `leading`, `left`, `centerX`, `centerY`, `width`, `height` are **never** auto-negated.

### Same-edge → auto-negated

```swift
.trailing(16)                                      // view.trailing = superview.trailing − 16
.bottom(16)                                        // view.bottom   = superview.bottom   − 16
.bottom(16).to(view.safeAreaLayoutGuide, .bottom)  // view.bottom   = safeArea.bottom    − 16
.trailing(8).to(avatar, .trailing)                 // view.trailing = avatar.trailing    − 8
```

The rule applies regardless of whether `.to()` was used — what matters is that source and target anchor are the same edge.

### Cross-anchor forward → constant applied as-is (positive)

These go "in the natural direction" — the gap is already positive:

```swift
.top(8).to(header, .bottom)           // view.top      = header.bottom  + 8   (gap below header) ✅
.leading(8).to(avatar, .trailing)     // view.leading  = avatar.trailing + 8   (gap after avatar) ✅
.left(8).to(avatar, .right)           // view.left     = avatar.right   + 8   (gap after avatar) ✅
```

### Cross-anchor reverse spacer → auto-negated

`bottom→top`, `trailing→leading`, `right→left` go "against the direction" — a positive constant
would produce overlap. Pass a positive gap value; the library negates it internally:

```swift
.bottom(16).to(header, .top)          // view.bottom   = header.top    − 16  (gap above header) ✅
.trailing(8).to(avatar, .leading)     // view.trailing = avatar.leading − 8   (gap before avatar) ✅
.right(8).to(avatar, .left)           // view.right    = avatar.left   − 8   (gap before avatar) ✅
```

### Override modifiers

Use when the auto behavior is not what you want:

```swift
// Same-anchor but you want a positive offset (extend beyond the edge)
.trailing(8).to(avatar, .trailing).asOffset    // view.trailing = avatar.trailing + 8

// Cross-anchor but you want a negative constant
.bottom(16).to(header, .top).asInset           // view.bottom   = header.top − 16
```

---

## 20. Content Hugging / Compression Resistance

```swift
.hugging(.high, axis: .horizontal)
.hugging(.low, axis: .vertical)
.compression(.required, axis: .horizontal)
.compression(.low, axis: .vertical)
```

Shortcuts for `setContentHuggingPriority` and `setContentCompressionResistancePriority`.

---

## 21. Debug Labels

```swift
.top(16).labeled("headerTop")
.height(44).labeled("buttonHeight")
```

Sets `OrbitalConstraint.identifier` to the string as-is — appears in Auto Layout conflict logs for easier debugging. Namespace is the caller's responsibility: `.labeled("headerTop")` sets identifier `"headerTop"`, not `"UILabel.headerTop"`.

Use `.labeled()` together with Xcode's "Unsatisfiable Constraints" log. Constraint identifiers appear in the `UIView-Encapsulated-Layout-*` output, making it easy to find the source of conflicts.

---

## 22. Create Constraints Without Activation

```swift
let constraints = view.orbital.prepareLayout(
    .top(8),
    .leading(16),
    .trailing(16)
)
// activate later
constraints.activate()
```

`prepareLayout()` creates constraints and stores them in `ConstraintStorage`, but does not activate them. Named accessors (`topConstraint`, etc.) will return these constraints even while inactive. Call `.activate()` when ready.

---

## 23. UIStackView

Orbital does not manage arranged subviews. Use Orbital to position the UIStackView itself, not its children.

```swift
view.orbit(stackView, .top(16), .leading(16), .trailing(16))
```