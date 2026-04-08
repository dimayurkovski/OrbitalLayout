#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Extensions on `Array` of `OrbitalConstraint` for batch activation and deactivation.
///
/// These convenience methods wrap `NSLayoutConstraint.activate(_:)` and
/// `NSLayoutConstraint.deactivate(_:)`, allowing you to toggle entire groups
/// of constraints returned by ``OrbitalProxy/layout(_:)``.
///
/// ```swift
/// let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
/// constraints.deactivate()
/// constraints.activate()
/// ```
extension Array where Element == OrbitalConstraint {

    /// Activates all constraints in the array.
    ///
    /// Calls `NSLayoutConstraint.activate(_:)` on `self`.
    ///
    /// ```swift
    /// let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
    /// constraints.deactivate()
    /// // ... later ...
    /// constraints.activate()
    /// ```
    @MainActor
    public func activate() {
        OrbitalConstraint.activate(self)
    }

    /// Deactivates all constraints in the array.
    ///
    /// Calls `NSLayoutConstraint.deactivate(_:)` on `self`.
    ///
    /// ```swift
    /// let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
    /// constraints.deactivate()
    /// ```
    @MainActor
    public func deactivate() {
        OrbitalConstraint.deactivate(self)
    }
}
