//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio endpoint device
/// - remark: This class correponds to objects with base class `kAudioEndPointDeviceClassID`
public class AudioEndpointDevice: AudioDevice, @unchecked Sendable {
	/// Returns the composition
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyComposition`
	public var composition: [AnyHashable: Any] {
		get throws {
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyComposition), type: CFDictionary.self) as! [AnyHashable: Any]
		}
	}

	/// Returns the audio endpoints owned by `self`
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyEndPointList`
	public var endpointList: [AudioEndpoint] {
		get throws {
			// Revisit if a subclass of `AudioEndpoint` is added
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyEndPointList)).map { AudioEndpoint($0) }
		}
	}

	/// Returns the owning `pid_t`or `0` for public devices
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyIsPrivate`
	public var isPrivate: pid_t {
		get throws {
			try getProperty(PropertyAddress(kAudioEndPointDevicePropertyIsPrivate))
		}
	}
}

extension AudioObjectSelector where T: AudioEndpointDevice {
	/// The property selector `kAudioEndPointDevicePropertyComposition`
	public static var composition: Self { Self(kAudioEndPointDevicePropertyComposition) }
	/// The property selector `kAudioEndPointDevicePropertyEndPointList`
	public static var endpointList: Self { Self(kAudioEndPointDevicePropertyEndPointList) }
	/// The property selector `kAudioEndPointDevicePropertyIsPrivate`
	public static var isPrivate: Self { Self(kAudioEndPointDevicePropertyIsPrivate) }
}
