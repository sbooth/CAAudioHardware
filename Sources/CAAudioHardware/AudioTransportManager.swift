//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio transport manager object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioTransportManagerClassID`
public class AudioTransportManager: AudioPlugIn {
	/// Returns the available audio transport managers
	/// - remark: This corresponds to the property`kAudioHardwarePropertyTransportManagerList` on `kAudioObjectSystemObject`
	public class func transportManagers() throws -> [AudioTransportManager] {
		// Revisit if a subclass of `AudioTransportManager` is added
		return try getAudioObjectProperty(PropertyAddress(kAudioHardwarePropertyTransportManagerList), from: AudioObjectID(kAudioObjectSystemObject)).map { AudioTransportManager($0) }
	}

	/// Returns an initialized `AudioTransportManager` with `bundleID` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateBundleIDToTransportManager` on `kAudioObjectSystemObject`
	/// - parameter bundleID: The bundle ID of the desired transport manager
	public class func makeTransportManager(forBundleID bundleID: String) throws -> AudioTransportManager? {
		var qualifier = bundleID as CFString
		let objectID: AudioObjectID = try getAudioObjectProperty(PropertyAddress(kAudioHardwarePropertyTranslateBundleIDToTransportManager), from: AudioObjectID(kAudioObjectSystemObject), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioTransportManager` is added
		return AudioTransportManager(objectID)
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(String(objectID, radix: 16, uppercase: false)), [\(try endpointList().map({ $0.debugDescription }).joined(separator: ", "))]>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioTransportManager {
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
	public func endpointList() throws -> [AudioEndpoint] {
		// Revisit if a subclass of `AudioEndpoint` is added
		return try getProperty(PropertyAddress(kAudioTransportManagerPropertyEndPointList)).map { AudioEndpoint($0) }
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
	public func transportType() throws -> AudioDevice.TransportType {
		return AudioDevice.TransportType(rawValue: try getProperty(PropertyAddress(kAudioTransportManagerPropertyTransportType), type: UInt32.self))
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

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioTransportManager>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
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
