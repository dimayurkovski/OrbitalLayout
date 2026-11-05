//
//  OrbitalProxyAddTests.swift
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

@MainActor
private func makeController() -> OrbitalViewController {
    let controller = OrbitalViewController()
    controller.view = makeParent()
    return controller
}

// MARK: - OrbitalProxyAddTests

@MainActor
@Suite("OrbitalProxy add Tests")
struct OrbitalProxyAddTests {

    // MARK: - add(_:_:) — variadic

    @Test("add(child, items...) adds child and disables autoresizing mask")
    func addVariadicAttachesChild() {
        let parent = makeParent()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        parent.orbital.add(child, .top(16), .leading(16))
        #expect(child.superview === parent)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("add(child, items...) returns active constraints in declaration order")
    func addVariadicReturnsActiveConstraints() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = parent.orbital.add(child, .top(16), .trailing(16))
        #expect(constraints.count == 2)
        #expect(constraints.allSatisfy { $0.isActive })
        #expect(constraints[0].firstAttribute == .top)
        #expect(constraints[0].constant == 16)
        #expect(constraints[1].firstAttribute == .trailing)
        #expect(constraints[1].constant == -16)
    }

    @Test("add(child, items...) constrains the child to the receiver")
    func addVariadicConstrainsChildToParent() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = parent.orbital.add(child, .top(16))
        #expect(constraints[0].firstItem === child)
        #expect(constraints[0].secondItem === parent)
    }

    @Test("add(child, items...) stores constraints on the child, not the receiver")
    func addVariadicStoresOnChild() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = parent.orbital.add(child, .top(16))
        #expect(child.orbital.topConstraint === constraints[0])
        #expect(parent.orbital.topConstraint == nil)
    }

    @Test("add(child, items...) expands group shortcuts")
    func addVariadicExpandsGroups() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = parent.orbital.add(child, .edges(4))
        #expect(constraints.count == 4)
    }

    @Test("add(child) without items only attaches the child")
    func addVariadicWithoutItems() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = parent.orbital.add(child)
        #expect(child.superview === parent)
        #expect(constraints.isEmpty)
    }

    // MARK: - add(_:_:) — array

    @Test("add(child, [items]) attaches child and returns active constraints")
    func addArrayAttachesChild() {
        let parent = makeParent()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        let constraints = parent.orbital.add(child, [.top(16), .leading(16), .trailing(16)])
        #expect(child.superview === parent)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
        #expect(constraints.count == 3)
        #expect(constraints.allSatisfy { $0.isActive })
    }

    // MARK: - add(to:_:) — variadic

    @Test("add(to: parent, items...) attaches receiver's view to parent")
    func addToVariadicAttachesView() {
        let parent = makeParent()
        let child = OrbitalView()
        child.translatesAutoresizingMaskIntoConstraints = true
        let constraints = child.orbital.add(to: parent, .top(16), .bottom(16))
        #expect(child.superview === parent)
        #expect(child.translatesAutoresizingMaskIntoConstraints == false)
        #expect(constraints.count == 2)
        #expect(constraints[0].secondItem === parent)
        #expect(constraints[1].constant == -16)
        #expect(child.orbital.bottomConstraint === constraints[1])
    }

    // MARK: - add(to:_:) — array

    @Test("add(to: parent, [items]) attaches receiver's view to parent")
    func addToArrayAttachesView() {
        let parent = makeParent()
        let child = OrbitalView()
        let constraints = child.orbital.add(to: parent, [.top(16), .leading(16), .trailing(16)])
        #expect(child.superview === parent)
        #expect(constraints.count == 3)
        #expect(constraints.allSatisfy { $0.isActive })
    }

    // MARK: - add(_:layout:)

    @Test("add(children..., layout:) attaches every child before running the closure")
    func addVariadicChildrenRunsClosureAfterAttach() {
        let parent = makeParent()
        let first = OrbitalView()
        let second = OrbitalView()
        var attachedBeforeClosure = false
        parent.orbital.add(first, second) {
            attachedBeforeClosure = first.superview === parent && second.superview === parent
            first.orbital.layout(.top(8))
            second.orbital.layout(.top(8).to(first, .bottom))
        }
        #expect(attachedBeforeClosure)
        #expect(first.translatesAutoresizingMaskIntoConstraints == false)
        #expect(second.translatesAutoresizingMaskIntoConstraints == false)
        #expect(second.orbital.topConstraint?.secondItem === first)
    }

    @Test("add([children], layout:) attaches every child before running the closure")
    func addArrayChildrenRunsClosureAfterAttach() {
        let parent = makeParent()
        let children = [OrbitalView(), OrbitalView()]
        var attachedBeforeClosure = false
        parent.orbital.add(children) {
            attachedBeforeClosure = children.allSatisfy { $0.superview === parent }
        }
        #expect(attachedBeforeClosure)
        #expect(children.allSatisfy { !$0.translatesAutoresizingMaskIntoConstraints })
    }

    // MARK: - add(to: controller, ...)

    @Test("add(to: controller, items...) attaches receiver's view to controller.view")
    func addToControllerVariadic() {
        let controller = makeController()
        let child = OrbitalView()
        let constraints = child.orbital.add(to: controller, .top(16), .leading(16))
        #expect(child.superview === controller.view)
        #expect(constraints.count == 2)
        #expect(constraints.allSatisfy { $0.isActive })
    }

    @Test("add(to: controller, [items]) attaches receiver's view to controller.view")
    func addToControllerArray() {
        let controller = makeController()
        let child = OrbitalView()
        let constraints = child.orbital.add(to: controller, [.top(16), .leading(16), .trailing(16)])
        #expect(child.superview === controller.view)
        #expect(constraints.count == 3)
    }
}
