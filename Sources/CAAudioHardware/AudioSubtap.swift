//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio subtap object
/// - remark: This class correponds to objects with base class `kAudioSubTapClassID`
@available(macOS 14.2, *)
public class AudioSubtap: AudioObject {
	/// Returns the extra latency
	/// - remark: This corresponds to the property `kAudioSubTapPropertyExtraLatency`
	/// - parameter scope: The desired scope
	public func extraLatency(inScope scope: PropertyScope) throws -> Double {
		try getProperty(PropertyAddress(PropertySelector(kAudioSubTapPropertyExtraLatency), scope: scope))
	}
	/// Sets the extra latency
	/// - remark: This corresponds to the property `kAudioSubTapPropertyExtraLatency`
	/// - parameter scope: The desired scope
	public func setExtraLatency(_ value: Double, inScope scope: PropertyScope) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioSubTapPropertyExtraLatency), scope: scope), to: value)
	}

	/// Returns the drift compensation
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensation`
	public var driftCompensation: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensation), type: UInt32.self) != 0
		}
	}
	/// Sets the drift compensation
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensation`
	public func setDriftCompensation(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensation), to: UInt32(value ? 1 : 0))
	}

	/// Returns the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensationQuality`
	public var driftCompensationQuality: AudioSubdevice.DriftCompensationQuality {
		get throws {
			try AudioSubdevice.DriftCompensationQuality(getProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensationQuality), type: UInt32.self))
		}
	}
	/// Sets the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensationQuality`
	public func setDriftCompensationQuality(_ value: AudioSubdevice.DriftCompensationQuality) throws {
		try setProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensationQuality), to: value.rawValue)
	}
}

@available(macOS 14.2, *)
extension AudioSubtap {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioSubtap>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioSubtap>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioSubtap>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
	}
}

@available(macOS 14.2, *)
extension AudioObjectSelector where T == AudioSubtap {
	/// The property selector `kAudioSubTapPropertyExtraLatency`
	public static let extraLatency = AudioObjectSelector(kAudioSubTapPropertyExtraLatency)
	/// The property selector `kAudioSubTapPropertyDriftCompensation`
	public static let driftCompensation = AudioObjectSelector(kAudioSubTapPropertyDriftCompensation)
	/// The property selector `kAudioSubTapPropertyDriftCompensationQuality`
	public static let driftCompensationQuality = AudioObjectSelector(kAudioSubTapPropertyDriftCompensationQuality)
}
