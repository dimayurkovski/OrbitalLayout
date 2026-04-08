//
//  OrbitalPriorityTests.swift
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

@Suite("OrbitalPriority")
struct OrbitalPriorityTests {

    @Test func requiredConvertsTo1000() {
        #expect(OrbitalPriority.required.layoutPriority == OrbitalLayoutPriority(1000))
    }

    @Test func highConvertsTo750() {
        #expect(OrbitalPriority.high.layoutPriority == OrbitalLayoutPriority(750))
    }

    @Test func lowConvertsTo250() {
        #expect(OrbitalPriority.low.layoutPriority == OrbitalLayoutPriority(250))
    }

    @Test func customConvertsToRawValue() {
        #expect(OrbitalPriority.custom(600).layoutPriority == OrbitalLayoutPriority(600))
        #expect(OrbitalPriority.custom(1).layoutPriority == OrbitalLayoutPriority(1))
        #expect(OrbitalPriority.custom(999).layoutPriority == OrbitalLayoutPriority(999))
    }
}
