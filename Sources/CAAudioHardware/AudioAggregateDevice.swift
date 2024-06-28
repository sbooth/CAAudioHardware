//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio aggregate device object
/// - remark: This class correponds to objects with the base class `kAudioAggregateDeviceClassID`
public class AudioAggregateDevice: AudioDevice {
	/// Creates and returns a new `AudioAggregateDevice` using the provided description
	/// - parameter description: A dictionary specifying how to build the `AudioAggregateDevice`
	/// - returns: A newly-created `AudioAggregateDevice`
	/// - throws: An error if the `AudioAggregateDevice` could not be created
	public static func create(description: [AnyHashable: Any]) throws -> AudioAggregateDevice {
		var objectID: AudioObjectID = kAudioObjectUnknown
		let result = AudioHardwareCreateAggregateDevice(description as CFDictionary, &objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareCreateAggregateDevice (%{public}@) failed: '%{public}@'", description, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: nil)
		}
		return AudioAggregateDevice(objectID)
	}

#if false
	public func destroy() throws {
		removeAllPropertyListeners()
	}
#endif

	/// Destroys `device`
	/// - note: Futher use of `device` following this function is undefined
	/// - parameter device: The `AudioAggregateDevice` to destroy
	/// - throws: An error if the `AudioAggregateDevice` could not be destroyed
	public static func destroy(_ device: AudioAggregateDevice) throws {
		let result = AudioHardwareDestroyAggregateDevice(device.objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareDestroyAggregateDevice (0x%x) failed: '%{public}@'", device.objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: nil)
		}
		device.removeAllPropertyListeners()
	}
}

extension AudioAggregateDevice {
	/// Returns the UIDs of all subdevices in the aggregate device, active or inactive
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyFullSubDeviceList`
	public func fullSubdeviceList() throws -> [String] {
		return try getProperty(PropertyAddress(kAudioAggregateDevicePropertyFullSubDeviceList), type: CFArray.self) as! [String]
	}

	/// Returns the active subdevices in the aggregate device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyActiveSubDeviceList`
	public func activeSubdeviceList() throws -> [AudioDevice] {
		return try getProperty(PropertyAddress(kAudioAggregateDevicePropertyActiveSubDeviceList)).map { try makeAudioDevice($0) }
	}

	/// Returns the composition
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyComposition`
	public func composition() throws -> [AnyHashable: Any] {
		return try getProperty(PropertyAddress(kAudioAggregateDevicePropertyComposition), type: CFDictionary.self) as! [AnyHashable: Any]
	}

	/// Returns the main subdevice
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyMainSubDevice`
	public func mainSubdevice() throws -> AudioDevice {
		return try makeAudioDevice(getProperty(PropertyAddress(kAudioAggregateDevicePropertyMainSubDevice)))
	}

	/// Returns the master subdevice
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyMasterSubDevice`
	@available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "mainSubdevice")
	public func masterSubdevice() throws -> AudioDevice {
		return try makeAudioDevice(getProperty(PropertyAddress(kAudioAggregateDevicePropertyMasterSubDevice)))
	}

	/// Returns the clock device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyClockDevice`
	public func clockDevice() throws -> AudioClockDevice {
		// Revisit if a subclass of `AudioClockDevice` is added
		return AudioClockDevice(try getProperty(PropertyAddress(kAudioAggregateDevicePropertyClockDevice)))
	}
	/// Sets the clock device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyClockDevice`
	public func setClockDevice(_ value: AudioClockDevice) throws {
		try setProperty(PropertyAddress(kAudioAggregateDevicePropertyClockDevice), to: value.objectID)
	}
}

extension AudioAggregateDevice {
	/// Returns `true` if the aggregate device is private
	/// - remark: This corresponds to the value of `kAudioAggregateDeviceIsPrivateKey` in `composition()`
	public func isPrivate() throws -> Bool {
		let isPrivate = try composition()[kAudioAggregateDeviceIsPrivateKey] as? NSNumber
		return isPrivate?.boolValue ?? false
	}

	/// Returns `true` if the aggregate device is stacked
	/// - remark: This corresponds to the value of `kAudioAggregateDeviceIsStackedKey` in `composition()`
	public func isStacked() throws -> Bool {
		let isPrivate = try composition()[kAudioAggregateDeviceIsStackedKey] as? NSNumber
		return isPrivate?.boolValue ?? false
	}
}

extension AudioObjectSelector where T == AudioAggregateDevice {
	/// The property selector `kAudioAggregateDevicePropertyFullSubDeviceList`
	public static let fullSubDeviceList = AudioObjectSelector(kAudioAggregateDevicePropertyFullSubDeviceList)
	/// The property selector `kAudioAggregateDevicePropertyActiveSubDeviceList`
	public static let activeSubDeviceList = AudioObjectSelector(kAudioAggregateDevicePropertyActiveSubDeviceList)
	/// The property selector `kAudioAggregateDevicePropertyComposition`
	public static let composition = AudioObjectSelector(kAudioAggregateDevicePropertyComposition)
	/// The property selector `kAudioAggregateDevicePropertyMainSubDevice`
	public static let mainSubDevice = AudioObjectSelector(kAudioAggregateDevicePropertyMainSubDevice)
	/// The property selector `kAudioAggregateDevicePropertyMasterSubDevice`
	@available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "mainSubDevice")
	public static let masterSubDevice = AudioObjectSelector(kAudioAggregateDevicePropertyMasterSubDevice)
	/// The property selector `kAudioAggregateDevicePropertyClockDevice`
	public static let clockDevice = AudioObjectSelector(kAudioAggregateDevicePropertyClockDevice)
}
