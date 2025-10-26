//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
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

extension AudioBox {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioBox>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioBox>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioBox>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioBox {
	/// The property selector `kAudioBoxPropertyBoxUID`
	public static let boxUID = AudioObjectSelector(kAudioBoxPropertyBoxUID)
	/// The property selector `kAudioBoxPropertyTransportType`
	public static let transportType = AudioObjectSelector(kAudioBoxPropertyTransportType)
	/// The property selector `kAudioBoxPropertyHasAudio`
	public static let hasAudio = AudioObjectSelector(kAudioBoxPropertyHasAudio)
	/// The property selector `kAudioBoxPropertyHasVideo`
	public static let hasVideo = AudioObjectSelector(kAudioBoxPropertyHasVideo)
	/// The property selector `kAudioBoxPropertyHasMIDI`
	public static let hasMIDI = AudioObjectSelector(kAudioBoxPropertyHasMIDI)
	/// The property selector `kAudioBoxPropertyIsProtected`
	public static let isProtected = AudioObjectSelector(kAudioBoxPropertyIsProtected)
	/// The property selector `kAudioBoxPropertyAcquired`
	public static let acquired = AudioObjectSelector(kAudioBoxPropertyAcquired)
	/// The property selector `kAudioBoxPropertyAcquisitionFailed`
	public static let acquisitionFailed = AudioObjectSelector(kAudioBoxPropertyAcquisitionFailed)
	/// The property selector `kAudioBoxPropertyDeviceList`
	public static let deviceList = AudioObjectSelector(kAudioBoxPropertyDeviceList)
	/// The property selector `kAudioBoxPropertyClockDeviceList`
	public static let clockDeviceList = AudioObjectSelector(kAudioBoxPropertyClockDeviceList)
}
