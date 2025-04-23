//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio plug-in object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects of type `kAudioPlugInClassID`
public class AudioPlugIn: AudioObject, @unchecked Sendable {
	/// Returns the available audio plug-ins
	/// - remark: This corresponds to the property`kAudioHardwarePropertyPlugInList` on `kAudioObjectSystemObject`
	public static var plugIns: [AudioPlugIn] {
		get throws {
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyPlugInList)).map { try makeAudioPlugIn($0) }
		}
	}

	/// Returns an initialized `AudioPlugIn` with `bundleID` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateBundleIDToPlugIn` on `kAudioObjectSystemObject`
	/// - parameter bundleID: The bundle ID of the desired plug-in
	public static func makePlugIn(forBundleID bundleID: String) throws -> AudioPlugIn? {
		var qualifier = bundleID as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateBundleIDToPlugIn), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		return try makeAudioPlugIn(objectID)
	}

	/// Creates and returns a new aggregate device
	/// - remark: This corresponds to the property `kAudioPlugInCreateAggregateDevice`
	/// - parameter composition: The composition of the new aggregate device
	/// - note: The constants for `composition` are defined in `AudioHardware.h`
	func createAggregateDevice(composition: [AnyHashable: Any]) throws -> AudioAggregateDevice {
		var qualifier = composition as CFDictionary
		return AudioAggregateDevice(try getProperty(PropertyAddress(kAudioPlugInCreateAggregateDevice), qualifier: PropertyQualifier(&qualifier)))
	}

	/// Destroys an aggregate device
	/// - remark: This corresponds to the property `kAudioPlugInDestroyAggregateDevice`
	func destroyAggregateDevice(_ aggregateDevice: AudioAggregateDevice) throws {
		_ = try getProperty(PropertyAddress(kAudioPlugInDestroyAggregateDevice), type: UInt32.self, initialValue: aggregateDevice.objectID)
	}

	/// Returns the plug-in's bundle ID
	/// - remark: This corresponds to the property `kAudioPlugInPropertyBundleID`
	public var bundleID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioPlugInPropertyBundleID), type: CFString.self) as String
		}
	}

	/// Returns the audio devices provided by the plug-in
	/// - remark: This corresponds to the property `kAudioPlugInPropertyDeviceList`
	public var deviceList: [AudioDevice] {
		get throws {
			try getProperty(PropertyAddress(kAudioPlugInPropertyDeviceList)).map { try makeAudioDevice($0) }
		}
	}

	/// Returns the audio device provided by the plug-in with the specified UID or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioPlugInPropertyTranslateUIDToDevice`
	/// - parameter uid: The UID of the desired device
	public func device(forUID uid: String) throws -> AudioDevice? {
		var qualifierData = uid as CFString
		let deviceObjectID = try getProperty(PropertyAddress(kAudioPlugInPropertyTranslateUIDToDevice), type: AudioObjectID.self, qualifier: PropertyQualifier(&qualifierData))
		guard deviceObjectID != kAudioObjectUnknown else {
			return nil
		}
		return try makeAudioDevice(deviceObjectID)
	}

	/// Returns the audio boxes provided by the plug-in
	/// - remark: This corresponds to the property `kAudioPlugInPropertyBoxList`
	public var boxList: [AudioBox] {
		get throws {
			// Revisit if a subclass of `AudioBox` is added
			try getProperty(PropertyAddress(kAudioPlugInPropertyBoxList)).map { AudioBox($0) }
		}
	}

	/// Returns the audio box provided by the plug-in with the specified UID or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioPlugInPropertyTranslateUIDToBox`
	/// - parameter uid: The UID of the desired box
	public func box(forUID uid: String) throws -> AudioBox? {
		var qualifierData = uid as CFString
		let boxObjectID = try getProperty(PropertyAddress(kAudioPlugInPropertyTranslateUIDToBox), type: AudioObjectID.self, qualifier: PropertyQualifier(&qualifierData))
		guard boxObjectID != kAudioObjectUnknown else {
			return nil
		}
		// Revisit if a subclass of `AudioBox` is added
		return AudioBox(boxObjectID)
	}

	/// Returns the clock devices provided by the plug-in
	/// - remark: This corresponds to the property `kAudioPlugInPropertyClockDeviceList`
	public var clockDeviceList: [AudioClockDevice] {
		get throws {
			// Revisit if a subclass of `AudioClockDevice` is added
			try getProperty(PropertyAddress(kAudioPlugInPropertyClockDeviceList)).map { AudioClockDevice($0) }
		}
	}

	/// Returns the audio clock device provided by the plug-in with the specified UID or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioPlugInPropertyTranslateUIDToClockDevice`
	/// - parameter uid: The UID of the desired clock device
	public func clockDevice(forUID uid: String) throws -> AudioClockDevice? {
		var qualifierData = uid as CFString
		let clockDeviceObjectID = try getProperty(PropertyAddress(kAudioPlugInPropertyTranslateUIDToClockDevice), type: AudioObjectID.self, qualifier: PropertyQualifier(&qualifierData))
		guard clockDeviceObjectID != kAudioObjectUnknown else {
			return nil
		}
		// Revisit if a subclass of `AudioClockDevice` is added
		return AudioClockDevice(clockDeviceObjectID)
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), [\(try deviceList.map({ $0.debugDescription }).joined(separator: ", "))]>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioPlugIn {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioPlugIn>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioPlugIn>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioPlugIn>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioPlugIn {
	/// The property selector `kAudioPlugInCreateAggregateDevice`
//	public static let createAggregateDevice = Selector(kAudioPlugInCreateAggregateDevice)
	/// The property selector `kAudioPlugInDestroyAggregateDevice`
//	public static let destroyAggregateDevice = Selector(kAudioPlugInDestroyAggregateDevice)
	/// The property selector `kAudioPlugInPropertyBundleID`
	public static let bundleID = AudioObjectSelector(kAudioPlugInPropertyBundleID)
	/// The property selector `kAudioPlugInPropertyDeviceList`
	public static let deviceList = AudioObjectSelector(kAudioPlugInPropertyDeviceList)
	/// The property selector `kAudioPlugInPropertyTranslateUIDToDevice`
	public static let translateUIDToDevice = AudioObjectSelector(kAudioPlugInPropertyTranslateUIDToDevice)
	/// The property selector `kAudioPlugInPropertyBoxList`
	public static let boxList = AudioObjectSelector(kAudioPlugInPropertyBoxList)
	/// The property selector `kAudioPlugInPropertyTranslateUIDToBox`
	public static let translateUIDToBox = AudioObjectSelector(kAudioPlugInPropertyTranslateUIDToBox)
	/// The property selector `kAudioPlugInPropertyClockDeviceList`
	public static let clockDeviceList = AudioObjectSelector(kAudioPlugInPropertyClockDeviceList)
	/// The property selector `kAudioPlugInPropertyTranslateUIDToClockDevice`
	public static let translateUIDToClockDevice = AudioObjectSelector(kAudioPlugInPropertyTranslateUIDToClockDevice)
}

// MARK: -

/// Creates and returns an initialized `AudioPlugIn` or subclass.
func makeAudioPlugIn(_ objectID: AudioObjectID) throws -> AudioPlugIn {
	precondition(objectID != kAudioObjectUnknown)
	precondition(objectID != kAudioObjectSystemObject)

	let objectClass = try AudioObject.getClass(objectID)

	switch objectClass {
	case kAudioPlugInClassID: 				return AudioPlugIn(objectID)
	case kAudioTransportManagerClassID: 	return AudioTransportManager(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown audio plug-in class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return AudioPlugIn(objectID)
	}
}
