//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio control object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioControlClassID`
public class AudioControl: AudioObject {
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

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioControl>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
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
