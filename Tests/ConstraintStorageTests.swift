//
//  ConstraintStorageTests.swift
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

/// Creates a simple active NSLayoutConstraint between two views.
///
/// Both views must share a common ancestor (parent contains child).
@MainActor
private func makeConstraint(parent: OrbitalView, child: OrbitalView) -> OrbitalConstraint {
    parent.addSubview(child)
    child.translatesAutoresizingMaskIntoConstraints = false
    let c = child.topAnchor.constraint(equalTo: parent.topAnchor)
    c.isActive = true
    return c
}

/// Creates an inactive NSLayoutConstraint together with its owner views.
/// Callers must hold the returned views to keep the constraint valid.
@MainActor
private func makeLooseConstraint() -> (constraint: OrbitalConstraint, parent: OrbitalView, child: OrbitalView) {
    let parent = OrbitalView()
    let child = OrbitalView()
    parent.addSubview(child)
    child.translatesAutoresizingMaskIntoConstraints = false
    let c = child.topAnchor.constraint(equalTo: parent.topAnchor)
    return (c, parent, child)
}

// MARK: - Suite

@Suite("ConstraintStorage")
@MainActor
struct ConstraintStorageTests {

    // MARK: - store + get

    @Test func storeAndGetReturnsCorrectConstraint() {
        let storage = ConstraintStorage()
        let (c, _cp1, _cc1) = makeLooseConstraint()
        storage.store(c, for: .top, relation: .equal)
        #expect(storage.get(.top, relation: .equal) === c)
    }

    @Test func getDefaultRelationIsEqual() {
        let storage = ConstraintStorage()
        let (c, _cp2, _cc2) = makeLooseConstraint()
        storage.store(c, for: .leading, relation: .equal)
        // calling get without explicit relation should return the .equal entry
        #expect(storage.get(.leading) === c)
    }

    @Test func getMissingKeyReturnsNil() {
        let storage = ConstraintStorage()
        #expect(storage.get(.top, relation: .equal) == nil)
        #expect(storage.get(.width, relation: .lessOrEqual) == nil)
    }

    // MARK: - Overwrite: old deactivated, new stored

    @Test func overwriteDeactivatesPreviousConstraint() {
        let storage = ConstraintStorage()
        let (c1, _c1p3, _c1c3) = makeLooseConstraint()
        let (c2, _c2p4, _c2c4) = makeLooseConstraint()
        c1.isActive = true

        storage.store(c1, for: .top, relation: .equal)
        storage.store(c2, for: .top, relation: .equal)

        #expect(c1.isActive == false)
        #expect(storage.get(.top, relation: .equal) === c2)
    }

    @Test func storingSameConstraintAgainDoesNotDeactivateIt() {
        // Storing the same object twice should NOT deactivate it (identity check)
        let storage = ConstraintStorage()
        let (c, _cp5, _cc5) = makeLooseConstraint()
        c.isActive = true

        storage.store(c, for: .top, relation: .equal)
        storage.store(c, for: .top, relation: .equal) // same object

        #expect(c.isActive == true)
        #expect(storage.get(.top) === c)
    }

    // MARK: - Different relations on the same anchor coexist

    @Test func differentRelationsSameAnchorCoexist() {
        let storage = ConstraintStorage()
        let (cEqual, _cEp1, _cEc1) = makeLooseConstraint()
        let (cLess, _cLp1, _cLc1)  = makeLooseConstraint()

        storage.store(cEqual, for: .width, relation: .equal)
        storage.store(cLess,  for: .width, relation: .lessOrEqual)

        #expect(storage.get(.width, relation: .equal)        === cEqual)
        #expect(storage.get(.width, relation: .lessOrEqual)  === cLess)
    }

    @Test func differentRelationsDoNotOverwriteEachOther() {
        let storage = ConstraintStorage()
        let (cEqual, _cEp2, _cEc2)     = makeLooseConstraint()
        let (cGreater, _cGp2, _cGc2)   = makeLooseConstraint()
        cEqual.isActive   = true
        cGreater.isActive = true

        storage.store(cEqual,   for: .height, relation: .equal)
        storage.store(cGreater, for: .height, relation: .greaterOrEqual)

        // Neither should have been deactivated by the other
        #expect(cEqual.isActive   == true)
        #expect(cGreater.isActive == true)
    }

    @Test func allThreeRelationsOnSameAnchorCoexist() {
        let storage = ConstraintStorage()
        let (cEq, _cEqp, _cEqc) = makeLooseConstraint()
        let (cLt, _cLtp, _cLtc) = makeLooseConstraint()
        let (cGt, _cGtp, _cGtc) = makeLooseConstraint()

        storage.store(cEq,  for: .width, relation: .equal)
        storage.store(cLt,  for: .width, relation: .lessOrEqual)
        storage.store(cGt,  for: .width, relation: .greaterOrEqual)

        #expect(storage.get(.width, relation: .equal)          === cEq)
        #expect(storage.get(.width, relation: .lessOrEqual)    === cLt)
        #expect(storage.get(.width, relation: .greaterOrEqual) === cGt)
    }

    // MARK: - removeAll

    @Test func removeAllReturnsAllConstraints() {
        let storage = ConstraintStorage()
        let (c1, _c1p8, _c1c8) = makeLooseConstraint()
        let (c2, _c2p9, _c2c9) = makeLooseConstraint()
        let (c3, _c3p10, _c3c10) = makeLooseConstraint()

        storage.store(c1, for: .top,     relation: .equal)
        storage.store(c2, for: .leading, relation: .equal)
        storage.store(c3, for: .width,   relation: .lessOrEqual)

        let all = storage.removeAll()
        #expect(all.count == 3)
        #expect(all.contains(c1))
        #expect(all.contains(c2))
        #expect(all.contains(c3))
    }

    @Test func removeAllEmptiesStorage() {
        let storage = ConstraintStorage()
        let (c, _cp11, _cc11) = makeLooseConstraint()
        storage.store(c, for: .top, relation: .equal)

        _ = storage.removeAll()

        #expect(storage.get(.top) == nil)
    }

    @Test func removeAllOnEmptyStorageReturnsEmptyArray() {
        let storage = ConstraintStorage()
        let result = storage.removeAll()
        #expect(result.isEmpty)
    }

    @Test func removeAllDoesNotDeactivateConstraints() {
        // removeAll returns constraints but does not deactivate them
        let storage = ConstraintStorage()
        let (c, _cp12, _cc12) = makeLooseConstraint()
        c.isActive = true
        storage.store(c, for: .top, relation: .equal)

        _ = storage.removeAll()

        #expect(c.isActive == true)
    }

    // MARK: - orbitalStorage on OrbitalView

    @Test func orbitalStorageCreatedOnFirstAccess() {
        let view = OrbitalView()
        // Just accessing the property must not crash — the returned object is always non-nil
        _ = view.orbitalStorage
    }

    @Test func orbitalStorageReturnsSameInstanceOnRepeatAccess() {
        let view = OrbitalView()
        let s1 = view.orbitalStorage
        let s2 = view.orbitalStorage
        #expect(s1 === s2)
    }

    @Test func differentViewsHaveSeparateStorages() {
        let viewA = OrbitalView()
        let viewB = OrbitalView()
        #expect(viewA.orbitalStorage !== viewB.orbitalStorage)
    }

    @Test func orbitalStoragePersistsConstraints() {
        let view = OrbitalView()
        let (c, _cp13, _cc13) = makeLooseConstraint()
        view.orbitalStorage.store(c, for: .top, relation: .equal)
        // Access storage again through the property — must be the same instance
        #expect(view.orbitalStorage.get(.top) === c)
    }

    // MARK: - Multiple anchors stored independently

    @Test func multipleAnchorsStoredAndRetrievedIndependently() {
        let storage = ConstraintStorage()
        let anchors: [OrbitalAnchor] = [.top, .bottom, .leading, .trailing, .width, .height, .centerX, .centerY]
        var constraints: [OrbitalAnchor: OrbitalConstraint] = [:]
        var retainedViews: [(OrbitalView, OrbitalView)] = []

        for anchor in anchors {
            let (c, p, ch) = makeLooseConstraint()
            retainedViews.append((p, ch))
            constraints[anchor] = c
            storage.store(c, for: anchor, relation: .equal)
        }

        for anchor in anchors {
            #expect(storage.get(anchor, relation: .equal) === constraints[anchor])
        }
        _ = retainedViews
    }
}
