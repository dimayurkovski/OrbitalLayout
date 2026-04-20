//
//  OrbitalView+Orbital.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - OrbitalView + orbital property

public extension OrbitalView {

    /// The OrbitalLayout proxy for this view.
    ///
    /// Use this property to access all constraint-creation, update, and storage APIs
    /// provided by OrbitalLayout.
    ///
    /// ```swift
    /// view.orbital.layout(.top(16), .leading(16), .trailing(16))
    /// view.orbital.heightConstraint?.constant = 300
    /// ```
    @MainActor
    var orbital: OrbitalProxy {
        OrbitalProxy(view: self)
    }
}

// MARK: - OrbitalView + orbit(child:...) overloads

public extension OrbitalView {

    /// Adds a single child view and applies inline constraints (preferred form).
    ///
    /// Performs the following steps in order:
    /// 1. Sets `child.translatesAutoresizingMaskIntoConstraints = false`
    /// 2. Calls `addSubview(child)`
    /// 3. Activates the given constraints relative to `self`
    ///
    /// Accepts any mix of ``OrbitalDescriptor`` anchors and ``OrbitalDescriptorGroup``
    /// shortcuts via leading-dot syntax:
    ///
    /// ```swift
    /// view.orbit(add: label, .top(16), .leading(16), .trailing(16))
    /// view.orbit(add: imageView, .edges(4))
    /// view.orbit(add: avatarView, .size(80), .center())
    /// view.orbit(add: iconView, .leading(8), .centerY(), .size(24))
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - items: One or more ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(add child: OrbitalView, _ items: any OrbitalConstraintConvertible...) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout(items)
    }

    /// Array-accepting overload of ``orbit(add:_:)-variadic``.
    ///
    /// Useful when the constraint list is built dynamically. Accepts descriptors and
    /// group shortcuts in the same array.
    ///
    /// ```swift
    /// view.orbit(add: label, [.top(16), .leading(16), .trailing(16)])
    /// view.orbit(add: imageView, [OrbitalDescriptor.edges(4)])
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - items: An array of ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(add child: OrbitalView, _ items: [any OrbitalConstraintConvertible]) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout(items)
    }

    /// Adds multiple child views and runs a closure to apply constraints.
    ///
    /// All views are added as subviews (with `translatesAutoresizingMaskIntoConstraints = false`)
    /// before the closure executes. Inside the closure, use `view.orbital.layout(...)` to set
    /// constraints. Constraints default to the parent view (`self`) unless `.to(...)` specifies
    /// another target.
    ///
    /// ```swift
    /// view.orbit(avatar, nameLabel, bioLabel) {
    ///     avatar.orbital.layout(.top(24), .leading(16), .size(80))
    ///     nameLabel.orbital.layout(.top.to(avatar, .top), .leading(12).to(avatar, .trailing))
    ///     bioLabel.orbital.layout(.top(4).to(nameLabel, .bottom), .leading(16), .trailing(16))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - children: One or more views to add as subviews.
    ///   - layout: A closure executed after all children are added. Use it to apply constraints.
    /// - Note: The closure is called on the main actor, synchronously after all `addSubview` calls.
    @MainActor
    func orbit(_ children: OrbitalView..., layout: @MainActor () -> Void) {
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }
        layout()
    }

    /// Array-accepting overload of ``orbit(_:layout:)-variadic``.
    ///
    /// Useful when the array of child views is built dynamically.
    ///
    /// ```swift
    /// let subviews: [OrbitalView] = [avatar, nameLabel]
    /// view.orbit(subviews) {
    ///     avatar.orbital.layout(.top(16), .leading(16))
    ///     nameLabel.orbital.layout(.top.to(avatar, .bottom), .leading(16))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - children: An array of views to add as subviews.
    ///   - layout: A closure executed after all children are added.
    @MainActor
    func orbit(_ children: [OrbitalView], layout: @MainActor () -> Void) {
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }
        layout()
    }

    /// Adds this view as a subview of `parent` and applies inline constraints.
    ///
    /// Mirror of ``orbit(_:_:)-variadic`` called from the child's perspective. Performs the
    /// following steps in order:
    /// 1. Sets `self.translatesAutoresizingMaskIntoConstraints = false`
    /// 2. Calls `parent.addSubview(self)`
    /// 3. Activates the given constraints relative to `parent`
    ///
    /// Accepts any mix of ``OrbitalDescriptor`` anchors and ``OrbitalDescriptorGroup``
    /// shortcuts via leading-dot syntax:
    ///
    /// ```swift
    /// avatar.orbit(to: view, .top(16), .leading(16), .size(80))
    /// imageView.orbit(to: view, .edges(4))
    /// ```
    ///
    /// - Parameters:
    ///   - parent: The view that will receive `self` as a subview.
    ///   - items: One or more ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(to parent: OrbitalView, _ items: any OrbitalConstraintConvertible...) {
        translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        orbital.layout(items)
    }

    /// Array-accepting overload of ``orbit(to:_:)-variadic``.
    ///
    /// Useful when the constraint list is built dynamically. Accepts descriptors and
    /// group shortcuts in the same array.
    ///
    /// ```swift
    /// avatar.orbit(to: view, [.top(16), .leading(16), .size(80)])
    /// imageView.orbit(to: view, [OrbitalDescriptor.edges(4)])
    /// ```
    ///
    /// - Parameters:
    ///   - parent: The view that will receive `self` as a subview.
    ///   - items: An array of ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(to parent: OrbitalView, _ items: [any OrbitalConstraintConvertible]) {
        translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        orbital.layout(items)
    }
}
