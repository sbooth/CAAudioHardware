//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio aggregate device object
/// - remark: This class correponds to objects with the base class `kAudioAggregateDeviceClassID`
public class AudioAggregateDevice: AudioDevice, @unchecked Sendable {
	/// Creates and returns a new `AudioAggregateDevice` using the provided description
	/// - parameter description: A dictionary specifying how to build the `AudioAggregateDevice`
	/// - returns: A newly-created `AudioAggregateDevice`
	/// - throws: An error if the `AudioAggregateDevice` could not be created
	public static func create(description: [AnyHashable: Any]) throws -> AudioAggregateDevice {
		var objectID: AudioObjectID = kAudioObjectUnknown
		let result = AudioHardwareCreateAggregateDevice(description as CFDictionary, &objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareCreateAggregateDevice (%{public}@) failed: '%{public}@'", description, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return AudioAggregateDevice(objectID)
	}

	/// Destroys `device`
	/// - note: Futher use of `device` following this function is undefined
	/// - important: Invalidate property observations and end property change sequences for `device` before destroying it
	/// - parameter device: The `AudioAggregateDevice` to destroy
	/// - throws: An error if the `AudioAggregateDevice` could not be destroyed
	public static func destroy(_ device: AudioAggregateDevice) throws {
		let result = AudioHardwareDestroyAggregateDevice(device.objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareDestroyAggregateDevice (0x%x) failed: '%{public}@'", device.objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
	}

	/// Returns the UIDs of all subdevices in the aggregate device, active or inactive
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyFullSubDeviceList`
	public var fullSubdeviceList: [String] {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyFullSubDeviceList), type: CFArray.self) as! [String]
		}
	}

	/// Returns the active subdevices in the aggregate device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyActiveSubDeviceList`
	public var activeSubdeviceList: [AudioDevice] {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyActiveSubDeviceList)).map { try makeAudioDevice($0) }
		}
	}

	/// Returns the composition
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyComposition`
	public var composition: [AnyHashable: Any] {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyComposition), type: CFDictionary.self) as! [AnyHashable: Any]
		}
	}

	/// Returns the UID of the main subdevice
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyMainSubDevice`
	public var mainSubdevice: String {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyMainSubDevice), type: CFString.self) as String
		}
	}

	/// Returns the UID of the master subdevice
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyMasterSubDevice`
	@available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "mainSubdevice")
	public var masterSubdevice: String {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyMasterSubDevice), type: CFString.self) as String
		}
	}

	/// Returns the UID of the clock device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyClockDevice`
	public var aggregateClockDevice: String {
		get throws {
			// Revisit if a subclass of `AudioClockDevice` is added
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyClockDevice), type: CFString.self) as String
		}
	}
	/// Sets the UID of the clock device
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyClockDevice`
	public func setAggregateClockDevice(_ value: String) throws {
		try setProperty(PropertyAddress(kAudioAggregateDevicePropertyClockDevice), to: value as CFString)
	}

	/// Returns the tap list
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertyTapList`
	@available(macOS 14.2, *)
	public var tapList: [String] {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertyTapList), type: CFArray.self) as! [String]
		}
	}

	/// Returns the sub tap list
	/// - remark: This corresponds to the property `kAudioAggregateDevicePropertySubTapList`
	@available(macOS 14.2, *)
	public var subTapList: [AudioSubtap] {
		get throws {
			try getProperty(PropertyAddress(kAudioAggregateDevicePropertySubTapList)).map { AudioSubtap($0) }
		}
	}

	/// Returns `true` if the aggregate device is private
	/// - remark: This corresponds to the value of `kAudioAggregateDeviceIsPrivateKey` in `composition`
	/// - attention: If `kAudioAggregateDeviceIsPrivateKey` is not present in `composition` an error is thrown
	public var isPrivate: Bool {
		get throws {
			guard let isPrivate = try composition[kAudioAggregateDeviceIsPrivateKey] as? NSNumber else {
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareUnspecifiedError))
			}
			return isPrivate.boolValue
		}
	}

	/// Returns `true` if the aggregate device is stacked
	/// - remark: This corresponds to the value of `kAudioAggregateDeviceIsStackedKey` in `composition`
	/// - attention: If `kAudioAggregateDeviceIsStackedKey` is not present in `composition` an error is thrown
	public var isStacked: Bool {
		get throws {
			guard let isStacked = try composition[kAudioAggregateDeviceIsStackedKey] as? NSNumber else {
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareUnspecifiedError))
			}
			return isStacked.boolValue
		}
	}
}

extension AudioObjectSelector where T: AudioAggregateDevice {
	/// The property selector `kAudioAggregateDevicePropertyFullSubDeviceList`
	public static var fullSubDeviceList: Self { Self(kAudioAggregateDevicePropertyFullSubDeviceList) }
	/// The property selector `kAudioAggregateDevicePropertyActiveSubDeviceList`
	public static var activeSubDeviceList: Self { Self(kAudioAggregateDevicePropertyActiveSubDeviceList) }
	/// The property selector `kAudioAggregateDevicePropertyComposition`
	public static var composition: Self { Self(kAudioAggregateDevicePropertyComposition) }
	/// The property selector `kAudioAggregateDevicePropertyMainSubDevice`
	public static var mainSubDevice: Self { Self(kAudioAggregateDevicePropertyMainSubDevice) }
	/// The property selector `kAudioAggregateDevicePropertyMasterSubDevice`
	@available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "mainSubDevice")
	public static var masterSubDevice: Self { Self(kAudioAggregateDevicePropertyMasterSubDevice) }
	/// The property selector `kAudioAggregateDevicePropertyClockDevice`
	public static var clockDevice: Self { Self(kAudioAggregateDevicePropertyClockDevice) }
}

@available(macOS 14.2, *)
extension AudioObjectSelector where T: AudioAggregateDevice {
	/// The property selector `kAudioAggregateDevicePropertyTapList`
	public static var tapList: Self { Self(kAudioAggregateDevicePropertyTapList) }
	/// The property selector `kAudioAggregateDevicePropertySubTapList`
	public static var subTapList: Self { Self(kAudioAggregateDevicePropertySubTapList) }
}
