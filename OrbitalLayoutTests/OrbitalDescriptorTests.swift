//
//  OrbitalDescriptorTests.swift
//  OrbitalLayoutTests
//

import Testing
@testable import OrbitalLayout
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("OrbitalDescriptor")
@MainActor
struct OrbitalDescriptorTests {

    // MARK: - Default values

    @Test func defaultValues() {
        let d = OrbitalDescriptor(anchor: .top)
        #expect(d.anchor == .top)
        #expect(d.constant == 0)
        #expect(d.relation == .equal)
        #expect(d.multiplier == 1)
        #expect(d.targetView == nil)
        #expect(d.targetGuide == nil)
        #expect(d.targetAnchor == nil)
        #expect(d.label == nil)
        #expect(d.signOverride == nil)
        #expect(d.targetIsSelf == false)
        #expect(d.likeWasCalled == false)
    }

    @Test func customConstant() {
        let d = OrbitalDescriptor(anchor: .leading, constant: 16)
        #expect(d.constant == 16)
    }

    @Test func customRelation() {
        let d = OrbitalDescriptor(anchor: .height, relation: .lessOrEqual)
        #expect(d.relation == .lessOrEqual)
    }

    @Test func customPriority() {
        let d = OrbitalDescriptor(anchor: .top, priority: .high)
        #expect(d.priority == .high)
    }

    // MARK: - Value semantics

    @Test func valueSemanticsIndependentCopies() {
        let original = OrbitalDescriptor(anchor: .top, constant: 8)
        var copy = original
        // Reassign copy to a new descriptor with different constant
        copy = OrbitalDescriptor(anchor: .top, constant: 99)
        #expect(original.constant == 8)
        #expect(copy.constant == 99)
    }

    @Test func mutatingCopyDoesNotAffectOriginal() {
        let d1 = OrbitalDescriptor(anchor: .bottom, constant: 16, relation: .equal)
        let d2 = OrbitalDescriptor(
            anchor: d1.anchor,
            constant: d1.constant,
            relation: .lessOrEqual,
            priority: d1.priority
        )
        #expect(d1.relation == .equal)
        #expect(d2.relation == .lessOrEqual)
    }

    // MARK: - OrbitalConstraintConvertible conformance

    @Test func asDescriptorsReturnsSelf() {
        let d = OrbitalDescriptor(anchor: .centerX)
        let result = d.asDescriptors()
        #expect(result.count == 1)
        #expect(result[0].anchor == .centerX)
    }

    // MARK: - SignOverride enum

    @Test func signOverrideOffset() {
        let d = OrbitalDescriptor(anchor: .trailing, signOverride: .offset)
        #expect(d.signOverride == .offset)
    }

    @Test func signOverrideInset() {
        let d = OrbitalDescriptor(anchor: .bottom, signOverride: .inset)
        #expect(d.signOverride == .inset)
    }

    // MARK: - OrbitalDescriptorGroup

    @Test func groupAsDescriptorsReturnsAll() {
        let d1 = OrbitalDescriptor(anchor: .top, constant: 8)
        let d2 = OrbitalDescriptor(anchor: .leading, constant: 16)
        let d3 = OrbitalDescriptor(anchor: .trailing, constant: 16)
        let group = OrbitalDescriptorGroup([d1, d2, d3])
        let result = group.asDescriptors()
        #expect(result.count == 3)
        #expect(result[0].anchor == .top)
        #expect(result[1].anchor == .leading)
        #expect(result[2].anchor == .trailing)
    }

    @Test func emptyGroupReturnsEmptyArray() {
        let group = OrbitalDescriptorGroup([])
        #expect(group.asDescriptors().isEmpty)
    }

    @Test func groupPreservesConstants() {
        let descriptors = [
            OrbitalDescriptor(anchor: .top, constant: 10),
            OrbitalDescriptor(anchor: .bottom, constant: 20),
            OrbitalDescriptor(anchor: .leading, constant: 30),
            OrbitalDescriptor(anchor: .trailing, constant: 40)
        ]
        let group = OrbitalDescriptorGroup(descriptors)
        let result = group.asDescriptors()
        #expect(result[0].constant == 10)
        #expect(result[1].constant == 20)
        #expect(result[2].constant == 30)
        #expect(result[3].constant == 40)
    }

    // MARK: - targetIsSelf / likeWasCalled flags

    @Test func targetIsSelfFlag() {
        let d = OrbitalDescriptor(anchor: .width, targetAnchor: .height, targetIsSelf: true)
        #expect(d.targetIsSelf == true)
        #expect(d.targetAnchor == OrbitalAnchor.height)
    }

    @Test func likeWasCalledFlag() {
        let d = OrbitalDescriptor(anchor: .width, likeWasCalled: true)
        #expect(d.likeWasCalled == true)
    }

    // MARK: - .to(view:anchor:)

    @Test func toViewSetsTargetView() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .top).to(view)
        #expect(d.targetView === view)
        #expect(d.targetGuide == nil)
        #expect(d.targetAnchor == nil)
    }

    @Test func toViewWithAnchorSetsTargetAnchor() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .top).to(view, .bottom)
        #expect(d.targetView === view)
        #expect(d.targetAnchor == .bottom)
    }

    @Test func toViewPreservesOtherFields() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .leading, constant: 8, relation: .greaterOrEqual, priority: .high)
            .to(view, .trailing)
        #expect(d.anchor == .leading)
        #expect(d.constant == 8)
        #expect(d.relation == .greaterOrEqual)
        #expect(d.priority == .high)
    }

    @Test func toViewDoesNotMutateOriginal() {
        let view = OrbitalView()
        let original = OrbitalDescriptor(anchor: .top)
        let modified = original.to(view, .bottom)
        #expect(original.targetView == nil)
        #expect(original.targetAnchor == nil)
        #expect(modified.targetView === view)
        #expect(modified.targetAnchor == .bottom)
    }

    @Test func toViewCalledTwiceLastWins() {
        let view1 = OrbitalView()
        let view2 = OrbitalView()
        let d = OrbitalDescriptor(anchor: .top).to(view1, .bottom).to(view2, .top)
        #expect(d.targetView === view2)
        #expect(d.targetAnchor == .top)
    }

    @Test func toViewClearsTargetGuide() {
        let guide = OrbitalLayoutGuide()
        let view = OrbitalView()
        // first set guide target, then override with view target
        let withGuide = OrbitalDescriptor(anchor: .top).to(guide, .top)
        let withView = withGuide.to(view, .bottom)
        #expect(withView.targetGuide == nil)
        #expect(withView.targetView === view)
    }

    // MARK: - .to(guide:anchor:)

    @Test func toGuideSetsTargetGuide() {
        let guide = OrbitalLayoutGuide()
        let d = OrbitalDescriptor(anchor: .top).to(guide, .top)
        #expect(d.targetGuide === guide)
        #expect(d.targetView == nil)
        #expect(d.targetAnchor == .top)
    }

    @Test func toGuideWithoutAnchorInfersNil() {
        let guide = OrbitalLayoutGuide()
        let d = OrbitalDescriptor(anchor: .bottom).to(guide)
        #expect(d.targetGuide === guide)
        #expect(d.targetAnchor == nil)
    }

    @Test func toGuideClearsTargetView() {
        let view = OrbitalView()
        let guide = OrbitalLayoutGuide()
        let withView = OrbitalDescriptor(anchor: .top).to(view, .bottom)
        let withGuide = withView.to(guide, .top)
        #expect(withGuide.targetView == nil)
        #expect(withGuide.targetGuide === guide)
    }

    // MARK: - .orLess / .orMore

    @Test func orLessSetsLessOrEqual() {
        let d = OrbitalDescriptor(anchor: .height, constant: 120).orLess
        #expect(d.relation == .lessOrEqual)
    }

    @Test func orMoreSetsGreaterOrEqual() {
        let d = OrbitalDescriptor(anchor: .width, constant: 100).orMore
        #expect(d.relation == .greaterOrEqual)
    }

    @Test func orLessDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .height)
        let modified = original.orLess
        #expect(original.relation == .equal)
        #expect(modified.relation == .lessOrEqual)
    }

    @Test func orMoreDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .width)
        let modified = original.orMore
        #expect(original.relation == .equal)
        #expect(modified.relation == .greaterOrEqual)
    }

    @Test func orMorePreservesOtherFields() {
        let d = OrbitalDescriptor(anchor: .top, constant: 8, priority: .low).orMore
        #expect(d.anchor == .top)
        #expect(d.constant == 8)
        #expect(d.priority == .low)
        #expect(d.relation == .greaterOrEqual)
    }

    // MARK: - .asOffset / .asInset

    @Test func asOffsetSetsSignOverride() {
        let d = OrbitalDescriptor(anchor: .trailing, constant: 8).asOffset
        #expect(d.signOverride == .offset)
    }

    @Test func asInsetSetsSignOverride() {
        let d = OrbitalDescriptor(anchor: .bottom, constant: 16).asInset
        #expect(d.signOverride == .inset)
    }

    @Test func asOffsetDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .trailing, constant: 8)
        let modified = original.asOffset
        #expect(original.signOverride == nil)
        #expect(modified.signOverride == .offset)
    }

    @Test func asInsetDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .bottom, constant: 16)
        let modified = original.asInset
        #expect(original.signOverride == nil)
        #expect(modified.signOverride == .inset)
    }

    // MARK: - .priority(_:)

    @Test func prioritySetsHigh() {
        let d = OrbitalDescriptor(anchor: .top).priority(.high)
        #expect(d.priority == .high)
    }

    @Test func prioritySetsLow() {
        let d = OrbitalDescriptor(anchor: .top).priority(.low)
        #expect(d.priority == .low)
    }

    @Test func prioritySetsRequired() {
        let d = OrbitalDescriptor(anchor: .top, priority: .low).priority(.required)
        #expect(d.priority == .required)
    }

    @Test func prioritySetsCustom() {
        let d = OrbitalDescriptor(anchor: .top).priority(.custom(600))
        #expect(d.priority == .custom(600))
    }

    @Test func priorityDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .top)
        let modified = original.priority(.low)
        #expect(original.priority == .required)
        #expect(modified.priority == .low)
    }

    // MARK: - .labeled(_:)

    @Test func labeledSetsIdentifier() {
        let d = OrbitalDescriptor(anchor: .top).labeled("card.top")
        #expect(d.label == "card.top")
    }

    @Test func labeledDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .top)
        let modified = original.labeled("myLabel")
        #expect(original.label == nil)
        #expect(modified.label == "myLabel")
    }

    @Test func labeledPreservesOtherFields() {
        let d = OrbitalDescriptor(anchor: .height, constant: 44, relation: .lessOrEqual).labeled("h")
        #expect(d.anchor == .height)
        #expect(d.constant == 44)
        #expect(d.relation == .lessOrEqual)
        #expect(d.label == "h")
    }

    // MARK: - .like(view:multiplier:)

    @Test func likeViewSetsTargetAndMultiplier() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .width).like(view, 0.4)
        #expect(d.targetView === view)
        #expect(d.multiplier == 0.4)
        #expect(d.likeWasCalled == true)
        #expect(d.targetIsSelf == false)
    }

    @Test func likeViewDefaultMultiplierIsOne() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .width).like(view)
        #expect(d.multiplier == 1)
        #expect(d.likeWasCalled == true)
    }

    @Test func likeViewDoesNotMutateOriginal() {
        let view = OrbitalView()
        let original = OrbitalDescriptor(anchor: .width)
        let modified = original.like(view, 0.5)
        #expect(original.targetView == nil)
        #expect(original.multiplier == 1)
        #expect(original.likeWasCalled == false)
        #expect(modified.targetView === view)
        #expect(modified.multiplier == 0.5)
    }

    // MARK: - .like(view:anchor:multiplier:)

    @Test func likeViewWithAnchorSetsTargetAnchor() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .height).like(view, .width, 0.5)
        #expect(d.targetView === view)
        #expect(d.targetAnchor == .width)
        #expect(d.multiplier == 0.5)
        #expect(d.likeWasCalled == true)
    }

    @Test func likeViewWithAnchorDefaultMultiplierIsOne() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .height).like(view, .width)
        #expect(d.multiplier == 1)
    }

    // MARK: - .like(anchor:multiplier:) — self-referencing

    @Test func likeAnchorSetsSelfReferencing() {
        let d = OrbitalDescriptor(anchor: .height).like(.width, 0.4)
        #expect(d.targetIsSelf == true)
        #expect(d.targetAnchor == .width)
        #expect(d.multiplier == 0.4)
        #expect(d.likeWasCalled == true)
        #expect(d.targetView == nil)
        #expect(d.targetGuide == nil)
    }

    @Test func likeAnchorDefaultMultiplierIsOne() {
        let d = OrbitalDescriptor(anchor: .height).like(.width)
        #expect(d.multiplier == 1)
        #expect(d.targetIsSelf == true)
    }

    @Test func likeAnchorDoesNotMutateOriginal() {
        let original = OrbitalDescriptor(anchor: .height)
        let modified = original.like(.width, 0.5)
        #expect(original.targetIsSelf == false)
        #expect(original.multiplier == 1)
        #expect(modified.targetIsSelf == true)
        #expect(modified.multiplier == 0.5)
    }

    // MARK: - Full chain

    @Test func fullChainAllFieldsCorrect() {
        let view = OrbitalView()
        let d = OrbitalDescriptor(anchor: .top, constant: 8)
            .to(view, .bottom)
            .orMore
            .priority(.high)
            .labeled("contentTop")
        #expect(d.anchor == .top)
        #expect(d.constant == 8)
        #expect(d.targetView === view)
        #expect(d.targetAnchor == .bottom)
        #expect(d.relation == .greaterOrEqual)
        #expect(d.priority == .high)
        #expect(d.label == "contentTop")
    }

    @Test func fullChainOriginalUnchanged() {
        let view = OrbitalView()
        let original = OrbitalDescriptor(anchor: .top, constant: 8)
        _ = original.to(view, .bottom).orMore.priority(.high).labeled("x")
        #expect(original.targetView == nil)
        #expect(original.relation == .equal)
        #expect(original.priority == .required)
        #expect(original.label == nil)
    }

    @Test func toCalledTwiceLastWinsInChain() {
        let view1 = OrbitalView()
        let view2 = OrbitalView()
        let d = OrbitalDescriptor(anchor: .top, constant: 8)
            .to(view1, .bottom)
            .to(view2, .top)
        #expect(d.targetView === view2)
        #expect(d.targetAnchor == .top)
    }

    // MARK: - OrbitalDescriptorGroup modifiers

    @Test func groupPriorityAppliedToAll() {
        let descriptors = [
            OrbitalDescriptor(anchor: .top, constant: 8),
            OrbitalDescriptor(anchor: .leading, constant: 16),
            OrbitalDescriptor(anchor: .trailing, constant: 16)
        ]
        let group = OrbitalDescriptorGroup(descriptors).priority(.high)
        let result = group.asDescriptors()
        #expect(result.allSatisfy { $0.priority == .high })
    }

    @Test func groupOrLessAppliedToAll() {
        let descriptors = [
            OrbitalDescriptor(anchor: .width, constant: 100),
            OrbitalDescriptor(anchor: .height, constant: 200)
        ]
        let group = OrbitalDescriptorGroup(descriptors).orLess
        let result = group.asDescriptors()
        #expect(result.allSatisfy { $0.relation == .lessOrEqual })
    }

    @Test func groupOrMoreAppliedToAll() {
        let descriptors = [
            OrbitalDescriptor(anchor: .width, constant: 100),
            OrbitalDescriptor(anchor: .height, constant: 50)
        ]
        let group = OrbitalDescriptorGroup(descriptors).orMore
        let result = group.asDescriptors()
        #expect(result.allSatisfy { $0.relation == .greaterOrEqual })
    }

    @Test func groupLabeledAppliedToAll() {
        let descriptors = [
            OrbitalDescriptor(anchor: .top),
            OrbitalDescriptor(anchor: .bottom)
        ]
        let group = OrbitalDescriptorGroup(descriptors).labeled("myGroup")
        let result = group.asDescriptors()
        #expect(result.allSatisfy { $0.label == "myGroup" })
    }

    @Test func groupModifiersDoNotMutateOriginal() {
        let descriptors = [
            OrbitalDescriptor(anchor: .top),
            OrbitalDescriptor(anchor: .bottom)
        ]
        let original = OrbitalDescriptorGroup(descriptors)
        let modified = original.priority(.low)
        let originalResult = original.asDescriptors()
        let modifiedResult = modified.asDescriptors()
        #expect(originalResult.allSatisfy { $0.priority == .required })
        #expect(modifiedResult.allSatisfy { $0.priority == .low })
    }

    @Test func groupOrLessPreservesCount() {
        let descriptors = [
            OrbitalDescriptor(anchor: .top),
            OrbitalDescriptor(anchor: .leading),
            OrbitalDescriptor(anchor: .trailing),
            OrbitalDescriptor(anchor: .bottom)
        ]
        let group = OrbitalDescriptorGroup(descriptors).orLess
        #expect(group.asDescriptors().count == 4)
    }

    // MARK: - Task 4: Static factory — single anchors (zero constant)

    @Test func staticTopZeroConstant() {
        let d = OrbitalDescriptor.top
        #expect(d.anchor == .top)
        #expect(d.constant == 0)
        #expect(d.relation == .equal)
        #expect(d.priority == .required)
    }

    @Test func staticBottomZeroConstant() {
        let d = OrbitalDescriptor.bottom
        #expect(d.anchor == .bottom)
        #expect(d.constant == 0)
    }

    @Test func staticLeadingZeroConstant() {
        let d = OrbitalDescriptor.leading
        #expect(d.anchor == .leading)
        #expect(d.constant == 0)
    }

    @Test func staticTrailingZeroConstant() {
        let d = OrbitalDescriptor.trailing
        #expect(d.anchor == .trailing)
        #expect(d.constant == 0)
    }

    @Test func staticLeftZeroConstant() {
        let d = OrbitalDescriptor.left
        #expect(d.anchor == .left)
        #expect(d.constant == 0)
    }

    @Test func staticRightZeroConstant() {
        let d = OrbitalDescriptor.right
        #expect(d.anchor == .right)
        #expect(d.constant == 0)
    }

    @Test func staticWidthZeroConstant() {
        let d = OrbitalDescriptor.width
        #expect(d.anchor == .width)
        #expect(d.constant == 0)
    }

    @Test func staticHeightZeroConstant() {
        let d = OrbitalDescriptor.height
        #expect(d.anchor == .height)
        #expect(d.constant == 0)
    }

    @Test func staticCenterXZeroConstant() {
        let d = OrbitalDescriptor.centerX
        #expect(d.anchor == .centerX)
        #expect(d.constant == 0)
    }

    @Test func staticCenterYZeroConstant() {
        let d = OrbitalDescriptor.centerY
        #expect(d.anchor == .centerY)
        #expect(d.constant == 0)
    }

    // MARK: - Task 4: Static factory — single anchors (with constant)

    @Test func staticTopWithConstant() {
        let d = OrbitalDescriptor.top(16)
        #expect(d.anchor == .top)
        #expect(d.constant == 16)
    }

    @Test func staticBottomWithConstant() {
        let d = OrbitalDescriptor.bottom(16)
        #expect(d.anchor == .bottom)
        #expect(d.constant == 16)
    }

    @Test func staticLeadingWithConstant() {
        let d = OrbitalDescriptor.leading(8)
        #expect(d.anchor == .leading)
        #expect(d.constant == 8)
    }

    @Test func staticTrailingWithConstant() {
        let d = OrbitalDescriptor.trailing(8)
        #expect(d.anchor == .trailing)
        #expect(d.constant == 8)
    }

    @Test func staticLeftWithConstant() {
        let d = OrbitalDescriptor.left(12)
        #expect(d.anchor == .left)
        #expect(d.constant == 12)
    }

    @Test func staticRightWithConstant() {
        let d = OrbitalDescriptor.right(12)
        #expect(d.anchor == .right)
        #expect(d.constant == 12)
    }

    @Test func staticWidthWithConstant() {
        let d = OrbitalDescriptor.width(100)
        #expect(d.anchor == .width)
        #expect(d.constant == 100)
    }

    @Test func staticHeightWithConstant() {
        let d = OrbitalDescriptor.height(44)
        #expect(d.anchor == .height)
        #expect(d.constant == 44)
    }

    @Test func staticCenterXWithOffset() {
        let d = OrbitalDescriptor.centerX(10)
        #expect(d.anchor == .centerX)
        #expect(d.constant == 10)
    }

    @Test func staticCenterYWithOffset() {
        let d = OrbitalDescriptor.centerY(8)
        #expect(d.anchor == .centerY)
        #expect(d.constant == 8)
    }

    @Test func staticCenterXDefaultZero() {
        let d = OrbitalDescriptor.centerX()
        #expect(d.constant == 0)
    }

    @Test func staticCenterYDefaultZero() {
        let d = OrbitalDescriptor.centerY()
        #expect(d.constant == 0)
    }

    // MARK: - Task 4: Static factory — defaults on all statics

    @Test func staticFactoryDefaultRelationIsEqual() {
        #expect(OrbitalDescriptor.top(8).relation == .equal)
        #expect(OrbitalDescriptor.width(100).relation == .equal)
    }

    @Test func staticFactoryDefaultPriorityIsRequired() {
        #expect(OrbitalDescriptor.leading(16).priority == .required)
        #expect(OrbitalDescriptor.height(44).priority == .required)
    }

    @Test func staticFactoryDefaultTargetsAreNil() {
        let d = OrbitalDescriptor.top(8)
        #expect(d.targetView == nil)
        #expect(d.targetGuide == nil)
        #expect(d.targetAnchor == nil)
    }

    @Test func staticFactoryDefaultMultiplierIsOne() {
        #expect(OrbitalDescriptor.width(100).multiplier == 1)
        #expect(OrbitalDescriptor.height(44).multiplier == 1)
    }

    // MARK: - Task 4: .edges group

    @Test func staticEdgesZeroInsetHasFourDescriptors() {
        let group = OrbitalDescriptor.edges
        let descs = group.asDescriptors()
        #expect(descs.count == 4)
    }

    @Test func staticEdgesZeroInsetAnchors() {
        let anchors = OrbitalDescriptor.edges.asDescriptors().map(\.anchor)
        #expect(anchors.contains(.top))
        #expect(anchors.contains(.bottom))
        #expect(anchors.contains(.leading))
        #expect(anchors.contains(.trailing))
    }

    @Test func staticEdgesZeroInsetAllConstantsAreZero() {
        let descs = OrbitalDescriptor.edges.asDescriptors()
        #expect(descs.allSatisfy { $0.constant == 0 })
    }

    @Test func staticEdgesWithInsetHasFourDescriptors() {
        let group = OrbitalDescriptor.edges(16)
        #expect(group.asDescriptors().count == 4)
    }

    @Test func staticEdgesWithInsetAllConstantsMatch() {
        let descs = OrbitalDescriptor.edges(16).asDescriptors()
        #expect(descs.allSatisfy { $0.constant == 16 })
    }

    @Test func staticEdgesWithInsetAnchors() {
        let anchors = OrbitalDescriptor.edges(16).asDescriptors().map(\.anchor)
        #expect(anchors.contains(.top))
        #expect(anchors.contains(.bottom))
        #expect(anchors.contains(.leading))
        #expect(anchors.contains(.trailing))
    }

    // MARK: - Task 4: .horizontal group

    @Test func staticHorizontalZeroInsetHasTwoDescriptors() {
        let descs = OrbitalDescriptor.horizontal.asDescriptors()
        #expect(descs.count == 2)
    }

    @Test func staticHorizontalZeroInsetAnchors() {
        let anchors = OrbitalDescriptor.horizontal.asDescriptors().map(\.anchor)
        #expect(anchors.contains(.leading))
        #expect(anchors.contains(.trailing))
    }

    @Test func staticHorizontalWithInset() {
        let descs = OrbitalDescriptor.horizontal(8).asDescriptors()
        #expect(descs.count == 2)
        #expect(descs.allSatisfy { $0.constant == 8 })
        let anchors = descs.map(\.anchor)
        #expect(anchors.contains(.leading))
        #expect(anchors.contains(.trailing))
    }

    // MARK: - Task 4: .vertical group

    @Test func staticVerticalZeroInsetHasTwoDescriptors() {
        let descs = OrbitalDescriptor.vertical.asDescriptors()
        #expect(descs.count == 2)
    }

    @Test func staticVerticalZeroInsetAnchors() {
        let anchors = OrbitalDescriptor.vertical.asDescriptors().map(\.anchor)
        #expect(anchors.contains(.top))
        #expect(anchors.contains(.bottom))
    }

    @Test func staticVerticalWithInset() {
        let descs = OrbitalDescriptor.vertical(24).asDescriptors()
        #expect(descs.count == 2)
        #expect(descs.allSatisfy { $0.constant == 24 })
        let anchors = descs.map(\.anchor)
        #expect(anchors.contains(.top))
        #expect(anchors.contains(.bottom))
    }

    // MARK: - Task 4: .size shortcuts

    @Test func staticSizeSquareHasTwoDescriptors() {
        let descs = OrbitalDescriptor.size(80).asDescriptors()
        #expect(descs.count == 2)
    }

    @Test func staticSizeSquareAnchorsAndConstants() {
        let descs = OrbitalDescriptor.size(80).asDescriptors()
        let anchors = descs.map(\.anchor)
        #expect(anchors.contains(.width))
        #expect(anchors.contains(.height))
        #expect(descs.allSatisfy { $0.constant == 80 })
    }

    @Test func staticSizeExplicitWidthHeight() {
        let descs = OrbitalDescriptor.size(width: 320, height: 180).asDescriptors()
        #expect(descs.count == 2)
        let widthDesc = descs.first { $0.anchor == .width }
        let heightDesc = descs.first { $0.anchor == .height }
        #expect(widthDesc?.constant == 320)
        #expect(heightDesc?.constant == 180)
    }

    @Test func staticSizeExplicitDifferentValues() {
        let descs = OrbitalDescriptor.size(width: 100, height: 200).asDescriptors()
        let w = descs.first { $0.anchor == .width }
        let h = descs.first { $0.anchor == .height }
        #expect(w?.constant == 100)
        #expect(h?.constant == 200)
    }

    // MARK: - Task 4: .center shortcuts

    @Test func staticCenterHasTwoDescriptors() {
        let descs = OrbitalDescriptor.center().asDescriptors()
        #expect(descs.count == 2)
    }

    @Test func staticCenterAnchors() {
        let anchors = OrbitalDescriptor.center().asDescriptors().map(\.anchor)
        #expect(anchors.contains(.centerX))
        #expect(anchors.contains(.centerY))
    }

    @Test func staticCenterZeroOffsets() {
        let descs = OrbitalDescriptor.center().asDescriptors()
        #expect(descs.allSatisfy { $0.constant == 0 })
    }

    @Test func staticCenterWithOffset() {
        let descs = OrbitalDescriptor.center(offset: CGPoint(x: 10, y: -5)).asDescriptors()
        let cx = descs.first { $0.anchor == .centerX }
        let cy = descs.first { $0.anchor == .centerY }
        #expect(cx?.constant == 10)
        #expect(cy?.constant == -5)
    }

    @Test func staticCenterWithOffsetHasTwoDescriptors() {
        let descs = OrbitalDescriptor.center(offset: CGPoint(x: 0, y: 0)).asDescriptors()
        #expect(descs.count == 2)
    }

    // MARK: - Task 4: .aspectRatio

    @Test func staticAspectRatioAnchorIsWidth() {
        let d = OrbitalDescriptor.aspectRatio(16.0 / 9.0)
        #expect(d.anchor == .width)
    }

    @Test func staticAspectRatioTargetAnchorIsHeight() {
        let d = OrbitalDescriptor.aspectRatio(16.0 / 9.0)
        #expect(d.targetAnchor == .height)
    }

    @Test func staticAspectRatioTargetIsSelf() {
        let d = OrbitalDescriptor.aspectRatio(2.0)
        #expect(d.targetIsSelf == true)
    }

    @Test func staticAspectRatioMultiplier() {
        let d = OrbitalDescriptor.aspectRatio(2.0)
        #expect(d.multiplier == 2.0)
    }

    @Test func staticAspectRatioSquare() {
        let d = OrbitalDescriptor.aspectRatio(1.0)
        #expect(d.multiplier == 1.0)
        #expect(d.targetIsSelf == true)
        #expect(d.targetAnchor == .height)
    }

    @Test func staticAspectRatioDefaultFields() {
        let d = OrbitalDescriptor.aspectRatio(1.5)
        #expect(d.constant == 0)
        #expect(d.relation == .equal)
        #expect(d.priority == .required)
        #expect(d.targetView == nil)
        #expect(d.targetGuide == nil)
    }

#if canImport(UIKit)
    // MARK: - Task 4: Baseline anchors (UIKit only)

    @Test func staticFirstBaselineZeroConstant() {
        let d = OrbitalDescriptor.firstBaseline
        #expect(d.anchor == .firstBaseline)
        #expect(d.constant == 0)
    }

    @Test func staticFirstBaselineWithConstant() {
        let d = OrbitalDescriptor.firstBaseline(4)
        #expect(d.anchor == .firstBaseline)
        #expect(d.constant == 4)
    }

    @Test func staticLastBaselineZeroConstant() {
        let d = OrbitalDescriptor.lastBaseline
        #expect(d.anchor == .lastBaseline)
        #expect(d.constant == 0)
    }

    @Test func staticLastBaselineWithConstant() {
        let d = OrbitalDescriptor.lastBaseline(8)
        #expect(d.anchor == .lastBaseline)
        #expect(d.constant == 8)
    }

    @Test func staticBaselineDefaultFields() {
        let d = OrbitalDescriptor.firstBaseline
        #expect(d.relation == .equal)
        #expect(d.priority == .required)
        #expect(d.targetView == nil)
        #expect(d.likeWasCalled == false)
    }
#endif
}
