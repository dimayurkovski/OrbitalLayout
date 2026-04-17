//
//  OrbitalProxy.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - OrbitalProxy

/// The main entry point for all OrbitalLayout constraint operations on a view.
///
/// Access an `OrbitalProxy` for any view via the `view.orbital` computed property.
/// The proxy provides single-constraint shortcuts, batch layout, update/remake, and
/// stored constraint accessors — all scoped to its associated view.
///
/// ```swift
/// // Single shortcut
/// view.orbital.top(16)
///
/// // Batch layout
/// view.orbital.layout(.top(8), .leading(16), .trailing(16), .height(44))
///
/// // Stored accessor
/// view.orbital.heightConstraint?.constant = 100
/// ```
@MainActor
public final class OrbitalProxy {

    // MARK: - Test hooks

    /// Replaceable debug warning handler used in tests to capture `#if DEBUG` output from `update()`.
    ///
    /// When non-nil, this closure is called instead of `print()` for all update-related debug warnings.
    /// Set this in tests to verify that specific warnings are emitted without relying on stdout.
    static var debugWarningHandler: ((String) -> Void)? = nil

    // MARK: - Properties

    /// The view this proxy is associated with.
    ///
    /// Held weakly to avoid retain cycles when the proxy is captured by closures.
    public private(set) weak var view: OrbitalView?

    // MARK: - Init

    /// Creates a proxy for the given view.
    ///
    /// - Parameter view: The view whose constraints this proxy manages.
    public init(view: OrbitalView) {
        self.view = view
    }

    // MARK: - Internal helpers

    /// Returns the storage associated with the current view, or `nil` if the view is deallocated.
    private var storage: ConstraintStorage? {
        view?.orbitalStorage
    }

    /// Creates, activates, stores, and returns a single constraint from `descriptor`.
    @discardableResult
    private func makeActivateStore(_ descriptor: OrbitalDescriptor) -> OrbitalConstraint {
        guard let view else {
            preconditionFailure("OrbitalLayout: OrbitalProxy's view has been deallocated.")
        }
        let constraint = ConstraintFactory.make(from: descriptor, for: view)
        constraint.isActive = true
        view.orbitalStorage.store(constraint, for: descriptor.anchor, relation: descriptor.relation)
        return constraint
    }

    /// Creates and stores a constraint from `descriptor` **without** activating it.
    @discardableResult
    private func makePrepareStore(_ descriptor: OrbitalDescriptor) -> OrbitalConstraint {
        guard let view else {
            preconditionFailure("OrbitalLayout: OrbitalProxy's view has been deallocated.")
        }
        let constraint = ConstraintFactory.make(from: descriptor, for: view)
        view.orbitalStorage.store(constraint, for: descriptor.anchor, relation: descriptor.relation)
        return constraint
    }

    // MARK: - Single Constraint Shortcuts

    /// Constrains the view's top anchor to its superview's top anchor.
    ///
    /// This is a convenience shortcut. When chaining modifiers (`.to()`, `.orMore`, `.priority()`)
    /// is needed, use ``constraint(_:)`` instead.
    ///
    /// - Parameter constant: The inset from the superview's top edge. Defaults to `0`.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func top(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.top(constant))
    }

    /// Constrains the view's bottom anchor to its superview's bottom anchor.
    ///
    /// This is a convenience shortcut. When chaining modifiers (`.to()`, `.orMore`, `.priority()`)
    /// is needed, use ``constraint(_:)`` instead.
    ///
    /// - Parameter constant: The inset from the superview's bottom edge. Defaults to `0`.
    ///   Internally auto-negated for same-edge constraints.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func bottom(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.bottom(constant))
    }

    /// Constrains the view's leading anchor to its superview's leading anchor.
    ///
    /// This is a convenience shortcut. When chaining modifiers (`.to()`, `.orMore`, `.priority()`)
    /// is needed, use ``constraint(_:)`` instead.
    ///
    /// - Parameter constant: The inset from the superview's leading edge. Defaults to `0`.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func leading(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.leading(constant))
    }

    /// Constrains the view's trailing anchor to its superview's trailing anchor.
    ///
    /// This is a convenience shortcut. When chaining modifiers (`.to()`, `.orMore`, `.priority()`)
    /// is needed, use ``constraint(_:)`` instead.
    ///
    /// - Parameter constant: The inset from the superview's trailing edge. Defaults to `0`.
    ///   Internally auto-negated for same-edge constraints.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func trailing(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.trailing(constant))
    }

    /// Constrains the view's left anchor to its superview's left anchor.
    ///
    /// Prefer ``leading(_:)`` for RTL-safe layouts.
    ///
    /// - Parameter constant: The inset from the superview's left edge. Defaults to `0`.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func left(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.left(constant))
    }

    /// Constrains the view's right anchor to its superview's right anchor.
    ///
    /// Prefer ``trailing(_:)`` for RTL-safe layouts.
    ///
    /// - Parameter constant: The inset from the superview's right edge. Defaults to `0`.
    ///   Internally auto-negated for same-edge constraints.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func right(_ constant: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.right(constant))
    }

    /// Constrains the view's width to a fixed constant.
    ///
    /// - Parameter constant: The width in points.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func width(_ constant: CGFloat) -> OrbitalConstraint {
        makeActivateStore(.width(constant))
    }

    /// Constrains the view's height to a fixed constant.
    ///
    /// - Parameter constant: The height in points.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func height(_ constant: CGFloat) -> OrbitalConstraint {
        makeActivateStore(.height(constant))
    }

    /// Constrains the view's centerX anchor to its superview's centerX anchor.
    ///
    /// - Parameter offset: The horizontal offset from center. Defaults to `0`.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func centerX(_ offset: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.centerX(offset))
    }

    /// Constrains the view's centerY anchor to its superview's centerY anchor.
    ///
    /// - Parameter offset: The vertical offset from center. Defaults to `0`.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func centerY(_ offset: CGFloat = 0) -> OrbitalConstraint {
        makeActivateStore(.centerY(offset))
    }

    // MARK: - Single Constraint with Chaining

    /// Creates, activates, stores, and returns a constraint from a fully-chained descriptor.
    ///
    /// Use this method when single-constraint shortcuts are insufficient — for example, when
    /// `.to()`, `.orMore`, or `.priority()` modifiers are required on a single constraint.
    ///
    /// ```swift
    /// let c = view.orbital.constraint(.top(16).to(header, .bottom).orMore.priority(.high))
    /// c.constant = 24
    /// ```
    ///
    /// - Parameter descriptor: A fully-specified ``OrbitalDescriptor``.
    /// - Returns: The activated, stored `OrbitalConstraint`.
    @discardableResult
    public func constraint(_ descriptor: OrbitalDescriptor) -> OrbitalConstraint {
        makeActivateStore(descriptor)
    }

    // MARK: - Batch Layout

    /// Creates, activates, stores, and returns constraints for all given descriptors.
    ///
    /// If a constraint for the same `anchor + relation` combination was stored previously,
    /// the previous constraint is **deactivated and replaced** by the new one.
    ///
    /// ```swift
    /// view.orbital.layout(
    ///     .top(8).to(header, .bottom),
    ///     .leading(16),
    ///     .trailing(16),
    ///     .height(200)
    /// )
    /// ```
    ///
    /// - Parameter items: One or more ``OrbitalDescriptor`` values.
    /// - Returns: All activated `OrbitalConstraint` instances, in declaration order.
    @discardableResult
    public func layout(_ items: OrbitalDescriptor...) -> [OrbitalConstraint] {
        items.map { makeActivateStore($0) }
    }

    /// Group-accepting overload of ``layout(_:)-variadic``.
    ///
    /// Enables leading-dot syntax for ``OrbitalDescriptorGroup`` shortcuts such as
    /// `.edges`, `.edges(16)`, `.size(80)`, `.horizontal(16)`, and `.center()`.
    ///
    /// ```swift
    /// view.orbital.layout(.edges(16))
    /// view.orbital.layout(.size(80), .center())
    /// ```
    ///
    /// - Parameter groups: One or more ``OrbitalDescriptorGroup`` values.
    /// - Returns: All activated `OrbitalConstraint` instances.
    @discardableResult
    public func layout(_ groups: OrbitalDescriptorGroup...) -> [OrbitalConstraint] {
        groups.flatMap { $0.asDescriptors() }.map { makeActivateStore($0) }
    }

    /// Mixed-type variadic overload of ``layout(_:)-variadic``.
    ///
    /// Accepts any ``OrbitalConstraintConvertible`` — useful for passing a mix of
    /// ``OrbitalDescriptor`` and ``OrbitalDescriptorGroup`` values stored in typed variables.
    ///
    /// - Parameter items: One or more ``OrbitalConstraintConvertible`` values.
    /// - Returns: All activated `OrbitalConstraint` instances.
    @discardableResult
    public func layout(_ items: any OrbitalConstraintConvertible...) -> [OrbitalConstraint] {
        items.flatMap { $0.asDescriptors() }.map { makeActivateStore($0) }
    }

    /// Array-accepting overload of ``layout(_:)-variadic``.
    ///
    /// Useful when the descriptor list is built dynamically.
    ///
    /// - Parameter items: An array of ``OrbitalConstraintConvertible`` values.
    /// - Returns: All activated `OrbitalConstraint` instances.
    @discardableResult
    public func layout(_ items: [any OrbitalConstraintConvertible]) -> [OrbitalConstraint] {
        items.flatMap { $0.asDescriptors() }.map { makeActivateStore($0) }
    }

    // MARK: - Prepare Layout (no activation)

    /// Creates and stores constraints for all given descriptors **without activating them**.
    ///
    /// Named accessors (`topConstraint`, etc.) will return these constraints even while inactive.
    /// Call `.activate()` on the returned array when ready.
    ///
    /// ```swift
    /// let constraints = view.orbital.prepareLayout(.top(8), .leading(16))
    /// // ... later ...
    /// constraints.activate()
    /// ```
    ///
    /// - Parameter items: One or more ``OrbitalDescriptor`` values.
    /// - Returns: All created (inactive) `OrbitalConstraint` instances.
    @discardableResult
    public func prepareLayout(_ items: OrbitalDescriptor...) -> [OrbitalConstraint] {
        items.map { makePrepareStore($0) }
    }

    /// Group overload of ``prepareLayout(_:)-variadic`` enabling leading-dot syntax for
    /// ``OrbitalDescriptorGroup`` shortcuts such as `.edges`, `.edges(16)`, `.size(80)`.
    ///
    /// - Parameter groups: One or more ``OrbitalDescriptorGroup`` values.
    /// - Returns: All created (inactive) `OrbitalConstraint` instances.
    @discardableResult
    public func prepareLayout(_ groups: OrbitalDescriptorGroup...) -> [OrbitalConstraint] {
        groups.flatMap { $0.asDescriptors() }.map { makePrepareStore($0) }
    }

    /// Mixed-type variadic overload of ``prepareLayout(_:)-variadic``.
    ///
    /// - Parameter items: One or more ``OrbitalConstraintConvertible`` values.
    /// - Returns: All created (inactive) `OrbitalConstraint` instances.
    @discardableResult
    public func prepareLayout(_ items: any OrbitalConstraintConvertible...) -> [OrbitalConstraint] {
        items.flatMap { $0.asDescriptors() }.map { makePrepareStore($0) }
    }

    /// Array-accepting overload of ``prepareLayout(_:)-variadic``.
    ///
    /// - Parameter items: An array of ``OrbitalConstraintConvertible`` values.
    /// - Returns: All created (inactive) `OrbitalConstraint` instances.
    @discardableResult
    public func prepareLayout(_ items: [any OrbitalConstraintConvertible]) -> [OrbitalConstraint] {
        items.flatMap { $0.asDescriptors() }.map { makePrepareStore($0) }
    }

    // MARK: - Stored Constraint Accessors

    /// The stored `.equal` constraint for the `top` anchor, if any.
    public var topConstraint: OrbitalConstraint? { storage?.get(.top) }

    /// The stored `.equal` constraint for the `bottom` anchor, if any.
    public var bottomConstraint: OrbitalConstraint? { storage?.get(.bottom) }

    /// The stored `.equal` constraint for the `leading` anchor, if any.
    public var leadingConstraint: OrbitalConstraint? { storage?.get(.leading) }

    /// The stored `.equal` constraint for the `trailing` anchor, if any.
    public var trailingConstraint: OrbitalConstraint? { storage?.get(.trailing) }

    /// The stored `.equal` constraint for the `left` anchor, if any.
    public var leftConstraint: OrbitalConstraint? { storage?.get(.left) }

    /// The stored `.equal` constraint for the `right` anchor, if any.
    public var rightConstraint: OrbitalConstraint? { storage?.get(.right) }

    /// The stored `.equal` constraint for the `width` anchor, if any.
    public var widthConstraint: OrbitalConstraint? { storage?.get(.width) }

    /// The stored `.equal` constraint for the `height` anchor, if any.
    public var heightConstraint: OrbitalConstraint? { storage?.get(.height) }

    /// The stored `.equal` constraint for the `centerX` anchor, if any.
    public var centerXConstraint: OrbitalConstraint? { storage?.get(.centerX) }

    /// The stored `.equal` constraint for the `centerY` anchor, if any.
    public var centerYConstraint: OrbitalConstraint? { storage?.get(.centerY) }

    // MARK: - Non-equal Constraint Access

    /// Returns the stored constraint for the given anchor and relation.
    ///
    /// Use this accessor to retrieve constraints with non-`.equal` relations (e.g. `<=`, `>=`).
    ///
    /// ```swift
    /// view.orbital.layout(
    ///     .width(200),              // width == 200
    ///     .width(300).orLess        // width <= 300
    /// )
    /// view.orbital.constraint(for: .width, relation: .lessOrEqual) // → <= 300
    /// ```
    ///
    /// - Parameters:
    ///   - anchor: The source anchor to look up.
    ///   - relation: The relational operator of the constraint.
    /// - Returns: The stored `OrbitalConstraint`, or `nil` if none exists.
    public func constraint(for anchor: OrbitalAnchor, relation: OrbitalRelation) -> OrbitalConstraint? {
        storage?.get(anchor, relation: relation)
    }
}

// MARK: - OrbitalProxy Group Shortcuts

extension OrbitalProxy {

    // MARK: - Edge Shortcuts

    /// Pins all four edges (top, bottom, leading, trailing) flush to the superview.
    ///
    /// Equivalent to `view.orbital.layout(.edges)`.
    ///
    /// ```swift
    /// view.orbital.edges
    /// ```
    ///
    /// - Returns: The four activated `OrbitalConstraint` instances.
    public var edges: [OrbitalConstraint] {
        layout(OrbitalDescriptor.edges)
    }

    /// Pins all four edges (top, bottom, leading, trailing) to the superview with equal inset.
    ///
    /// Trailing and bottom constants are auto-negated internally.
    ///
    /// ```swift
    /// view.orbital.edges(16)
    /// ```
    ///
    /// - Parameter inset: The inset from each edge in points.
    /// - Returns: The four activated `OrbitalConstraint` instances.
    @discardableResult
    public func edges(_ inset: CGFloat) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.edges(inset))
    }

    /// Pins the leading and trailing anchors flush to the superview.
    ///
    /// Equivalent to `view.orbital.layout(.horizontal)`.
    ///
    /// ```swift
    /// view.orbital.horizontal
    /// ```
    ///
    /// - Returns: The two activated `OrbitalConstraint` instances.
    public var horizontal: [OrbitalConstraint] {
        layout(OrbitalDescriptor.horizontal)
    }

    /// Pins the leading and trailing anchors to the superview with equal inset.
    ///
    /// The trailing constant is auto-negated internally.
    ///
    /// ```swift
    /// view.orbital.horizontal(16)
    /// ```
    ///
    /// - Parameter inset: The inset from each horizontal edge in points.
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func horizontal(_ inset: CGFloat) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.horizontal(inset))
    }

    /// Pins the top and bottom anchors flush to the superview.
    ///
    /// Equivalent to `view.orbital.layout(.vertical)`.
    ///
    /// ```swift
    /// view.orbital.vertical
    /// ```
    ///
    /// - Returns: The two activated `OrbitalConstraint` instances.
    public var vertical: [OrbitalConstraint] {
        layout(OrbitalDescriptor.vertical)
    }

    /// Pins the top and bottom anchors to the superview with equal inset.
    ///
    /// The bottom constant is auto-negated internally.
    ///
    /// ```swift
    /// view.orbital.vertical(24)
    /// ```
    ///
    /// - Parameter inset: The inset from each vertical edge in points.
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func vertical(_ inset: CGFloat) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.vertical(inset))
    }

    // MARK: - Size Shortcuts

    /// Constrains width and height to the same value (square).
    ///
    /// ```swift
    /// view.orbital.size(80)
    /// ```
    ///
    /// - Parameter side: The size in points applied to both width and height.
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func size(_ side: CGFloat) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.size(side))
    }

    /// Constrains width and height to explicit values.
    ///
    /// ```swift
    /// view.orbital.size(width: 320, height: 180)
    /// ```
    ///
    /// - Parameters:
    ///   - width: The width in points.
    ///   - height: The height in points.
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func size(width: CGFloat, height: CGFloat) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.size(width: width, height: height))
    }

    /// Constrains the view's width-to-height ratio.
    ///
    /// Creates a constraint of the form `self.width == self.height * ratio`.
    ///
    /// ```swift
    /// view.orbital.aspectRatio(16.0 / 9.0)
    /// ```
    ///
    /// - Parameter ratio: The width-to-height ratio.
    /// - Returns: The activated `OrbitalConstraint`.
    @discardableResult
    public func aspectRatio(_ ratio: CGFloat) -> OrbitalConstraint {
        makeActivateStore(.aspectRatio(ratio))
    }

    // MARK: - Center Shortcuts

    /// Centers the view in its superview (centerX and centerY at offset zero).
    ///
    /// ```swift
    /// view.orbital.center()
    /// ```
    ///
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func center() -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.center())
    }

    /// Centers the view in its superview with a CGPoint offset.
    ///
    /// ```swift
    /// view.orbital.center(offset: CGPoint(x: 10, y: -5))
    /// ```
    ///
    /// - Parameter offset: The x and y offsets from center.
    /// - Returns: The two activated `OrbitalConstraint` instances.
    @discardableResult
    public func center(offset: CGPoint) -> [OrbitalConstraint] {
        layout(OrbitalDescriptor.center(offset: offset))
    }
}

// MARK: - OrbitalProxy Update / Remake

extension OrbitalProxy {

    // MARK: - update()

    /// Updates the `constant` of previously created constraints matching the given descriptors.
    ///
    /// Only the `anchor` and `constant` fields of each descriptor are used — all other fields
    /// (`relation`, `priority`, `target`, `label`, `multiplier`) are silently ignored.
    /// The lookup always targets the `.equal` relation constraint for each anchor.
    ///
    /// If no stored constraint exists for a given anchor, the descriptor is skipped without error.
    ///
    /// ```swift
    /// // Initial layout
    /// view.orbital.layout(.top(16), .height(200))
    ///
    /// // Update constants only — no new constraints created
    /// view.orbital.update(.top(24), .height(300))
    /// ```
    ///
    /// Accepts ``OrbitalConstraintConvertible``, so group descriptors work:
    /// `update(.edges(24))` updates all four edge constants at once.
    ///
    /// - Parameter items: One or more ``OrbitalDescriptor`` values whose `constant`
    ///   fields will be applied to matching stored constraints.
    /// - Note: To change anything other than `constant` (relation, priority, target anchor),
    ///   use ``remake(_:)`` instead.
    public func update(_ items: OrbitalDescriptor...) {
        performUpdate(items)
    }

    /// Group overload of ``update(_:)-variadic`` enabling leading-dot syntax for
    /// ``OrbitalDescriptorGroup`` shortcuts such as `.edges(24)`.
    ///
    /// - Parameter groups: One or more ``OrbitalDescriptorGroup`` values.
    public func update(_ groups: OrbitalDescriptorGroup...) {
        performUpdate(groups.flatMap { $0.asDescriptors() })
    }

    /// Mixed-type variadic overload of ``update(_:)-variadic``.
    ///
    /// - Parameter items: One or more ``OrbitalConstraintConvertible`` values.
    public func update(_ items: any OrbitalConstraintConvertible...) {
        performUpdate(items.flatMap { $0.asDescriptors() })
    }

    /// Array-accepting overload of ``update(_:)-variadic``.
    ///
    /// - Parameter items: An array of ``OrbitalConstraintConvertible`` values.
    public func update(_ items: [any OrbitalConstraintConvertible]) {
        performUpdate(items.flatMap { $0.asDescriptors() })
    }

    /// Core implementation shared by all `update()` overloads.
    private func performUpdate(_ descriptors: [OrbitalDescriptor]) {
        guard let storage else { return }
        for descriptor in descriptors {
            guard let existing = storage.get(descriptor.anchor) else {
                #if DEBUG
                emitUpdateWarning("OrbitalLayout [DEBUG]: update() skipped anchor .\(descriptor.anchor) — no stored constraint found.")
                #endif
                continue
            }
            #if DEBUG
            if descriptor.relation != .equal {
                emitUpdateWarning("OrbitalLayout [DEBUG]: update() ignoring non-default relation modifier on .\(descriptor.anchor) — only constant is updated.")
            }
            if descriptor.priority != .required {
                emitUpdateWarning("OrbitalLayout [DEBUG]: update() ignoring priority modifier on .\(descriptor.anchor) — only constant is updated.")
            }
            if descriptor.targetView != nil || descriptor.targetGuide != nil {
                emitUpdateWarning("OrbitalLayout [DEBUG]: update() ignoring target modifier on .\(descriptor.anchor) — only constant is updated.")
            }
            #endif
            existing.constant = descriptor.constant
        }
    }

    #if DEBUG
    /// Routes an update-related warning through ``debugWarningHandler`` or `print`.
    private func emitUpdateWarning(_ message: String) {
        if let handler = OrbitalProxy.debugWarningHandler {
            handler(message)
        } else {
            print(message)
        }
    }
    #endif

    // MARK: - remake()

    /// Replaces existing constraints matching the given descriptors with newly created ones.
    ///
    /// For each descriptor, the existing constraint for that `anchor + relation` combination (if any)
    /// is deactivated and removed from storage, then a new constraint is created, activated, and stored.
    /// If no previous constraint exists for a given anchor, a new one is created regardless.
    ///
    /// Constraints for anchors **not** mentioned in the call are not affected.
    ///
    /// ```swift
    /// // Initial layout
    /// view.orbital.layout(.top(16), .leading(16), .trailing(16), .height(200))
    ///
    /// // Replaces top and height — leading/trailing are unchanged
    /// view.orbital.remake(.top(8), .height(120))
    ///
    /// // Remake with a different target
    /// contentView.orbital.remake(.top.to(navigationBar, .bottom))
    /// ```
    ///
    /// - Parameter items: One or more ``OrbitalDescriptor`` values describing
    ///   the constraints to replace.
    /// - Note: Replaced constraints are deactivated and removed from ``ConstraintStorage``.
    ///   If previously captured by the caller, the objects remain in memory but are no longer
    ///   managed by OrbitalLayout.
    public func remake(_ items: OrbitalDescriptor...) {
        items.forEach { makeActivateStore($0) }
    }

    /// Group overload of ``remake(_:)-variadic`` enabling leading-dot syntax for
    /// ``OrbitalDescriptorGroup`` shortcuts such as `.edges(16)`.
    ///
    /// - Parameter groups: One or more ``OrbitalDescriptorGroup`` values.
    public func remake(_ groups: OrbitalDescriptorGroup...) {
        groups.flatMap { $0.asDescriptors() }.forEach { makeActivateStore($0) }
    }

    /// Mixed-type variadic overload of ``remake(_:)-variadic``.
    ///
    /// - Parameter items: One or more ``OrbitalConstraintConvertible`` values.
    public func remake(_ items: any OrbitalConstraintConvertible...) {
        items.flatMap { $0.asDescriptors() }.forEach { makeActivateStore($0) }
    }

    /// Array-accepting overload of ``remake(_:)-variadic``.
    ///
    /// - Parameter items: An array of ``OrbitalConstraintConvertible`` values.
    public func remake(_ items: [any OrbitalConstraintConvertible]) {
        items.flatMap { $0.asDescriptors() }.forEach { makeActivateStore($0) }
    }
}

// MARK: - OrbitalProxy Content Hugging / Compression Resistance

extension OrbitalProxy {

    /// Sets the content hugging priority for the specified axis.
    ///
    /// A higher priority means the view resists being stretched beyond its intrinsic size.
    ///
    /// ```swift
    /// titleLabel.orbital.hugging(.high, axis: .horizontal)
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The layout priority to apply.
    ///   - axis: The axis (`.horizontal` or `.vertical`) along which to set the priority.
    public func hugging(_ priority: OrbitalPriority, axis: OrbitalAxis) {
        view?.setContentHuggingPriority(priority.layoutPriority, for: axis)
    }

    /// Sets the content compression resistance priority for the specified axis.
    ///
    /// A higher priority means the view resists being compressed below its intrinsic size.
    ///
    /// ```swift
    /// titleLabel.orbital.compression(.required, axis: .horizontal)
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The layout priority to apply.
    ///   - axis: The axis (`.horizontal` or `.vertical`) along which to set the priority.
    public func compression(_ priority: OrbitalPriority, axis: OrbitalAxis) {
        view?.setContentCompressionResistancePriority(priority.layoutPriority, for: axis)
    }
}
