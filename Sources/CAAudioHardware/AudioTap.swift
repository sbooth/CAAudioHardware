//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio tap object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioTapClassID`
@available(macOS 14.2, *)
public class AudioTap: AudioObject, @unchecked Sendable {
	/// Returns the available audio taps
	/// - remark: This corresponds to the property`kAudioHardwarePropertyTapList` on `kAudioObjectSystemObject`
	public static var taps: [AudioTap] {
		get throws {
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTapList)).map { AudioTap($0) }
		}
	}

	/// Returns an initialized `AudioTap` with `uid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateUIDToTap` on `kAudioObjectSystemObject`
	/// - parameter uid: The UID of the desired tap
	public static func makeTap(forUID uid: String) throws -> AudioTap? {
		var qualifier = uid as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateUIDToTap), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioTap` is added
		return AudioTap(objectID)
	}

	/// Creates and returns a new `AudioTap` using the provided description
	/// - parameter description: A `CATapDescription` describing the `AudioTap`
	/// - returns: A newly-created `AudioTap`
	/// - throws: An error if the `AudioTap` could not be created
	public static func create(description: CATapDescription) throws -> AudioTap {
		var objectId = kAudioObjectUnknown
		let result = AudioHardwareCreateProcessTap(description, &objectId)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareCreateProcessTap (%{public}@) failed: '%{public}@'", description, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return AudioTap(objectId)
	}

#if false
	public func destroy() throws {
		removeAllPropertyListeners()
	}
#endif

	/// Destroys `tap`
	/// - note: Futher use of `tap` following this function is undefined
	/// - parameter tap: The `AudioTap` to destroy
	/// - throws: An error if the `AudioTap` could not be destroyed
	public static func destroy(_ tap: AudioTap) throws {
		let result = AudioHardwareDestroyProcessTap(tap.objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareDestroyProcessTap (0x%x) failed: '%{public}@'", tap.objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		tap.removeAllPropertyListeners()
	}

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
	/// Sets the description
	/// - remark: This corresponds to the property `kAudioTapPropertyDescription`
	public func setDescription(_ value: CATapDescription) throws {
		try setProperty(PropertyAddress(kAudioTapPropertyDescription), to: value)
	}

	/// Returns the format
	/// - remark: This corresponds to the property `kAudioTapPropertyFormat`
	public var format: AudioStreamBasicDescription {
		get throws {
			try getProperty(PropertyAddress(kAudioTapPropertyFormat))
		}
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
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioTap>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
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
