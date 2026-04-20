//
//  IntegrationTests.swift
//  OrbitalLayoutTests
//
//  End-to-end integration tests replicating real-world usage patterns from the
//  OrbitalLayout documentation. Each test corresponds to a practical scenario
//  described in the API reference or examples guide.
//

import Testing
@testable import OrbitalLayout

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Helpers

/// Creates a parent view with a known frame suitable for Auto Layout calculations.
@MainActor
private func makeParent() -> OrbitalView {
    OrbitalView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
}

/// Creates a child view without adding it to any hierarchy.
@MainActor
private func makeChild() -> OrbitalView {
    let v = OrbitalView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
}

// MARK: - IntegrationTests

@Suite("Integration Tests")
@MainActor
struct IntegrationTests {

    // MARK: - 1. Full Profile Layout (requirements.md §15)

    /// Replicates the full profile card layout from Section 15 of requirements.md:
    /// avatar + nameLabel + bioLabel + followButton arranged in a parent view.
    @Suite("Full profile layout")
    @MainActor
    struct FullProfileLayout {

        @Test("all views added as subviews")
        func allViewsAddedAsSubviews() {
            let view = makeParent()
            let avatar = makeChild()
            let nameLabel = makeChild()
            let bioLabel = makeChild()
            let followButton = makeChild()

            view.orbit(avatar, nameLabel, bioLabel, followButton) {
                avatar.orbital.layout(.top(24).to(view, .top), .leading(16))
                avatar.orbital.size(80)
                nameLabel.orbital.layout(
                    .top.to(avatar, .top),
                    .leading(12).to(avatar, .trailing),
                    .trailing(16)
                )
                bioLabel.orbital.layout(
                    .top(4).to(nameLabel, .bottom),
                    .leading.to(nameLabel, .leading),
                    .trailing(16),
                    .height(60).orLess
                )
                followButton.orbital.layout(
                    .top(16).to(bioLabel, .bottom),
                    .leading(16),
                    .trailing(16),
                    .height(44),
                    .bottom(16).priority(.low)
                )
            }

            #expect(avatar.superview === view)
            #expect(nameLabel.superview === view)
            #expect(bioLabel.superview === view)
            #expect(followButton.superview === view)
        }

        @Test("avatar constraints are active with correct values")
        func avatarConstraints() {
            let view = makeParent()
            let avatar = makeChild()

            view.orbit(avatar) {
                avatar.orbital.layout(.top(24).to(view, .top), .leading(16))
                avatar.orbital.size(80)
            }

            let topC = avatar.orbital.topConstraint
            let leadingC = avatar.orbital.leadingConstraint
            let widthC = avatar.orbital.widthConstraint
            let heightC = avatar.orbital.heightConstraint

            #expect(topC?.isActive == true)
            #expect(topC?.constant == 24)
            #expect(leadingC?.isActive == true)
            #expect(leadingC?.constant == 16)
            #expect(widthC?.isActive == true)
            #expect(widthC?.constant == 80)
            #expect(heightC?.isActive == true)
            #expect(heightC?.constant == 80)
        }

        @Test("nameLabel top is pinned to avatar top")
        func nameLabelTopToAvatarTop() {
            let view = makeParent()
            let avatar = makeChild()
            let nameLabel = makeChild()

            view.orbit(avatar, nameLabel) {
                avatar.orbital.layout(.top(24), .leading(16))
                avatar.orbital.size(80)
                nameLabel.orbital.layout(
                    .top.to(avatar, .top),
                    .leading(12).to(avatar, .trailing),
                    .trailing(16)
                )
            }

            let nameLabelTop = nameLabel.orbital.topConstraint
            #expect(nameLabelTop?.isActive == true)
            #expect(nameLabelTop?.constant == 0)
            #expect(nameLabelTop?.secondItem as? OrbitalView === avatar)
        }

        @Test("bioLabel height orLess constraint stored correctly")
        func bioLabelHeightOrLess() {
            let view = makeParent()
            let nameLabel = makeChild()
            let bioLabel = makeChild()

            view.orbit(nameLabel, bioLabel) {
                nameLabel.orbital.layout(.top(16), .leading(16), .trailing(16))
                bioLabel.orbital.layout(
                    .top(4).to(nameLabel, .bottom),
                    .leading(16),
                    .trailing(16),
                    .height(60).orLess
                )
            }

            let heightOrLess = bioLabel.orbital.constraint(for: .height, relation: .lessOrEqual)
            #expect(heightOrLess?.isActive == true)
            #expect(heightOrLess?.constant == 60)
            #expect(heightOrLess?.relation == .lessThanOrEqual)
        }

        @Test("followButton bottom priority is low")
        func followButtonBottomLowPriority() {
            let view = makeParent()
            let followButton = makeChild()

            view.orbit(followButton) {
                followButton.orbital.layout(
                    .top(16),
                    .leading(16),
                    .trailing(16),
                    .height(44),
                    .bottom(16).priority(.low)
                )
            }

            let bottomC = followButton.orbital.bottomConstraint
            #expect(bottomC?.isActive == true)
            #expect(bottomC?.priority == OrbitalPriority.low.layoutPriority)
        }
    }

    // MARK: - 2. Card with Shadow (Example 25)

    /// Replicates Example 25: a card view with nested title/subtitle labels.
    @Suite("Card with shadow (nested orbital calls)")
    @MainActor
    struct CardWithShadow {

        @Test("card is added to view with correct constraints")
        func cardConstraints() {
            let view = makeParent()
            let card = makeChild()

            view.orbit(card) {
                card.orbital.layout(
                    .top(16).to(view, .top),
                    .leading(20),
                    .trailing(20),
                    .height(120)
                )
            }

            #expect(card.superview === view)
            #expect(card.orbital.topConstraint?.isActive == true)
            #expect(card.orbital.topConstraint?.constant == 16)
            #expect(card.orbital.leadingConstraint?.constant == 20)
            #expect(card.orbital.trailingConstraint?.constant == -20)
            #expect(card.orbital.heightConstraint?.constant == 120)
        }

        @Test("nested labels added to card with constraints")
        func nestedLabels() {
            let view = makeParent()
            let card = makeChild()
            let titleLabel = makeChild()
            let subtitleLabel = makeChild()

            view.orbit(card) {
                card.orbital.layout(.top(16), .leading(20), .trailing(20), .height(120))
            }

            card.orbit(titleLabel, subtitleLabel) {
                titleLabel.orbital.layout(
                    .top(16),
                    .leading(16),
                    .trailing(16)
                )
                subtitleLabel.orbital.layout(
                    .top(8).to(titleLabel, .bottom),
                    .leading(16),
                    .trailing(16),
                    .bottom(16).priority(.low)
                )
            }

            #expect(titleLabel.superview === card)
            #expect(subtitleLabel.superview === card)
            #expect(titleLabel.orbital.topConstraint?.constant == 16)
            #expect(subtitleLabel.orbital.topConstraint?.constant == 8)
            #expect(subtitleLabel.orbital.topConstraint?.secondItem as? OrbitalView === titleLabel)
            let subtitleBottom = subtitleLabel.orbital.bottomConstraint
            #expect(subtitleBottom?.priority == OrbitalPriority.low.layoutPriority)
        }
    }

    // MARK: - 3. Expandable Panel (Example 26)

    /// Replicates Example 26: layout → update → verify constants change.
    @Suite("Expandable panel (update)")
    @MainActor
    struct ExpandablePanel {

        @Test("initial height is 60")
        func initialHeight() {
            let parent = makeParent()
            let panel = makeChild()

            parent.orbit(panel) {
                panel.orbital.layout(.top, .leading, .trailing, .height(60))
            }

            #expect(panel.orbital.heightConstraint?.constant == 60)
            #expect(panel.orbital.heightConstraint?.isActive == true)
        }

        @Test("expand: update height to 200")
        func expandHeight() {
            let parent = makeParent()
            let panel = makeChild()

            parent.orbit(panel) {
                panel.orbital.layout(.top, .leading, .trailing, .height(60))
            }

            let originalConstraint = panel.orbital.heightConstraint
            panel.orbital.update(.height(200))

            // Same object, updated constant
            #expect(panel.orbital.heightConstraint === originalConstraint)
            #expect(panel.orbital.heightConstraint?.constant == 200)
        }

        @Test("collapse: update height back to 60")
        func collapseHeight() {
            let parent = makeParent()
            let panel = makeChild()

            parent.orbit(panel) {
                panel.orbital.layout(.top, .leading, .trailing, .height(60))
            }

            panel.orbital.update(.height(200))
            panel.orbital.update(.height(60))

            #expect(panel.orbital.heightConstraint?.constant == 60)
        }

        @Test("update only changes height — other constraints untouched")
        func updateOnlyHeight() {
            let parent = makeParent()
            let panel = makeChild()

            parent.orbit(panel) {
                panel.orbital.layout(.top(8), .leading(16), .trailing(16), .height(60))
            }

            let topBefore = panel.orbital.topConstraint
            panel.orbital.update(.height(200))

            #expect(panel.orbital.topConstraint === topBefore)
            #expect(panel.orbital.topConstraint?.constant == 8)
        }

        @Test("update with .edges(24) updates all four edge constants")
        func updateEdgesGroup() {
            let parent = makeParent()
            let panel = makeChild()

            parent.orbit(panel) {
                panel.orbital.edges(16)
            }

            panel.orbital.update(OrbitalDescriptor.edges(24))

            // update() sets constant directly without auto-negation.
            // The existing constraints for bottom/trailing already hold negative values;
            // update() just overwrites the constant field with the provided value.
            #expect(panel.orbital.topConstraint?.constant == 24)
            #expect(panel.orbital.bottomConstraint?.constant == 24)
            #expect(panel.orbital.leadingConstraint?.constant == 24)
            #expect(panel.orbital.trailingConstraint?.constant == 24)
        }
    }

    // MARK: - 4. Dynamic Constraint Swap (Example 27)

    /// Replicates Example 27: layout → remake → verify new target.
    @Suite("Dynamic constraint swap (remake)")
    @MainActor
    struct DynamicConstraintSwap {

        @Test("initial leading is pinned to superview")
        func initialLeading() {
            let parent = makeParent()
            let iconView = makeChild()

            parent.orbit(iconView) {
                iconView.orbital.layout(.leading(16), .centerY)
            }

            #expect(iconView.orbital.leadingConstraint?.isActive == true)
            #expect(iconView.orbital.leadingConstraint?.constant == 16)
            #expect(iconView.orbital.leadingConstraint?.secondItem as? OrbitalView === parent)
        }

        @Test("remake leading to another view's trailing")
        func remakeLeadingToOtherView() {
            let parent = makeParent()
            let iconView = makeChild()
            let badgeView = makeChild()

            parent.orbit(iconView, badgeView) {
                iconView.orbital.layout(.leading(16), .centerY)
                badgeView.orbital.layout(.leading(8), .top(8))
                badgeView.orbital.size(20)
            }

            let oldLeading = iconView.orbital.leadingConstraint
            iconView.orbital.remake(.leading(8).to(badgeView, .trailing))

            let newLeading = iconView.orbital.leadingConstraint
            #expect(oldLeading?.isActive == false)
            #expect(newLeading?.isActive == true)
            #expect(newLeading?.constant == 8)
            #expect(newLeading?.secondItem as? OrbitalView === badgeView)
        }

        @Test("remake does not affect other existing constraints")
        func remakeDoesNotAffectOthers() {
            let parent = makeParent()
            let iconView = makeChild()

            parent.orbit(iconView) {
                iconView.orbital.layout(.leading(16), .centerY, .height(44))
            }

            iconView.orbital.remake(.leading(8))

            // centerY and height untouched
            #expect(iconView.orbital.centerYConstraint?.isActive == true)
            #expect(iconView.orbital.heightConstraint?.constant == 44)
        }

        @Test("remake with different constant updates the constraint")
        func remakeChangesConstant() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16), .leading(16), .trailing(16), .height(200))
            }

            view.orbital.remake(.top(8), .height(120))

            #expect(view.orbital.topConstraint?.constant == 8)
            #expect(view.orbital.heightConstraint?.constant == 120)
            // Untouched
            #expect(view.orbital.leadingConstraint?.constant == 16)
            #expect(view.orbital.trailingConstraint?.constant == -16)
        }
    }

    // MARK: - 5. Safe Area Layout

    /// Verifies that constraints to UILayoutGuide / NSLayoutGuide targets are applied correctly.
    @Suite("Safe area layout")
    @MainActor
    struct SafeAreaLayout {

        @Test("leading and trailing constrained to superview directly")
        func leadingTrailingToSuperview() {
            let parent = makeParent()
            let contentView = makeChild()

            parent.orbit(contentView) {
                contentView.orbital.layout(
                    .leading,
                    .trailing
                )
            }

            #expect(contentView.orbital.leadingConstraint?.isActive == true)
            #expect(contentView.orbital.trailingConstraint?.isActive == true)
        }

        @Test("top and bottom pinned to layout guide")
        func topBottomToLayoutGuide() {
            let parent = makeParent()
            let contentView = makeChild()

            #if canImport(UIKit)
            let guide = UILayoutGuide()
            parent.addLayoutGuide(guide)
            #elseif canImport(AppKit)
            let guide = NSLayoutGuide()
            parent.addLayoutGuide(guide)
            #endif

            parent.orbit(contentView) {
                contentView.orbital.layout(
                    .top(16).to(guide, .top),
                    .bottom(16).to(guide, .bottom)
                )
            }

            let topC = contentView.orbital.topConstraint
            let bottomC = contentView.orbital.bottomConstraint

            #expect(topC?.isActive == true)
            #expect(topC?.constant == 16)
            #expect(topC?.secondItem as? OrbitalLayoutGuide === guide)

            #expect(bottomC?.isActive == true)
            #expect(bottomC?.constant == -16)
            #expect(bottomC?.secondItem as? OrbitalLayoutGuide === guide)
        }

        @Test("individual edges pinned to layout guide using inferred anchor")
        func allEdgesToLayoutGuide() {
            let parent = makeParent()
            let contentView = makeChild()

            #if canImport(UIKit)
            let guide = UILayoutGuide()
            parent.addLayoutGuide(guide)
            #elseif canImport(AppKit)
            let guide = NSLayoutGuide()
            parent.addLayoutGuide(guide)
            #endif

            parent.orbit(contentView) {
                contentView.orbital.layout(
                    .top.to(guide, .top),
                    .bottom.to(guide, .bottom),
                    .leading.to(guide, .leading),
                    .trailing.to(guide, .trailing)
                )
            }

            #expect(contentView.orbital.topConstraint?.isActive == true)
            #expect(contentView.orbital.bottomConstraint?.isActive == true)
            #expect(contentView.orbital.leadingConstraint?.isActive == true)
            #expect(contentView.orbital.trailingConstraint?.isActive == true)
        }
    }

    // MARK: - 6. Mixed Relations: Same Anchor, Different Relations

    /// Verifies that `.width == 200` and `.width <= 300` coexist without conflict.
    @Suite("Mixed relations on same anchor")
    @MainActor
    struct MixedRelations {

        @Test("equal and lessOrEqual width constraints coexist")
        func equalAndLessOrEqualWidth() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .top(16),
                    .width(200),
                    .width(300).orLess
                )
            }

            let equalWidth = view.orbital.widthConstraint
            let lessWidth = view.orbital.constraint(for: .width, relation: .lessOrEqual)

            #expect(equalWidth?.isActive == true)
            #expect(equalWidth?.constant == 200)
            #expect(equalWidth?.relation == .equal)

            #expect(lessWidth?.isActive == true)
            #expect(lessWidth?.constant == 300)
            #expect(lessWidth?.relation == .lessThanOrEqual)
        }

        @Test("equal and greaterOrEqual height constraints coexist")
        func equalAndGreaterOrEqualHeight() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .leading(16),
                    .height(100),
                    .height(44).orMore
                )
            }

            let equalHeight = view.orbital.heightConstraint
            let moreHeight = view.orbital.constraint(for: .height, relation: .greaterOrEqual)

            #expect(equalHeight?.isActive == true)
            #expect(equalHeight?.constant == 100)
            #expect(moreHeight?.isActive == true)
            #expect(moreHeight?.constant == 44)
            #expect(moreHeight?.relation == .greaterThanOrEqual)
        }

        @Test("replacing equal relation deactivates previous equal constraint")
        func replacingEqualDeactivatesPrevious() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16), .width(200))
            }

            let firstWidth = view.orbital.widthConstraint
            view.orbital.layout(.width(300))
            let secondWidth = view.orbital.widthConstraint

            #expect(firstWidth?.isActive == false)
            #expect(secondWidth?.isActive == true)
            #expect(secondWidth?.constant == 300)
        }
    }

    // MARK: - 7. prepareLayout → activate flow

    /// Verifies that `prepareLayout` creates inactive constraints that can be activated later.
    @Suite("prepareLayout → activate flow")
    @MainActor
    struct PrepareLayoutActivate {

        @Test("prepareLayout creates inactive constraints")
        func prepareCreatesInactiveConstraints() {
            let parent = makeParent()
            let view = makeChild()
            parent.addSubview(view)

            let constraints = view.orbital.prepareLayout(.top(8), .leading(16), .trailing(16))

            #expect(constraints.count == 3)
            #expect(constraints.allSatisfy { !$0.isActive })
        }

        @Test("named accessors are non-nil after prepareLayout even while inactive")
        func accessorsNonNilWhileInactive() {
            let parent = makeParent()
            let view = makeChild()
            parent.addSubview(view)

            _ = view.orbital.prepareLayout(.top(8), .leading(16), .trailing(16))

            #expect(view.orbital.topConstraint != nil)
            #expect(view.orbital.topConstraint?.isActive == false)
            #expect(view.orbital.leadingConstraint != nil)
            #expect(view.orbital.trailingConstraint != nil)
        }

        @Test("activate() activates all prepared constraints")
        func activateActivatesAll() {
            let parent = makeParent()
            let view = makeChild()
            parent.addSubview(view)

            let constraints = view.orbital.prepareLayout(.top(8), .leading(16), .trailing(16))
            constraints.activate()

            #expect(constraints.allSatisfy { $0.isActive })
            #expect(view.orbital.topConstraint?.isActive == true)
        }

        @Test("deactivate() deactivates all activated constraints")
        func deactivateDeactivatesAll() {
            let parent = makeParent()
            let view = makeChild()
            parent.addSubview(view)

            let constraints = view.orbital.layout(.top(8), .leading(16), .trailing(16))
            constraints.deactivate()

            #expect(constraints.allSatisfy { !$0.isActive })
        }

        @Test("reactivate after deactivate")
        func reactivateAfterDeactivate() {
            let parent = makeParent()
            let view = makeChild()
            parent.addSubview(view)

            let constraints = view.orbital.layout(.top(8), .leading(16))
            constraints.deactivate()
            constraints.activate()

            #expect(constraints.allSatisfy { $0.isActive })
        }
    }

    // MARK: - 8. Multiplier: .like()

    /// Verifies `.width.like(superview, 0.4)` and `.height.like(.width, 0.5)` constraints.
    @Suite("Multiplier via .like()")
    @MainActor
    struct MultiplierLike {

        @Test("width = 40% of superview width")
        func widthLikeSuperview() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .top(16),
                    .width.like(parent, 0.4)
                )
            }

            let widthC = view.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(abs((widthC?.multiplier ?? 0) - 0.4) < 0.001)
            #expect(widthC?.secondItem as? OrbitalView === parent)
        }

        @Test("height = twice another view's height")
        func heightLikeOtherView() {
            let parent = makeParent()
            let reference = makeChild()
            let view = makeChild()

            parent.orbit(reference, view) {
                reference.orbital.layout(.top(0), .leading(0), .height(50))
                view.orbital.layout(
                    .top(60),
                    .height.like(reference, 2)
                )
            }

            let heightC = view.orbital.heightConstraint
            #expect(heightC?.isActive == true)
            #expect(heightC?.multiplier == 2)
            #expect(heightC?.secondItem as? OrbitalView === reference)
        }

        @Test("height = 50% of another view's width (cross-dimension)")
        func heightLikeOtherViewWidth() {
            let parent = makeParent()
            let imageView = makeChild()
            let view = makeChild()

            parent.orbit(imageView, view) {
                imageView.orbital.layout(.top(0), .leading(0), .width(200), .height(200))
                view.orbital.layout(
                    .top(210),
                    .height.like(imageView, .width, 0.5)
                )
            }

            let heightC = view.orbital.heightConstraint
            #expect(heightC?.isActive == true)
            #expect(heightC?.multiplier == 0.5)
            #expect(heightC?.secondItem as? OrbitalView === imageView)
            #expect(heightC?.secondAttribute == .width)
        }

        @Test("height = own width * 0.4 (self-referential)")
        func heightLikeSelfWidth() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .top(16),
                    .width(200),
                    .height.like(.width, 0.4)
                )
            }

            let heightC = view.orbital.heightConstraint
            #expect(heightC?.isActive == true)
            #expect(abs((heightC?.multiplier ?? 0) - 0.4) < 0.001)
            #expect(heightC?.firstItem as? OrbitalView === view)
            #expect(heightC?.secondItem as? OrbitalView === view)
            #expect(heightC?.secondAttribute == .width)
        }

        @Test("equal width to another view (no multiplier arg)")
        func widthLikeOtherViewEqualWidth() {
            let parent = makeParent()
            let reference = makeChild()
            let view = makeChild()

            parent.orbit(reference, view) {
                reference.orbital.layout(.top(0), .leading(0), .width(150), .height(40))
                view.orbital.layout(
                    .top(50),
                    .width.like(reference)
                )
            }

            let widthC = view.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(widthC?.multiplier == 1.0)
            #expect(widthC?.secondItem as? OrbitalView === reference)
        }

        @Test("aspectRatio: width = height * ratio")
        func aspectRatio() {
            let parent = makeParent()
            let videoView = makeChild()

            parent.orbit(videoView) {
                videoView.orbital.layout(
                    .top(16),
                    .leading,
                    .trailing,
                    .aspectRatio(16.0 / 9.0)
                )
            }

            let widthC = videoView.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(abs((widthC?.multiplier ?? 0) - 16.0 / 9.0) < 0.0001)
            #expect(widthC?.firstItem as? OrbitalView === videoView)
            #expect(widthC?.secondItem as? OrbitalView === videoView)
            #expect(widthC?.secondAttribute == .height)
        }
    }

    // MARK: - 9. Sign Convention

    /// Verifies auto-negation and override modifiers (.asOffset / .asInset).
    @Suite("Sign convention")
    @MainActor
    struct SignConvention {

        @Test("trailing(16) constant is auto-negated to -16")
        func trailingAutoNegated() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(0), .trailing(16))
            }

            #expect(view.orbital.trailingConstraint?.constant == -16)
        }

        @Test("bottom(16) constant is auto-negated to -16")
        func bottomAutoNegated() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.leading(0), .bottom(16))
            }

            #expect(view.orbital.bottomConstraint?.constant == -16)
        }

        @Test("top(16) constant is NOT negated")
        func topNotNegated() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16), .leading(0))
            }

            #expect(view.orbital.topConstraint?.constant == 16)
        }

        @Test("cross-anchor bottom.to(header, .top) constant is auto-negated")
        func crossAnchorBottomToHeaderTop() {
            let parent = makeParent()
            let header = makeChild()
            let view = makeChild()

            parent.orbit(header, view) {
                header.orbital.layout(.top(0), .leading(0), .trailing(0), .height(44))
                view.orbital.layout(
                    .bottom(16).to(header, .top),
                    .leading(0)
                )
            }

            #expect(view.orbital.bottomConstraint?.constant == -16)
        }

        @Test("asOffset suppresses auto-negation on same-anchor trailing")
        func asOffsetSuppressesNegation() {
            let parent = makeParent()
            let avatar = makeChild()
            let view = makeChild()

            parent.orbit(avatar, view) {
                avatar.orbital.layout(.top(0), .leading(0))
                avatar.orbital.size(40)
                view.orbital.layout(
                    .top(0),
                    .trailing(8).to(avatar, .trailing).asOffset
                )
            }

            // .asOffset: constant should be +8 (not negated)
            #expect(view.orbital.trailingConstraint?.constant == 8)
        }

        @Test("asInset forces negation on cross-anchor")
        func asInsetForcesNegation() {
            let parent = makeParent()
            let header = makeChild()
            let view = makeChild()

            parent.orbit(header, view) {
                header.orbital.layout(.top(0), .leading(0), .trailing(0), .height(44))
                view.orbital.layout(
                    .bottom(16).to(header, .top).asInset,
                    .leading(0)
                )
            }

            // .asInset: constant should be -16
            #expect(view.orbital.bottomConstraint?.constant == -16)
        }

        @Test("right→left reverse spacer is auto-negated; left→right forward spacer is not")
        func rightLeftNegatedLeftRightNotNegated() {
            let parent = makeParent()
            let reference = makeChild()
            let viewA = makeChild()
            let viewB = makeChild()

            parent.orbit(reference, viewA, viewB) {
                reference.orbital.layout(.top(0), .leading(0), .width(40))
                // right→left: reverse spacer — should negate to -16
                viewA.orbital.layout(.top(0), .right(16).to(reference, .left))
                // left→right: forward spacer — should NOT negate, stays +16
                viewB.orbital.layout(.top(0), .left(16).to(reference, .right))
            }

            #expect(viewA.orbital.constraint(for: .right, relation: .equal)?.constant == -16)
            #expect(viewB.orbital.constraint(for: .left, relation: .equal)?.constant == 16)
        }

        @Test("asInset on centerX — forces negation even though centerX is not a trailing edge")
        func asInsetOnCenterX() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(0), .centerX(10).asInset)
            }

            #expect(view.orbital.centerXConstraint?.constant == -10)
        }

        @Test("right(16) constant is auto-negated to -16 (same as trailing)")
        func rightAutoNegated() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.right(16), .top(0))
            }

            #expect(view.orbital.constraint(for: .right, relation: .equal)?.constant == -16)
        }

        @Test("layout(.width(100), .width(300).orLess) stores both relations independently")
        func multipleRelationsSameAnchorCoexist() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(0), .width(100), .width(300).orLess)
            }

            #expect(view.orbital.widthConstraint?.constant == 100)
            #expect(view.orbital.widthConstraint?.isActive == true)
            let lessOrEqual = view.orbital.constraint(for: .width, relation: .lessOrEqual)
            #expect(lessOrEqual?.constant == 300)
            #expect(lessOrEqual?.isActive == true)
        }

        @Test("layout(.width(150)) replaces only .equal — .lessOrEqual on same anchor unchanged")
        func relayoutEqualDoesNotTouchOtherRelations() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(0), .width(100), .width(300).orLess)
            }
            let lessOrEqual = view.orbital.constraint(for: .width, relation: .lessOrEqual)
            view.orbital.layout(.width(150))

            #expect(view.orbital.widthConstraint?.constant == 150)
            #expect(view.orbital.constraint(for: .width, relation: .lessOrEqual) === lessOrEqual)
            #expect(lessOrEqual?.constant == 300)
        }
    }

    // MARK: - 10. Priority

    /// Verifies constraint priority is applied correctly.
    @Suite("Priority")
    @MainActor
    struct Priority {

        @Test("high priority constraint has priority 750")
        func highPriority() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16).priority(.high), .leading(0))
            }

            #expect(view.orbital.topConstraint?.priority.rawValue == 750)
        }

        @Test("low priority constraint has priority 250")
        func lowPriority() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.leading(0), .bottom(16).priority(.low))
            }

            #expect(view.orbital.bottomConstraint?.priority.rawValue == 250)
        }

        @Test("required priority constraint has priority 1000")
        func requiredPriority() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16).priority(.required), .leading(0))
            }

            #expect(view.orbital.topConstraint?.priority.rawValue == 1000)
        }

        @Test("custom priority value is applied")
        func customPriority() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.leading(0), .width(200).priority(.custom(600)))
            }

            #expect(view.orbital.widthConstraint?.priority.rawValue == 600)
        }

        @Test("custom priority at boundary values 1 and 999 are accepted")
        func customPriorityBoundaries() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .top(0).priority(.custom(1)),
                    .width(100).priority(.custom(999))
                )
            }

            #expect(view.orbital.topConstraint?.priority.rawValue == 1)
            #expect(view.orbital.widthConstraint?.priority.rawValue == 999)
        }
    }

    // MARK: - 11. Labeled Constraints

    /// Verifies that `.labeled()` sets the constraint identifier.
    @Suite("Debug labels")
    @MainActor
    struct DebugLabels {

        @Test("labeled constraint has correct identifier")
        func labeledIdentifier() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(
                    .top(16).labeled("card.top"),
                    .height(44).labeled("card.height")
                )
            }

            #expect(view.orbital.topConstraint?.identifier == "card.top")
            #expect(view.orbital.heightConstraint?.identifier == "card.height")
        }

        @Test("unlabeled constraint has nil identifier")
        func unlabeledNilIdentifier() {
            let parent = makeParent()
            let view = makeChild()

            parent.orbit(view) {
                view.orbital.layout(.top(16), .leading(16))
            }

            #expect(view.orbital.topConstraint?.identifier == nil)
        }
    }

    // MARK: - 12. Array overloads

    /// Verifies array-form overloads of `orbital()` produce identical results.
    @Suite("Array overloads")
    @MainActor
    struct ArrayOverloads {

        @Test("array children overload adds all as subviews")
        func arrayChildrenAdded() {
            let parent = makeParent()
            let child1 = makeChild()
            let child2 = makeChild()

            let children: [OrbitalView] = [child1, child2]
            parent.orbit(children) {
                child1.orbital.layout(.top(0), .leading(0))
                child1.orbital.size(40)
                child2.orbital.layout(.top(50), .leading(0))
                child2.orbital.size(40)
            }

            #expect(child1.superview === parent)
            #expect(child2.superview === parent)
        }

        @Test("array constraints overload applies constraints")
        func arrayConstraintsApplied() {
            let parent = makeParent()
            let child = makeChild()

            parent.orbit(add: child, [.top(16), .leading(16), .trailing(16)])

            #expect(child.superview === parent)
            #expect(child.orbital.topConstraint?.constant == 16)
            #expect(child.orbital.leadingConstraint?.constant == 16)
            #expect(child.orbital.trailingConstraint?.constant == -16)
        }
    }

    // MARK: - 13. Size shortcut: .width.to() and .height.to()

    /// Verifies that `.width.to(otherView)` and `.height.to(otherView)` work end-to-end.
    @Suite("Size shortcuts: dimension .to()")
    @MainActor
    struct DimensionToShortcut {

        @Test("width == another view's width via .to()")
        func widthToOtherView() {
            let parent = makeParent()
            let thumbnailView = makeChild()
            let headerView = makeChild()

            parent.orbit(thumbnailView, headerView) {
                headerView.orbital.layout(.top(0), .leading(0), .width(200), .height(44))
                thumbnailView.orbital.layout(
                    .top(50),
                    .width.to(headerView)           // width == headerView.width
                )
            }

            let widthC = thumbnailView.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(widthC?.firstAttribute == .width)
            #expect(widthC?.secondAttribute == .width)
            #expect(widthC?.secondItem as? OrbitalView === headerView)
            #expect(widthC?.constant == 0)
            #expect(widthC?.multiplier == 1.0)
        }

        @Test("width == another view's width with explicit anchor (.to(otherView, .width))")
        func widthToOtherViewExplicit() {
            let parent = makeParent()
            let thumbnailView = makeChild()
            let headerView = makeChild()

            parent.orbit(thumbnailView, headerView) {
                headerView.orbital.layout(.top(0), .leading(0), .width(200), .height(44))
                thumbnailView.orbital.layout(
                    .top(50),
                    .width.to(headerView, .width)   // explicit anchor — same result
                )
            }

            let widthC = thumbnailView.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(widthC?.secondAttribute == .width)
        }

        @Test("width == another view's height (cross-dimension via .to())")
        func widthToOtherViewHeight() {
            let parent = makeParent()
            let thumbnailView = makeChild()
            let headerView = makeChild()

            parent.orbit(thumbnailView, headerView) {
                headerView.orbital.layout(.top(0), .leading(0), .width(200), .height(100))
                thumbnailView.orbital.layout(
                    .top(50),
                    .width.to(headerView, .height)  // width == headerView.height
                )
            }

            let widthC = thumbnailView.orbital.widthConstraint
            #expect(widthC?.isActive == true)
            #expect(widthC?.firstAttribute == .width)
            #expect(widthC?.secondAttribute == .height)
            #expect(widthC?.secondItem as? OrbitalView === headerView)
        }
    }

#if canImport(UIKit)
    // MARK: - 14. Baseline Anchors (iOS / tvOS only)

    /// Verifies baseline anchor constraints from Section 17 of requirements.
    @Suite("Baseline anchors (iOS/tvOS)")
    @MainActor
    struct BaselineAnchors {

        @Test("firstBaseline.to(titleLabel, .firstBaseline) aligns labels")
        func firstBaselineAlignment() {
            let parent = makeParent()
            let titleLabel = UILabel()
            let valueLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            valueLabel.translatesAutoresizingMaskIntoConstraints = false

            parent.orbit(titleLabel, valueLabel) {
                titleLabel.orbital.layout(.top(16), .leading(16))
                valueLabel.orbital.layout(
                    .firstBaseline.to(titleLabel, .firstBaseline),
                    .leading(8).to(titleLabel, .trailing)
                )
            }

            let baselineC = valueLabel.orbital.constraint(for: .firstBaseline, relation: .equal)
            #expect(baselineC?.isActive == true)
            #expect(baselineC?.firstAttribute == .firstBaseline)
            #expect(baselineC?.secondAttribute == .firstBaseline)
            #expect(baselineC?.secondItem === titleLabel)
            #expect(baselineC?.constant == 0)
        }

        @Test("lastBaseline(4).to(mainLabel, .lastBaseline) with constant offset")
        func lastBaselineWithOffset() {
            let parent = makeParent()
            let mainLabel = UILabel()
            let footnote = UILabel()
            mainLabel.translatesAutoresizingMaskIntoConstraints = false
            footnote.translatesAutoresizingMaskIntoConstraints = false

            parent.orbit(mainLabel, footnote) {
                mainLabel.orbital.layout(.top(16), .leading(16))
                footnote.orbital.layout(
                    .lastBaseline(4).to(mainLabel, .lastBaseline),
                    .leading(8).to(mainLabel, .trailing)
                )
            }

            let baselineC = footnote.orbital.constraint(for: .lastBaseline, relation: .equal)
            #expect(baselineC?.isActive == true)
            #expect(baselineC?.constant == 4)
            #expect(baselineC?.firstAttribute == .lastBaseline)
            #expect(baselineC?.secondAttribute == .lastBaseline)
        }

        @Test("firstBaseline via constraint() single constraint helper")
        func firstBaselineViaConstraintMethod() {
            let parent = makeParent()
            let referenceLabel = UILabel()
            let targetLabel = UILabel()
            referenceLabel.translatesAutoresizingMaskIntoConstraints = false
            targetLabel.translatesAutoresizingMaskIntoConstraints = false

            parent.orbit(referenceLabel, targetLabel) {
                referenceLabel.orbital.layout(.top(16), .leading(16))
                let c = targetLabel.orbital.constraint(
                    .firstBaseline.to(referenceLabel, .firstBaseline)
                )
                targetLabel.orbital.layout(.leading(8).to(referenceLabel, .trailing))
                #expect(c.isActive)
                #expect(c.firstAttribute == .firstBaseline)
            }
        }
    }
#endif

    // MARK: - 15. Single constraint shortcut via orbit(child:descriptor) (was 13)

    /// Verifies the inline single-child orbital shortcut from Section 1 of requirements.
    @Suite("Inline orbital shortcut")
    @MainActor
    struct InlineOrbitalShortcut {

        @Test("single child with variadic inline constraints")
        func singleChildVariadic() {
            let parent = makeParent()
            let label = makeChild()

            parent.orbit(add: label, OrbitalDescriptor.top(16), OrbitalDescriptor.leading(16), OrbitalDescriptor.trailing(16))

            #expect(label.superview === parent)
            #expect(label.translatesAutoresizingMaskIntoConstraints == false)
            #expect(label.orbital.topConstraint?.constant == 16)
            #expect(label.orbital.leadingConstraint?.constant == 16)
            #expect(label.orbital.trailingConstraint?.constant == -16)
        }

        @Test("edges shortcut pins all four sides")
        func edgesShortcut() {
            let parent = makeParent()
            let imageView = makeChild()

            parent.orbit(add: imageView, OrbitalDescriptor.edges(4))

            #expect(imageView.orbital.topConstraint?.constant == 4)
            #expect(imageView.orbital.bottomConstraint?.constant == -4)
            #expect(imageView.orbital.leadingConstraint?.constant == 4)
            #expect(imageView.orbital.trailingConstraint?.constant == -4)
        }

        @Test("size(80) + center() places view centered with fixed size")
        func sizeAndCenter() {
            let parent = makeParent()
            let avatarView = makeChild()

            parent.orbit(add: avatarView, OrbitalDescriptor.size(80), OrbitalDescriptor.center())

            #expect(avatarView.orbital.widthConstraint?.constant == 80)
            #expect(avatarView.orbital.heightConstraint?.constant == 80)
            #expect(avatarView.orbital.centerXConstraint?.isActive == true)
            #expect(avatarView.orbital.centerYConstraint?.isActive == true)
        }
    }
}
