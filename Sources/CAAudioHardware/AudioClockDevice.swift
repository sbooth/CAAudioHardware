//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio clock device object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioClockDeviceClassID`
public class AudioClockDevice: AudioObject {
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
}

extension AudioClockDevice {
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

	/// Returns the domain
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyClockDomain`
	public var domain: UInt32 {
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
	public var isRunning: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyDeviceIsRunning))
		}
	}

	/// Returns the latency
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyLatency`
	public var latency: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyLatency))
		}
	}

	/// Returns the audio controls owned by `self`
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyControlList`
	public var controlList: [AudioControl] {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyControlList)).map { try makeAudioControl($0, baseClass: AudioObject.getBaseClass($0)) }
		}
	}

	/// Returns the sample rate
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyNominalSampleRate`
	public var sampleRate: Double {
		get throws {
			try getProperty(PropertyAddress(kAudioClockDevicePropertyNominalSampleRate))
		}
	}

	/// Returns the available sample rates
	/// - remark: This corresponds to the property `kAudioClockDevicePropertyAvailableNominalSampleRates`
	public var availableSampleRates: [ClosedRange<Double>] {
		get throws {
			let value = try getProperty(PropertyAddress(kAudioClockDevicePropertyAvailableNominalSampleRates), elementType: AudioValueRange.self)
			return value.map { $0.mMinimum ... $0.mMaximum }
		}
	}
}

extension AudioClockDevice {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioClockDevice>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioClockDevice>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioClockDevice>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioClockDevice {
	/// The property selector `kAudioClockDevicePropertyDeviceUID`
	public static let deviceUID = AudioObjectSelector(kAudioClockDevicePropertyDeviceUID)
	/// The property selector `kAudioClockDevicePropertyTransportType`
	public static let transportType = AudioObjectSelector(kAudioClockDevicePropertyTransportType)
	/// The property selector `kAudioClockDevicePropertyClockDomain`
	public static let clockDomain = AudioObjectSelector(kAudioClockDevicePropertyClockDomain)
	/// The property selector `kAudioClockDevicePropertyDeviceIsAlive`
	public static let deviceIsAlive = AudioObjectSelector(kAudioClockDevicePropertyDeviceIsAlive)
	/// The property selector `kAudioClockDevicePropertyDeviceIsRunning`
	public static let deviceIsRunning = AudioObjectSelector(kAudioClockDevicePropertyDeviceIsRunning)
	/// The property selector `kAudioClockDevicePropertyLatency`
	public static let latency = AudioObjectSelector(kAudioClockDevicePropertyLatency)
	/// The property selector `kAudioClockDevicePropertyControlList`
	public static let controlList = AudioObjectSelector(kAudioClockDevicePropertyControlList)
	/// The property selector `kAudioClockDevicePropertyNominalSampleRate`
	public static let nominalSampleRate = AudioObjectSelector(kAudioClockDevicePropertyNominalSampleRate)
	/// The property selector `kAudioClockDevicePropertyAvailableNominalSampleRates`
	public static let availableNominalSampleRates = AudioObjectSelector(kAudioClockDevicePropertyAvailableNominalSampleRates)
}
