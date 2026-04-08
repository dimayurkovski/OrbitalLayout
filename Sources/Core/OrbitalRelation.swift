//
//  OrbitalRelation.swift
//  OrbitalLayout
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

/// The relational operator of a layout constraint.
///
/// Corresponds directly to `NSLayoutConstraint.Relation`. Use the
/// chaining modifiers ``OrbitalDescriptor/orLess`` and ``OrbitalDescriptor/orMore``
/// to change a descriptor's relation — the default is ``equal``.
///
/// ```swift
/// descriptionLabel.orbital.layout(
///     .height(120).orLess   // NSLayoutRelation.lessThanOrEqual
/// )
///
/// button.orbital.layout(
///     .width(100).orMore,   // NSLayoutRelation.greaterThanOrEqual
///     .height(44)           // NSLayoutRelation.equal (default)
/// )
/// ```
///
/// Constraints with different relations on the **same anchor** coexist in storage —
/// they are keyed by `anchor + relation`, so `.width == 200` and `.width <= 300`
/// can both be active simultaneously.
public enum OrbitalRelation: Hashable, Sendable {

    /// The constraint's first attribute exactly equals the second attribute
    /// times the multiplier, plus the constant. This is the default.
    case equal

    /// The constraint's first attribute is less than or equal to the second
    /// attribute times the multiplier, plus the constant. Applied via `.orLess`.
    case lessOrEqual

    /// The constraint's first attribute is greater than or equal to the second
    /// attribute times the multiplier, plus the constant. Applied via `.orMore`.
    case greaterOrEqual
}
