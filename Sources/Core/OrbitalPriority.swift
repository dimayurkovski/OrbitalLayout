//
//  OrbitalPriority.swift
//  OrbitalLayout
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The priority of a layout constraint.
///
/// Use the ``OrbitalDescriptor/priority(_:)`` modifier to assign a priority
/// to any descriptor. The default priority for all constraints is ``required``.
///
/// ```swift
/// view.orbital.layout(
///     .top(16).priority(.high),         // 750 — can be broken if needed
///     .bottom(16).priority(.low),       // 250 — easily sacrificed
///     .height(44),                      // 1000 — required (default)
///     .width(200).priority(.custom(600))
/// )
/// ```
///
/// ### Predefined values
/// | Case       | Raw value | Equivalent                        |
/// |------------|-----------|-----------------------------------|
/// | `.required`| 1000      | `UILayoutPriority.required`        |
/// | `.high`    | 750       | `UILayoutPriority.defaultHigh`     |
/// | `.low`     | 250       | `UILayoutPriority.defaultLow`      |
/// | `.custom`  | any Float | arbitrary priority                 |
///
/// - Note: The Auto Layout engine may break constraints with non-`.required` priority
///   to satisfy the layout if no other solution exists. Use `.required` (1000) only
///   for constraints that must never break.
public enum OrbitalPriority: Equatable, Sendable {

    // MARK: - Cases

    /// A required constraint. The layout engine **must** satisfy it.
    ///
    /// Raw priority value: **1000**.
    case required

    /// A high-priority constraint. Satisfied before `.low`, but may be broken
    /// in favour of `.required` constraints.
    ///
    /// Raw priority value: **750** (`UILayoutPriority.defaultHigh`).
    case high

    /// A low-priority constraint. The first to be sacrificed when the engine
    /// cannot satisfy all constraints simultaneously.
    ///
    /// Raw priority value: **250** (`UILayoutPriority.defaultLow`).
    case low

    /// An arbitrary constraint priority specified as a raw `Float`.
    ///
    /// Valid range: `1...1000`. Values outside this range are clamped by the
    /// layout engine.
    ///
    /// ```swift
    /// .height(44).priority(.custom(600))
    /// ```
    case custom(Float)

    // MARK: - Conversion

    /// The platform layout priority value corresponding to this case.
    ///
    /// Converts to `UILayoutPriority` on iOS/tvOS or `NSLayoutConstraint.Priority`
    /// on macOS.
    public var layoutPriority: OrbitalLayoutPriority {
        switch self {
        case .required:        return OrbitalLayoutPriority(1000)
        case .high:            return OrbitalLayoutPriority(750)
        case .low:             return OrbitalLayoutPriority(250)
        case .custom(let v):   return OrbitalLayoutPriority(v)
        }
    }
}
