//
//  OrbitalRelationTests.swift
//  OrbitalLayoutTests
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Testing
@testable import OrbitalLayout

@Suite("OrbitalRelation")
struct OrbitalRelationTests {

    @Test func allCasesExist() {
        let relations: [OrbitalRelation] = [.equal, .lessOrEqual, .greaterOrEqual]
        #expect(relations.count == 3)
    }

    @Test func isHashable() {
        var set = Set<OrbitalRelation>()
        set.insert(.equal)
        set.insert(.equal)
        set.insert(.lessOrEqual)
        set.insert(.greaterOrEqual)
        #expect(set.count == 3)
    }

    @Test func equality() {
        #expect(OrbitalRelation.equal == OrbitalRelation.equal)
        #expect(OrbitalRelation.lessOrEqual != OrbitalRelation.greaterOrEqual)
    }
}
