//
//  OrbitalProxyTests.swift
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

/// Returns a child view already added to a parent, plus its `OrbitalProxy`.
/// Task 11 will expose `view.orbital` — until then, tests instantiate `OrbitalProxy` directly.
@MainActor
private func makeViewInHierarchy() -> (parent: OrbitalView, child: OrbitalView, proxy: OrbitalProxy) {
    let parent = OrbitalView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let child = OrbitalView()
    child.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(child)
    let proxy = OrbitalProxy(view: child)
    return (parent, child, proxy)
}

// MARK: - OrbitalProxyTests

@Suite("OrbitalProxy")
@MainActor
struct OrbitalProxyTests {

    // MARK: - Single Constraint Shortcuts

    @Suite("Single constraint shortcuts")
    @MainActor
    struct SingleShortcuts {

        @Test("top() creates an active constraint stored under .top")
        func topShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.top(16)
            #expect(c.isActive)
            #expect(proxy.topConstraint === c)
            #expect(c.constant == 16)
        }

        @Test("bottom() creates an active constraint stored under .bottom (constant auto-negated)")
        func bottomShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.bottom(16)
            #expect(c.isActive)
            #expect(proxy.bottomConstraint === c)
            // ConstraintFactory auto-negates same-edge bottom
            #expect(c.constant == -16)
        }

        @Test("leading() creates an active constraint stored under .leading")
        func leadingShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.leading(8)
            #expect(c.isActive)
            #expect(proxy.leadingConstraint === c)
            #expect(c.constant == 8)
        }

        @Test("trailing() creates an active constraint stored under .trailing (constant auto-negated)")
        func trailingShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.trailing(8)
            #expect(c.isActive)
            #expect(proxy.trailingConstraint === c)
            #expect(c.constant == -8)
        }

        @Test("left() creates an active constraint stored under .left")
        func leftShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.left(4)
            #expect(c.isActive)
            #expect(proxy.leftConstraint === c)
            #expect(c.constant == 4)
        }

        @Test("right() creates an active constraint stored under .right (constant auto-negated)")
        func rightShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.right(4)
            #expect(c.isActive)
            #expect(proxy.rightConstraint === c)
            #expect(c.constant == -4)
        }

        @Test("width() creates an active dimension constraint")
        func widthShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.width(100)
            #expect(c.isActive)
            #expect(proxy.widthConstraint === c)
            #expect(c.constant == 100)
        }

        @Test("height() creates an active dimension constraint")
        func heightShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.height(44)
            #expect(c.isActive)
            #expect(proxy.heightConstraint === c)
            #expect(c.constant == 44)
        }

        @Test("centerX() creates an active constraint with default offset 0")
        func centerXShortcut() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.centerX()
            #expect(c.isActive)
            #expect(proxy.centerXConstraint === c)
            #expect(c.constant == 0)
        }

        @Test("centerY() creates an active constraint with the given offset")
        func centerYShortcutWithOffset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.centerY(8)
            #expect(c.isActive)
            #expect(proxy.centerYConstraint === c)
            #expect(c.constant == 8)
        }

        @Test("Discarded return value still activates and stores the constraint")
        func discardedReturnActivatesAndStores() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.top(20)
            #expect(proxy.topConstraint != nil)
            #expect(proxy.topConstraint?.isActive == true)
            #expect(proxy.topConstraint?.constant == 20)
        }

        @Test("top() with default constant 0")
        func topDefaultConstant() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.top()
            #expect(c.constant == 0)
        }

        @Test("centerX() with non-zero offset")
        func centerXWithOffset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.centerX(12)
            #expect(c.constant == 12)
        }
    }

    // MARK: - constraint() with chaining

    @Suite("constraint() with chaining")
    @MainActor
    struct ConstraintWithChaining {

        @Test("constraint() stores and returns the constraint")
        func constraintMethod() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.constraint(.top(16))
            #expect(c.isActive)
            #expect(proxy.topConstraint === c)
        }

        @Test("constraint() with .to() cross-anchor and .orMore")
        func constraintWithToAndRelation() {
            let (parent, _, proxy) = makeViewInHierarchy()
            let header = OrbitalView()
            header.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(header)

            let c = proxy.constraint(.top(8).to(header, .bottom).orMore)
            #expect(c.isActive)
            #expect(c.relation == .greaterThanOrEqual)
            #expect(c.constant == 8)
            #expect(c.secondItem === header)
        }

        @Test("constraint() with priority")
        func constraintWithPriority() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.constraint(.height(44).priority(.high))
            #expect(c.isActive)
            #expect(c.priority.rawValue == 750)
        }

        @Test("constraint() with .labeled sets identifier")
        func constraintWithLabel() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.constraint(.top(16).labeled("headerTop"))
            #expect(c.identifier == "headerTop")
        }

        @Test("constraint() full chain: .to() .orMore .priority() .labeled()")
        func fullChain() {
            let (parent, _, proxy) = makeViewInHierarchy()
            let header = OrbitalView()
            header.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(header)

            let c = proxy.constraint(
                .top(8).to(header, .bottom).orMore.priority(.high).labeled("fullChain")
            )
            #expect(c.isActive)
            #expect(c.relation == .greaterThanOrEqual)
            #expect(c.constant == 8)
            #expect(c.priority.rawValue == 750)
            #expect(c.identifier == "fullChain")
            #expect(c.secondItem === header)
        }
    }

    // MARK: - layout()

    @Suite("layout()")
    @MainActor
    struct BatchLayout {

        @Test("layout() activates all constraints")
        func layoutActivatesAll() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.top(8), .leading(16), .trailing(16))
            #expect(constraints.count == 3)
            #expect(constraints.allSatisfy { $0.isActive })
        }

        @Test("layout() stores all constraints under correct keys")
        func layoutStoresAll() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(8), .leading(16), .height(200))
            #expect(proxy.topConstraint?.constant == 8)
            #expect(proxy.leadingConstraint?.constant == 16)
            #expect(proxy.heightConstraint?.constant == 200)
        }

        @Test("layout() with group descriptor expands into individual constraints")
        func layoutWithGroup() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(OrbitalDescriptor.edges(12))
            #expect(constraints.count == 4)
            #expect(proxy.topConstraint?.constant == 12)
            #expect(proxy.leadingConstraint?.constant == 12)
            // bottom/trailing are auto-negated
            #expect(proxy.bottomConstraint?.constant == -12)
            #expect(proxy.trailingConstraint?.constant == -12)
        }

        @Test("layout() overwrites previous constraint for same anchor+relation")
        func layoutOverwritesSameAnchor() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let first = proxy.layout(.top(16)).first!
            let second = proxy.layout(.top(32)).first!

            // Old constraint is deactivated
            #expect(!first.isActive)
            // New constraint is active
            #expect(second.isActive)
            // Accessor returns the new one
            #expect(proxy.topConstraint === second)
        }

        @Test("layout() allows different relations on the same anchor to coexist")
        func layoutMultipleRelationsSameAnchor() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.width(200), .width(300).orLess)
            #expect(proxy.widthConstraint?.constant == 200)
            let lessOrEqual = proxy.constraint(for: .width, relation: .lessOrEqual)
            #expect(lessOrEqual?.constant == 300)
            #expect(proxy.widthConstraint?.isActive == true)
            #expect(lessOrEqual?.isActive == true)
        }

        @Test("layout() array overload works identically to variadic")
        func layoutArrayOverload() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let descriptors: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.top(8), OrbitalDescriptor.height(100)]
            let constraints = proxy.layout(descriptors)
            #expect(constraints.count == 2)
            #expect(constraints.allSatisfy { $0.isActive })
        }

        @Test("layout() returns empty array for empty input")
        func layoutEmptyInput() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints: [OrbitalConstraint] = proxy.layout([any OrbitalConstraintConvertible]())
            #expect(constraints.isEmpty)
        }

        @Test("layout(.edges) — leading-dot group shortcut resolves without type prefix")
        func layoutLeadingDotEdgesFlush() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.edges)
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.topConstraint?.constant == 0)
            #expect(proxy.leadingConstraint?.constant == 0)
            #expect(proxy.bottomConstraint?.constant == 0)
            #expect(proxy.trailingConstraint?.constant == 0)
        }

        @Test("layout(.edges(inset)) — leading-dot group shortcut with inset")
        func layoutLeadingDotEdgesInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.edges(16))
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.topConstraint?.constant == 16)
            #expect(proxy.leadingConstraint?.constant == 16)
            // bottom/trailing auto-negated
            #expect(proxy.bottomConstraint?.constant == -16)
            #expect(proxy.trailingConstraint?.constant == -16)
        }

        @Test("layout(.size, .center) — multiple group shortcuts via leading-dot")
        func layoutLeadingDotMultipleGroups() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.size(80), .center())
            // size → width + height (2), center → centerX + centerY (2)
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.widthConstraint?.constant == 80)
            #expect(proxy.heightConstraint?.constant == 80)
            #expect(proxy.centerXConstraint?.constant == 0)
            #expect(proxy.centerYConstraint?.constant == 0)
        }

        @Test("layout(.leading(8), .centerY(), .size(24)) — mixed descriptor + group shortcuts")
        func layoutMixedDescriptorAndGroup() {
            // Regression: mixing single-anchor descriptors and group shortcuts in one
            // variadic call must type-check via leading-dot on any OrbitalConstraintConvertible.
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.leading(8), .centerY(), .size(24))
            // leading (1) + centerY (1) + size → width+height (2)
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.leadingConstraint?.constant == 8)
            #expect(proxy.centerYConstraint?.constant == 0)
            #expect(proxy.widthConstraint?.constant == 24)
            #expect(proxy.heightConstraint?.constant == 24)
        }

        @Test("layout(.edges(16), .centerY()) — group + descriptor mix, group first")
        func layoutMixedGroupFirstThenDescriptor() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.layout(.edges(16), .centerY(4))
            // edges → 4 + centerY → 1 (centerY overwrites the anchor but we asked twice on different anchors)
            #expect(constraints.count == 5)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.topConstraint?.constant == 16)
            #expect(proxy.centerYConstraint?.constant == 4)
        }
    }

    // MARK: - prepareLayout()

    @Suite("prepareLayout()")
    @MainActor
    struct PrepareLayout {

        @Test("prepareLayout() creates but does NOT activate constraints")
        func prepareLayoutDoesNotActivate() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.prepareLayout(.top(8), .leading(16))
            #expect(constraints.count == 2)
            #expect(constraints.allSatisfy { c in !c.isActive })
        }

        @Test("prepareLayout() stores constraints — named accessors return them while inactive")
        func prepareLayoutStores() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.prepareLayout(.top(8), .height(44))
            #expect(proxy.topConstraint != nil)
            #expect(proxy.topConstraint?.isActive == false)
            #expect(proxy.heightConstraint != nil)
            #expect(proxy.heightConstraint?.isActive == false)
        }

        @Test("activate() on prepareLayout result makes all constraints active")
        func prepareLayoutThenActivate() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.prepareLayout(.top(8), .leading(16))
            NSLayoutConstraint.activate(constraints)
            #expect(constraints.allSatisfy { $0.isActive })
        }

        @Test("prepareLayout() array overload works identically to variadic")
        func prepareLayoutArrayOverload() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let descriptors: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.top(0), OrbitalDescriptor.width(50)]
            let constraints = proxy.prepareLayout(descriptors)
            #expect(constraints.count == 2)
            #expect(constraints.allSatisfy { c in !c.isActive })
        }

        @Test("prepareLayout() returns empty array for empty input")
        func prepareLayoutEmptyInput() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints: [OrbitalConstraint] = proxy.prepareLayout([any OrbitalConstraintConvertible]())
            #expect(constraints.isEmpty)
        }

        @Test("prepareLayout(.edges) — leading-dot group shortcut, inactive")
        func prepareLayoutLeadingDotEdgesFlush() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.prepareLayout(.edges)
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { !$0.isActive })
            #expect(proxy.topConstraint?.constant == 0)
            #expect(proxy.leadingConstraint?.constant == 0)
            #expect(proxy.bottomConstraint?.constant == 0)
            #expect(proxy.trailingConstraint?.constant == 0)
        }

        @Test("prepareLayout(.edges(inset)) — leading-dot group shortcut with inset, inactive")
        func prepareLayoutLeadingDotEdgesInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.prepareLayout(.edges(10))
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { !$0.isActive })
            #expect(proxy.topConstraint?.constant == 10)
            #expect(proxy.leadingConstraint?.constant == 10)
            #expect(proxy.bottomConstraint?.constant == -10)
            #expect(proxy.trailingConstraint?.constant == -10)
        }
    }

    // MARK: - Stored Constraint Accessors

    @Suite("Stored constraint accessors")
    @MainActor
    struct StoredAccessors {

        @Test("All named accessors return nil before any constraint is created")
        func allAccessorsNilInitially() {
            let child = OrbitalView()
            let proxy = OrbitalProxy(view: child)
            #expect(proxy.topConstraint == nil)
            #expect(proxy.bottomConstraint == nil)
            #expect(proxy.leadingConstraint == nil)
            #expect(proxy.trailingConstraint == nil)
            #expect(proxy.leftConstraint == nil)
            #expect(proxy.rightConstraint == nil)
            #expect(proxy.widthConstraint == nil)
            #expect(proxy.heightConstraint == nil)
            #expect(proxy.centerXConstraint == nil)
            #expect(proxy.centerYConstraint == nil)
        }

        @Test("Each named accessor returns the corresponding .equal constraint")
        func allNamedAccessors() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(
                .top(1), .bottom(2), .leading(3), .trailing(4),
                .left(5), .right(6), .width(7), .height(8),
                .centerX(9), .centerY(10)
            )
            #expect(proxy.topConstraint?.constant == 1)
            #expect(proxy.bottomConstraint?.constant == -2)
            #expect(proxy.leadingConstraint?.constant == 3)
            #expect(proxy.trailingConstraint?.constant == -4)
            #expect(proxy.leftConstraint?.constant == 5)
            #expect(proxy.rightConstraint?.constant == -6)
            #expect(proxy.widthConstraint?.constant == 7)
            #expect(proxy.heightConstraint?.constant == 8)
            #expect(proxy.centerXConstraint?.constant == 9)
            #expect(proxy.centerYConstraint?.constant == 10)
        }

        @Test("Mutating constant via named accessor works")
        func mutateConstantViaAccessor() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.height(200)
            proxy.heightConstraint?.constant = 300
            #expect(proxy.heightConstraint?.constant == 300)
        }
    }

    // MARK: - constraint(for:relation:)

    @Suite("constraint(for:relation:)")
    @MainActor
    struct ConstraintForRelation {

        @Test("Returns nil when no constraint stored for that anchor+relation")
        func returnsNilWhenMissing() {
            let child = OrbitalView()
            let proxy = OrbitalProxy(view: child)
            #expect(proxy.constraint(for: .width, relation: .lessOrEqual) == nil)
        }

        @Test("Returns the correct constraint for a non-equal relation")
        func returnsNonEqualConstraint() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.width(200), .width(300).orLess)
            let c = proxy.constraint(for: .width, relation: .lessOrEqual)
            #expect(c != nil)
            #expect(c?.constant == 300)
            #expect(c?.relation == .lessThanOrEqual)
        }

        @Test("Equal and greaterOrEqual constraints on same anchor are independent")
        func equalAndGreaterCoexist() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.height(100), .height(200).orMore)
            let eq = proxy.heightConstraint
            let geq = proxy.constraint(for: .height, relation: .greaterOrEqual)
            #expect(eq !== geq)
            #expect(eq?.isActive == true)
            #expect(geq?.isActive == true)
        }

        @Test("constraint(for:relation:) returns .equal constraint same as named accessor")
        func equalRelationMatchesNamedAccessor() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.top(24)
            let viaMethod = proxy.constraint(for: .top, relation: .equal)
            let viaAccessor = proxy.topConstraint
            #expect(viaMethod === viaAccessor)
        }
    }

    // MARK: - Group Shortcuts (Task 8)

    @Suite("Group shortcuts")
    @MainActor
    struct GroupShortcuts {

        // MARK: edges

        @Test("edges (property) creates 4 active constraints flush to superview")
        func edgesProperty() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.edges
            #expect(constraints.count == 4)
            #expect(constraints.allSatisfy { $0.isActive })
            #expect(proxy.topConstraint?.constant == 0)
            #expect(proxy.leadingConstraint?.constant == 0)
            #expect(proxy.bottomConstraint?.constant == 0)
            #expect(proxy.trailingConstraint?.constant == 0)
        }

        @Test("edges(_:) creates 4 active constraints with auto-negated bottom/trailing")
        func edgesWithInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.edges(16)
            #expect(constraints.count == 4)
            #expect(proxy.topConstraint?.constant == 16)
            #expect(proxy.leadingConstraint?.constant == 16)
            #expect(proxy.bottomConstraint?.constant == -16)
            #expect(proxy.trailingConstraint?.constant == -16)
        }

        @Test("edges(_:) zero inset equals flush edges")
        func edgesZeroInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.edges(0)
            #expect(proxy.topConstraint?.constant == 0)
            #expect(proxy.bottomConstraint?.constant == 0)
        }

        // MARK: horizontal

        @Test("horizontal (property) creates 2 constraints: leading and trailing flush")
        func horizontalProperty() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.horizontal
            #expect(constraints.count == 2)
            #expect(proxy.leadingConstraint?.constant == 0)
            #expect(proxy.trailingConstraint?.constant == 0)
            #expect(proxy.topConstraint == nil)
            #expect(proxy.bottomConstraint == nil)
        }

        @Test("horizontal(_:) creates leading and trailing with auto-negated trailing")
        func horizontalWithInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.horizontal(8)
            #expect(constraints.count == 2)
            #expect(proxy.leadingConstraint?.constant == 8)
            #expect(proxy.trailingConstraint?.constant == -8)
        }

        // MARK: vertical

        @Test("vertical (property) creates 2 constraints: top and bottom flush")
        func verticalProperty() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.vertical
            #expect(constraints.count == 2)
            #expect(proxy.topConstraint?.constant == 0)
            #expect(proxy.bottomConstraint?.constant == 0)
            #expect(proxy.leadingConstraint == nil)
            #expect(proxy.trailingConstraint == nil)
        }

        @Test("vertical(_:) creates top and bottom with auto-negated bottom")
        func verticalWithInset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.vertical(24)
            #expect(constraints.count == 2)
            #expect(proxy.topConstraint?.constant == 24)
            #expect(proxy.bottomConstraint?.constant == -24)
        }

        // MARK: size

        @Test("size(_:) creates width and height constraints with equal value")
        func sizeSquare() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.size(80)
            #expect(constraints.count == 2)
            #expect(proxy.widthConstraint?.constant == 80)
            #expect(proxy.heightConstraint?.constant == 80)
            #expect(constraints.allSatisfy { $0.isActive })
        }

        @Test("size(width:height:) creates constraints with distinct values")
        func sizeExplicit() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.size(width: 320, height: 180)
            #expect(constraints.count == 2)
            #expect(proxy.widthConstraint?.constant == 320)
            #expect(proxy.heightConstraint?.constant == 180)
        }

        // MARK: aspectRatio

        @Test("aspectRatio(_:) creates a width-to-height multiplier constraint")
        func aspectRatioConstraint() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let c = proxy.aspectRatio(2.0)
            #expect(c.isActive)
            // self.width = self.height * 2 → multiplier == 2
            #expect(c.multiplier == 2.0)
        }

        @Test("aspectRatio(_:) constraint is stored under .width / .equal")
        func aspectRatioStored() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.aspectRatio(1.5)
            #expect(proxy.widthConstraint != nil)
        }

        // MARK: center

        @Test("center() creates centerX and centerY constraints at offset zero")
        func centerDefault() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.center()
            #expect(constraints.count == 2)
            #expect(proxy.centerXConstraint?.constant == 0)
            #expect(proxy.centerYConstraint?.constant == 0)
            #expect(constraints.allSatisfy { $0.isActive })
        }

        @Test("center(offset:) creates centerX and centerY with CGPoint offsets")
        func centerWithOffset() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            let constraints = proxy.center(offset: CGPoint(x: 10, y: -5))
            #expect(constraints.count == 2)
            #expect(proxy.centerXConstraint?.constant == 10)
            #expect(proxy.centerYConstraint?.constant == -5)
        }

        @Test("center(offset: .zero) equals center()")
        func centerOffsetZero() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.center(offset: .zero)
            #expect(proxy.centerXConstraint?.constant == 0)
            #expect(proxy.centerYConstraint?.constant == 0)
        }
    }

    // MARK: - update() (Task 9)

    @Suite("update()")
    @MainActor
    struct Update {

        @Test("update() changes constant of existing constraint — same object")
        func updateChangesConstant() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16), .height(200))
            let originalTop = proxy.topConstraint
            let originalHeight = proxy.heightConstraint

            proxy.update(.top(24), .height(300))

            // Same object — constant mutated in place
            #expect(proxy.topConstraint === originalTop)
            #expect(proxy.heightConstraint === originalHeight)
            #expect(proxy.topConstraint?.constant == 24)
            #expect(proxy.heightConstraint?.constant == 300)
        }

        @Test("update() with group descriptor updates all matching anchors")
        func updateWithGroup() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(8), .bottom(8), .leading(8), .trailing(8))

            // OrbitalDescriptorGroup conforms to OrbitalConstraintConvertible — use group overload
            proxy.update(OrbitalDescriptor.edges(24))

            #expect(proxy.topConstraint?.constant == 24)
            // bottom/trailing are auto-negated by ConstraintFactory at creation time,
            // but update() writes the raw constant from the descriptor directly
            #expect(proxy.bottomConstraint?.constant == 24)
            #expect(proxy.leadingConstraint?.constant == 24)
            #expect(proxy.trailingConstraint?.constant == 24)
        }

        @Test("update() skips anchors with no stored constraint — no crash")
        func updateMissingAnchorNocrash() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            // No constraints set up at all
            proxy.update(.width(100))   // should not crash
            #expect(proxy.widthConstraint == nil)
        }

        @Test("update() ignores relation modifier — still updates the .equal constraint")
        func updateIgnoresRelation() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.height(100))
            // Passing .orLess on update — relation is ignored, .equal constraint is updated
            proxy.update(OrbitalDescriptor.height(200).orLess)
            #expect(proxy.heightConstraint?.constant == 200)
            #expect(proxy.heightConstraint?.relation == .equal)
        }

        @Test("update() ignores priority modifier — constraint priority is unchanged")
        func updateIgnoresPriority() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16))
            let before = proxy.topConstraint?.priority

            proxy.update(OrbitalDescriptor.top(24).priority(.low))

            #expect(proxy.topConstraint?.constant == 24)
            #expect(proxy.topConstraint?.priority == before)
        }

        @Test("update() array overload works identically to variadic")
        func updateArrayOverload() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16), .height(200))
            let items: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.top(32), OrbitalDescriptor.height(400)]
            proxy.update(items)
            #expect(proxy.topConstraint?.constant == 32)
            #expect(proxy.heightConstraint?.constant == 400)
        }

        @Test("update(.edges(inset)) — leading-dot group shortcut updates all 4 edges")
        func updateLeadingDotEdges() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(8), .bottom(8), .leading(8), .trailing(8))
            proxy.update(.edges(24))
            #expect(proxy.topConstraint?.constant == 24)
            #expect(proxy.bottomConstraint?.constant == 24)
            #expect(proxy.leadingConstraint?.constant == 24)
            #expect(proxy.trailingConstraint?.constant == 24)
        }
    }

    // MARK: - remake() (Task 9)

    @Suite("remake()")
    @MainActor
    struct Remake {

        @Test("remake() deactivates old constraint and creates a new active one")
        func remakeDeactivatesOldCreatesNew() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16))
            let old = proxy.topConstraint

            proxy.remake(.top(8))
            let new = proxy.topConstraint

            #expect(old?.isActive == false)
            #expect(new?.isActive == true)
            #expect(new !== old)
            #expect(new?.constant == 8)
        }

        @Test("remake() stored accessor returns the new constraint")
        func remakeAccessorReturnsNew() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.height(200))
            proxy.remake(.height(120))
            #expect(proxy.heightConstraint?.constant == 120)
        }

        @Test("remake() leaves unmentioned constraints untouched")
        func remakeDoesNotAffectOtherAnchors() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16), .leading(16), .trailing(16), .height(200))
            let originalLeading = proxy.leadingConstraint
            let originalTrailing = proxy.trailingConstraint

            proxy.remake(.top(8), .height(120))

            // top and height are replaced
            #expect(proxy.topConstraint?.constant == 8)
            #expect(proxy.heightConstraint?.constant == 120)
            // leading and trailing are untouched (same object, still active)
            #expect(proxy.leadingConstraint === originalLeading)
            #expect(proxy.trailingConstraint === originalTrailing)
            #expect(proxy.leadingConstraint?.isActive == true)
            #expect(proxy.trailingConstraint?.isActive == true)
        }

        @Test("remake() with a different target creates constraint to new target")
        func remakeWithDifferentTarget() {
            let (parent, _, proxy) = makeViewInHierarchy()
            let header = OrbitalView()
            header.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(header)
            let nav = OrbitalView()
            nav.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(nav)

            proxy.layout(.top(8).to(header, .bottom))
            let old = proxy.topConstraint
            #expect(old?.secondItem === header)

            proxy.remake(OrbitalDescriptor.top(12).to(nav, .bottom))
            let new = proxy.topConstraint
            #expect(new?.secondItem === nav)
            #expect(old?.isActive == false)
        }

        @Test("remake() without a prior constraint creates a new one")
        func remakeCreatesNewWhenNoPrior() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            // No layout() called first
            proxy.remake(.width(100))
            #expect(proxy.widthConstraint?.constant == 100)
            #expect(proxy.widthConstraint?.isActive == true)
        }

        @Test("remake() changes relation when specified")
        func remakeChangesRelation() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.height(200))
            proxy.remake(OrbitalDescriptor.height(120).orLess)

            // .equal is now gone (remade as .lessOrEqual)
            let lessOrEqual = proxy.constraint(for: .height, relation: .lessOrEqual)
            #expect(lessOrEqual?.constant == 120)
            #expect(lessOrEqual?.isActive == true)
        }

        @Test("remake() array overload works identically to variadic")
        func remakeArrayOverload() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16), .height(200))
            let items: [any OrbitalConstraintConvertible] = [OrbitalDescriptor.top(8), OrbitalDescriptor.height(120)]
            proxy.remake(items)
            #expect(proxy.topConstraint?.constant == 8)
            #expect(proxy.heightConstraint?.constant == 120)
        }

        @Test("remake(.edges(inset)) — leading-dot group shortcut replaces all 4 edges")
        func remakeLeadingDotEdges() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent; _ = child
            proxy.layout(.top(16), .bottom(16), .leading(16), .trailing(16))
            proxy.remake(.edges(8))
            #expect(proxy.topConstraint?.constant == 8)
            #expect(proxy.leadingConstraint?.constant == 8)
            #expect(proxy.bottomConstraint?.constant == -8)
            #expect(proxy.trailingConstraint?.constant == -8)
            #expect(proxy.topConstraint?.isActive == true)
        }
    }

    // MARK: - OrbitalProxy init

    @Suite("OrbitalProxy init")
    @MainActor
    struct ProxyInit {

        @Test("view property reflects the associated view")
        func viewProperty() {
            let view = OrbitalView()
            let proxy = OrbitalProxy(view: view)
            #expect(proxy.view === view)
        }

        @Test("view property is weak — proxy does not retain view")
        func viewIsWeak() {
            var proxy: OrbitalProxy?
            do {
                let view = OrbitalView()
                proxy = OrbitalProxy(view: view)
                #expect(proxy?.view != nil)
            }
            // view goes out of scope; proxy.view should be nil
            #expect(proxy?.view == nil)
        }
    }

    // MARK: - Size shortcuts: .width.to() / .height.to()

    @Suite("Size shortcuts: dimension .to()")
    @MainActor
    struct DimensionTo {

        /// Verifies `.width.to(otherView)` creates a width == otherView.width constraint.
        /// This is section 5 of the API reference: `.width.to(otherView)`.
        @Test("width.to(otherView) creates width == otherView.width constraint")
        func widthToOtherView() {
            let (parent, child, proxy) = makeViewInHierarchy()
            let other = OrbitalView()
            other.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(other)

            let c = proxy.constraint(.width.to(other))
            #expect(c.isActive)
            #expect(c.firstAttribute == .width)
            #expect(c.secondAttribute == .width)
            #expect(c.secondItem as? OrbitalView === other)
            #expect(c.constant == 0)
        }

        /// Verifies `.height.to(otherView)` creates a height == otherView.height constraint.
        @Test("height.to(otherView) creates height == otherView.height constraint")
        func heightToOtherView() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = child
            let other = OrbitalView()
            other.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(other)

            let c = proxy.constraint(.height.to(other))
            #expect(c.isActive)
            #expect(c.firstAttribute == .height)
            #expect(c.secondAttribute == .height)
            #expect(c.secondItem as? OrbitalView === other)
        }

        /// Verifies `.width.to(otherView, .height)` creates a cross-dimension constraint.
        @Test("width.to(otherView, .height) creates width == otherView.height constraint")
        func widthToOtherViewHeight() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = child
            let other = OrbitalView()
            other.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(other)

            let c = proxy.constraint(.width.to(other, .height))
            #expect(c.isActive)
            #expect(c.firstAttribute == .width)
            #expect(c.secondAttribute == .height)
            #expect(c.secondItem as? OrbitalView === other)
        }

        /// Verifies `.width(40).to(headerView, .width)` creates width == headerView.width + 40.
        @Test("width(40).to(otherView, .width) creates width == otherView.width + 40")
        func widthWithOffsetToOtherView() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = child
            let other = OrbitalView()
            other.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(other)

            let c = proxy.constraint(.width(40).to(other, .width))
            #expect(c.isActive)
            #expect(c.firstAttribute == .width)
            #expect(c.secondAttribute == .width)
            #expect(c.constant == 40)
        }
    }

    // MARK: - Baseline anchors (UIKit / tvOS only)

#if canImport(UIKit)
    @Suite("Baseline anchors")
    @MainActor
    struct BaselineAnchors {

        /// Verifies `.firstBaseline.to(label, .firstBaseline)` creates a baseline constraint.
        @Test("firstBaseline.to(label, .firstBaseline) creates active baseline constraint")
        func firstBaselineToLabel() {
            let (parent, _, proxy) = makeViewInHierarchy()
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(label)

            let c = proxy.constraint(.firstBaseline.to(label, .firstBaseline))
            #expect(c.isActive)
            #expect(c.firstAttribute == .firstBaseline)
            #expect(c.secondAttribute == .firstBaseline)
            #expect(c.secondItem === label)
        }

        /// Verifies `.lastBaseline(8).to(titleLabel, .lastBaseline)` with constant offset.
        @Test("lastBaseline(8).to(label, .lastBaseline) applies constant offset")
        func lastBaselineWithConstant() {
            let (parent, _, proxy) = makeViewInHierarchy()
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(label)

            let c = proxy.constraint(.lastBaseline(8).to(label, .lastBaseline))
            #expect(c.isActive)
            #expect(c.constant == 8)
            #expect(c.firstAttribute == .lastBaseline)
            #expect(c.secondAttribute == .lastBaseline)
        }

        /// Verifies baseline constraint is stored under the correct anchor key.
        @Test("firstBaseline constraint is stored and accessible")
        func firstBaselineStored() {
            let (parent, child, _) = makeViewInHierarchy()
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(label)

            child.orbital.layout(.firstBaseline.to(label, .firstBaseline))
            let c = child.orbital.constraint(for: .firstBaseline, relation: .equal)
            #expect(c != nil)
            #expect(c?.isActive == true)
            #expect(c?.firstAttribute == .firstBaseline)
        }
    }
#endif

    // MARK: - Content Hugging / Compression Resistance

    @Suite("hugging and compression")
    @MainActor
    struct HuggingCompression {

        @Test("hugging(.high, .horizontal) sets contentHuggingPriority to .defaultHigh")
        func huggingHighHorizontal() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.hugging(.high, axis: .horizontal)
            #expect(child.contentHuggingPriority(for: .horizontal) == .defaultHigh)
        }

        @Test("hugging(.low, .vertical) sets contentHuggingPriority to .defaultLow")
        func huggingLowVertical() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.hugging(.low, axis: .vertical)
            #expect(child.contentHuggingPriority(for: .vertical) == .defaultLow)
        }

        @Test("hugging(.required, .horizontal) sets contentHuggingPriority to .required")
        func huggingRequired() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.hugging(.required, axis: .horizontal)
            #expect(child.contentHuggingPriority(for: .horizontal) == .required)
        }

        @Test("hugging(.custom(600), .vertical) sets contentHuggingPriority to 600")
        func huggingCustom() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.hugging(.custom(600), axis: .vertical)
            #expect(child.contentHuggingPriority(for: .vertical) == OrbitalLayoutPriority(600))
        }

        @Test("compression(.required, .horizontal) sets compressionResistance to .required")
        func compressionRequiredHorizontal() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.compression(.required, axis: .horizontal)
            #expect(child.contentCompressionResistancePriority(for: .horizontal) == .required)
        }

        @Test("compression(.low, .vertical) sets compressionResistance to .defaultLow")
        func compressionLowVertical() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.compression(.low, axis: .vertical)
            #expect(child.contentCompressionResistancePriority(for: .vertical) == .defaultLow)
        }

        @Test("compression(.high, .horizontal) sets compressionResistance to .defaultHigh")
        func compressionHighHorizontal() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.compression(.high, axis: .horizontal)
            #expect(child.contentCompressionResistancePriority(for: .horizontal) == .defaultHigh)
        }

        @Test("compression(.custom(400), .vertical) sets compressionResistance to 400")
        func compressionCustom() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.compression(.custom(400), axis: .vertical)
            #expect(child.contentCompressionResistancePriority(for: .vertical) == OrbitalLayoutPriority(400))
        }

        @Test("hugging horizontal and vertical can be set independently")
        func huggingBothAxes() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.hugging(.high, axis: .horizontal)
            proxy.hugging(.low, axis: .vertical)
            #expect(child.contentHuggingPriority(for: .horizontal) == .defaultHigh)
            #expect(child.contentHuggingPriority(for: .vertical) == .defaultLow)
        }

        @Test("compression horizontal and vertical can be set independently")
        func compressionBothAxes() {
            let (parent, child, proxy) = makeViewInHierarchy()
            _ = parent
            proxy.compression(.required, axis: .horizontal)
            proxy.compression(.low, axis: .vertical)
            #expect(child.contentCompressionResistancePriority(for: .horizontal) == .required)
            #expect(child.contentCompressionResistancePriority(for: .vertical) == .defaultLow)
        }
    }
}
