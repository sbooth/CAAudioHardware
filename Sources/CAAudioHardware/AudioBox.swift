//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio box object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioBoxClassID`
public class AudioBox: AudioObject, @unchecked Sendable {
	/// Returns the available audio boxes
	/// - remark: This corresponds to the property`kAudioHardwarePropertyBoxList` on `kAudioObjectSystemObject`
	public static var boxes: [AudioBox] {
		get throws {
			// Revisit if a subclass of `AudioBox` is added
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyBoxList)).map { AudioBox($0) }
		}
	}

	/// Returns an initialized `AudioBox` with `uid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateUIDToBox` on `kAudioObjectSystemObject`
	/// - parameter uid: The UID of the desired box
	public static func makeBox(forUID uid: String) throws -> AudioBox? {
		var qualifier = uid as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateUIDToBox), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioBox` is added
		return AudioBox(objectID)
	}

	/// Returns the box UID
	/// - remark: This corresponds to the property `kAudioBoxPropertyBoxUID`
	public var boxUID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyBoxUID), type: CFString.self) as String
		}
	}

	/// Returns the transport type
	/// - remark: This corresponds to the property `kAudioBoxPropertyTransportType`
	public var transportType: AudioDevice.TransportType {
		get throws {
			AudioDevice.TransportType(try getProperty(PropertyAddress(kAudioBoxPropertyTransportType), type: UInt32.self))
		}
	}

	/// Returns `true` if the box has audio
	/// - remark: This corresponds to the property `kAudioBoxPropertyHasAudio`
	public var hasAudio: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyHasAudio), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the box has video
	/// - remark: This corresponds to the property `kAudioBoxPropertyHasVideo`
	public var hasVideo: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyHasVideo), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the box has MIDI
	/// - remark: This corresponds to the property `kAudioBoxPropertyHasMIDI`
	public var hasMIDI: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyHasMIDI), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the box is protected
	/// - remark: This corresponds to the property `kAudioBoxPropertyIsProtected`
	public var isProtected: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyIsProtected), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the box is acquired
	/// - remark: This corresponds to the property `kAudioBoxPropertyAcquired`
	public var acquired: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyAcquired), type: UInt32.self) != 0
		}
	}

	/// Returns the reason an attempt to acquire the box failed
	/// - remark: This corresponds to the property `kAudioBoxPropertyAcquisitionFailed`
	public var acquisitionFailed: OSStatus {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyAcquisitionFailed))
		}
	}

	/// Returns the audio devices provided by the box
	/// - remark: This corresponds to the property `kAudioBoxPropertyDeviceList`
	public var deviceList: [AudioDevice] {
		get throws {
			try getProperty(PropertyAddress(kAudioBoxPropertyDeviceList)).map { try makeAudioDevice($0) }
		}
	}

	/// Returns the audio clock devices provided by the box
	/// - remark: This corresponds to the property `kAudioBoxPropertyClockDeviceList`
	public var clockDeviceList: [AudioClockDevice] {
		get throws {
			// Revisit if a subclass of `AudioClockDevice` is added
			try getProperty(PropertyAddress(kAudioBoxPropertyClockDeviceList)).map { AudioClockDevice($0) }
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			var media = [String]()
			if try hasAudio { media.append("audio") }
			if try hasVideo { media.append("video") }
			if try hasMIDI { media.append("MIDI") }
			return "<\(type(of: self)): 0x\(objectID.hexString), \(media.joined(separator: ", ")), [\(try deviceList.map({ $0.debugDescription }).joined(separator: ", "))]>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioObjectSelector where T: AudioBox {
	/// The property selector `kAudioBoxPropertyBoxUID`
	public static var boxUID: Self { Self(kAudioBoxPropertyBoxUID) }
	/// The property selector `kAudioBoxPropertyTransportType`
	public static var transportType: Self { Self(kAudioBoxPropertyTransportType) }
	/// The property selector `kAudioBoxPropertyHasAudio`
	public static var hasAudio: Self { Self(kAudioBoxPropertyHasAudio) }
	/// The property selector `kAudioBoxPropertyHasVideo`
	public static var hasVideo: Self { Self(kAudioBoxPropertyHasVideo) }
	/// The property selector `kAudioBoxPropertyHasMIDI`
	public static var hasMIDI: Self { Self(kAudioBoxPropertyHasMIDI) }
	/// The property selector `kAudioBoxPropertyIsProtected`
	public static var isProtected: Self { Self(kAudioBoxPropertyIsProtected) }
	/// The property selector `kAudioBoxPropertyAcquired`
	public static var acquired: Self { Self(kAudioBoxPropertyAcquired) }
	/// The property selector `kAudioBoxPropertyAcquisitionFailed`
	public static var acquisitionFailed: Self { Self(kAudioBoxPropertyAcquisitionFailed) }
	/// The property selector `kAudioBoxPropertyDeviceList`
	public static var deviceList: Self { Self(kAudioBoxPropertyDeviceList) }
	/// The property selector `kAudioBoxPropertyClockDeviceList`
	public static var clockDeviceList: Self { Self(kAudioBoxPropertyClockDeviceList) }
}
