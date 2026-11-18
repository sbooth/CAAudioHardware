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

extension AudioObjectSelector where T: AudioTransportManager {
	/// The property selector `kAudioTransportManagerCreateEndPointDevice`
//	public static var createEndpointDevice: Self { Self(kAudioTransportManagerCreateEndPointDevice) }
	/// The property selector `kAudioTransportManagerDestroyEndPointDevice`
//	public static var destroyEndpointDevice: Self { Self(kAudioTransportManagerDestroyEndPointDevice) }
	/// The property selector `kAudioTransportManagerPropertyEndPointList`
	public static var endpointList: Self { Self(kAudioTransportManagerPropertyEndPointList) }
	/// The property selector `kAudioTransportManagerPropertyTranslateUIDToEndPoint`
	public static var translateUIDToEndpoint: Self { Self(kAudioTransportManagerPropertyTranslateUIDToEndPoint) }
	/// The property selector `kAudioTransportManagerPropertyTransportType`
	public static var transportType: Self { Self(kAudioTransportManagerPropertyTransportType) }
}
