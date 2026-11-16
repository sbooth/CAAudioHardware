//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio control object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioControlClassID`
public class AudioControl: AudioObject, @unchecked Sendable {
	/// Returns the control's scope
	/// - remark: This corresponds to the property `kAudioControlPropertyScope`
	public var scope: PropertyScope {
		get throws {
			PropertyScope(try getProperty(PropertyAddress(kAudioControlPropertyScope)))
		}
	}

	/// Returns the control's element
	/// - remark: This corresponds to the property `kAudioControlPropertyElement`
	public var element: PropertyElement {
		get throws {
			PropertyElement(try getProperty(PropertyAddress(kAudioControlPropertyElement)))
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element))>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioControl {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioControl>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioControl>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioControl>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioControl>, on queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioControl>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioControl>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioControl>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

extension AudioObjectSelector where T == AudioControl {
	/// The property selector `kAudioControlPropertyScope`
	public static let scope = AudioObjectSelector(kAudioControlPropertyScope)
	/// The property selector `kAudioControlPropertyElement`
	public static let element = AudioObjectSelector(kAudioControlPropertyElement)
}

// MARK: -

/// Creates and returns an initialized `AudioControl` or subclass.
func makeAudioControl(_ objectID: AudioObjectID, baseClass: AudioClassID /*= kAudioControlClassID*/) throws -> AudioControl {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid audio control object id")
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let objectClass = try AudioObject.getClass(objectID)

	switch baseClass {
	case kAudioControlClassID:
		switch objectClass {
		case kAudioBooleanControlClassID:		return BooleanControl(objectID)
		case kAudioLevelControlClassID:			return LevelControl(objectID)
		case kAudioSelectorControlClassID: 		return SelectorControl(objectID)
		case kAudioSliderControlClassID:		return SliderControl(objectID)
		case kAudioStereoPanControlClassID: 	return StereoPanControl(objectID)
		default:
			os_log(.debug, log: audioObjectLog, "Unknown audio control class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
			return AudioControl(objectID)
		}
	case kAudioBooleanControlClassID: 	return try makeBooleanControl(objectID)
	case kAudioLevelControlClassID: 	return try makeLevelControl(objectID)
	case kAudioSelectorControlClassID: 	return try makeSelectorControl(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown audio control base class '%{public}@' for audio object 0x%{public}@", baseClass.fourCC, objectID.hexString)
		return AudioControl(objectID)
	}
}
