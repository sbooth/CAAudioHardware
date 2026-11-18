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
public protocol PropertyOwning: AudioObject {}

extension AudioObject: PropertyOwning {}

// Each method takes a scope and element with defaults, so one method covers every call shape:
// `observe(.x)`, `observe(.x, onElement: 1)`, `observe(.x, inScope: .output)`, and both together.
// No other overloads take an AudioObjectSelector, so the defaults cannot make a call ambiguous.
extension PropertyOwning {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
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
	public func observe(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
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
	public func observe(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, queue: DispatchQueue, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
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
	public func observeOnMainActor(_ selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> AsyncThrowingStream<[PropertyAddress], any Error> {
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
	public func values<Value: Sendable>(of selector: AudioObjectSelector<Self>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), read: read)
	}
}

// MARK: - Selector-first forms

// These forms accept an instance of `T` or any subclass, so a selector whose type names a superclass,
// such as a stored `AudioObjectSelector<AudioDevice>`, can be used with a subclass instance such as an
// `AudioAggregateDevice`. The object is implicitly upcast to `T`, which makes the object's `Self` equal
// `T` and the selector's type match. The PropertyOwning methods cannot offer this directly because
// Swift cannot constrain `Self` to be a subclass of a generic parameter.
extension AudioObjectSelector {
	/// Returns `true` if `object` has this property in `scope` on `element`
	/// - parameter object: The audio object to query
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func isSupported(by object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		object.hasSelector(self, inScope: scope, onElement: element)
	}

	/// Returns `true` if this property in `scope` on `element` is settable on `object`
	/// - parameter object: The audio object to query
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `object` does not have the requested property
	public func isSettable(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		try object.isSelectorSettable(self, inScope: scope, onElement: element)
	}

	/// Registers `block` to be performed serially on a private dispatch queue when this property in `scope` on `element` changes on `object`
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter object: The audio object to observe
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try object.observe(self, inScope: scope, onElement: element, perform: block)
	}

	/// Registers `block` to be performed on `queue` when this property in `scope` on `element` changes on `object`
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter object: The audio object to observe
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, queue: DispatchQueue, perform block: @escaping AudioObject.PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try object.observe(self, inScope: scope, onElement: element, queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when this property in `scope` on `element` changes on `object`
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter object: The audio object to observe
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping AudioObject.MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try object.observeOnMainActor(self, inScope: scope, onElement: element, perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for this property in `scope` on `element` on `object`
	/// - parameter object: The audio object to observe
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - returns: An asynchronous sequence of change notifications
	public func changes(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		object.changes(of: self, inScope: scope, onElement: element)
	}

	/// Returns an asynchronous sequence of values for this property in `scope` on `element` on `object`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter object: The audio object to observe
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(on object: T, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		object.values(of: self, inScope: scope, onElement: element, read: read)
	}
}
