# OrbitalLayout — Claude Instructions

## Project Overview

**OrbitalLayout** is a Swift Auto Layout constraint library (similar to SnapKit/Anchorage) with a clean DSL.  
Status: **early development** — no source code yet, documentation only.

Reference documents:
- `Docs/plan.md` — full task list (Task 1–16) with implementation order
- `Docs/requirements.md` — public API reference
- `Docs/architecture.md` — file structure, types, platform specifics
- `Docs/examples.md` — usage examples (source for doc comment snippets)

---

## Technology Stack

- **Swift Tools Version:** 6.0, language modes: `.v5`, `.v6`
- **Platforms:** iOS 15+, tvOS 15+, macOS 12+ (watchOS excluded — no Auto Layout support)
- **Testing framework:** Swift Testing (`@Suite`, `@Test`) — not XCTest
- **Coverage target:** 100% per source file

---

## Source Structure

```
Sources/
    Core/
        OrbitalAnchor.swift              // enum of anchor types (top, bottom, leading, … baseline UIKit-only)
        OrbitalRelation.swift            // .equal / .lessOrEqual / .greaterOrEqual
        OrbitalPriority.swift            // .required / .high / .low / .custom(Float)
        OrbitalDescriptor.swift          // value type describing one constraint + chaining modifiers
        ConstraintFactory.swift          // OrbitalDescriptor → NSLayoutConstraint (does not activate)
    Proxy/
        OrbitalProxy.swift               // view.orbital — main user entry point
    Extensions/
        PlatformAliases.swift            // OrbitalView, OrbitalLayoutGuide, etc.
        OrbitalView+Orbital.swift        // .orbital property + .orbit(...) addSubview methods
        OrbitalConstraint+Orbital.swift  // [NSLayoutConstraint].activate() / .deactivate()
    Storage/
        ConstraintStorage.swift          // per-view storage via objc_setAssociatedObject
Tests/
    OrbitalAnchorTests.swift
    OrbitalRelationTests.swift
    OrbitalPriorityTests.swift
    OrbitalDescriptorTests.swift
    ConstraintStorageTests.swift
    ConstraintFactoryTests.swift
    OrbitalProxyTests.swift
    OrbitalViewExtensionTests.swift
    OrbitalConstraintExtensionTests.swift
    ErrorHandlingTests.swift
    IntegrationTests.swift
```

---

## Key Design Decisions

### Platform typealiases
```swift
// UIKit (iOS, tvOS)
OrbitalView           = UIView
OrbitalLayoutGuide    = UILayoutGuide
OrbitalLayoutPriority = UILayoutPriority

// AppKit (macOS)
OrbitalView           = NSView
OrbitalLayoutGuide    = NSLayoutGuide
OrbitalLayoutPriority = NSLayoutConstraint.Priority

// Shared
OrbitalConstraint = NSLayoutConstraint
OrbitalAxis       = NSLayoutConstraint.Axis
```

### OrbitalDescriptor — value type, chaining via copy-return
All modifiers (`.to()`, `.orLess`, `.priority()`, `.labeled()`) copy `self`, mutate the copy, and return it. The original is never mutated.

### Sign Convention (important)
- `trailing`, `bottom`, `right` — **auto-negated** on same-edge constraints (caller passes `+16`, internally becomes `-16`)
- `top`, `leading`, `left`, `centerX`, `centerY`, `width`, `height` — never negated
- `.asOffset` — suppresses auto-negation; `.asInset` — forces negation on cross-anchor constraints

### Storage key = `anchor + relation`
Constraints are stored by `(OrbitalAnchor, OrbitalRelation)`. Multiple constraints on the same anchor coexist if they have different relations (e.g. `.equal` and `.lessOrEqual`). Named accessors (`topConstraint`, etc.) return the `.equal` constraint.

### ConstraintFactory — creates only, does not activate
`ConstraintFactory.make(from:for:)` returns an inactive `NSLayoutConstraint`. Activation is the caller's responsibility (OrbitalProxy). Triggers `preconditionFailure` when: no superview and no explicit `.to()` target; incompatible anchor types.

### Baseline anchors — UIKit only, compile-time guard
`firstBaseline` / `lastBaseline` are wrapped in `#if canImport(UIKit)` — using them on macOS is a compile-time error, not a runtime crash.

### @MainActor
`OrbitalProxy`, `OrbitalDescriptor`, `ConstraintStorage`, and `ConstraintFactory` are all `@MainActor`.

---

## Implementation Order (Tasks)

Follow strictly in order as specified in `Docs/plan.md`:

1. **Task 1** — Project structure + platform typealiases + core enums (Anchor, Relation, Priority)
2. **Task 2** — OrbitalDescriptor (struct + OrbitalConstraintConvertible + OrbitalDescriptorGroup)
3. **Task 3** — Chaining modifiers on OrbitalDescriptor (`.to()`, `.orLess`, `.like()`, etc.)
4. **Task 4** — Static factory methods (`.top(16)`, `.edges`, `.center()`, `.aspectRatio()`, etc.)
5. **Task 5** — ConstraintStorage
6. **Task 6** — ConstraintFactory
7. **Task 7** — OrbitalProxy core (shortcuts + `layout()` + `prepareLayout()` + accessors)
8. **Task 8** — OrbitalProxy group shortcuts (edges, size, center)
9. **Task 9** — OrbitalProxy `update()` / `remake()`
10. **Task 10** — OrbitalProxy `hugging()` / `compression()`
11. **Task 11** — OrbitalView extensions (`orbital` property + `orbit(add:...)` / `orbit(to:...)` overloads)
12. **Task 12** — NSLayoutConstraint extensions (batch activate/deactivate)
13. **Task 13** — Error handling & debug warnings
14. **Task 14** — Integration tests
15. **Task 15** — Final verification & cleanup
16. **Task 16** — Documentation comments (DocC-style)

Each task has a completion criterion: `swift build` passes + tests are green.

---

## Documentation Comments (REQUIRED)

Every `public` type, property, method, and enum case **must** have a DocC-style `///` comment.
Apply this rule to **all new and modified code** — do not skip documentation even for simple members.

### Standard (Apple DocC, SnapKit/Alamofire style)

```swift
/// Short one-line summary (imperative mood, no period at end).
///
/// Extended description if needed. Explain *why*, not just *what*.
///
/// ```swift
/// // Usage example
/// view.orbital.layout(.top(16), .leading(16))
/// ```
///
/// - Parameters:
///   - constant: The inset value in points.
///   - relation: The relational operator. Defaults to `.equal`.
/// - Returns: The activated `OrbitalConstraint`.
/// - Note: Trailing and bottom constants are auto-negated internally.
```

### Rules

1. **Type-level comment** — describe purpose, include a usage example and an anchor table or bullet list where relevant
2. **Each case / property** — at minimum a one-liner `///`. Add `- Note:` for platform restrictions or non-obvious behaviour
3. **Methods** — `- Parameters:` for every non-obvious parameter, `- Returns:` if the return value has meaningful semantics, `- Note:` for side effects or caveats
4. **`#if canImport(UIKit)` blocks** — always add `- Note: iOS and tvOS only.` to the affected symbol
5. **Internal types** — doc comments are optional but appreciated for complex logic (e.g. `ConstraintFactory.make`)
6. **No redundant comments** — `/// The top anchor.` on `case top` is fine; restating the type name is not

### Cross-reference syntax

```swift
/// Use ``OrbitalProxy/layout(_:)`` for batch constraint creation.
```

---

## Testing Rules

- Framework: **Swift Testing** (`@Suite`, `@Test`) — not XCTest
- Every source file has a paired test file
- Target: 100% coverage per file
- `preconditionFailure` paths are tested via the appropriate Swift Testing mechanisms
- `#if DEBUG` warnings are tested by capturing/redirecting stderr or via dedicated test hooks
