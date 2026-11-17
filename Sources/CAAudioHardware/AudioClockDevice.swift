//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio clock device object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioClockDeviceClassID`
public class AudioClockDevice: AudioObject, @unchecked Sendable {
	/// Returns the available audio clock devices
	/// - remark: This corresponds to the property`kAudioHardwarePropertyClockDeviceList` on `kAudioObjectSystemObject`
	public static var clockDevices: [AudioClockDevice] {
		get throws {
			// Revisit if a subclass of `AudioClockDevice` is added
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyClockDeviceList)).map { AudioClockDevice($0) }
		}
	}

	/// Returns an initialized `AudioClockDevice` with `uid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateUIDToClockDevice` on `kAudioObjectSystemObject`
	/// - parameter uid: The UID of the desired clock device
	public static func makeClockDevice(forUID uid: String) throws -> AudioClockDevice? {
		var qualifier = uid as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateUIDToClockDevice), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioClockDevice` is added
		return AudioClockDevice(objectID)
	}

	/// Returns the clock device UID
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyDeviceUID`
	public var deviceUID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyDeviceUID), type: CFString.self) as String
		}
	}

	/// Returns the transport type
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyTransportType`
	public var transportType: AudioDevice.TransportType {
		get throws {
			AudioDevice.TransportType(try getProperty(PropertyAddress(kAudioClockDevicePropertyTransportType), type: UInt32.self))
		}
	}

	/// Returns the clock domain
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyClockDomain`
	public var clockDomain: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyClockDomain))
		}
	}

	/// Returns `true` if the clock device is alive
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyDeviceIsAlive`
	public var isAlive: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyDeviceIsAlive), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the clock device is running
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyDeviceIsRunning`
	public var isRunning: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyDeviceIsRunning), type: UInt32.self) != 0
		}
	}

	/// Returns the latency in frames
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyLatency`
	public var latency: Int {
		get throws {
			Int(try getProperty(PropertyAddress(kAudioClockDevicePropertyLatency), type: UInt32.self))
		}
	}

	/// Returns the audio controls owned by `self`
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyControlList`
	public var controlList: [AudioControl] {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyControlList)).map { try makeAudioControl($0, baseClass: AudioObject.getBaseClass($0)) }
		}
	}

	/// Returns the nominal sample rate
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyNominalSampleRate`
	public var nominalSampleRate: Double {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyNominalSampleRate))
		}
	}

	/// Sets the nominal sample rate
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyNominalSampleRate`
	/// - parameter value: The desired property value
	public func setNominalSampleRate(_ value: Double) throws {
		os_log(.info, log: audioObjectLog, "Setting clock device 0x%x nominal sample rate to %.2f Hz", objectID, value)
		try setProperty(PropertyAddress(kAudioClockDevicePropertyNominalSampleRate), to: value)
	}

	/// Returns the available nominal sample rates
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyAvailableNominalSampleRates`
	public var availableNominalSampleRates: [ClosedRange<Double>] {
		get throws {
			let value = try getProperty(PropertyAddress(kAudioClockDevicePropertyAvailableNominalSampleRates), elementType: AudioValueRange.self)
			return value.map { $0.mMinimum ... $0.mMaximum }
		}
	}
}

extension AudioObjectSelector where T: AudioClockDevice {
	/// The property selector `kAudioClockDevicePropertyDeviceUID`
	public static var deviceUID: Self { Self(kAudioClockDevicePropertyDeviceUID) }
	/// The property selector `kAudioClockDevicePropertyTransportType`
	public static var transportType: Self { Self(kAudioClockDevicePropertyTransportType) }
	/// The property selector `kAudioClockDevicePropertyClockDomain`
	public static var clockDomain: Self { Self(kAudioClockDevicePropertyClockDomain) }
	/// The property selector `kAudioClockDevicePropertyDeviceIsAlive`
	public static var deviceIsAlive: Self { Self(kAudioClockDevicePropertyDeviceIsAlive) }
	/// The property selector `kAudioClockDevicePropertyDeviceIsRunning`
	public static var deviceIsRunning: Self { Self(kAudioClockDevicePropertyDeviceIsRunning) }
	/// The property selector `kAudioClockDevicePropertyLatency`
	public static var latency: Self { Self(kAudioClockDevicePropertyLatency) }
	/// The property selector `kAudioClockDevicePropertyControlList`
	public static var controlList: Self { Self(kAudioClockDevicePropertyControlList) }
	/// The property selector `kAudioClockDevicePropertyNominalSampleRate`
	public static var nominalSampleRate: Self { Self(kAudioClockDevicePropertyNominalSampleRate) }
	/// The property selector `kAudioClockDevicePropertyAvailableNominalSampleRates`
	public static var availableNominalSampleRates: Self { Self(kAudioClockDevicePropertyAvailableNominalSampleRates) }
}
