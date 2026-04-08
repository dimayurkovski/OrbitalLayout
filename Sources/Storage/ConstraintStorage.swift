//
//  ConstraintStorage.swift
//  OrbitalLayout
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import ObjectiveC

// MARK: - StorageKey

/// A composite key that uniquely identifies a stored constraint by its anchor and relation.
///
/// Two constraints on the same anchor can coexist as long as their relations differ —
/// for example, `.width == 200` (`.equal`) and `.width <= 300` (`.lessOrEqual`) are
/// stored under separate keys and can both be active simultaneously.
struct StorageKey: Hashable, Sendable {

    /// The layout anchor this key targets.
    let anchor: OrbitalAnchor

    /// The relational operator of the constraint.
    let relation: OrbitalRelation
}

// MARK: - ConstraintStorage

/// Per-view storage for constraints created by OrbitalLayout.
///
/// `ConstraintStorage` holds a dictionary keyed by `anchor + relation`. When a new
/// constraint is stored for an existing key, the previous constraint is automatically
/// deactivated and replaced.
///
/// ```swift
/// let storage = ConstraintStorage()
/// storage.store(constraint, for: .top, relation: .equal)
/// let c = storage.get(.top, relation: .equal)  // → constraint
/// ```
///
/// Instances are attached to views via `objc_setAssociatedObject` — access through
/// `view.orbitalStorage` rather than instantiating directly.
@MainActor
final class ConstraintStorage {

    // MARK: - Private state

    private var stored: [StorageKey: OrbitalConstraint] = [:]

    // MARK: - Store

    /// Stores a constraint for the given anchor and relation.
    ///
    /// If a constraint already exists for the same `anchor + relation` key, it is
    /// deactivated before being replaced. The new constraint is **not** activated here —
    /// activation is the caller's responsibility.
    ///
    /// - Parameters:
    ///   - constraint: The constraint to store.
    ///   - anchor: The source anchor the constraint targets.
    ///   - relation: The relational operator of the constraint.
    func store(_ constraint: OrbitalConstraint, for anchor: OrbitalAnchor, relation: OrbitalRelation) {
        let key = StorageKey(anchor: anchor, relation: relation)
        if let previous = stored[key], previous !== constraint {
            previous.isActive = false
        }
        stored[key] = constraint
    }

    // MARK: - Get

    /// Returns the stored constraint for the given anchor and relation, if any.
    ///
    /// - Parameters:
    ///   - anchor: The source anchor to look up.
    ///   - relation: The relational operator to match. Defaults to ``OrbitalRelation/equal``.
    /// - Returns: The stored `OrbitalConstraint`, or `nil` if none exists for the key.
    func get(_ anchor: OrbitalAnchor, relation: OrbitalRelation = .equal) -> OrbitalConstraint? {
        stored[StorageKey(anchor: anchor, relation: relation)]
    }

    // MARK: - Remove

    /// Removes and returns all stored constraints, clearing the internal dictionary.
    ///
    /// Returned constraints are **not** deactivated — the caller decides what to do with them.
    ///
    /// - Returns: All constraints that were in storage at the time of the call.
    @discardableResult
    func removeAll() -> [OrbitalConstraint] {
        let all = Array(stored.values)
        stored.removeAll()
        return all
    }
}

// MARK: - OrbitalView extension

/// A private namespace whose static address is used as the `objc_setAssociatedObject` key.
///
/// Using a type's static property address is the canonical Swift pattern for association keys
/// because the address of a `static var` is stable for the lifetime of the process.
private enum StorageAssociation {
    nonisolated(unsafe) static var key: UInt8 = 0
}

extension OrbitalView {

    /// The `ConstraintStorage` instance associated with this view.
    ///
    /// Created lazily on first access and attached via `objc_setAssociatedObject`.
    /// Subsequent accesses return the same object, so stored constraints persist
    /// for the lifetime of the view.
    ///
    /// ```swift
    /// view.orbitalStorage.store(constraint, for: .top, relation: .equal)
    /// ```
    @MainActor
    var orbitalStorage: ConstraintStorage {
        if let existing = objc_getAssociatedObject(self, &StorageAssociation.key) as? ConstraintStorage {
            return existing
        }
        let storage = ConstraintStorage()
        objc_setAssociatedObject(self, &StorageAssociation.key, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return storage
    }
}
