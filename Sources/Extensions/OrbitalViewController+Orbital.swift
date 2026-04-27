//
//  OrbitalViewController+Orbital.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - OrbitalViewController + orbit(add:...) overloads

public extension OrbitalViewController {

    /// Adds a single child view to the controller's `view` and applies inline constraints.
    ///
    /// Convenience that forwards to ``OrbitalView/orbit(add:_:)-variadic`` on `self.view`,
    /// so you can write `controller.orbit(add: label, ...)` instead of
    /// `controller.view.orbit(add: label, ...)`.
    ///
    /// ```swift
    /// controller.orbit(add: label, .top(16), .leading(16), .trailing(16))
    /// controller.orbit(add: imageView, .edges(4))
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview of `self.view`.
    ///   - items: One or more ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(add child: OrbitalView, _ items: any OrbitalConstraintConvertible...) {
        view.orbit(add: child, items)
    }

    /// Array-accepting overload of ``orbit(add:_:)-variadic``.
    ///
    /// Useful when the constraint list is built dynamically.
    ///
    /// ```swift
    /// controller.orbit(add: label, [.top(16), .leading(16), .trailing(16)])
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview of `self.view`.
    ///   - items: An array of ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(add child: OrbitalView, _ items: [any OrbitalConstraintConvertible]) {
        view.orbit(add: child, items)
    }

    /// Adds multiple child views to the controller's `view` and runs a closure to apply constraints.
    ///
    /// All views are added as subviews of `self.view` (with
    /// `translatesAutoresizingMaskIntoConstraints = false`) before the closure executes.
    /// Inside the closure, use `view.orbital.layout(...)` to set constraints.
    ///
    /// ```swift
    /// controller.orbit(avatar, nameLabel, bioLabel) {
    ///     avatar.orbital.layout(.top(24), .leading(16), .size(80))
    ///     nameLabel.orbital.layout(.top.to(avatar, .top), .leading(12).to(avatar, .trailing))
    ///     bioLabel.orbital.layout(.top(4).to(nameLabel, .bottom), .leading(16), .trailing(16))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - children: One or more views to add as subviews of `self.view`.
    ///   - layout: A closure executed after all children are added. Use it to apply constraints.
    /// - Note: The closure is called on the main actor, synchronously after all `addSubview` calls.
    @MainActor
    func orbit(_ children: OrbitalView..., layout: @MainActor () -> Void) {
        view.orbit(children, layout: layout)
    }

    /// Array-accepting overload of ``orbit(_:layout:)-variadic``.
    ///
    /// Useful when the array of child views is built dynamically.
    ///
    /// ```swift
    /// let subviews: [OrbitalView] = [avatar, nameLabel]
    /// controller.orbit(subviews) {
    ///     avatar.orbital.layout(.top(16), .leading(16))
    ///     nameLabel.orbital.layout(.top.to(avatar, .bottom), .leading(16))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - children: An array of views to add as subviews of `self.view`.
    ///   - layout: A closure executed after all children are added.
    @MainActor
    func orbit(_ children: [OrbitalView], layout: @MainActor () -> Void) {
        view.orbit(children, layout: layout)
    }
}

// MARK: - OrbitalView + orbit(to: controller, ...) overloads

public extension OrbitalView {

    /// Adds this view as a subview of `controller.view` and applies inline constraints.
    ///
    /// Convenience that forwards to ``OrbitalView/orbit(to:_:)-variadic`` with
    /// `controller.view` as the parent.
    ///
    /// ```swift
    /// label.orbit(to: controller, .top(16), .leading(16), .trailing(16))
    /// imageView.orbit(to: controller, .edges(4))
    /// ```
    ///
    /// - Parameters:
    ///   - controller: The view controller whose `view` will receive `self` as a subview.
    ///   - items: One or more ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(to controller: OrbitalViewController, _ items: any OrbitalConstraintConvertible...) {
        orbit(to: controller.view, items)
    }

    /// Array-accepting overload of ``orbit(to:_:)-variadic``.
    ///
    /// Useful when the constraint list is built dynamically.
    ///
    /// ```swift
    /// label.orbit(to: controller, [.top(16), .leading(16), .trailing(16)])
    /// ```
    ///
    /// - Parameters:
    ///   - controller: The view controller whose `view` will receive `self` as a subview.
    ///   - items: An array of ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(to controller: OrbitalViewController, _ items: [any OrbitalConstraintConvertible]) {
        orbit(to: controller.view, items)
    }
}
