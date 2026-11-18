//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio subdevice
/// - remark: This class correponds to objects with base class `kAudioSubDeviceClassID`
public class AudioSubdevice: AudioDevice, @unchecked Sendable {
	/// Returns the extra latency
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyExtraLatency`
	public var extraLatency: Double {
		get throws {
			try getProperty(PropertyAddress(kAudioSubDevicePropertyExtraLatency))
		}
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

extension AudioObjectSelector where T: AudioSubdevice {
	/// The property selector `kAudioSubDevicePropertyExtraLatency`
	public static var extraLatency: Self { Self(kAudioSubDevicePropertyExtraLatency) }
	/// The property selector `kAudioSubDevicePropertyDriftCompensation`
	public static var driftCompensation: Self { Self(kAudioSubDevicePropertyDriftCompensation) }
	/// The property selector `kAudioSubDevicePropertyDriftCompensationQuality`
	public static var driftCompensationQuality: Self { Self(kAudioSubDevicePropertyDriftCompensationQuality) }
}
