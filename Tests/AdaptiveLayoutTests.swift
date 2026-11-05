//
//  AdaptiveLayoutTests.swift
//  OrbitalLayoutTests
//

import Testing
@testable import OrbitalLayout

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
private func makeHierarchy() -> (parent: OrbitalView, child: OrbitalView) {
    let parent = OrbitalView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    let child = OrbitalView()
    child.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(child)
    return (parent, child)
}

@MainActor
private func addSibling(to parent: OrbitalView) -> OrbitalView {
    let sibling = OrbitalView()
    sibling.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(sibling)
    return sibling
}

@Suite("Adaptive layout", .serialized)
@MainActor
struct AdaptiveLayoutTests {

    // MARK: - update() sign

    @Suite("update() keeps the sign convention")
    @MainActor
    struct UpdateSign {

        @Test("update(.trailing) keeps an inset, not an overhang")
        func trailingStaysInset() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.leading(16), .trailing(16))
            child.orbital.update(.trailing(24))
            #expect(child.orbital.trailingConstraint?.constant == -24)
        }

        @Test("update(.bottom) keeps an inset")
        func bottomStaysInset() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.bottom(16))
            child.orbital.update(.bottom(24))
            #expect(child.orbital.bottomConstraint?.constant == -24)
        }

        @Test("update(.right) keeps an inset")
        func rightStaysInset() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.right(16))
            child.orbital.update(.right(24))
            #expect(child.orbital.rightConstraint?.constant == -24)
        }

        @Test("update(.top) and update(.leading) stay positive")
        func topAndLeadingStayPositive() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(16), .leading(16))
            child.orbital.update(.top(24), .leading(24))
            #expect(child.orbital.topConstraint?.constant == 24)
            #expect(child.orbital.leadingConstraint?.constant == 24)
        }

        @Test("update(.edges) inverts only trailing and bottom")
        func edgesGroup() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.edges(8))
            child.orbital.update(.edges(24))
            #expect(child.orbital.topConstraint?.constant == 24)
            #expect(child.orbital.leadingConstraint?.constant == 24)
            #expect(child.orbital.bottomConstraint?.constant == -24)
            #expect(child.orbital.trailingConstraint?.constant == -24)
        }

        @Test("update() keeps the reverse spacer gap")
        func reverseSpacer() {
            let (parent, child) = makeHierarchy()
            let footer = addSibling(to: parent)
            child.orbital.layout(.bottom(8).to(footer, .top))
            child.orbital.update(.bottom(24))
            #expect(child.orbital.bottomConstraint?.constant == -24)
        }

        @Test("update() respects .asOffset from creation")
        func asOffsetStaysPositive() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            child.orbital.layout(.trailing(8).to(other, .trailing).asOffset)
            child.orbital.update(.trailing(24))
            #expect(child.orbital.trailingConstraint?.constant == 24)
        }

        @Test("update() respects .asInset from creation")
        func asInsetStaysNegative() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            child.orbital.layout(.top(8).to(other, .bottom).asInset)
            child.orbital.update(.top(24))
            #expect(child.orbital.topConstraint?.constant == -24)
        }

        @Test("update() with a negative value gives the same overhang as layout()")
        func negativeMatchesLayout() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.trailing(16))
            child.orbital.update(.trailing(-8))
            #expect(child.orbital.trailingConstraint?.constant == 8)
        }

        #if canImport(UIKit)
        @Test("update() insets both edges of a 300 pt container down to 252 pt")
        func resolvedWidth() {
            let (parent, child) = makeHierarchy()
            let window = UIWindow(frame: parent.frame)
            window.addSubview(parent)
            child.orbital.layout(.top(0), .leading(16), .trailing(16), .height(50))
            parent.layoutIfNeeded()
            child.orbital.update(.leading(24), .trailing(24))
            parent.layoutIfNeeded()
            #expect(child.frame.width == 252)
            #expect(child.frame.maxX == 276)
        }
        #endif
    }

    // MARK: - remake() relations

    @Suite("remake() replaces every relation on the anchor")
    @MainActor
    struct RemakeRelations {

        @Test("a new relation deactivates the old .equal")
        func equalToGreaterOrEqual() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(200))
            let old = child.orbital.topConstraint
            child.orbital.remake(.top(0).orMore)
            #expect(old?.isActive == false)
            #expect(child.orbital.topConstraint == nil)
            #expect(child.orbital.constraint(for: .top, relation: .greaterOrEqual)?.isActive == true)
        }

        @Test(".equal deactivates the old .orMore")
        func greaterOrEqualToEqual() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(0).orMore)
            let old = child.orbital.constraint(for: .top, relation: .greaterOrEqual)
            child.orbital.remake(.top(200))
            #expect(old?.isActive == false)
            #expect(child.orbital.constraint(for: .top, relation: .greaterOrEqual) == nil)
            #expect(child.orbital.topConstraint?.isActive == true)
        }

        @Test("relations listed in one call coexist")
        func sameCallCoexist() {
            let (parent, child) = makeHierarchy()
            child.orbital.layout(.width(8).orMore)
            child.orbital.remake(.width(0).like(parent, 0.5).priority(.high), .width(8).orMore)
            #expect(child.orbital.widthConstraint?.isActive == true)
            #expect(child.orbital.constraint(for: .width, relation: .greaterOrEqual)?.isActive == true)
        }

        @Test("other anchors keep their relations")
        func otherAnchorsUntouched() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.height(10).orMore, .top(5))
            let height = child.orbital.constraint(for: .height, relation: .greaterOrEqual)
            child.orbital.remake(.top(0).orMore)
            #expect(height?.isActive == true)
        }

        #if canImport(UIKit)
        @Test("the top edge returns after a fold appears and disappears")
        func foldRoundTrip() {
            let (parent, child) = makeHierarchy()
            let window = UIWindow(frame: parent.frame)
            window.addSubview(parent)
            child.orbital.layout(.bottom(0), .leading(0), .trailing(0), .height(250).priority(.low), .top(0).orMore)
            parent.layoutIfNeeded()
            #expect(child.frame.minY == 50)
            child.orbital.remake(.top(200))
            parent.layoutIfNeeded()
            #expect(child.frame.minY == 200)
            child.orbital.remake(.top(0).orMore)
            parent.layoutIfNeeded()
            #expect(child.frame.minY == 50)
        }
        #endif
    }

    // MARK: - remove()

    @Suite("remove()")
    @MainActor
    struct Remove {

        @Test("removes every relation on the anchor by default")
        func allRelations() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(5), .top(0).orMore)
            let equal = child.orbital.topConstraint
            let minimum = child.orbital.constraint(for: .top, relation: .greaterOrEqual)
            child.orbital.remove(.top)
            #expect(equal?.isActive == false)
            #expect(minimum?.isActive == false)
            #expect(child.orbital.topConstraint == nil)
            #expect(child.orbital.constraint(for: .top, relation: .greaterOrEqual) == nil)
        }

        @Test("removes only the given relation")
        func singleRelation() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(5), .top(0).orMore)
            let minimum = child.orbital.constraint(for: .top, relation: .greaterOrEqual)
            child.orbital.remove(.top, relation: .equal)
            #expect(child.orbital.topConstraint == nil)
            #expect(minimum?.isActive == true)
        }

        @Test("removes several anchors and leaves others")
        func severalAnchors() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(5), .bottom(5), .leading(5))
            child.orbital.remove(.top, .bottom)
            #expect(child.orbital.topConstraint == nil)
            #expect(child.orbital.bottomConstraint == nil)
            #expect(child.orbital.leadingConstraint?.isActive == true)
        }

        @Test("does nothing when the anchor has no constraint")
        func missingAnchor() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(5))
            child.orbital.remove(.height)
            #expect(child.orbital.topConstraint?.isActive == true)
        }

        #if canImport(UIKit)
        @Test("the top edge returns after a fold appears and disappears")
        func foldRoundTrip() {
            let (parent, child) = makeHierarchy()
            let window = UIWindow(frame: parent.frame)
            window.addSubview(parent)
            child.orbital.layout(.bottom(0), .leading(0), .trailing(0), .height(250).priority(.low), .top(200))
            parent.layoutIfNeeded()
            #expect(child.frame.minY == 200)
            child.orbital.remove(.top)
            parent.layoutIfNeeded()
            #expect(child.frame.minY == 50)
        }
        #endif
    }

    // MARK: - Group .to()

    @Suite("Group .to()")
    @MainActor
    struct GroupTarget {

        @Test(".edges(16).to(guide) pins all four edges to the guide with the right signs")
        func edgesToGuide() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.edges(16).to(guide))
            for constraint in [child.orbital.topConstraint, child.orbital.bottomConstraint, child.orbital.leadingConstraint, child.orbital.trailingConstraint] {
                #expect(constraint?.secondItem as? OrbitalLayoutGuide === guide)
            }
            #expect(child.orbital.topConstraint?.secondAttribute == .top)
            #expect(child.orbital.leadingConstraint?.constant == 16)
            #expect(child.orbital.bottomConstraint?.constant == -16)
            #expect(child.orbital.trailingConstraint?.constant == -16)
        }

        @Test(".horizontal(16).to(view) pins only the horizontal edges to the view")
        func horizontalToView() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            child.orbital.layout(.horizontal(16).to(other))
            #expect(child.orbital.leadingConstraint?.secondItem as? OrbitalView === other)
            #expect(child.orbital.trailingConstraint?.secondItem as? OrbitalView === other)
            #expect(child.orbital.trailingConstraint?.constant == -16)
            #expect(child.orbital.topConstraint == nil)
        }

        @Test(".center().to(guide) centers on the guide")
        func centerToGuide() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.center().to(guide))
            #expect(child.orbital.centerXConstraint?.secondItem as? OrbitalLayoutGuide === guide)
            #expect(child.orbital.centerYConstraint?.secondItem as? OrbitalLayoutGuide === guide)
        }

        @Test("update() on a group pinned to a guide keeps its signs")
        func updateKeepsSigns() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.edges(16).to(guide))
            child.orbital.update(.edges(24))
            #expect(child.orbital.bottomConstraint?.constant == -24)
            #expect(child.orbital.trailingConstraint?.secondItem as? OrbitalLayoutGuide === guide)
        }
    }

    // MARK: - .like(guide)

    @Suite(".like(guide)")
    @MainActor
    struct LikeGuide {

        @Test(".width.like(guide, 0.5) scales the guide width")
        func matchingAnchor() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.width.like(guide, 0.5))
            let width = child.orbital.widthConstraint
            #expect(width?.secondItem as? OrbitalLayoutGuide === guide)
            #expect(width?.secondAttribute == .width)
            #expect(width?.multiplier == 0.5)
        }

        @Test(".height.like(guide, .width, 0.25) uses the given guide anchor")
        func explicitAnchor() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.height.like(guide, .width, 0.25))
            let height = child.orbital.heightConstraint
            #expect(height?.secondItem as? OrbitalLayoutGuide === guide)
            #expect(height?.secondAttribute == .width)
            #expect(height?.multiplier == 0.25)
        }

        @Test(".like(guide) defaults the multiplier to 1")
        func defaultMultiplier() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout(.width.like(guide))
            #expect(child.orbital.widthConstraint?.multiplier == 1)
            #expect(child.orbital.widthConstraint?.secondItem as? OrbitalLayoutGuide === guide)
        }
    }

    // MARK: - Empty edge calls

    @Suite("Edge factories without arguments")
    @MainActor
    struct EmptyEdgeCalls {

        @Test("edge calls without arguments mean zero in a mixed list")
        func zeroConstants() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout([.top(), .bottom(), .leading(), .trailing(), .height(44)])
            #expect(child.orbital.topConstraint?.constant == 0)
            #expect(child.orbital.bottomConstraint?.constant == 0)
            #expect(child.orbital.leadingConstraint?.constant == 0)
            #expect(child.orbital.trailingConstraint?.constant == 0)
        }

        @Test("left and right without arguments mean zero")
        func leftRight() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.left(), .right())
            #expect(child.orbital.leftConstraint?.constant == 0)
            #expect(child.orbital.rightConstraint?.constant == 0)
        }

        @Test("edge calls without arguments chain into .to()")
        func chained() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            child.orbital.layout([.top().to(guide, .top), .bottom().to(guide, .bottom)])
            #expect(child.orbital.topConstraint?.secondItem as? OrbitalLayoutGuide === guide)
            #expect(child.orbital.bottomConstraint?.secondItem as? OrbitalLayoutGuide === guide)
        }
    }

    // MARK: - .like() warning

    #if DEBUG
    @Suite(".like() overwrite warning", .serialized)
    @MainActor
    struct LikeWarning {

        private func warnings(_ descriptor: OrbitalDescriptor, on child: OrbitalView) -> [String] {
            var captured: [String] = []
            ConstraintFactory.debugWarningHandler = { captured.append($0) }
            _ = ConstraintFactory.make(from: descriptor, for: child)
            ConstraintFactory.debugWarningHandler = nil
            return captured
        }

        @Test(".like(view) alone stays silent")
        func likeViewSilent() {
            let (parent, child) = makeHierarchy()
            #expect(warnings(.width.like(parent, 0.5), on: child).isEmpty)
        }

        @Test(".like(view, anchor) alone stays silent")
        func likeViewAnchorSilent() {
            let (parent, child) = makeHierarchy()
            #expect(warnings(.height.like(parent, .width, 0.5), on: child).isEmpty)
        }

        @Test(".like(view) with other modifiers stays silent")
        func likeWithModifiersSilent() {
            let (parent, child) = makeHierarchy()
            #expect(warnings(.width.like(parent, 0.5).priority(.high).orLess.labeled("w"), on: child).isEmpty)
        }

        @Test(".to() before .like() stays silent")
        func toBeforeLikeSilent() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            #expect(warnings(.width.to(other).like(parent, 0.5), on: child).isEmpty)
        }

        @Test(".like(view).to(view) warns")
        func likeThenToViewWarns() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            #expect(warnings(.width.like(parent, 0.5).to(other), on: child).count == 1)
        }

        @Test(".like(view).to(guide) warns")
        func likeThenToGuideWarns() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            #expect(warnings(.width.like(parent, 0.5).to(guide), on: child).count == 1)
        }

        @Test(".like(guide).to(view) warns")
        func likeGuideThenToViewWarns() {
            let (parent, child) = makeHierarchy()
            let guide = OrbitalLayoutGuide()
            parent.addLayoutGuide(guide)
            #expect(warnings(.width.like(guide, 0.5).to(parent), on: child).count == 1)
        }

        @Test("the warning survives modifiers after .to()")
        func modifiersKeepWarning() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            let descriptor = OrbitalDescriptor.width.like(parent, 0.5).to(other).priority(.high).orMore.orLess.asOffset.asInset.labeled("w")
            #expect(warnings(descriptor, on: child).count == 1)
        }

        @Test("a later .like() clears the warning")
        func laterLikeClears() {
            let (parent, child) = makeHierarchy()
            let other = addSibling(to: parent)
            #expect(warnings(OrbitalDescriptor.width.like(parent, 0.5).to(other).like(other, 0.25), on: child).isEmpty)
        }
    }
    #endif

    // MARK: - update() after reparenting

    #if DEBUG
    @Suite("update() warns about constraints lost on reparenting", .serialized)
    @MainActor
    struct UpdateAfterReparent {

        private func capture(_ body: () -> Void) -> [String] {
            var warnings: [String] = []
            OrbitalProxy.debugWarningHandler = { warnings.append($0) }
            body()
            OrbitalProxy.debugWarningHandler = nil
            return warnings
        }

        @Test("warns when the superview changed and the constraint died")
        func warnsAfterReparent() {
            let (parent, child) = makeHierarchy()
            let other = OrbitalView()
            child.orbital.layout(.top(10))
            child.removeFromSuperview()
            other.addSubview(child)
            let warnings = capture { child.orbital.update(.top(99)) }
            #expect(warnings.contains { $0.contains("superview") && $0.contains(".top") })
            _ = parent
        }

        @Test("stays silent for a prepared constraint")
        func silentForPrepared() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.prepareLayout(.top(10))
            let warnings = capture { child.orbital.update(.top(99)) }
            #expect(warnings.isEmpty)
        }

        @Test("stays silent for a constraint the caller deactivated")
        func silentForManualToggle() {
            let (parent, child) = makeHierarchy()
            _ = parent
            child.orbital.layout(.top(10))
            child.orbital.topConstraint?.isActive = false
            let warnings = capture { child.orbital.update(.top(99)) }
            #expect(warnings.isEmpty)
        }
    }
    #endif
}
