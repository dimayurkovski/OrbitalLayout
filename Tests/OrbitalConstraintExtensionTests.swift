import Testing
@testable import OrbitalLayout

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
@Suite("OrbitalConstraint Array Extensions")
struct OrbitalConstraintExtensionTests {

    // MARK: - Helpers

    /// Holds parent/child views alive for the duration of a test.
    private struct ViewHolder {
        let parent: OrbitalView
        let child: OrbitalView
        let constraints: [OrbitalConstraint]
    }

    /// Creates width constraints on a view pair. Caller must hold the returned
    /// ViewHolder to keep parent/child alive while constraints are in use.
    private func makeConstraints(count: Int = 3) -> ViewHolder {
        let parent = OrbitalView()
        let child = OrbitalView()
        parent.addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        let constraints = (1...count).map { value in
            child.widthAnchor.constraint(equalToConstant: CGFloat(value * 10))
        }
        return ViewHolder(parent: parent, child: child, constraints: constraints)
    }

    // MARK: - activate()

    @Test("activate() sets isActive = true on all constraints")
    func activateAll() {
        let holder = makeConstraints()
        let constraints = holder.constraints
        OrbitalConstraint.deactivate(constraints)
        for c in constraints { #expect(c.isActive == false) }

        constraints.activate()

        for c in constraints { #expect(c.isActive == true) }
    }

    @Test("activate() on already-active constraints leaves them active")
    func activateAlreadyActive() {
        let holder = makeConstraints()
        let constraints = holder.constraints
        OrbitalConstraint.activate(constraints)

        constraints.activate()

        for c in constraints { #expect(c.isActive == true) }
    }

    @Test("activate() on empty array does not crash")
    func activateEmpty() {
        let empty: [OrbitalConstraint] = []
        empty.activate()
    }

    // MARK: - deactivate()

    @Test("deactivate() sets isActive = false on all constraints")
    func deactivateAll() {
        let holder = makeConstraints()
        let constraints = holder.constraints
        OrbitalConstraint.activate(constraints)
        for c in constraints { #expect(c.isActive == true) }

        constraints.deactivate()

        for c in constraints { #expect(c.isActive == false) }
    }

    @Test("deactivate() on already-inactive constraints leaves them inactive")
    func deactivateAlreadyInactive() {
        let holder = makeConstraints()
        let constraints = holder.constraints
        for c in constraints { #expect(c.isActive == false) }

        constraints.deactivate()

        for c in constraints { #expect(c.isActive == false) }
    }

    @Test("deactivate() on empty array does not crash")
    func deactivateEmpty() {
        let empty: [OrbitalConstraint] = []
        empty.deactivate()
    }

    // MARK: - Round-trip

    @Test("activate then deactivate round-trip works correctly")
    func roundTrip() {
        let holder = makeConstraints(count: 4)
        let constraints = holder.constraints

        constraints.activate()
        for c in constraints { #expect(c.isActive == true) }

        constraints.deactivate()
        for c in constraints { #expect(c.isActive == false) }

        constraints.activate()
        for c in constraints { #expect(c.isActive == true) }
    }

    @Test("single-element array activate and deactivate")
    func singleElement() {
        let holder = makeConstraints(count: 1)
        let constraints = holder.constraints

        constraints.activate()
        #expect(constraints[0].isActive == true)

        constraints.deactivate()
        #expect(constraints[0].isActive == false)
    }
}
