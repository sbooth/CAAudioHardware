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
}

extension AudioAggregateDevice {
	/// Returns `true` if the aggregate device is private
	/// - remark: This corresponds to the value of `kAudioAggregateDeviceIsPrivateKey` in `composition`
	/// - attention: If `kAudioAggregateDeviceIsPrivateKey` is not present in `composition` an error is thrown
	public var isPrivate: Bool {
		get throws {
			guard let isPrivate = try composition[kAudioAggregateDeviceIsPrivateKey] as? NSNumber else {
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareUnspecifiedError), userInfo: nil)
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
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareUnspecifiedError), userInfo: nil)
			}
			return isStacked.boolValue
		}
	}
}

extension AudioAggregateDevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioAggregateDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioAggregateDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed when `selector` in `scope` on `element` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioAggregateDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, onQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), onQueue: queue, perform: block)
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
