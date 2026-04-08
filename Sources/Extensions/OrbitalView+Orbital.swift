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

    /// Adds a single child view and applies inline ``OrbitalDescriptor`` constraints, using idiomatic dot-notation.
    ///
    /// Performs the following steps in order:
    /// 1. Sets `child.translatesAutoresizingMaskIntoConstraints = false`
    /// 2. Calls `addSubview(child)`
    /// 3. Activates the given constraints relative to `self`
    ///
    /// ```swift
    /// view.orbit(label, .top(16), .leading(16), .trailing(16))
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - first: The first ``OrbitalDescriptor`` constraint.
    ///   - rest: Additional ``OrbitalDescriptor`` constraints.
    @_disfavoredOverload
    @MainActor
    func orbit(_ child: OrbitalView, _ first: OrbitalDescriptor, _ rest: OrbitalDescriptor...) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout([first] + rest)
    }

    /// Variadic overload accepting group descriptors and mixed ``OrbitalConstraintConvertible`` types.
    ///
    /// Use when passing group shortcuts like `.edges(16)`, `.size(80)`, or `.center()`:
    ///
    /// ```swift
    /// view.orbit(imageView, .edges(4))
    /// view.orbit(avatarView, .size(80), .center())
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - items: One or more ``OrbitalConstraintConvertible`` values (including group descriptors).
    @MainActor
    func orbit(_ child: OrbitalView, _ items: any OrbitalConstraintConvertible...) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout(items)
    }

    /// Variadic overload for ``OrbitalDescriptorGroup`` shortcuts, enabling dot-notation without type prefix.
    ///
    /// Use for group shortcuts like `.edges(16)`, `.size(80)`, `.center()`, or combinations:
    ///
    /// ```swift
    /// view.orbit(imageView, .edges(4))
    /// view.orbit(avatarView, .size(80), .center())
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - groups: One or more ``OrbitalDescriptorGroup`` values.
    @MainActor
    func orbit(_ child: OrbitalView, _ groups: OrbitalDescriptorGroup...) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout(groups)
    }

    /// Array-accepting overload of ``orbit(_:_:)-variadic``.
    ///
    /// Accepts an array of ``OrbitalDescriptor`` values, enabling idiomatic dot-notation:
    ///
    /// ```swift
    /// view.orbit(label, [.top(16), .leading(16), .trailing(16)])
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - items: An array of ``OrbitalDescriptor`` values.
    @MainActor
    func orbit(_ child: OrbitalView, _ items: [OrbitalDescriptor]) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        child.orbital.layout(items)
    }

    /// Array-accepting overload supporting ``OrbitalDescriptorGroup`` values (e.g. `.edges`, `.size`, `.center`).
    ///
    /// Use this overload when the array contains group descriptors or a mix of types:
    ///
    /// ```swift
    /// view.orbit(imageView, [OrbitalDescriptor.edges(4)])
    /// view.orbit(imageView, [OrbitalDescriptor.size(80), OrbitalDescriptor.center()])
    /// ```
    ///
    /// - Parameters:
    ///   - child: The view to add as a subview.
    ///   - items: An array of ``OrbitalConstraintConvertible`` values.
    @MainActor
    func orbit(_ child: OrbitalView, _ items: [any OrbitalConstraintConvertible]) {
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
}
