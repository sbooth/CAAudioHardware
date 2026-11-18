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
	/// - remark: This corresponds to the property `kAudioHardwarePropertyClockDeviceList` on `kAudioObjectSystemObject`
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
			try getProperty(PropertyAddress(kAudioClockDevicePropertyControlList)).map { try makeAudioControl($0) }
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

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioClockDevice>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioClockDevice>, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioClockDevice>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioClockDevice>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioClockDevice>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
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
