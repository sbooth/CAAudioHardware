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

	/// Destroys `tap`
	/// - note: Futher use of `tap` following this function is undefined
	/// - important: Invalidate property observations and end property change sequences for `tap` before destroying it
	/// - parameter tap: The `AudioTap` to destroy
	/// - throws: An error if the `AudioTap` could not be destroyed
	public static func destroy(_ tap: AudioTap) throws {
		let result = AudioHardwareDestroyProcessTap(tap.objectID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioHardwareDestroyProcessTap (0x%x) failed: '%{public}@'", tap.objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
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

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioTap>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioTap>, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioTap>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioTap>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioTap>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
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
