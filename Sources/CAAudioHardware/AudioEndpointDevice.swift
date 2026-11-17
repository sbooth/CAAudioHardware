//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio endpoint device
/// - remark: This class correponds to objects with base class `kAudioEndPointDeviceClassID`
public class AudioEndpointDevice: AudioDevice, @unchecked Sendable {
	/// Returns the composition
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyComposition`
	public var composition: [AnyHashable: Any] {
		get throws {
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyComposition), type: CFDictionary.self) as! [AnyHashable: Any]
		}
	}

	/// Returns the audio endpoints owned by `self`
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyEndPointList`
	public var endpointList: [AudioEndpoint] {
		get throws {
			// Revisit if a subclass of `AudioEndpoint` is added
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyEndPointList)).map { AudioEndpoint($0) }
		}
	}

	/// Returns the owning `pid_t`or `0` for public devices
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyIsPrivate`
	public var isPrivate: pid_t {
		get throws {
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyIsPrivate))
		}
	}
}

extension AudioEndpointDevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
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
	public func observe(_ selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
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
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> AsyncThrowingStream<[PropertyAddress], any Error> {
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
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioEndpointDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), read: read)
	}
}

extension AudioObjectSelector where T == AudioEndpointDevice {
	/// The property selector `kAudioEndPointDevicePropertyComposition`
	public static let composition = AudioObjectSelector(kAudioEndPointDevicePropertyComposition)
	/// The property selector `kAudioEndPointDevicePropertyEndPointList`
	public static let endpointList = AudioObjectSelector(kAudioEndPointDevicePropertyEndPointList)
	/// The property selector `kAudioEndPointDevicePropertyIsPrivate`
	public static let isPrivate = AudioObjectSelector(kAudioEndPointDevicePropertyIsPrivate)
}
