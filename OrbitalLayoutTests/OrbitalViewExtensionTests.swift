//
//  OrbitalViewExtensionTests.swift
//  OrbitalLayoutTests
//

import Testing
@testable import OrbitalLayout

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Helpers

@MainActor
private func makeParent() -> OrbitalView {
    OrbitalView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
}

// MARK: - OrbitalViewExtensionTests

@MainActor
@Suite("OrbitalView Extension Tests")
struct OrbitalViewExtensionTests {

    // MARK: - orbital property

    @Test("orbital property returns an OrbitalProxy bound to the view")
    func orbitalPropertyReturnsBoundProxy() {
        let view = OrbitalView()
        let proxy = view.orbital
        #expect(proxy.view === view)
    }

    @Test("orbital property creates a new proxy each time (no caching needed)")
    func orbitalPropertyCreatesNewProxy() {
        let view = OrbitalView()
        let p1 = view.orbital
        let p2 = view.orbital
        // Both point to the same view — identity of proxy objects may differ,
        // but what matters is the view reference is consistent.
        #expect(p1.view === view)
        #expect(p2.view === view)
    }

    // MARK: - orbit(_:items...) — variadic

    @Test("orbit(_:items) adds child as subview")
    func oritalSingleChildAddsSubview() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, .top(16))
        #expect(child.superview === parent)
    }

    @Test("orbit(_:items) disables translatesAutoresizingMaskIntoConstraints")
    func orbitalSingleChildDisablesTranslates() {
        let parent = makeParent()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        parent.orbit(child, .top(16))
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("orbit(_:items) activates constraints on child")
    func orbitalSingleChildActivatesConstraints() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, .top(16), .leading(16), .trailing(16))
        #expect(child.orbital.topConstraint != nil)
        #expect(child.orbital.leadingConstraint != nil)
        #expect(child.orbital.trailingConstraint != nil)
    }

    @Test("orbit(_:items) with .edges creates 4 constraints")
    func orbitalSingleChildEdges() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, .edges(4))
        #expect(child.orbital.topConstraint != nil)
        #expect(child.orbital.bottomConstraint != nil)
        #expect(child.orbital.leadingConstraint != nil)
        #expect(child.orbital.trailingConstraint != nil)
    }

    @Test("orbit(_:items) with .size and .center creates width, height, and center constraints")
    func orbitalSingleChildSize() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, .size(80), .center())
        #expect(child.orbital.widthConstraint?.constant == 80)
        #expect(child.orbital.heightConstraint?.constant == 80)
        #expect(child.orbital.centerXConstraint != nil)
        #expect(child.orbital.centerYConstraint != nil)
    }

    // MARK: - orbit(_:items:[]) — array

    @Test("orbit(_:array) adds child as subview")
    func orbitalArrayAddsSubview() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, [.top(16), .leading(16)])
        #expect(child.superview === parent)
    }

    @Test("orbit(_:array) disables translatesAutoresizingMaskIntoConstraints")
    func orbitalArrayDisablesTranslates() {
        let parent = makeParent()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        parent.orbit(child, [.top(16)])
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("orbit(_:array) activates constraints on child")
    func orbitalArrayActivatesConstraints() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, [.top(16), .leading(16), .trailing(16)])
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint != nil)
    }

    // MARK: - orbit(_:layout:) — variadic children + closure

    @Test("orbit(children..., layout:) adds all children as subviews")
    func orbitalMultipleChildrenAddsAll() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        parent.orbit(child1, child2) {
            child1.orbital.layout(.top(8), .leading(16))
            child2.orbital.layout(.top(8).to(child1, .bottom), .leading(16))
        }
        #expect(child1.superview === parent)
        #expect(child2.superview === parent)
    }

    @Test("orbit(children..., layout:) disables translatesAutoresizing for all children")
    func orbitalMultipleChildrenDisablesTranslates() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        child1.translatesAutoresizingMaskIntoConstraints = true
        child2.translatesAutoresizingMaskIntoConstraints = true
        parent.orbit(child1, child2) {}
        #expect(child1.translatesAutoresizingMaskIntoConstraints == false)
        #expect(child2.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("orbit(children..., layout:) executes closure after subview is added")
    func orbitalMultipleChildrenClosureRunsAfterAdd() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        var closureRan = false
        parent.orbit(child1, child2) {
            // Both are already subviews when closure runs
            closureRan = true
            #expect(child1.superview === parent)
            #expect(child2.superview === parent)
        }
        #expect(closureRan)
    }

    @Test("orbit(children..., layout:) constraints set in closure are active")
    func orbitalMultipleChildrenConstraintsActive() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        parent.orbit(child1, child2) {
            child1.orbital.layout(.top(16), .leading(16))
            child2.orbital.layout(.top(8).to(child1, .bottom), .trailing(16))
        }
        #expect(child1.orbital.topConstraint?.constant == 16)
        #expect(child1.orbital.leadingConstraint?.constant == 16)
        #expect(child2.orbital.topConstraint?.constant == 8)
        #expect(child2.orbital.trailingConstraint != nil)
    }

    @Test("orbit(child) { layout(.edges(inset)) } — leading-dot group inside closure")
    func orbitalSingleChildEdgesInsideClosure() {
        // Regression: `.edges(1)` inside the orbit trailing closure must resolve
        // to OrbitalDescriptorGroup via the group variadic overload of `layout(_:)`.
        let parent = makeParent()
        let container = OrbitalView()
        parent.orbit(container) {
            container.orbital.layout(.edges(1))
        }
        #expect(container.superview === parent)
        #expect(container.translatesAutoresizingMaskIntoConstraints == false)
        #expect(container.orbital.topConstraint?.constant == 1)
        #expect(container.orbital.leadingConstraint?.constant == 1)
        #expect(container.orbital.bottomConstraint?.constant == -1)
        #expect(container.orbital.trailingConstraint?.constant == -1)
        #expect(container.orbital.topConstraint?.isActive == true)
    }

    @Test("orbit(child) { layout(.edges) } — flush leading-dot group inside closure")
    func orbitalSingleChildEdgesFlushInsideClosure() {
        let parent = makeParent()
        let container = OrbitalView()
        parent.orbit(container) {
            container.orbital.layout(.edges)
        }
        #expect(container.orbital.topConstraint?.constant == 0)
        #expect(container.orbital.bottomConstraint?.constant == 0)
        #expect(container.orbital.leadingConstraint?.constant == 0)
        #expect(container.orbital.trailingConstraint?.constant == 0)
    }

    // MARK: - orbit([children], layout:) — array children + closure

    @Test("orbit(array, layout:) adds all children as subviews")
    func orbitalArrayChildrenAddsAll() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        let children: [OrbitalView] = [child1, child2]
        parent.orbit(children) {
            child1.orbital.layout(.top(8), .leading(16))
            child2.orbital.layout(.leading(16), .bottom(8))
        }
        #expect(child1.superview === parent)
        #expect(child2.superview === parent)
    }

    @Test("orbit(array, layout:) disables translatesAutoresizing for all children")
    func orbitalArrayChildrenDisablesTranslates() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        child1.translatesAutoresizingMaskIntoConstraints = true
        child2.translatesAutoresizingMaskIntoConstraints = true
        let children: [OrbitalView] = [child1, child2]
        parent.orbit(children) {}
        #expect(child1.translatesAutoresizingMaskIntoConstraints == false)
        #expect(child2.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("orbit(array, layout:) executes closure and constraints are active")
    func orbitalArrayChildrenConstraintsActive() {
        let parent = makeParent()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        let children: [OrbitalView] = [child1, child2]
        parent.orbit(children) {
            child1.orbital.layout(.top(16), .leading(16))
            child2.orbital.layout(.bottom(16), .trailing(16))
        }
        #expect(child1.orbital.topConstraint?.constant == 16)
        #expect(child2.orbital.bottomConstraint != nil)
    }

    // MARK: - orbit(_:items) with no constraints (empty)

    @Test("orbit(_:items) with no descriptors still adds child")
    func orbitalNoDescriptorsStillAddsChild() {
        let parent = makeParent()
        let child = OrbitalView()
        // Empty array — child should be added even without constraints
        let empty: [OrbitalDescriptor] = []
        parent.orbit(child, empty)
        #expect(child.superview === parent)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    // MARK: - Dot-notation type inference (matches documented API style)

    /// Verifies the idiomatic API style from the documentation:
    /// `view.orbit(label, .top(16), .leading(16), .trailing(16))`
    @Test("orbit(_:items) using dot-notation — no explicit OrbitalDescriptor prefix needed")
    func orbitalDotNotationVariadic() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, .top(16), .leading(16), .trailing(16))
        #expect(child.superview === parent)
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    /// Verifies array form with multiple dot-notation descriptors:
    /// `view.orbit(label, [.top(16), .leading(16), .trailing(16)])`
    @Test("orbit(_:array) dot-notation — [.top(16), .leading(16), .trailing(16)]")
    func orbitalArrayDotNotationMultiple() {
        let parent = makeParent()
        let child = OrbitalView()
        parent.orbit(child, [.top(16), .leading(16), .trailing(16)])
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    /// Verifies group descriptors (`.edges`, `.size`, `.center`) work via the convertible overload.
    /// Groups return `OrbitalDescriptorGroup`, not `OrbitalDescriptor`, so they use the
    /// `[any OrbitalConstraintConvertible]` overload.
    @Test("orbit(_:array) group descriptor via [any OrbitalConstraintConvertible]")
    func orbitalArrayGroupDescriptor() {
        let parent = makeParent()
        let child = OrbitalView()
        let items: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.edges(8)]
        parent.orbit(child, items)
        #expect(child.orbital.topConstraint?.constant == 8)
        #expect(child.orbital.bottomConstraint?.constant == -8)
        #expect(child.orbital.leadingConstraint?.constant == 8)
        #expect(child.orbital.trailingConstraint?.constant == -8)
    }
}
