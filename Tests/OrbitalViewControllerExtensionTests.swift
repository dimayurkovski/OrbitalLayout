//
//  OrbitalViewControllerExtensionTests.swift
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
private func makeController() -> OrbitalViewController {
    let controller = OrbitalViewController()
    controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
    return controller
}

// MARK: - OrbitalViewControllerExtensionTests

@MainActor
@Suite("OrbitalViewController Extension Tests")
struct OrbitalViewControllerExtensionTests {

    // MARK: - orbit(add:items...) — variadic

    @Test("controller.orbit(add:items) adds child as subview of controller.view")
    func orbitAddVariadicAddsSubview() {
        let controller = makeController()
        let child = OrbitalView()
        controller.orbit(add: child, .top(16))
        #expect(child.superview === controller.view)
    }

    @Test("controller.orbit(add:items) disables translatesAutoresizingMaskIntoConstraints")
    func orbitAddVariadicDisablesTranslates() {
        let controller = makeController()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        controller.orbit(add: child, .top(16))
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("controller.orbit(add:items) activates constraints")
    func orbitAddVariadicActivatesConstraints() {
        let controller = makeController()
        let child = OrbitalView()
        controller.orbit(add: child, .top(16), .leading(16), .trailing(16))
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    @Test("controller.orbit(add:items) with .edges group descriptor")
    func orbitAddVariadicEdgesGroup() {
        let controller = makeController()
        let child = OrbitalView()
        controller.orbit(add: child, .edges(8))
        #expect(child.orbital.topConstraint?.constant == 8)
        #expect(child.orbital.bottomConstraint?.constant == -8)
        #expect(child.orbital.leadingConstraint?.constant == 8)
        #expect(child.orbital.trailingConstraint?.constant == -8)
    }

    // MARK: - orbit(add:items) — array

    @Test("controller.orbit(add:array) adds child as subview of controller.view")
    func orbitAddArrayAddsSubview() {
        let controller = makeController()
        let child = OrbitalView()
        controller.orbit(add: child, [.top(16), .leading(16)])
        #expect(child.superview === controller.view)
    }

    @Test("controller.orbit(add:array) disables translatesAutoresizingMaskIntoConstraints")
    func orbitAddArrayDisablesTranslates() {
        let controller = makeController()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        controller.orbit(add: child, [.top(16)])
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("controller.orbit(add:array) activates constraints")
    func orbitAddArrayActivatesConstraints() {
        let controller = makeController()
        let child = OrbitalView()
        controller.orbit(add: child, [.top(16), .leading(16), .trailing(16)])
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    @Test("controller.orbit(add:array) with empty array still adds child")
    func orbitAddArrayEmptyStillAddsChild() {
        let controller = makeController()
        let child = OrbitalView()
        let empty: [OrbitalDescriptor] = []
        controller.orbit(add: child, empty)
        #expect(child.superview === controller.view)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("controller.orbit(add:array) group descriptor via [any OrbitalConstraintConvertible]")
    func orbitAddArrayGroupDescriptor() {
        let controller = makeController()
        let child = OrbitalView()
        let items: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.edges(8)]
        controller.orbit(add: child, items)
        #expect(child.orbital.topConstraint?.constant == 8)
        #expect(child.orbital.bottomConstraint?.constant == -8)
        #expect(child.orbital.leadingConstraint?.constant == 8)
        #expect(child.orbital.trailingConstraint?.constant == -8)
    }

    // MARK: - orbit(_:layout:) — variadic children + closure

    @Test("controller.orbit(children..., layout:) adds all children as subviews of controller.view")
    func orbitMultipleChildrenVariadicAddsAll() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        controller.orbit(child1, child2) {
            child1.orbital.layout(.top(8), .leading(16))
            child2.orbital.layout(.top(8).to(child1, .bottom), .leading(16))
        }
        #expect(child1.superview === controller.view)
        #expect(child2.superview === controller.view)
    }

    @Test("controller.orbit(children..., layout:) disables translatesAutoresizing for all children")
    func orbitMultipleChildrenVariadicDisablesTranslates() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        child1.translatesAutoresizingMaskIntoConstraints = true
        child2.translatesAutoresizingMaskIntoConstraints = true
        controller.orbit(child1, child2) {}
        #expect(child1.translatesAutoresizingMaskIntoConstraints == false)
        #expect(child2.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("controller.orbit(children..., layout:) executes closure after subviews are added")
    func orbitMultipleChildrenVariadicClosureRunsAfterAdd() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        var closureRan = false
        controller.orbit(child1, child2) {
            closureRan = true
            #expect(child1.superview === controller.view)
            #expect(child2.superview === controller.view)
        }
        #expect(closureRan)
    }

    @Test("controller.orbit(children..., layout:) constraints set in closure are active")
    func orbitMultipleChildrenVariadicConstraintsActive() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        controller.orbit(child1, child2) {
            child1.orbital.layout(.top(16), .leading(16))
            child2.orbital.layout(.top(8).to(child1, .bottom), .trailing(16))
        }
        #expect(child1.orbital.topConstraint?.constant == 16)
        #expect(child1.orbital.leadingConstraint?.constant == 16)
        #expect(child2.orbital.topConstraint?.constant == 8)
        #expect(child2.orbital.trailingConstraint != nil)
    }

    // MARK: - orbit([children], layout:) — array children + closure

    @Test("controller.orbit(array, layout:) adds all children as subviews of controller.view")
    func orbitArrayChildrenAddsAll() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        let children: [OrbitalView] = [child1, child2]
        controller.orbit(children) {
            child1.orbital.layout(.top(8), .leading(16))
            child2.orbital.layout(.leading(16), .bottom(8))
        }
        #expect(child1.superview === controller.view)
        #expect(child2.superview === controller.view)
    }

    @Test("controller.orbit(array, layout:) disables translatesAutoresizing for all children")
    func orbitArrayChildrenDisablesTranslates() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        child1.translatesAutoresizingMaskIntoConstraints = true
        child2.translatesAutoresizingMaskIntoConstraints = true
        let children: [OrbitalView] = [child1, child2]
        controller.orbit(children) {}
        #expect(child1.translatesAutoresizingMaskIntoConstraints == false)
        #expect(child2.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("controller.orbit(array, layout:) executes closure and constraints are active")
    func orbitArrayChildrenConstraintsActive() {
        let controller = makeController()
        let child1 = OrbitalView()
        let child2 = OrbitalView()
        let children: [OrbitalView] = [child1, child2]
        controller.orbit(children) {
            child1.orbital.layout(.top(16), .leading(16))
            child2.orbital.layout(.bottom(16), .trailing(16))
        }
        #expect(child1.orbital.topConstraint?.constant == 16)
        #expect(child2.orbital.bottomConstraint != nil)
    }

    // MARK: - orbit(to: controller, ...) — child-side variadic

    @Test("child.orbit(to: controller, items) adds self as subview of controller.view")
    func orbitToControllerVariadicAddsSubview() {
        let controller = makeController()
        let child = OrbitalView()
        child.orbit(to: controller, .top(16))
        #expect(child.superview === controller.view)
    }

    @Test("child.orbit(to: controller, items) disables translatesAutoresizingMaskIntoConstraints")
    func orbitToControllerVariadicDisablesTranslates() {
        let controller = makeController()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        child.orbit(to: controller, .top(16))
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("child.orbit(to: controller, items) activates constraints on self")
    func orbitToControllerVariadicActivatesConstraints() {
        let controller = makeController()
        let child = OrbitalView()
        child.orbit(to: controller, .top(16), .leading(16), .trailing(16))
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    @Test("child.orbit(to: controller) with .size and .center")
    func orbitToControllerVariadicSizeCenter() {
        let controller = makeController()
        let child = OrbitalView()
        child.orbit(to: controller, .size(80), .center())
        #expect(child.orbital.widthConstraint?.constant == 80)
        #expect(child.orbital.heightConstraint?.constant == 80)
        #expect(child.orbital.centerXConstraint != nil)
        #expect(child.orbital.centerYConstraint != nil)
    }

    // MARK: - orbit(to: controller, ...) — child-side array

    @Test("child.orbit(to: controller, array) adds self as subview of controller.view")
    func orbitToControllerArrayAddsSubview() {
        let controller = makeController()
        let child = OrbitalView()
        child.orbit(to: controller, [.top(16), .leading(16)])
        #expect(child.superview === controller.view)
    }

    @Test("child.orbit(to: controller, array) disables translatesAutoresizingMaskIntoConstraints")
    func orbitToControllerArrayDisablesTranslates() {
        let controller = makeController()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        child.orbit(to: controller, [.top(16)])
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("child.orbit(to: controller, array) activates constraints on self")
    func orbitToControllerArrayActivatesConstraints() {
        let controller = makeController()
        let child = OrbitalView()
        child.orbit(to: controller, [.top(16), .leading(16), .trailing(16)])
        #expect(child.orbital.topConstraint?.constant == 16)
        #expect(child.orbital.leadingConstraint?.constant == 16)
        #expect(child.orbital.trailingConstraint?.constant == -16)
    }

    @Test("child.orbit(to: controller, array) with empty array still adds child")
    func orbitToControllerArrayEmptyStillAddsChild() {
        let controller = makeController()
        let child = OrbitalView()
        let empty: [OrbitalDescriptor] = []
        child.orbit(to: controller, empty)
        #expect(child.superview === controller.view)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("child.orbit(to: controller, array) group descriptor via [any OrbitalConstraintConvertible]")
    func orbitToControllerArrayGroupDescriptor() {
        let controller = makeController()
        let child = OrbitalView()
        let items: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.edges(8)]
        child.orbit(to: controller, items)
        #expect(child.orbital.topConstraint?.constant == 8)
        #expect(child.orbital.bottomConstraint?.constant == -8)
        #expect(child.orbital.leadingConstraint?.constant == 8)
        #expect(child.orbital.trailingConstraint?.constant == -8)
    }

    // MARK: - Reparenting

    @Test("controller.orbit(add:) on child already in another parent — child is reparented")
    func orbitAddReparentsChild() {
        let controller1 = makeController()
        let controller2 = makeController()
        let child = OrbitalView()
        controller1.orbit(add: child, [.top(8)])
        #expect(child.superview === controller1.view)
        controller2.orbit(add: child, [.leading(8)])
        #expect(child.superview === controller2.view)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("child.orbit(to: controller) on child already in another parent — child is reparented")
    func orbitToControllerReparentsChild() {
        let controller1 = makeController()
        let controller2 = makeController()
        let child = OrbitalView()
        child.orbit(to: controller1, [.top(8)])
        #expect(child.superview === controller1.view)
        child.orbit(to: controller2, [.leading(8)])
        #expect(child.superview === controller2.view)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }
}
