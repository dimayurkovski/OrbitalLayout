//
//  OrbitalAnchorTests.swift
//  OrbitalLayoutTests
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

import Testing
@testable import OrbitalLayout

@Suite("OrbitalAnchor")
struct OrbitalAnchorTests {

    // MARK: — Individual cases

    @Test func topCase() { _ = OrbitalAnchor.top }
    @Test func bottomCase() { _ = OrbitalAnchor.bottom }
    @Test func leadingCase() { _ = OrbitalAnchor.leading }
    @Test func trailingCase() { _ = OrbitalAnchor.trailing }
    @Test func leftCase() { _ = OrbitalAnchor.left }
    @Test func rightCase() { _ = OrbitalAnchor.right }
    @Test func centerXCase() { _ = OrbitalAnchor.centerX }
    @Test func centerYCase() { _ = OrbitalAnchor.centerY }
    @Test func widthCase() { _ = OrbitalAnchor.width }
    @Test func heightCase() { _ = OrbitalAnchor.height }

    // MARK: — Equality (every case == itself, != a different case)

    @Test func equalitySameCase() {
        #expect(OrbitalAnchor.top == .top)
        #expect(OrbitalAnchor.bottom == .bottom)
        #expect(OrbitalAnchor.leading == .leading)
        #expect(OrbitalAnchor.trailing == .trailing)
        #expect(OrbitalAnchor.left == .left)
        #expect(OrbitalAnchor.right == .right)
        #expect(OrbitalAnchor.centerX == .centerX)
        #expect(OrbitalAnchor.centerY == .centerY)
        #expect(OrbitalAnchor.width == .width)
        #expect(OrbitalAnchor.height == .height)
    }

    @Test func inequalityDifferentCases() {
        #expect(OrbitalAnchor.top != .bottom)
        #expect(OrbitalAnchor.leading != .trailing)
        #expect(OrbitalAnchor.left != .right)
        #expect(OrbitalAnchor.centerX != .centerY)
        #expect(OrbitalAnchor.width != .height)
        #expect(OrbitalAnchor.top != .width)
    }

    // MARK: — Hashable: all 10 base cases are distinct in a Set

    @Test func allBaseCasesHashableAndDistinct() {
        let set: Set<OrbitalAnchor> = [
            .top, .bottom, .leading, .trailing,
            .left, .right, .centerX, .centerY,
            .width, .height
        ]
        #expect(set.count == 10)
    }

    @Test func duplicatesCollapsedInSet() {
        var set = Set<OrbitalAnchor>()
        set.insert(.top)
        set.insert(.top)
        set.insert(.leading)
        #expect(set.count == 2)
    }

    // MARK: — Baseline (UIKit only)

#if canImport(UIKit)
    @Test func firstBaselineCase() { _ = OrbitalAnchor.firstBaseline }
    @Test func lastBaselineCase() { _ = OrbitalAnchor.lastBaseline }

    @Test func baselineEqualitySameCase() {
        #expect(OrbitalAnchor.firstBaseline == .firstBaseline)
        #expect(OrbitalAnchor.lastBaseline == .lastBaseline)
    }

    @Test func baselineInequalityDifferentCases() {
        #expect(OrbitalAnchor.firstBaseline != .lastBaseline)
        #expect(OrbitalAnchor.firstBaseline != .top)
        #expect(OrbitalAnchor.lastBaseline != .bottom)
    }

    @Test func baselineCasesDistinctInSet() {
        let set: Set<OrbitalAnchor> = [.firstBaseline, .lastBaseline]
        #expect(set.count == 2)
    }

    @Test func allCasesIncludingBaselineDistinct() {
        let set: Set<OrbitalAnchor> = [
            .top, .bottom, .leading, .trailing,
            .left, .right, .centerX, .centerY,
            .width, .height, .firstBaseline, .lastBaseline
        ]
        #expect(set.count == 12)
    }
#endif
}
