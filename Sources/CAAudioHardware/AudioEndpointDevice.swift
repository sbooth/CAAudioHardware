//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio endpoint device
/// - remark: This class correponds to objects with base class `kAudioEndPointDeviceClassID`
public class AudioEndpointDevice: AudioDevice {
}

extension AudioEndpointDevice {
	/// Returns the composition
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyComposition`
	public func composition() throws -> [AnyHashable: Any] {
		return try getProperty(PropertyAddress(kAudioEndPointDevicePropertyComposition), type: CFDictionary.self) as! [AnyHashable: Any]
	}

	/// Returns the audio endpoints owned by `self`
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyEndPointList`
	public func endpointList() throws -> [AudioEndpoint] {
		// Revisit if a subclass of `AudioEndpoint` is added
		return try getProperty(PropertyAddress(kAudioEndPointDevicePropertyEndPointList)).map { AudioEndpoint($0) }
	}

	/// Returns the owning `pid_t`or `0` for public devices
	/// - remark: This corresponds to the property `kAudioEndPointDevicePropertyIsPrivate`
	public func isPrivate() throws -> pid_t {
		return try getProperty(PropertyAddress(kAudioEndPointDevicePropertyIsPrivate))
	}
}

extension AudioObjectSelector where T == AudioEndpointDevice {
	/// The property selector `kAudioEndPointDevicePropertyComposition`
	public static let composition = AudioObjectSelector(kAudioEndPointDevicePropertyComposition)
	/// The property selector `kAudioEndPointDevicePropertyEndPointList`
	public static let endpointList = AudioObjectSelector(kAudioEndPointDevicePropertyEndPointList)
	/// The property selector `kAudioEndPointDevicePropertyIsPrivate`
	public static let isPrivate = AudioObjectSelector(kAudioEndPointDevicePropertyIsPrivate)
}
