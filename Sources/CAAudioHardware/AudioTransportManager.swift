//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio transport manager object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioTransportManagerClassID`
public class AudioTransportManager: AudioPlugIn, @unchecked Sendable {
	/// Returns the available audio transport managers
	/// - remark: This corresponds to the property`kAudioHardwarePropertyTransportManagerList` on `kAudioObjectSystemObject`
	public static var transportManagers: [AudioTransportManager] {
		get throws {
			// Revisit if a subclass of `AudioTransportManager` is added
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTransportManagerList)).map { AudioTransportManager($0) }
		}
	}

	/// Returns an initialized `AudioTransportManager` with `bundleID` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateBundleIDToTransportManager` on `kAudioObjectSystemObject`
	/// - parameter bundleID: The bundle ID of the desired transport manager
	public static func makeTransportManager(forBundleID bundleID: String) throws -> AudioTransportManager? {
		var qualifier = bundleID as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateBundleIDToTransportManager), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioTransportManager` is added
		return AudioTransportManager(objectID)
	}

	/// Creates and returns a new endpoint device
	/// - remark: This corresponds to the property `kAudioTransportManagerCreateEndPointDevice`
	/// - parameter composition: The composition of the new endpoint device
	/// - note: The constants for `composition` are defined in `AudioHardware.h`
	func createEndpointDevice(composition: [AnyHashable: Any]) throws -> AudioEndpointDevice {
		// Revisit if a subclass of `AudioEndpointDevice` is added
		var qualifier = composition as CFDictionary
		return AudioEndpointDevice(try getProperty(PropertyAddress(kAudioTransportManagerCreateEndPointDevice), qualifier: PropertyQualifier(&qualifier)))
	}

	/// Destroys an endpoint device
	/// - remark: This corresponds to the property `kAudioTransportManagerDestroyEndPointDevice`
	func destroyEndpointDevice(_ endpointDevice: AudioEndpointDevice) throws {
		_ = try getProperty(PropertyAddress(kAudioTransportManagerDestroyEndPointDevice), type: UInt32.self, initialValue: endpointDevice.objectID)
	}

	/// Returns the audio endpoints provided by the transport manager
	/// - remark: This corresponds to the property `kAudioTransportManagerPropertyEndPointList`
	public var endpointList: [AudioEndpoint] {
		get throws {
			// Revisit if a subclass of `AudioEndpoint` is added
			try getProperty(PropertyAddress(kAudioTransportManagerPropertyEndPointList)).map { AudioEndpoint($0) }
		}
	}

	/// Returns the audio endpoint provided by the transport manager with the specified UID or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioTransportManagerPropertyTranslateUIDToEndPoint`
	/// - parameter uid: The UID of the desired endpoint
	public func endpoint(forUID uid: String) throws -> AudioEndpoint? {
		var qualifierData = uid as CFString
		let endpointObjectID = try getProperty(PropertyAddress(kAudioTransportManagerPropertyTranslateUIDToEndPoint), type: AudioObjectID.self, qualifier: PropertyQualifier(&qualifierData))
		guard endpointObjectID != kAudioObjectUnknown else {
			return nil
		}
		// Revisit if a subclass of `AudioEndpoint` is added
		return AudioEndpoint(endpointObjectID)
	}

	/// Returns the transport type
	/// - remark: This corresponds to the property `kAudioTransportManagerPropertyTransportType`
	public var transportType: AudioDevice.TransportType {
		get throws {
			AudioDevice.TransportType(try getProperty(PropertyAddress(kAudioTransportManagerPropertyTransportType), type: UInt32.self))
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), [\(try endpointList.map({ $0.debugDescription }).joined(separator: ", "))]>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioTransportManager {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioTransportManager>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioTransportManager>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioTransportManager>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioTransportManager>, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioTransportManager>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioTransportManager>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioTransportManager>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

extension AudioObjectSelector where T == AudioTransportManager {
	/// The property selector `kAudioTransportManagerCreateEndPointDevice`
//	public static let createEndpointDevice = Selector(kAudioTransportManagerCreateEndPointDevice)
	/// The property selector `kAudioTransportManagerDestroyEndPointDevice`
//	public static let destroyEndpointDevice = Selector(kAudioTransportManagerDestroyEndPointDevice)
	/// The property selector `kAudioTransportManagerPropertyEndPointList`
	public static let endpointList = AudioObjectSelector(kAudioTransportManagerPropertyEndPointList)
	/// The property selector `kAudioTransportManagerPropertyTranslateUIDToEndPoint`
	public static let translateUIDToEndpoint = AudioObjectSelector(kAudioTransportManagerPropertyTranslateUIDToEndPoint)
	/// The property selector `kAudioTransportManagerPropertyTransportType`
	public static let transportType = AudioObjectSelector(kAudioTransportManagerPropertyTransportType)
}
