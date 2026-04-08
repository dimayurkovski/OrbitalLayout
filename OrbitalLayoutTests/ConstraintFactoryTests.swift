//
//  ConstraintFactoryTests.swift
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
private func makeViewPair() -> (parent: OrbitalView, child: OrbitalView) {
    let parent = OrbitalView()
    let child = OrbitalView()
    parent.addSubview(child)
    child.translatesAutoresizingMaskIntoConstraints = false
    return (parent, child)
}

@MainActor
private func make(_ descriptor: OrbitalDescriptor, for view: OrbitalView) -> OrbitalConstraint {
    ConstraintFactory.make(from: descriptor, for: view)
}

// MARK: - Test Suite

@MainActor
@Suite("ConstraintFactory")
struct ConstraintFactoryTests {

    // MARK: - Basic constraints

    @Test("top(16) to superview — constant and anchors correct")
    func topToSuperview() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(16), for: child)
        #expect(c.constant == 16)
        #expect(c.isActive == false)
        #expect(c.firstAttribute == .top)
        #expect(c.secondAttribute == .top)
        #expect(c.relation == .equal)
    }

    @Test("leading(8) to superview")
    func leadingToSuperview() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.leading(8), for: child)
        #expect(c.constant == 8)
        #expect(c.firstAttribute == .leading)
        #expect(c.secondAttribute == .leading)
    }

    @Test("height(200) — constant-only dimension constraint, no second item")
    func heightConstantOnly() {
        let view = OrbitalView()
        let c = make(.height(200), for: view)
        #expect(c.constant == 200)
        #expect(c.firstAttribute == .height)
        #expect(c.secondItem == nil)
    }

    @Test("width(100) — constant-only dimension constraint, no second item")
    func widthConstantOnly() {
        let view = OrbitalView()
        let c = make(.width(100), for: view)
        #expect(c.constant == 100)
        #expect(c.firstAttribute == .width)
        #expect(c.secondItem == nil)
    }

    // MARK: - Cross-view constraints

    @Test("top(8).to(header, .bottom) — cross-view, positive constant")
    func topToOtherViewBottom() {
        let (parent, child) = makeViewPair()
        let header = OrbitalView()
        parent.addSubview(header)
        let c = make(.top(8).to(header, .bottom), for: child)
        #expect(c.constant == 8)
        #expect(c.firstItem === child)
        #expect(c.secondItem === header)
        #expect(c.firstAttribute == .top)
        #expect(c.secondAttribute == .bottom)
    }

    @Test("leading(8).to(avatar, .trailing) — cross-anchor, constant positive")
    func leadingToTrailing() {
        let (parent, child) = makeViewPair()
        let avatar = OrbitalView()
        parent.addSubview(avatar)
        let c = make(.leading(8).to(avatar, .trailing), for: child)
        #expect(c.constant == 8)
        #expect(c.firstAttribute == .leading)
        #expect(c.secondAttribute == .trailing)
        #expect(c.secondItem === avatar)
    }

    @Test("width.to(otherView) — inferred width anchor")
    func widthToOtherViewInferred() {
        let (parent, child) = makeViewPair()
        let other = OrbitalView()
        parent.addSubview(other)
        let c = make(.width.to(other), for: child)
        #expect(c.constant == 0)
        #expect(c.firstAttribute == .width)
        #expect(c.secondAttribute == .width)
        #expect(c.secondItem === other)
    }

    @Test("width.to(otherView, .height) — cross-dimension")
    func widthToOtherViewHeight() {
        let (parent, child) = makeViewPair()
        let other = OrbitalView()
        parent.addSubview(other)
        let c = make(.width.to(other, .height), for: child)
        #expect(c.firstAttribute == .width)
        #expect(c.secondAttribute == .height)
    }

    // MARK: - Auto-negation (sign convention)

    @Test("trailing(16) → constant = -16 (auto-negated)")
    func trailingAutoNegated() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.trailing(16), for: child)
        #expect(c.constant == -16)
    }

    @Test("bottom(16) → constant = -16 (auto-negated)")
    func bottomAutoNegated() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.bottom(16), for: child)
        #expect(c.constant == -16)
    }

    @Test("right(8) → constant = -8 (auto-negated)")
    func rightAutoNegated() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.right(8), for: child)
        #expect(c.constant == -8)
    }

    @Test("trailing(16) to superview via explicit .to() → still auto-negated")
    func trailingSameEdgeExplicitTarget() {
        let (parent, child) = makeViewPair()
        let c = make(.trailing(16).to(parent, .trailing), for: child)
        #expect(c.constant == -16)
    }

    @Test("bottom(16).to(safeArea, .bottom) → auto-negated")
    func bottomToSafeAreaBottomAutoNegated() {
        let (parent, child) = makeViewPair()
        #if canImport(UIKit)
        let guide = parent.safeAreaLayoutGuide
        #else
        let guide = parent.layoutMarginsGuide
        #endif
        let c = make(.bottom(16).to(guide, .bottom), for: child)
        #expect(c.constant == -16)
    }

    // MARK: - Cross-anchor (no auto-negation)

    @Test("bottom(16).to(header, .top) → cross-anchor, constant positive")
    func bottomToHeaderTop() {
        let (parent, child) = makeViewPair()
        let header = OrbitalView()
        parent.addSubview(header)
        let c = make(.bottom(16).to(header, .top), for: child)
        #expect(c.constant == 16)
        #expect(c.firstAttribute == .bottom)
        #expect(c.secondAttribute == .top)
    }

    @Test("trailing(8).to(avatar, .leading) → cross-anchor, constant positive")
    func trailingToLeading() {
        let (parent, child) = makeViewPair()
        let avatar = OrbitalView()
        parent.addSubview(avatar)
        let c = make(.trailing(8).to(avatar, .leading), for: child)
        #expect(c.constant == 8)
    }

    // MARK: - .asOffset / .asInset overrides

    @Test(".asOffset suppresses auto-negation on same-anchor trailing")
    func asOffsetSuppressesNegation() {
        let (parent, child) = makeViewPair()
        let avatar = OrbitalView()
        parent.addSubview(avatar)
        let c = make(.trailing(8).to(avatar, .trailing).asOffset, for: child)
        #expect(c.constant == 8)
    }

    @Test(".asInset forces negation on cross-anchor")
    func asInsetForcesCrossAnchorNegation() {
        let (parent, child) = makeViewPair()
        let header = OrbitalView()
        parent.addSubview(header)
        let c = make(.bottom(16).to(header, .top).asInset, for: child)
        #expect(c.constant == -16)
    }

    // MARK: - Relations

    @Test(".orLess → lessThanOrEqual")
    func orLessRelation() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.height(120).orLess, for: child)
        #expect(c.relation == .lessThanOrEqual)
        #expect(c.constant == 120)
    }

    @Test(".orMore → greaterThanOrEqual")
    func orMoreRelation() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.width(100).orMore, for: child)
        #expect(c.relation == .greaterThanOrEqual)
    }

    @Test("default relation is .equal")
    func defaultRelation() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(8), for: child)
        #expect(c.relation == .equal)
    }

    // MARK: - Priority

    @Test(".priority(.high) → 750")
    func priorityHigh() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.height(44).priority(.high), for: child)
        #expect(c.priority.rawValue == 750)
    }

    @Test(".priority(.low) → 250")
    func priorityLow() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(16).priority(.low), for: child)
        #expect(c.priority.rawValue == 250)
    }

    @Test(".priority(.required) → 1000")
    func priorityRequired() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.leading(8).priority(.required), for: child)
        #expect(c.priority.rawValue == 1000)
    }

    @Test(".priority(.custom(600)) → 600")
    func priorityCustom() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.width(200).priority(.custom(600)), for: child)
        #expect(c.priority.rawValue == 600)
    }

    // MARK: - Debug label

    @Test(".labeled sets constraint identifier")
    func labeledSetsIdentifier() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(16).labeled("headerTop"), for: child)
        #expect(c.identifier == "headerTop")
    }

    @Test("no label → identifier is nil")
    func noLabel() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(16), for: child)
        #expect(c.identifier == nil)
    }

    // MARK: - Multiplier (dimension anchors)

    @Test(".width.like(superview, 0.4) → multiplier = 0.4 via NSLayoutDimension API")
    func widthLikeSuperviewMultiplier() {
        let (parent, child) = makeViewPair()
        let desc = OrbitalDescriptor(
            anchor: .width,
            constant: 0,
            targetView: parent,
            multiplier: 0.4,
            likeWasCalled: true
        )
        let c = make(desc, for: child)
        #expect(abs(c.multiplier - 0.4) < 0.001)
        #expect(c.firstAttribute == .width)
        #expect(c.secondAttribute == .width)
        #expect(c.secondItem === parent)
    }

    @Test(".height.like(otherView, 2) → multiplier = 2.0")
    func heightLikeOtherViewMultiplier() {
        let (parent, child) = makeViewPair()
        let other = OrbitalView()
        parent.addSubview(other)
        let desc = OrbitalDescriptor(
            anchor: .height,
            constant: 0,
            targetView: other,
            multiplier: 2.0,
            likeWasCalled: true
        )
        let c = make(desc, for: child)
        #expect(c.multiplier == 2.0)
    }

    @Test(".height.like(.width, 0.4) → self-referencing, multiplier applied")
    func heightLikeSelfWidth() {
        let (parent, child) = makeViewPair()
        _ = parent
        let desc = OrbitalDescriptor(
            anchor: .height,
            constant: 0,
            targetAnchor: .width,
            multiplier: 0.4,
            targetIsSelf: true,
            likeWasCalled: true
        )
        let c = make(desc, for: child)
        #expect(c.firstItem === child)
        #expect(c.secondItem === child)
        #expect(c.firstAttribute == .height)
        #expect(c.secondAttribute == .width)
        #expect(abs(c.multiplier - 0.4) < 0.001)
    }

    // MARK: - Multiplier (non-dimension anchor, item-based API fallback)

    @Test("non-dimension anchor with multiplier → item-based NSLayoutConstraint")
    func nonDimensionMultiplierFallback() {
        let (parent, child) = makeViewPair()
        let desc = OrbitalDescriptor(
            anchor: .centerX,
            constant: 0,
            targetView: parent,
            multiplier: 0.5
        )
        let c = make(desc, for: child)
        #expect(c.firstAttribute == .centerX)
        #expect(c.secondAttribute == .centerX)
        #expect(abs(c.multiplier - 0.5) < 0.001)
    }

    // MARK: - aspectRatio

    @Test(".aspectRatio(2) → self.width = self.height * 2")
    func aspectRatio() {
        let (parent, child) = makeViewPair()
        _ = parent
        let desc = OrbitalDescriptor(
            anchor: .width,
            constant: 0,
            targetAnchor: .height,
            multiplier: 2.0,
            targetIsSelf: true
        )
        let c = make(desc, for: child)
        #expect(c.firstItem === child)
        #expect(c.secondItem === child)
        #expect(c.firstAttribute == .width)
        #expect(c.secondAttribute == .height)
        #expect(abs(c.multiplier - 2.0) < 0.001)
    }

    // MARK: - Layout guide as target

    @Test(".top(16).to(safeAreaLayoutGuide, .top) — guide target")
    func topToLayoutGuide() {
        let (parent, child) = makeViewPair()
        #if canImport(UIKit)
        let guide = parent.safeAreaLayoutGuide
        #else
        let guide = parent.layoutMarginsGuide
        #endif
        let c = make(.top(16).to(guide, .top), for: child)
        #expect(c.constant == 16)
        #expect(c.firstAttribute == .top)
        #expect(c.secondAttribute == .top)
        #expect(c.secondItem === guide)
    }

    @Test(".leading(16).to(safeAreaLayoutGuide, .leading) — guide x-axis")
    func leadingToLayoutGuide() {
        let (parent, child) = makeViewPair()
        #if canImport(UIKit)
        let guide = parent.safeAreaLayoutGuide
        #else
        let guide = parent.layoutMarginsGuide
        #endif
        let c = make(.leading(16).to(guide, .leading), for: child)
        #expect(c.constant == 16)
        #expect(c.firstAttribute == .leading)
        #expect(c.secondAttribute == .leading)
    }

    @Test(".width.to(guide, .width) — guide dimension")
    func widthToLayoutGuide() {
        let (parent, child) = makeViewPair()
        #if canImport(UIKit)
        let guide = parent.safeAreaLayoutGuide
        #else
        let guide = parent.layoutMarginsGuide
        #endif
        let c = make(.width.to(guide, .width), for: child)
        #expect(c.firstAttribute == .width)
        #expect(c.secondAttribute == .width)
        #expect(c.secondItem === guide)
    }

    // MARK: - centerX / centerY

    @Test("centerX(0) to superview")
    func centerXToSuperview() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.centerX(), for: child)
        #expect(c.constant == 0)
        #expect(c.firstAttribute == .centerX)
        #expect(c.secondAttribute == .centerX)
    }

    @Test("centerY(8) to superview")
    func centerYWithOffset() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.centerY(8), for: child)
        #expect(c.constant == 8)
        #expect(c.firstAttribute == .centerY)
    }

    // MARK: - Constraint is not activated by factory

    @Test("returned constraint is not active")
    func constraintIsNotActive() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.top(16), for: child)
        #expect(c.isActive == false)
    }

    // MARK: - All edge anchors

    @Test("left(8) to superview — absolute anchor")
    func leftToSuperview() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.left(8), for: child)
        #expect(c.constant == 8)
        #expect(c.firstAttribute == .left)
    }

    @Test("right(8) → auto-negated")
    func rightAutoNegatedEdge() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.right(8), for: child)
        #expect(c.constant == -8)
        #expect(c.firstAttribute == .right)
    }

    // MARK: - orLess/orMore with layout guide (dimension)

    @Test(".width(300).orLess with guide target")
    func widthOrLessGuide() {
        let (parent, child) = makeViewPair()
        #if canImport(UIKit)
        let guide = parent.safeAreaLayoutGuide
        #else
        let guide = parent.layoutMarginsGuide
        #endif
        let c = make(.width(300).orLess.to(guide, .width), for: child)
        #expect(c.relation == .lessThanOrEqual)
        #expect(c.firstAttribute == .width)
    }

    @Test(".height(100).orMore constant-only")
    func heightOrMoreConstantOnly() {
        let (parent, child) = makeViewPair()
        _ = parent
        let c = make(.height(100).orMore, for: child)
        #expect(c.relation == .greaterThanOrEqual)
        #expect(c.constant == 100)
    }

    // MARK: - Baseline (UIKit only)

#if canImport(UIKit)
    @Test("firstBaseline.to(label, .firstBaseline) — y-axis baseline constraint")
    func firstBaselineConstraint() {
        let (parent, child) = makeViewPair()
        let label = UILabel()
        parent.addSubview(label)
        let c = make(.firstBaseline.to(label, .firstBaseline), for: child)
        #expect(c.firstAttribute == .firstBaseline)
        #expect(c.secondAttribute == .firstBaseline)
        #expect(c.secondItem === label)
    }

    @Test("lastBaseline(4).to(label, .lastBaseline) — with constant")
    func lastBaselineConstraint() {
        let (parent, child) = makeViewPair()
        let label = UILabel()
        parent.addSubview(label)
        let c = make(.lastBaseline(4).to(label, .lastBaseline), for: child)
        #expect(c.constant == 4)
        #expect(c.firstAttribute == .lastBaseline)
        #expect(c.secondAttribute == .lastBaseline)
    }
#endif

}
