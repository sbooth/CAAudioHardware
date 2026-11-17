//
// SPDX-FileCopyrightText: 2026 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A type whose properties are identified by ``AudioObjectSelector`` values
///
/// This protocol exists so the selector methods can be declared once for every `AudioObject` subclass.
/// In these methods the selector's type is `AudioObjectSelector<Self>`, where `Self` is the static type
/// of the receiver, so a call such as `device.observe(.nominalSampleRate)` accepts exactly the
/// selectors of the receiver's class and its superclasses.
///
/// `AudioObject` conforms to this protocol, and therefore so does every subclass.
public protocol AudioPropertyOwner: AudioObject {}

extension AudioObject: AudioPropertyOwner {}

// MARK: - Global scope

extension AudioPropertyOwner {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<Self>) -> Bool {
		hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<Self>) throws -> Bool {
		try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<Self>, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<Self>, queue: DispatchQueue, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<Self>, perform block: @escaping AudioObject.MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<Self>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<Self>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

// MARK: - Device scopes

// `inScope:` has no default value in these methods. With one, a call such as `device.observe(.mute) { … }`
// would match both these methods and the global scope methods above with the same selector type.
// Requiring it means calls without a scope resolve to the methods above, and calls with one resolve here.
extension AudioPropertyOwner where Self: AudioDevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main) -> Bool {
		hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main, queue: DispatchQueue, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns an asynchronous sequence of values for `selector` in `scope` on `element`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<Self>, inScope scope: PropertyScope, onElement element: PropertyElement = .main, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), read: read)
	}
}
