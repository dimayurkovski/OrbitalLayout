//
//  ConstraintFactory.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - ConstraintFactory

/// Converts an `OrbitalDescriptor` into an inactive `NSLayoutConstraint`.
///
/// This is a pure factory — it never activates, stores, or manages the constraint it creates.
/// Activation and storage are the caller's responsibility (`OrbitalProxy`).
///
/// ### Precondition failures
/// - No superview and no explicit target: the view must be in a hierarchy or `.to(...)` must
///   supply an explicit second item.
/// - Incompatible anchor types: e.g. constraining `.top` (y-axis) to `.width` (dimension).
@MainActor
enum ConstraintFactory {

    // MARK: - Test hooks

    /// Replaceable failure handler used in tests to intercept `preconditionFailure` calls.
    ///
    /// In production this is `nil` and the real `preconditionFailure` is called.
    /// Tests can set this to capture the failure message instead of crashing the process.
    ///
    /// - Note: This property exists in all build configurations so that `@testable import`
    ///   can access it without conditional compilation in the test target.
    static var failureHandler: ((String) -> Void)? = nil

    /// Replaceable print handler used in tests to capture `#if DEBUG` warning output.
    ///
    /// When non-nil, this closure is called instead of `print()` for all debug warnings.
    /// Set this in tests to verify that specific warnings are emitted.
    static var debugWarningHandler: ((String) -> Void)? = nil

    /// Calls the replaceable failure handler if set; otherwise forwards to `preconditionFailure`.
    ///
    /// When `failureHandler` is set (test mode), the handler is called and then `Swift.fatalError`
    /// is invoked with the same message — the test must wrap the call in `withKnownIssue` so that
    /// the Swift Testing runtime catches the trap signal gracefully.
    ///
    /// - Parameter message: The human-readable failure message.
    @inline(__always)
    private static func fail(_ message: String) -> Never {
        if let handler = failureHandler {
            handler(message)
        }
        preconditionFailure(message)
    }

    // MARK: - Public API

    /// Creates an inactive `NSLayoutConstraint` from the given descriptor for `view`.
    ///
    /// The returned constraint is **not activated**. Call `NSLayoutConstraint.activate([c])`
    /// or `c.isActive = true` when ready.
    ///
    /// - Parameters:
    ///   - descriptor: The fully-specified descriptor produced by the OrbitalLayout DSL.
    ///   - view: The view whose anchors form the left-hand side of the constraint.
    /// - Returns: An inactive `OrbitalConstraint` ready for activation.
    /// - Note: Triggers `preconditionFailure` when the view has no superview and no
    ///   explicit `.to()` target, or when source and target anchors are incompatible.
    static func make(from descriptor: OrbitalDescriptor, for view: OrbitalView) -> OrbitalConstraint {

        // MARK: 1. Resolve target item

        let resolvedTargetView: OrbitalView?
        let resolvedTargetGuide: OrbitalLayoutGuide?

        if let explicitView = descriptor.targetView {
            // Explicit view target (.to(view) or .like(view))
            resolvedTargetView = explicitView
            resolvedTargetGuide = nil
        } else if let explicitGuide = descriptor.targetGuide {
            // Explicit guide target (.to(guide, anchor))
            resolvedTargetView = nil
            resolvedTargetGuide = explicitGuide
        } else if descriptor.targetIsSelf {
            // Self-referencing (aspectRatio, .like(.width, 0.4))
            resolvedTargetView = view
            resolvedTargetGuide = nil
        } else {
            let isDimension = descriptor.anchor == .width || descriptor.anchor == .height
            if isDimension {
                // Dimension anchors may be constant-only (e.g. .width(200), .height(44))
                // — no second item needed; factory will use the constantOnly path.
                resolvedTargetView = nil
                resolvedTargetGuide = nil
            } else {
                // Non-dimension anchor: must have a superview
                guard let superview = view.superview else {
                    fail(
                        "OrbitalLayout: view must have a superview before adding constraints. " +
                        "Use .to() to specify an explicit target."
                    )
                }
                resolvedTargetView = superview
                resolvedTargetGuide = nil
            }
        }

        // MARK: 2. Resolve target anchor (infer if nil)

        let targetAnchor = descriptor.targetAnchor ?? descriptor.anchor

        // MARK: 3. Validate anchor compatibility

        validateAnchorCompatibility(source: descriptor.anchor, target: targetAnchor)

        // MARK: 4. Compute signed constant

        let constant = resolvedConstant(
            for: descriptor.anchor,
            targetAnchor: targetAnchor,
            constant: descriptor.constant,
            signOverride: descriptor.signOverride
        )

        // MARK: 5. Build constraint

        let constraint: OrbitalConstraint

        if descriptor.multiplier != 1 {
            constraint = makeWithMultiplier(
                descriptor: descriptor,
                view: view,
                targetView: resolvedTargetView,
                targetGuide: resolvedTargetGuide,
                targetAnchor: targetAnchor,
                constant: constant
            )
        } else {
            constraint = makeWithAnchorAPI(
                descriptor: descriptor,
                view: view,
                targetView: resolvedTargetView,
                targetGuide: resolvedTargetGuide,
                targetAnchor: targetAnchor,
                constant: constant
            )
        }

        // MARK: 6. Priority

        constraint.priority = descriptor.priority.layoutPriority

        // MARK: 7. Identifier

        if let label = descriptor.label {
            constraint.identifier = label
        }

        // MARK: 8. DEBUG warnings

        #if DEBUG
        emitDebugWarnings(descriptor: descriptor, view: view)
        #endif

        return constraint
    }

    // MARK: - Anchor compatibility

    /// Validates that `source` and `target` belong to the same axis group.
    ///
    /// Valid groups:
    /// - **x-axis**: `leading`, `trailing`, `left`, `right`, `centerX`
    /// - **y-axis**: `top`, `bottom`, `centerY` (+ `firstBaseline`, `lastBaseline` on UIKit)
    /// - **dimension**: `width`, `height`
    ///
    /// - Parameters:
    ///   - source: The source anchor on the constrained view.
    ///   - target: The resolved target anchor.
    private static func validateAnchorCompatibility(source: OrbitalAnchor, target: OrbitalAnchor) {
        let sourceGroup = anchorGroup(source)
        let targetGroup = anchorGroup(target)
        guard sourceGroup == targetGroup else {
            fail(
                "OrbitalLayout: incompatible anchor types — cannot constrain .\(source) to .\(target)."
            )
        }
    }

    // MARK: - Sign convention

    /// Applies the sign convention to the constant.
    ///
    /// - If `signOverride` is `.offset` → constant returned as-is (positive).
    /// - If `signOverride` is `.inset`  → constant negated.
    /// - Otherwise: auto-negate when source and target anchors are both a trailing/bottom/right edge.
    ///
    /// - Parameters:
    ///   - anchor: The source anchor.
    ///   - targetAnchor: The resolved target anchor.
    ///   - constant: The raw constant from the descriptor.
    ///   - signOverride: Optional override from `.asOffset` / `.asInset`.
    /// - Returns: The signed constant to use in the constraint.
    private static func resolvedConstant(
        for anchor: OrbitalAnchor,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat,
        signOverride: OrbitalDescriptor.SignOverride?
    ) -> CGFloat {
        switch signOverride {
        case .offset:
            return constant
        case .inset:
            return -constant
        case nil:
            // Auto-negate same-edge trailing/bottom/right constraints
            let isAutoNegated = isTrailingEdge(anchor) && anchor == targetAnchor
            return isAutoNegated ? -constant : constant
        }
    }

    // MARK: - Constraint construction (anchor-based API, multiplier = 1)

    /// Builds a constraint using the type-safe anchor API.
    ///
    /// Used when `multiplier == 1` (the common case).
    private static func makeWithAnchorAPI(
        descriptor: OrbitalDescriptor,
        view: OrbitalView,
        targetView: OrbitalView?,
        targetGuide: OrbitalLayoutGuide?,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        let relation = descriptor.relation

        switch descriptor.anchor {

        // MARK: Dimension anchors
        case .width:
            let source = view.widthAnchor
            if let guide = targetGuide {
                return dimensionConstraint(source, relation: relation, toGuide: guide, anchor: targetAnchor, constant: constant)
            }
            if let tv = targetView {
                return dimensionConstraint(source, relation: relation, to: tv, anchor: targetAnchor, constant: constant)
            }
            return dimensionConstantConstraint(source, relation: relation, constant: constant)

        case .height:
            let source = view.heightAnchor
            if let guide = targetGuide {
                return dimensionConstraint(source, relation: relation, toGuide: guide, anchor: targetAnchor, constant: constant)
            }
            if let tv = targetView {
                return dimensionConstraint(source, relation: relation, to: tv, anchor: targetAnchor, constant: constant)
            }
            return dimensionConstantConstraint(source, relation: relation, constant: constant)

        // MARK: X-axis anchors
        case .leading:
            return xAxisConstraint(view.leadingAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .trailing:
            return xAxisConstraint(view.trailingAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .left:
            return xAxisConstraint(view.leftAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .right:
            return xAxisConstraint(view.rightAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .centerX:
            return xAxisConstraint(view.centerXAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)

        // MARK: Y-axis anchors
        case .top:
            return yAxisConstraint(view.topAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .bottom:
            return yAxisConstraint(view.bottomAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)
        case .centerY:
            return yAxisConstraint(view.centerYAnchor, relation: relation,
                                   targetView: targetView, targetGuide: targetGuide,
                                   targetAnchor: targetAnchor, constant: constant)

        // MARK: Baseline (UIKit only)
#if canImport(UIKit)
        case .firstBaseline:
            guard let tv = targetView else {
                fail("OrbitalLayout: baseline anchors require an explicit target via .to().")
            }
            return baselineConstraint(view.firstBaselineAnchor, relation: relation,
                                      targetView: tv, targetAnchor: targetAnchor, constant: constant)
        case .lastBaseline:
            guard let tv = targetView else {
                fail("OrbitalLayout: baseline anchors require an explicit target via .to().")
            }
            return baselineConstraint(view.lastBaselineAnchor, relation: relation,
                                      targetView: tv, targetAnchor: targetAnchor, constant: constant)
#endif
        }
    }

    // MARK: - Constraint construction (item-based API, multiplier ≠ 1)

    /// Builds a constraint using the item-based `NSLayoutConstraint` initialiser.
    ///
    /// Used when `multiplier != 1` AND the anchor is a non-dimension type. For dimension
    /// anchors with a multiplier, the type-safe `NSLayoutDimension` API is used instead.
    private static func makeWithMultiplier(
        descriptor: OrbitalDescriptor,
        view: OrbitalView,
        targetView: OrbitalView?,
        targetGuide: OrbitalLayoutGuide?,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        let isDimension = descriptor.anchor == .width || descriptor.anchor == .height

        if isDimension {
            // Use type-safe NSLayoutDimension API with multiplier
            let source: NSLayoutDimension = descriptor.anchor == .width ? view.widthAnchor : view.heightAnchor
            let relation = descriptor.relation
            let multiplier = descriptor.multiplier

            if let guide = targetGuide {
                let targetDim = dimensionAnchor(for: targetAnchor, on: guide)
                switch relation {
                case .equal:
                    return source.constraint(equalTo: targetDim, multiplier: multiplier, constant: constant)
                case .lessOrEqual:
                    return source.constraint(lessThanOrEqualTo: targetDim, multiplier: multiplier, constant: constant)
                case .greaterOrEqual:
                    return source.constraint(greaterThanOrEqualTo: targetDim, multiplier: multiplier, constant: constant)
                }
            }

            guard let tv = targetView else {
                // Constant-only dimension constraint with multiplier is unusual, but handle gracefully
                return source.constraint(equalToConstant: constant)
            }
            let targetDim = dimensionAnchor(for: targetAnchor, on: tv)
            switch relation {
            case .equal:
                return source.constraint(equalTo: targetDim, multiplier: multiplier, constant: constant)
            case .lessOrEqual:
                return source.constraint(lessThanOrEqualTo: targetDim, multiplier: multiplier, constant: constant)
            case .greaterOrEqual:
                return source.constraint(greaterThanOrEqualTo: targetDim, multiplier: multiplier, constant: constant)
            }
        } else {
            // Fall back to item-based API for non-dimension anchors with multiplier
            let sourceAttr = nsLayoutAttribute(for: descriptor.anchor)
            let targetAttr = nsLayoutAttribute(for: targetAnchor)
            let nsRelation = nsLayoutRelation(for: descriptor.relation)
            let targetItem: AnyObject? = targetGuide ?? targetView

            return NSLayoutConstraint(
                item: view,
                attribute: sourceAttr,
                relatedBy: nsRelation,
                toItem: targetItem,
                attribute: targetAttr,
                multiplier: descriptor.multiplier,
                constant: constant
            )
        }
    }

    // MARK: - Axis anchor helpers

    /// Creates an x-axis constraint from `source` to the appropriate anchor on `targetView` or `targetGuide`.
    private static func xAxisConstraint(
        _ source: NSLayoutXAxisAnchor,
        relation: OrbitalRelation,
        targetView: OrbitalView?,
        targetGuide: OrbitalLayoutGuide?,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        if let guide = targetGuide {
            let target = xAnchor(for: targetAnchor, on: guide)
            return xAxisConstraint(source, relation: relation, to: target, constant: constant)
        }
        guard let tv = targetView else {
            fail("OrbitalLayout: no target resolved for x-axis anchor.")
        }
        let target = xAnchor(for: targetAnchor, on: tv)
        return xAxisConstraint(source, relation: relation, to: target, constant: constant)
    }

    private static func xAxisConstraint(
        _ source: NSLayoutXAxisAnchor,
        relation: OrbitalRelation,
        to target: NSLayoutXAxisAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        switch relation {
        case .equal:        return source.constraint(equalTo: target, constant: constant)
        case .lessOrEqual:  return source.constraint(lessThanOrEqualTo: target, constant: constant)
        case .greaterOrEqual: return source.constraint(greaterThanOrEqualTo: target, constant: constant)
        }
    }

    /// Creates a y-axis constraint from `source` to the appropriate anchor on `targetView` or `targetGuide`.
    private static func yAxisConstraint(
        _ source: NSLayoutYAxisAnchor,
        relation: OrbitalRelation,
        targetView: OrbitalView?,
        targetGuide: OrbitalLayoutGuide?,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        if let guide = targetGuide {
            let target = yAnchor(for: targetAnchor, on: guide)
            return yAxisConstraint(source, relation: relation, to: target, constant: constant)
        }
        guard let tv = targetView else {
            fail("OrbitalLayout: no target resolved for y-axis anchor.")
        }
        let target = yAnchor(for: targetAnchor, on: tv)
        return yAxisConstraint(source, relation: relation, to: target, constant: constant)
    }

    private static func yAxisConstraint(
        _ source: NSLayoutYAxisAnchor,
        relation: OrbitalRelation,
        to target: NSLayoutYAxisAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        switch relation {
        case .equal:        return source.constraint(equalTo: target, constant: constant)
        case .lessOrEqual:  return source.constraint(lessThanOrEqualTo: target, constant: constant)
        case .greaterOrEqual: return source.constraint(greaterThanOrEqualTo: target, constant: constant)
        }
    }

    /// Creates a dimension constraint from `source` to the matching dimension anchor on `targetView`.
    private static func dimensionConstraint(
        _ source: NSLayoutDimension,
        relation: OrbitalRelation,
        to targetView: OrbitalView,
        anchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        let target = dimensionAnchor(for: anchor, on: targetView)
        switch relation {
        case .equal:        return source.constraint(equalTo: target, constant: constant)
        case .lessOrEqual:  return source.constraint(lessThanOrEqualTo: target, constant: constant)
        case .greaterOrEqual: return source.constraint(greaterThanOrEqualTo: target, constant: constant)
        }
    }

    /// Creates a dimension constraint from `source` to the matching dimension anchor on `guide`.
    private static func dimensionConstraint(
        _ source: NSLayoutDimension,
        relation: OrbitalRelation,
        toGuide guide: OrbitalLayoutGuide,
        anchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        let target = dimensionAnchor(for: anchor, on: guide)
        switch relation {
        case .equal:        return source.constraint(equalTo: target, constant: constant)
        case .lessOrEqual:  return source.constraint(lessThanOrEqualTo: target, constant: constant)
        case .greaterOrEqual: return source.constraint(greaterThanOrEqualTo: target, constant: constant)
        }
    }

    /// Creates a constant-only dimension constraint (e.g. `.width(200)` with no target view).
    private static func dimensionConstantConstraint(
        _ source: NSLayoutDimension,
        relation: OrbitalRelation,
        constant: CGFloat
    ) -> OrbitalConstraint {
        switch relation {
        case .equal:        return source.constraint(equalToConstant: constant)
        case .lessOrEqual:  return source.constraint(lessThanOrEqualToConstant: constant)
        case .greaterOrEqual: return source.constraint(greaterThanOrEqualToConstant: constant)
        }
    }

#if canImport(UIKit)
    /// Creates a baseline constraint from `source` to the matching baseline anchor on `targetView`.
    ///
    /// - Note: iOS and tvOS only.
    private static func baselineConstraint(
        _ source: NSLayoutYAxisAnchor,
        relation: OrbitalRelation,
        targetView: OrbitalView,
        targetAnchor: OrbitalAnchor,
        constant: CGFloat
    ) -> OrbitalConstraint {
        let target = yAnchor(for: targetAnchor, on: targetView)
        return yAxisConstraint(source, relation: relation, to: target, constant: constant)
    }
#endif

    // MARK: - Anchor resolution helpers

    /// Returns the x-axis anchor for the given `OrbitalAnchor` on a view.
    private static func xAnchor(for anchor: OrbitalAnchor, on view: OrbitalView) -> NSLayoutXAxisAnchor {
        switch anchor {
        case .leading:  return view.leadingAnchor
        case .trailing: return view.trailingAnchor
        case .left:     return view.leftAnchor
        case .right:    return view.rightAnchor
        case .centerX:  return view.centerXAnchor
        default:
            fail("OrbitalLayout: \(anchor) is not an x-axis anchor.")
        }
    }

    /// Returns the x-axis anchor for the given `OrbitalAnchor` on a layout guide.
    private static func xAnchor(for anchor: OrbitalAnchor, on guide: OrbitalLayoutGuide) -> NSLayoutXAxisAnchor {
        switch anchor {
        case .leading:  return guide.leadingAnchor
        case .trailing: return guide.trailingAnchor
        case .left:     return guide.leftAnchor
        case .right:    return guide.rightAnchor
        case .centerX:  return guide.centerXAnchor
        default:
            fail("OrbitalLayout: \(anchor) is not an x-axis anchor on a layout guide.")
        }
    }

    /// Returns the y-axis anchor for the given `OrbitalAnchor` on a view.
    private static func yAnchor(for anchor: OrbitalAnchor, on view: OrbitalView) -> NSLayoutYAxisAnchor {
        switch anchor {
        case .top:      return view.topAnchor
        case .bottom:   return view.bottomAnchor
        case .centerY:  return view.centerYAnchor
#if canImport(UIKit)
        case .firstBaseline: return view.firstBaselineAnchor
        case .lastBaseline:  return view.lastBaselineAnchor
#endif
        default:
            fail("OrbitalLayout: \(anchor) is not a y-axis anchor.")
        }
    }

    /// Returns the y-axis anchor for the given `OrbitalAnchor` on a layout guide.
    private static func yAnchor(for anchor: OrbitalAnchor, on guide: OrbitalLayoutGuide) -> NSLayoutYAxisAnchor {
        switch anchor {
        case .top:    return guide.topAnchor
        case .bottom: return guide.bottomAnchor
        case .centerY: return guide.centerYAnchor
        default:
            fail("OrbitalLayout: \(anchor) is not a y-axis anchor on a layout guide.")
        }
    }

    /// Returns the dimension anchor for the given `OrbitalAnchor` on a view.
    private static func dimensionAnchor(for anchor: OrbitalAnchor, on view: OrbitalView) -> NSLayoutDimension {
        switch anchor {
        case .width:  return view.widthAnchor
        case .height: return view.heightAnchor
        default:
            fail("OrbitalLayout: \(anchor) is not a dimension anchor.")
        }
    }

    /// Returns the dimension anchor for the given `OrbitalAnchor` on a layout guide.
    private static func dimensionAnchor(for anchor: OrbitalAnchor, on guide: OrbitalLayoutGuide) -> NSLayoutDimension {
        switch anchor {
        case .width:  return guide.widthAnchor
        case .height: return guide.heightAnchor
        default:
            fail("OrbitalLayout: \(anchor) is not a dimension anchor on a layout guide.")
        }
    }

    // MARK: - Anchor group classification

    /// Identifies which axis group an anchor belongs to for compatibility checking.
    private enum AnchorGroup {
        case xAxis
        case yAxis
        case dimension
    }

    private static func anchorGroup(_ anchor: OrbitalAnchor) -> AnchorGroup {
        switch anchor {
        case .leading, .trailing, .left, .right, .centerX:
            return .xAxis
        case .top, .bottom, .centerY:
            return .yAxis
        case .width, .height:
            return .dimension
#if canImport(UIKit)
        case .firstBaseline, .lastBaseline:
            return .yAxis
#endif
        }
    }

    /// Returns `true` if the anchor is a trailing edge that participates in auto-negation.
    private static func isTrailingEdge(_ anchor: OrbitalAnchor) -> Bool {
        anchor == .trailing || anchor == .bottom || anchor == .right
    }

    // MARK: - NSLayoutConstraint item-based API helpers

    /// Maps `OrbitalAnchor` to `NSLayoutConstraint.Attribute` for the item-based fallback API.
    private static func nsLayoutAttribute(for anchor: OrbitalAnchor) -> NSLayoutConstraint.Attribute {
        switch anchor {
        case .top:      return .top
        case .bottom:   return .bottom
        case .leading:  return .leading
        case .trailing: return .trailing
        case .left:     return .left
        case .right:    return .right
        case .centerX:  return .centerX
        case .centerY:  return .centerY
        case .width:    return .width
        case .height:   return .height
#if canImport(UIKit)
        case .firstBaseline: return .firstBaseline
        case .lastBaseline:  return .lastBaseline
#endif
        }
    }

    /// Maps `OrbitalRelation` to `NSLayoutConstraint.Relation`.
    private static func nsLayoutRelation(for relation: OrbitalRelation) -> NSLayoutConstraint.Relation {
        switch relation {
        case .equal:        return .equal
        case .lessOrEqual:  return .lessThanOrEqual
        case .greaterOrEqual: return .greaterThanOrEqual
        }
    }

    // MARK: - DEBUG warnings

    #if DEBUG
    /// Emits debug warnings for common misuse patterns detected via descriptor flags.
    ///
    /// Routes output through ``debugWarningHandler`` when set (for tests), otherwise uses `print`.
    private static func emitDebugWarnings(descriptor: OrbitalDescriptor, view: OrbitalView) {
        // Warn when .like() was called but then overwritten by a subsequent .to()
        if descriptor.likeWasCalled && descriptor.targetView != nil && !descriptor.targetIsSelf {
            emitWarning(
                "OrbitalLayout [DEBUG]: .like() was called on descriptor for .\(descriptor.anchor), " +
                "but .to() was called afterwards and overwrote the target. " +
                "Only one of .like() / .to() should be used per descriptor."
            )
        }
        // Warn when a negative constant is passed for trailing/bottom/right
        // (auto-negation already handles this, but explicit negatives are usually a mistake)
        if isTrailingEdge(descriptor.anchor) && descriptor.constant < 0 {
            emitWarning(
                "OrbitalLayout [DEBUG]: Negative constant \(descriptor.constant) passed to " +
                ".\(descriptor.anchor) — auto-negation will make this a positive offset. " +
                "Pass a positive value to inset from the edge."
            )
        }
        // Warn when .aspectRatio() descriptor (targetIsSelf + .width + .height) is combined with .to()
        // targetIsSelf + likeWasCalled=false + explicit targetView means user wrote .aspectRatio().to(...)
        if descriptor.targetIsSelf && descriptor.targetAnchor == .height
            && descriptor.anchor == .width && !descriptor.likeWasCalled {
            if descriptor.targetView != nil {
                emitWarning(
                    "OrbitalLayout [DEBUG]: .aspectRatio() combined with .to() on anchor .\(descriptor.anchor). " +
                    ".aspectRatio() sets a self-referencing constraint — .to() has no effect and is ignored. " +
                    "Use .like() if you intend to relate to another view."
                )
            }
        }
    }

    /// Routes a warning message through ``debugWarningHandler`` or `print`.
    private static func emitWarning(_ message: String) {
        if let handler = debugWarningHandler {
            handler(message)
        } else {
            print(message)
        }
    }
    #endif
}
