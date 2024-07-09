//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio tap object
///
/// - remark: This class correponds to objects with base class `kAudioTapClassID`
@available(macOS 14.2, *)
public class AudioTap: AudioObject {
	/// Returns the available audio taps
	/// - remark: This corresponds to the property`kAudioHardwarePropertyTapList` on `kAudioObjectSystemObject`
	public static var taps: [AudioTap] {
		get throws {
			try getAudioObjectProperty(PropertyAddress(kAudioHardwarePropertyTapList), from: AudioObjectID(kAudioObjectSystemObject)).map { try makeAudioTap($0) }
		}
	}

	/// Returns an initialized `AudioTap` with `uid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateUIDToTap` on `kAudioObjectSystemObject`
	/// - parameter uid: The UID of the desired tap
	public static func makeTap(forUID uid: String) throws -> AudioTap? {
		var qualifier = uid as CFString
		let objectID: AudioObjectID = try getAudioObjectProperty(PropertyAddress(kAudioHardwarePropertyTranslateUIDToTap), from: AudioObjectID(kAudioObjectSystemObject), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioTap` is added
		return AudioTap(objectID)
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString) \(try uid)>"
		} catch {
			return super.debugDescription
		}
	}
}

@available(macOS 14.2, *)
extension AudioTap {
	/// Returns the UID
	/// - remark: This corresponds to the property `kAudioTapPropertyUID`
	public var uid: String {
		get throws {
			try getProperty(PropertyAddress(kAudioTapPropertyUID), type: CFString.self) as String
		}
	}

	/// Returns the description
	/// - remark: This corresponds to the property `kAudioTapPropertyDescription`
	public var description: CATapDescription {
		get throws {
			try getProperty(PropertyAddress(kAudioTapPropertyDescription))
		}
	}

	/// Returns the format
	/// - remark: This corresponds to the property `kAudioTapPropertyFormat`
	public var format: AudioStreamBasicDescription {
		get throws {
			try getProperty(PropertyAddress(kAudioTapPropertyFormat))
		}
	}
}

@available(macOS 14.2, *)
extension AudioTap {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioTap>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioTap>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioTap>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}
}

@available(macOS 14.2, *)
extension AudioObjectSelector where T == AudioTap {
	/// The property selector `kAudioTapPropertyUID`
	public static let uid = AudioObjectSelector(kAudioTapPropertyUID)
	/// The property selector `kAudioTapPropertyDescription`
	public static let description = AudioObjectSelector(kAudioTapPropertyDescription)
	/// The property selector `kAudioTapPropertyFormat`
	public static let format = AudioObjectSelector(kAudioTapPropertyFormat)
}

// MARK: -

/// Creates and returns an initialized `AudioTap` or subclass.
@available(macOS 14.2, *)
func makeAudioTap(_ objectID: AudioObjectID) throws -> AudioTap {
	precondition(objectID != kAudioObjectUnknown)
	precondition(objectID != kAudioObjectSystemObject)

	let objectClass = try AudioObjectClass(objectID)

	switch objectClass {
	case kAudioTapClassID: 					return AudioTap(objectID)
	case kAudioSubTapClassID: 				return AudioSubtap(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown audio tap class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return AudioTap(objectID)
	}
}
