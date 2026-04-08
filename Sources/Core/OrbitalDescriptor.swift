//
//  OrbitalDescriptor.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A value type that fully describes a single layout constraint before it is created.
///
/// `OrbitalDescriptor` is the core DSL building block. Instances are produced by
/// static factory methods (`.top(16)`, `.edges`, `.center()`, …) and then passed
/// to `OrbitalProxy.layout(_:)` or `view.orbit(_:_:)`.
///
/// All modifier methods (`.to()`, `.orLess`, `.priority()`, etc.) return a **new**
/// copy of the descriptor — the original is never mutated, giving safe chaining.
///
/// ```swift
/// view.orbital.layout(
///     .top(8).to(header, .bottom).orMore.priority(.high).labeled("contentTop")
/// )
/// ```
@MainActor
public struct OrbitalDescriptor: Sendable {

    // MARK: - Nested Types

    /// Controls whether the auto-negation sign convention is overridden.
    ///
    /// By default, `trailing`, `bottom`, and `right` constants are auto-negated
    /// when the source and target anchor are the same edge. Use ``offset`` or
    /// ``inset`` to suppress or force that behaviour.
    public enum SignOverride: Sendable {
        /// Suppress auto-negation — apply the constant as a positive offset.
        ///
        /// Use when you want the view to extend *beyond* the referenced edge.
        case offset

        /// Force negation — apply the constant as a negative inset even on cross-anchor constraints.
        case inset
    }

    // MARK: - Properties

    /// The source anchor this descriptor targets on the constrained view.
    public let anchor: OrbitalAnchor

    /// The constant value added to the constraint expression.
    ///
    /// For `trailing`, `bottom`, and `right` same-edge constraints this value is
    /// auto-negated internally by `ConstraintFactory` unless ``signOverride`` is set.
    public let constant: CGFloat

    /// The relational operator of the constraint. Defaults to `.equal`.
    public let relation: OrbitalRelation

    /// The layout priority of the constraint. Defaults to `.required`.
    public let priority: OrbitalPriority

    /// The target view for this constraint, if any.
    ///
    /// When `nil` and ``targetGuide`` is also `nil`, `ConstraintFactory` uses
    /// the view's superview as the second item.
    public let targetView: OrbitalView?

    /// The target layout guide for this constraint, if any.
    ///
    /// Mutually exclusive with ``targetView``.
    public let targetGuide: OrbitalLayoutGuide?

    /// The anchor on the target item. When `nil`, the matching anchor is inferred
    /// from ``anchor``.
    public let targetAnchor: OrbitalAnchor?

    /// The multiplier applied to the target anchor's value. Defaults to `1`.
    ///
    /// Only meaningful when set via `.like(...)`.
    public let multiplier: CGFloat

    /// An optional identifier set on the created `NSLayoutConstraint`.
    ///
    /// Appears in Xcode's Auto Layout conflict log for easier debugging.
    public let label: String?

    /// Overrides the automatic sign convention for this descriptor's constant.
    ///
    /// When `nil`, the default sign convention applies (auto-negate same-edge).
    public let signOverride: SignOverride?

    /// When `true`, the target is the constrained view itself (used for
    /// self-referencing constraints such as `.aspectRatio` and `.like(.width, 0.4)`).
    public let targetIsSelf: Bool

    /// Set to `true` when `.like(...)` was called on this descriptor.
    ///
    /// Used in `#if DEBUG` mode by `ConstraintFactory` to warn when `.to()` is
    /// called afterwards and overwrites the `.like()` target.
    public let likeWasCalled: Bool

    // MARK: - Initialiser

    /// Creates a fully-specified descriptor.
    ///
    /// In most cases, use the static factory methods (`.top(_:)`, `.edges`, …)
    /// rather than this initialiser directly.
    ///
    /// - Parameters:
    ///   - anchor: The source anchor on the constrained view.
    ///   - constant: The layout constant. Defaults to `0`.
    ///   - relation: The relational operator. Defaults to `.equal`.
    ///   - priority: The constraint priority. Defaults to `.required`.
    ///   - targetView: An explicit target view. Defaults to `nil` (superview).
    ///   - targetGuide: An explicit target layout guide. Defaults to `nil`.
    ///   - targetAnchor: The anchor on the target. Defaults to `nil` (inferred).
    ///   - multiplier: The multiplier. Defaults to `1`.
    ///   - label: An optional debug identifier. Defaults to `nil`.
    ///   - signOverride: Overrides the auto-negation convention. Defaults to `nil`.
    ///   - targetIsSelf: Whether the target is the view itself. Defaults to `false`.
    ///   - likeWasCalled: Internal flag for debug warnings. Defaults to `false`.
    public init(
        anchor: OrbitalAnchor,
        constant: CGFloat = 0,
        relation: OrbitalRelation = .equal,
        priority: OrbitalPriority = .required,
        targetView: OrbitalView? = nil,
        targetGuide: OrbitalLayoutGuide? = nil,
        targetAnchor: OrbitalAnchor? = nil,
        multiplier: CGFloat = 1,
        label: String? = nil,
        signOverride: SignOverride? = nil,
        targetIsSelf: Bool = false,
        likeWasCalled: Bool = false
    ) {
        self.anchor = anchor
        self.constant = constant
        self.relation = relation
        self.priority = priority
        self.targetView = targetView
        self.targetGuide = targetGuide
        self.targetAnchor = targetAnchor
        self.multiplier = multiplier
        self.label = label
        self.signOverride = signOverride
        self.targetIsSelf = targetIsSelf
        self.likeWasCalled = likeWasCalled
    }
}

// MARK: - Chaining Modifiers

extension OrbitalDescriptor {

    // MARK: Target

    /// Redirects the constraint to a specific anchor on another view.
    ///
    /// ```swift
    /// .top(8).to(header, .bottom)       // view.top = header.bottom + 8
    /// .leading(8).to(avatar, .trailing) // view.leading = avatar.trailing + 8
    /// ```
    ///
    /// If `.to()` is called more than once, the **last call wins**.
    ///
    /// - Parameters:
    ///   - view: The target view.
    ///   - anchor: The anchor on the target view. When omitted, the matching anchor is inferred.
    /// - Returns: A new descriptor targeting `view` at `anchor`.
    public func to(_ view: OrbitalView, _ anchor: OrbitalAnchor? = nil) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: self.anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: view,
            targetGuide: nil,
            targetAnchor: anchor ?? targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: false,
            likeWasCalled: likeWasCalled
        )
    }

    /// Redirects the constraint to a specific anchor on a layout guide.
    ///
    /// ```swift
    /// .top(16).to(view.safeAreaLayoutGuide, .top)
    /// .bottom(16).to(view.safeAreaLayoutGuide, .bottom)
    /// ```
    ///
    /// - Parameters:
    ///   - guide: The target layout guide.
    ///   - anchor: The anchor on the guide. When omitted, the matching anchor is inferred.
    /// - Returns: A new descriptor targeting `guide` at `anchor`.
    public func to(_ guide: OrbitalLayoutGuide, _ anchor: OrbitalAnchor? = nil) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: self.anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: nil,
            targetGuide: guide,
            targetAnchor: anchor ?? targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: false,
            likeWasCalled: likeWasCalled
        )
    }

    // MARK: Relations

    /// Changes the constraint relation to `<=` (less-than-or-equal).
    ///
    /// ```swift
    /// .height(120).orLess   // height <= 120
    /// ```
    public var orLess: OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: .lessOrEqual,
            priority: priority,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    /// Changes the constraint relation to `>=` (greater-than-or-equal).
    ///
    /// ```swift
    /// .width(100).orMore    // width >= 100
    /// .top(8).orMore.to(header, .bottom)
    /// ```
    public var orMore: OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: .greaterOrEqual,
            priority: priority,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    // MARK: Sign override

    /// Suppresses the automatic sign negation on same-edge constraints.
    ///
    /// By default, `trailing`, `bottom`, and `right` constants are negated when
    /// source and target anchors are the same edge. Use `.asOffset` to apply the
    /// constant as a **positive offset** instead (view extends beyond the edge).
    ///
    /// ```swift
    /// .trailing(8).to(avatar, .trailing).asOffset  // view.trailing = avatar.trailing + 8
    /// ```
    public var asOffset: OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: .offset,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    /// Forces the constant to be applied as a **negative inset** even on cross-anchor constraints.
    ///
    /// ```swift
    /// .bottom(16).to(header, .top).asInset   // view.bottom = header.top − 16
    /// ```
    public var asInset: OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: .inset,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    // MARK: Priority

    /// Sets the layout priority of the constraint.
    ///
    /// ```swift
    /// .height(200).priority(.high)          // 750
    /// .top(16).priority(.custom(600))
    /// .bottom(16).priority(.low)            // 250
    /// ```
    ///
    /// - Parameter p: The desired priority.
    /// - Returns: A new descriptor with the specified priority.
    public func priority(_ p: OrbitalPriority) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: relation,
            priority: p,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    // MARK: Debug label

    /// Sets the `NSLayoutConstraint.identifier` on the created constraint.
    ///
    /// The identifier appears in Xcode's "Unsatisfiable Constraints" log, making
    /// it easy to find the source of conflicts.
    ///
    /// ```swift
    /// .top(16).labeled("card.top")
    /// .height(44).labeled("buttonHeight")
    /// ```
    ///
    /// - Parameter id: The identifier string. Namespace is the caller's responsibility.
    /// - Returns: A new descriptor with the debug label set.
    public func labeled(_ id: String) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: targetView,
            targetGuide: targetGuide,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: id,
            signOverride: signOverride,
            targetIsSelf: targetIsSelf,
            likeWasCalled: likeWasCalled
        )
    }

    // MARK: Multiplier (.like)

    /// Constrains this anchor to another view's matching anchor scaled by a multiplier.
    ///
    /// ```swift
    /// .width.like(superview, 0.4)       // width == superview.width * 0.4
    /// .height.like(otherView, 2)        // height == otherView.height * 2
    /// .width.like(referenceView)        // width == referenceView.width (multiplier = 1)
    /// ```
    ///
    /// - Parameters:
    ///   - view: The target view.
    ///   - multiplier: Scale factor applied to the target anchor's value. Defaults to `1`.
    /// - Returns: A new descriptor with the target view and multiplier set.
    /// - Note: Do not combine `.like()` with `.to()` on the same descriptor —
    ///   the last call wins and a `#if DEBUG` warning is printed.
    public func like(_ view: OrbitalView, _ multiplier: CGFloat = 1) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: view,
            targetGuide: nil,
            targetAnchor: targetAnchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: false,
            likeWasCalled: true
        )
    }

    /// Constrains this anchor to a **specific anchor** on another view scaled by a multiplier.
    ///
    /// ```swift
    /// .height.like(imageView, .width, 0.5)   // height == imageView.width * 0.5
    /// ```
    ///
    /// - Parameters:
    ///   - view: The target view.
    ///   - anchor: The anchor on the target view.
    ///   - multiplier: Scale factor. Defaults to `1`.
    /// - Returns: A new descriptor with the target view, target anchor, and multiplier set.
    public func like(_ view: OrbitalView, _ anchor: OrbitalAnchor, _ multiplier: CGFloat = 1) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: self.anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: view,
            targetGuide: nil,
            targetAnchor: anchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: false,
            likeWasCalled: true
        )
    }

    /// Constrains this anchor to **another anchor on the same view** scaled by a multiplier.
    ///
    /// ```swift
    /// .height.like(.width, 0.4)   // height == self.width * 0.4
    /// ```
    ///
    /// - Parameters:
    ///   - anchor: The source anchor on the same view.
    ///   - multiplier: Scale factor. Defaults to `1`.
    /// - Returns: A new descriptor with `targetIsSelf = true` and the multiplier set.
    public func like(_ anchor: OrbitalAnchor, _ multiplier: CGFloat = 1) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: self.anchor,
            constant: constant,
            relation: relation,
            priority: priority,
            targetView: nil,
            targetGuide: nil,
            targetAnchor: anchor,
            multiplier: multiplier,
            label: label,
            signOverride: signOverride,
            targetIsSelf: true,
            likeWasCalled: true
        )
    }
}

// MARK: - Static Factory Methods

extension OrbitalDescriptor {

    // MARK: Edge anchors — zero-constant properties

    /// A descriptor that pins the top edge to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.top)          // view.top == superview.top
    /// view.orbital.layout(.top.orMore)   // view.top >= superview.top
    /// ```
    public static var top: OrbitalDescriptor { OrbitalDescriptor(anchor: .top) }

    /// A descriptor that pins the bottom edge to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.bottom)   // view.bottom == superview.bottom
    /// ```
    public static var bottom: OrbitalDescriptor { OrbitalDescriptor(anchor: .bottom) }

    /// A descriptor that pins the leading edge to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.leading)   // view.leading == superview.leading
    /// ```
    public static var leading: OrbitalDescriptor { OrbitalDescriptor(anchor: .leading) }

    /// A descriptor that pins the trailing edge to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.trailing)   // view.trailing == superview.trailing
    /// ```
    public static var trailing: OrbitalDescriptor { OrbitalDescriptor(anchor: .trailing) }

    /// A descriptor that pins the left edge to the superview with zero inset.
    ///
    /// - Note: Prefer ``leading`` for RTL-safe layouts.
    public static var left: OrbitalDescriptor { OrbitalDescriptor(anchor: .left) }

    /// A descriptor that pins the right edge to the superview with zero inset.
    ///
    /// - Note: Prefer ``trailing`` for RTL-safe layouts.
    public static var right: OrbitalDescriptor { OrbitalDescriptor(anchor: .right) }

    // MARK: Dimension anchors — zero-constant properties

    /// A descriptor that matches the view's width to the superview's width.
    ///
    /// ```swift
    /// view.orbital.layout(.width)   // view.width == superview.width
    /// ```
    public static var width: OrbitalDescriptor { OrbitalDescriptor(anchor: .width) }

    /// A descriptor that matches the view's height to the superview's height.
    ///
    /// ```swift
    /// view.orbital.layout(.height)   // view.height == superview.height
    /// ```
    public static var height: OrbitalDescriptor { OrbitalDescriptor(anchor: .height) }

    // MARK: Center anchors — zero-offset properties

    /// A descriptor that centers the view horizontally in the superview.
    ///
    /// ```swift
    /// view.orbital.layout(.centerX)   // view.centerX == superview.centerX
    /// ```
    public static var centerX: OrbitalDescriptor { OrbitalDescriptor(anchor: .centerX) }

    /// A descriptor that centers the view vertically in the superview.
    ///
    /// ```swift
    /// view.orbital.layout(.centerY)   // view.centerY == superview.centerY
    /// ```
    public static var centerY: OrbitalDescriptor { OrbitalDescriptor(anchor: .centerY) }

    // MARK: Edge anchors — with constant

    /// Pins the top edge with an inset constant.
    ///
    /// ```swift
    /// view.orbital.layout(.top(16))   // view.top == superview.top + 16
    /// ```
    ///
    /// - Parameter constant: The inset in points.
    /// - Returns: A descriptor for the top anchor.
    public static func top(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .top, constant: constant)
    }

    /// Pins the bottom edge with an inset constant.
    ///
    /// The constant is auto-negated internally when source and target are the same edge.
    /// Pass a positive value — the library applies the correct sign.
    ///
    /// ```swift
    /// view.orbital.layout(.bottom(16))   // view.bottom == superview.bottom − 16
    /// ```
    ///
    /// - Parameter constant: The inset in points (positive).
    /// - Returns: A descriptor for the bottom anchor.
    public static func bottom(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .bottom, constant: constant)
    }

    /// Pins the leading edge with an inset constant.
    ///
    /// ```swift
    /// view.orbital.layout(.leading(16))   // view.leading == superview.leading + 16
    /// ```
    ///
    /// - Parameter constant: The inset in points.
    /// - Returns: A descriptor for the leading anchor.
    public static func leading(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .leading, constant: constant)
    }

    /// Pins the trailing edge with an inset constant.
    ///
    /// The constant is auto-negated internally when source and target are the same edge.
    ///
    /// ```swift
    /// view.orbital.layout(.trailing(16))   // view.trailing == superview.trailing − 16
    /// ```
    ///
    /// - Parameter constant: The inset in points (positive).
    /// - Returns: A descriptor for the trailing anchor.
    public static func trailing(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .trailing, constant: constant)
    }

    /// Pins the left edge with an inset constant.
    ///
    /// - Note: Prefer ``leading(_:)`` for RTL-safe layouts.
    /// - Parameter constant: The inset in points.
    /// - Returns: A descriptor for the left anchor.
    public static func left(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .left, constant: constant)
    }

    /// Pins the right edge with an inset constant.
    ///
    /// - Note: Prefer ``trailing(_:)`` for RTL-safe layouts.
    /// - Parameter constant: The inset in points (positive).
    /// - Returns: A descriptor for the right anchor.
    public static func right(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .right, constant: constant)
    }

    // MARK: Dimension anchors — with constant

    /// Sets a fixed width constraint.
    ///
    /// ```swift
    /// view.orbital.layout(.width(100))   // view.width == 100
    /// ```
    ///
    /// - Parameter constant: The width in points.
    /// - Returns: A descriptor for the width anchor.
    public static func width(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .width, constant: constant)
    }

    /// Sets a fixed height constraint.
    ///
    /// ```swift
    /// view.orbital.layout(.height(44))   // view.height == 44
    /// ```
    ///
    /// - Parameter constant: The height in points.
    /// - Returns: A descriptor for the height anchor.
    public static func height(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .height, constant: constant)
    }

    // MARK: Center anchors — with offset

    /// Centers the view horizontally with an optional offset.
    ///
    /// ```swift
    /// view.orbital.layout(.centerX())      // view.centerX == superview.centerX
    /// view.orbital.layout(.centerX(10))    // view.centerX == superview.centerX + 10
    /// ```
    ///
    /// - Parameter offset: The horizontal offset in points. Defaults to `0`.
    /// - Returns: A descriptor for the centerX anchor.
    public static func centerX(_ offset: CGFloat = 0) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .centerX, constant: offset)
    }

    /// Centers the view vertically with an optional offset.
    ///
    /// ```swift
    /// view.orbital.layout(.centerY())      // view.centerY == superview.centerY
    /// view.orbital.layout(.centerY(8))     // view.centerY == superview.centerY + 8
    /// ```
    ///
    /// - Parameter offset: The vertical offset in points. Defaults to `0`.
    /// - Returns: A descriptor for the centerY anchor.
    public static func centerY(_ offset: CGFloat = 0) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .centerY, constant: offset)
    }

    // MARK: Edge group shortcuts

    /// Pins all four edges to the superview with zero inset.
    ///
    /// Uses `leading`/`trailing`/`top`/`bottom` — RTL-safe.
    ///
    /// ```swift
    /// view.orbital.layout(.edges)   // all 4 edges flush to superview
    /// ```
    public static var edges: OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .top),
            OrbitalDescriptor(anchor: .bottom),
            OrbitalDescriptor(anchor: .leading),
            OrbitalDescriptor(anchor: .trailing)
        ])
    }

    /// Pins all four edges to the superview with an equal inset.
    ///
    /// Uses `leading`/`trailing`/`top`/`bottom` — RTL-safe.
    /// `trailing` and `bottom` constants are auto-negated internally.
    ///
    /// ```swift
    /// view.orbital.layout(.edges(16))   // 16pt inset on all sides
    /// ```
    ///
    /// - Parameter inset: The inset in points (positive).
    /// - Returns: A group descriptor for all four edges.
    public static func edges(_ inset: CGFloat) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .top, constant: inset),
            OrbitalDescriptor(anchor: .bottom, constant: inset),
            OrbitalDescriptor(anchor: .leading, constant: inset),
            OrbitalDescriptor(anchor: .trailing, constant: inset)
        ])
    }

    /// Pins the leading and trailing edges to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.horizontal)   // leading + trailing flush to superview
    /// ```
    public static var horizontal: OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .leading),
            OrbitalDescriptor(anchor: .trailing)
        ])
    }

    /// Pins the leading and trailing edges to the superview with an equal inset.
    ///
    /// ```swift
    /// view.orbital.layout(.horizontal(16))   // leading + trailing, 16pt inset
    /// ```
    ///
    /// - Parameter inset: The inset in points (positive).
    /// - Returns: A group descriptor for leading and trailing.
    public static func horizontal(_ inset: CGFloat) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .leading, constant: inset),
            OrbitalDescriptor(anchor: .trailing, constant: inset)
        ])
    }

    /// Pins the top and bottom edges to the superview with zero inset.
    ///
    /// ```swift
    /// view.orbital.layout(.vertical)   // top + bottom flush to superview
    /// ```
    public static var vertical: OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .top),
            OrbitalDescriptor(anchor: .bottom)
        ])
    }

    /// Pins the top and bottom edges to the superview with an equal inset.
    ///
    /// ```swift
    /// view.orbital.layout(.vertical(24))   // top + bottom, 24pt inset
    /// ```
    ///
    /// - Parameter inset: The inset in points (positive).
    /// - Returns: A group descriptor for top and bottom.
    public static func vertical(_ inset: CGFloat) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .top, constant: inset),
            OrbitalDescriptor(anchor: .bottom, constant: inset)
        ])
    }

    // MARK: Size shortcuts

    /// Sets equal width and height constraints.
    ///
    /// ```swift
    /// view.orbital.layout(.size(80))   // width == 80, height == 80
    /// ```
    ///
    /// - Parameter side: The value applied to both width and height.
    /// - Returns: A group descriptor for width and height.
    public static func size(_ side: CGFloat) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .width, constant: side),
            OrbitalDescriptor(anchor: .height, constant: side)
        ])
    }

    /// Sets explicit width and height constraints.
    ///
    /// ```swift
    /// view.orbital.layout(.size(width: 320, height: 180))
    /// ```
    ///
    /// - Parameters:
    ///   - width: The width in points.
    ///   - height: The height in points.
    /// - Returns: A group descriptor for width and height.
    public static func size(width: CGFloat, height: CGFloat) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .width, constant: width),
            OrbitalDescriptor(anchor: .height, constant: height)
        ])
    }

    // MARK: Center shortcuts

    /// Centers the view in the superview on both axes with zero offset.
    ///
    /// ```swift
    /// view.orbital.layout(.center())   // centerX + centerY == superview center
    /// ```
    ///
    /// - Returns: A group descriptor for centerX and centerY.
    public static func center() -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .centerX),
            OrbitalDescriptor(anchor: .centerY)
        ])
    }

    /// Centers the view in the superview with an offset on each axis.
    ///
    /// ```swift
    /// view.orbital.layout(.center(offset: CGPoint(x: 10, y: -5)))
    /// ```
    ///
    /// - Parameter offset: The `x` offset is applied to `centerX`; `y` to `centerY`.
    /// - Returns: A group descriptor for centerX and centerY with offsets.
    public static func center(offset: CGPoint) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup([
            OrbitalDescriptor(anchor: .centerX, constant: offset.x),
            OrbitalDescriptor(anchor: .centerY, constant: offset.y)
        ])
    }

    // MARK: Aspect ratio

    /// Constrains the view's width to equal its height multiplied by `ratio`.
    ///
    /// Uses a self-referencing constraint: `self.width == self.height * ratio`.
    ///
    /// ```swift
    /// view.orbital.layout(.aspectRatio(16.0 / 9.0))   // 16:9 aspect ratio
    /// view.orbital.layout(.aspectRatio(1))             // square
    /// ```
    ///
    /// - Parameter ratio: The width-to-height ratio.
    /// - Returns: A descriptor representing `width == height * ratio`.
    public static func aspectRatio(_ ratio: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(
            anchor: .width,
            targetAnchor: .height,
            multiplier: ratio,
            targetIsSelf: true
        )
    }

#if canImport(UIKit)
    // MARK: Baseline anchors (UIKit only)

    /// A descriptor that aligns the view's first baseline with zero offset.
    ///
    /// ```swift
    /// label.orbital.layout(.firstBaseline.to(otherLabel, .firstBaseline))
    /// ```
    ///
    /// - Note: iOS and tvOS only. Not available on macOS.
    public static var firstBaseline: OrbitalDescriptor {
        OrbitalDescriptor(anchor: .firstBaseline)
    }

    /// A descriptor that aligns the view's first baseline with an offset constant.
    ///
    /// ```swift
    /// label.orbital.layout(.firstBaseline(4).to(title, .firstBaseline))
    /// ```
    ///
    /// - Parameter constant: The baseline offset in points.
    /// - Returns: A descriptor for the firstBaseline anchor.
    /// - Note: iOS and tvOS only. Not available on macOS.
    public static func firstBaseline(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .firstBaseline, constant: constant)
    }

    /// A descriptor that aligns the view's last baseline with zero offset.
    ///
    /// ```swift
    /// label.orbital.layout(.lastBaseline.to(otherLabel, .lastBaseline))
    /// ```
    ///
    /// - Note: iOS and tvOS only. Not available on macOS.
    public static var lastBaseline: OrbitalDescriptor {
        OrbitalDescriptor(anchor: .lastBaseline)
    }

    /// A descriptor that aligns the view's last baseline with an offset constant.
    ///
    /// ```swift
    /// footnote.orbital.layout(.lastBaseline(4).to(mainLabel, .lastBaseline))
    /// ```
    ///
    /// - Parameter constant: The baseline offset in points.
    /// - Returns: A descriptor for the lastBaseline anchor.
    /// - Note: iOS and tvOS only. Not available on macOS.
    public static func lastBaseline(_ constant: CGFloat) -> OrbitalDescriptor {
        OrbitalDescriptor(anchor: .lastBaseline, constant: constant)
    }
#endif
}

// MARK: - OrbitalConstraintConvertible

/// A type that can be converted to one or more `OrbitalDescriptor` instances.
///
/// Conforming types can be passed directly to `OrbitalProxy.layout(_:)`,
/// `OrbitalProxy.update(_:)`, and `OrbitalProxy.remake(_:)`.
///
/// ```swift
/// view.orbital.layout(.edges(16))       // OrbitalDescriptorGroup conforms
/// view.orbital.layout(.top(8))          // OrbitalDescriptor conforms
/// ```
@MainActor
public protocol OrbitalConstraintConvertible: Sendable {
    /// Returns the flat array of descriptors represented by this value.
    func asDescriptors() -> [OrbitalDescriptor]
}

// MARK: OrbitalDescriptor: OrbitalConstraintConvertible

extension OrbitalDescriptor: OrbitalConstraintConvertible {
    /// Returns `[self]`.
    public func asDescriptors() -> [OrbitalDescriptor] { [self] }
}

// MARK: - OrbitalDescriptorGroup

/// A group of `OrbitalDescriptor` values produced by multi-anchor shortcuts
/// such as `.edges(_:)`, `.horizontal(_:)`, `.vertical(_:)`, and `.center()`.
///
/// Groups conform to ``OrbitalConstraintConvertible`` and can be passed anywhere
/// a single descriptor is accepted.
///
/// ```swift
/// view.orbital.layout(.edges(16))           // OrbitalDescriptorGroup
/// view.orbital.update(.edges(24))           // updates all 4 edge constants at once
/// ```
@MainActor
public struct OrbitalDescriptorGroup: OrbitalConstraintConvertible, Sendable {

    /// The individual descriptors that make up this group.
    public let descriptors: [OrbitalDescriptor]

    /// Creates a group from an array of descriptors.
    ///
    /// - Parameter descriptors: The descriptors to group.
    public init(_ descriptors: [OrbitalDescriptor]) {
        self.descriptors = descriptors
    }

    /// Returns the flat array of all descriptors in this group.
    public func asDescriptors() -> [OrbitalDescriptor] { descriptors }
}

// MARK: - OrbitalDescriptorGroup Factory Methods

extension OrbitalDescriptorGroup {

    /// Pins all four edges to the superview with zero inset.
    ///
    /// - Note: Equivalent to `OrbitalDescriptor.edges`.
    public static var edges: OrbitalDescriptorGroup { OrbitalDescriptor.edges }

    /// Pins all four edges to the superview with an equal inset.
    ///
    /// - Parameter inset: The inset in points (positive).
    public static func edges(_ inset: CGFloat) -> OrbitalDescriptorGroup { OrbitalDescriptor.edges(inset) }

    /// Pins leading and trailing edges to the superview with zero inset.
    public static var horizontal: OrbitalDescriptorGroup { OrbitalDescriptor.horizontal }

    /// Pins leading and trailing edges to the superview with an equal inset.
    ///
    /// - Parameter inset: The inset in points (positive).
    public static func horizontal(_ inset: CGFloat) -> OrbitalDescriptorGroup { OrbitalDescriptor.horizontal(inset) }

    /// Pins top and bottom edges to the superview with zero inset.
    public static var vertical: OrbitalDescriptorGroup { OrbitalDescriptor.vertical }

    /// Pins top and bottom edges to the superview with an equal inset.
    ///
    /// - Parameter inset: The inset in points (positive).
    public static func vertical(_ inset: CGFloat) -> OrbitalDescriptorGroup { OrbitalDescriptor.vertical(inset) }

    /// Sets equal width and height constraints.
    ///
    /// - Parameter side: The value applied to both width and height.
    public static func size(_ side: CGFloat) -> OrbitalDescriptorGroup { OrbitalDescriptor.size(side) }

    /// Sets explicit width and height constraints.
    ///
    /// - Parameters:
    ///   - width: The width in points.
    ///   - height: The height in points.
    public static func size(width: CGFloat, height: CGFloat) -> OrbitalDescriptorGroup { OrbitalDescriptor.size(width: width, height: height) }

    /// Centers the view in the superview on both axes with zero offset.
    public static func center() -> OrbitalDescriptorGroup { OrbitalDescriptor.center() }

    /// Centers the view in the superview with an offset on each axis.
    ///
    /// - Parameter offset: The `x` offset is applied to `centerX`; `y` to `centerY`.
    public static func center(offset: CGPoint) -> OrbitalDescriptorGroup { OrbitalDescriptor.center(offset: offset) }
}

// MARK: - OrbitalDescriptorGroup Chaining Modifiers

extension OrbitalDescriptorGroup {

    /// Sets the layout priority on every descriptor in the group.
    ///
    /// ```swift
    /// .edges(16).priority(.high)   // all 4 edges at priority 750
    /// ```
    ///
    /// - Parameter p: The desired priority.
    /// - Returns: A new group with the priority applied to all descriptors.
    public func priority(_ p: OrbitalPriority) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup(descriptors.map { $0.priority(p) })
    }

    /// Changes the relation to `<=` on every descriptor in the group.
    ///
    /// ```swift
    /// .size(100).orLess   // width <= 100, height <= 100
    /// ```
    public var orLess: OrbitalDescriptorGroup {
        OrbitalDescriptorGroup(descriptors.map { $0.orLess })
    }

    /// Changes the relation to `>=` on every descriptor in the group.
    ///
    /// ```swift
    /// .size(44).orMore   // width >= 44, height >= 44
    /// ```
    public var orMore: OrbitalDescriptorGroup {
        OrbitalDescriptorGroup(descriptors.map { $0.orMore })
    }

    /// Sets a debug label on every descriptor in the group.
    ///
    /// Each descriptor receives the same identifier string. For unique identifiers
    /// per constraint, label individual descriptors instead.
    ///
    /// - Parameter id: The identifier string.
    /// - Returns: A new group with the label applied to all descriptors.
    public func labeled(_ id: String) -> OrbitalDescriptorGroup {
        OrbitalDescriptorGroup(descriptors.map { $0.labeled(id) })
    }
}
