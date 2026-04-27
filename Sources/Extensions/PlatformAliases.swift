//
//  PlatformAliases.swift
//  OrbitalLayout
//
//  Created by Dmitry Yurkovski on 02/04/2026.
//

/// A platform-agnostic view type.
///
/// - On iOS and tvOS, resolves to `UIView`.
/// - On macOS, resolves to `NSView`.
#if canImport(UIKit)
import UIKit
public typealias OrbitalView = UIView

/// A platform-agnostic layout guide type.
///
/// - On iOS and tvOS, resolves to `UILayoutGuide`.
/// - On macOS, resolves to `NSLayoutGuide`.
public typealias OrbitalLayoutGuide = UILayoutGuide

/// A platform-agnostic layout priority type.
///
/// - On iOS and tvOS, resolves to `UILayoutPriority`.
/// - On macOS, resolves to `NSLayoutConstraint.Priority`.
public typealias OrbitalLayoutPriority = UILayoutPriority

/// A platform-agnostic view controller type.
///
/// - On iOS and tvOS, resolves to `UIViewController`.
/// - On macOS, resolves to `NSViewController`.
public typealias OrbitalViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
/// A platform-agnostic view type.
///
/// - On iOS and tvOS, resolves to `UIView`.
/// - On macOS, resolves to `NSView`.
public typealias OrbitalView = NSView

/// A platform-agnostic layout guide type.
///
/// - On iOS and tvOS, resolves to `UILayoutGuide`.
/// - On macOS, resolves to `NSLayoutGuide`.
public typealias OrbitalLayoutGuide = NSLayoutGuide

/// A platform-agnostic layout priority type.
///
/// - On iOS and tvOS, resolves to `UILayoutPriority`.
/// - On macOS, resolves to `NSLayoutConstraint.Priority`.
public typealias OrbitalLayoutPriority = NSLayoutConstraint.Priority

/// A platform-agnostic view controller type.
///
/// - On iOS and tvOS, resolves to `UIViewController`.
/// - On macOS, resolves to `NSViewController`.
public typealias OrbitalViewController = NSViewController
#endif

/// A platform-agnostic layout constraint type. Resolves to `NSLayoutConstraint`.
///
/// Returned by all OrbitalLayout constraint-creation APIs. You can use it
/// directly to read or mutate `constant`, `isActive`, or `priority` at any time.
///
/// ```swift
/// let top = view.orbital.top(16)
/// top.constant = 32
/// UIView.animate(withDuration: 0.3) { view.superview?.layoutIfNeeded() }
/// ```
public typealias OrbitalConstraint = NSLayoutConstraint

#if canImport(UIKit)
/// A platform-agnostic layout axis type.
///
/// - On iOS and tvOS, resolves to `NSLayoutConstraint.Axis`.
/// - On macOS, resolves to `NSUserInterfaceLayoutOrientation`.
///
/// Used with ``OrbitalProxy/hugging(_:axis:)`` and ``OrbitalProxy/compression(_:axis:)``.
public typealias OrbitalAxis = NSLayoutConstraint.Axis
#elseif canImport(AppKit)
import AppKit
/// A platform-agnostic layout axis type.
///
/// - On iOS and tvOS, resolves to `NSLayoutConstraint.Axis`.
/// - On macOS, resolves to `NSLayoutConstraint.Orientation`.
///
/// Used with ``OrbitalProxy/hugging(_:axis:)`` and ``OrbitalProxy/compression(_:axis:)``.
public typealias OrbitalAxis = NSLayoutConstraint.Orientation
#endif
