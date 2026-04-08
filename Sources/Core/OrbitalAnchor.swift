//
//  OrbitalAnchor.swift
//  OrbitalLayout
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

/// Identifies a layout anchor on a view.
///
/// `OrbitalAnchor` is used in descriptor factory methods (`.top`, `.leading`, …)
/// and in `.to(_:_:)` to name the **target** anchor of a constraint.
///
/// ```swift
/// subtitle.orbital.layout(
///     .top(8).to(titleLabel, .bottom),   // source: .top, target: .bottom
///     .leading.to(titleLabel, .leading)  // source: .top, target: .leading (same)
/// )
/// ```
///
/// ### Anchor groups
/// | Group       | Cases                                      |
/// |-------------|--------------------------------------------|
/// | Vertical    | `top`, `bottom`, `centerY`                 |
/// | Horizontal  | `leading`, `trailing`, `left`, `right`, `centerX` |
/// | Dimension   | `width`, `height`                          |
/// | Baseline    | `firstBaseline`, `lastBaseline` *(UIKit only)* |
///
/// - Note: `.firstBaseline` and `.lastBaseline` are only available on iOS and tvOS.
///   Attempting to use them on macOS produces a **compile-time error**.
public enum OrbitalAnchor: Hashable, Sendable {

    // MARK: - Vertical

    /// The top edge of the view's alignment rectangle.
    case top

    /// The bottom edge of the view's alignment rectangle.
    case bottom

    // MARK: - Horizontal (RTL-safe)

    /// The leading edge of the view's alignment rectangle (RTL-aware).
    case leading

    /// The trailing edge of the view's alignment rectangle (RTL-aware).
    case trailing

    // MARK: - Horizontal (absolute)

    /// The left edge of the view's alignment rectangle (absolute, non-RTL).
    ///
    /// Prefer ``leading`` for RTL-safe layouts.
    case left

    /// The right edge of the view's alignment rectangle (absolute, non-RTL).
    ///
    /// Prefer ``trailing`` for RTL-safe layouts.
    case right

    // MARK: - Center

    /// The horizontal center of the view's alignment rectangle.
    case centerX

    /// The vertical center of the view's alignment rectangle.
    case centerY

    // MARK: - Dimension

    /// The width of the view's alignment rectangle.
    case width

    /// The height of the view's alignment rectangle.
    case height

    // MARK: - Baseline (UIKit only)

#if canImport(UIKit)
    /// The baseline of the first line of text in the view.
    ///
    /// - Note: iOS and tvOS only. Not available on macOS.
    case firstBaseline

    /// The baseline of the last line of text in the view.
    ///
    /// - Note: iOS and tvOS only. Not available on macOS.
    case lastBaseline
#endif
}
