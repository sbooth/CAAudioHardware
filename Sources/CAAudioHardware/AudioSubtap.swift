//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio subtap object
/// - remark: This class correponds to objects with base class `kAudioSubTapClassID`
@available(macOS 14.2, *)
public class AudioSubtap: AudioObject, @unchecked Sendable {
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
extension AudioObjectSelector where T: AudioSubtap {
	/// The property selector `kAudioSubTapPropertyExtraLatency`
	public static var extraLatency: Self { Self(kAudioSubTapPropertyExtraLatency) }
	/// The property selector `kAudioSubTapPropertyDriftCompensation`
	public static var driftCompensation: Self { Self(kAudioSubTapPropertyDriftCompensation) }
	/// The property selector `kAudioSubTapPropertyDriftCompensationQuality`
	public static var driftCompensationQuality: Self { Self(kAudioSubTapPropertyDriftCompensationQuality) }
}
