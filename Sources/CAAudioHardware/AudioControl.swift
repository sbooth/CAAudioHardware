//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
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
	precondition(objectID != kAudioObjectUnknown)
	precondition(objectID != kAudioObjectSystemObject)

	let objectClass = try AudioObjectClass(objectID)

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
