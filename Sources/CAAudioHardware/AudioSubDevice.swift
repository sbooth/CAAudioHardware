//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio subdevice
/// - remark: This class correponds to objects with base class `kAudioSubDeviceClassID`
public class AudioSubDevice: AudioDevice {
}

extension AudioSubDevice {
	/// Returns the extra latency
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyExtraLatency`
	public func extraLatency(inScope scope: PropertyScope) throws -> Double {
		try getProperty(PropertyAddress(PropertySelector(kAudioSubDevicePropertyExtraLatency), scope: scope))
	}
	/// Sets the extra latency
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyExtraLatency`
	/// - parameter scope: The desired scope
	public func setExtraLatency(_ value: Double, inScope scope: PropertyScope) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioSubDevicePropertyExtraLatency), scope: scope), to: value)
	}

	/// Returns the drift compensation
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensation`
	public var driftCompensation: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensation), type: UInt32.self) != 0
		}
	}
	/// Sets the drift compensation
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensation`
	public func setDriftCompensation(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensation), to: UInt32(value ? 1 : 0))
	}

	/// Returns the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensationQuality`
	public var driftCompensationQuality: DriftCompensationQuality {
		get throws {
			DriftCompensationQuality(try getProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensationQuality), type: UInt32.self))
		}
	}
	/// Sets the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensationQuality`
	public func setDriftCompensationQuality(_ value: DriftCompensationQuality) throws {
		try setProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensationQuality), to: value.rawValue)
	}
}

extension AudioSubDevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioSubDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioSubDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed when `selector` in `scope` on `element` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioSubDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), on: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioSubDevice {
	/// The property selector `kAudioSubDevicePropertyExtraLatency`
	public static let extraLatency = AudioObjectSelector(kAudioSubDevicePropertyExtraLatency)
	/// The property selector `kAudioSubDevicePropertyDriftCompensation`
	public static let driftCompensation = AudioObjectSelector(kAudioSubDevicePropertyDriftCompensation)
	/// The property selector `kAudioSubDevicePropertyDriftCompensationQuality`
	public static let driftCompensationQuality = AudioObjectSelector(kAudioSubDevicePropertyDriftCompensationQuality)
}
