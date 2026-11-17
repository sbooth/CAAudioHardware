//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio boolean control object
/// - remark: This class correponds to objects with base class `kAudioBooleanControlClassID`
public class BooleanControl: AudioControl, @unchecked Sendable {
	/// Returns the control's value
	/// - remark: This corresponds to the property `kAudioBooleanControlPropertyValue`
	public var value: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioBooleanControlPropertyValue), type: UInt32.self) != 0
		}
	}
	/// Sets the control's value
	/// - remark: This corresponds to the property `kAudioBooleanControlPropertyValue`
	public func setValue(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioBooleanControlPropertyValue), to: UInt32(value ? 1 : 0))
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element)), \(try value ? "On" : "Off")>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioObjectSelector where T: BooleanControl {
	/// The property selector `kAudioBooleanControlPropertyValue`
	public static var value: Self { Self(kAudioBooleanControlPropertyValue) }
}

// MARK: -

/// A HAL audio mute control object
/// - remark: This class correponds to objects with base class `kAudioMuteControlClassID`
public class MuteControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio solo control object
/// - remark: This class correponds to objects with base class `kAudioSoloControlClassID`
public class SoloControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio jack control object
/// - remark: This class correponds to objects with base class `kAudioJackControlClassID`
public class JackControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio LFE mute control object
/// - remark: This class correponds to objects with base class `kAudioLFEMuteControlClassID`
public class LFEMuteControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio phantom power control object
/// - remark: This class correponds to objects with base class `kAudioPhantomPowerControlClassID`
public class PhantomPowerControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio phase invert control object
/// - remark: This class correponds to objects with base class `kAudioPhaseInvertControlClassID`
public class PhaseInvertControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio clip light control object
/// - remark: This class correponds to objects with base class `kAudioClipLightControlClassID`
public class ClipLightControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio talkback control object
/// - remark: This class correponds to objects with base class `kAudioTalkbackControlClassID`
public class TalkbackControl: BooleanControl, @unchecked Sendable {
}

/// A HAL audio listenback control object
/// - remark: This class correponds to objects with base class `kAudioListenbackControlClassID`
public class ListenbackControl: BooleanControl, @unchecked Sendable {
}

// MARK: -

/// Creates and returns an initialized `BooleanControl` or subclass.
func makeBooleanControl(_ objectID: AudioObjectID) throws -> BooleanControl {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid boolean control object id")
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let objectClass = try AudioObject.getClass(objectID)

	switch objectClass {
	case kAudioBooleanControlClassID: 		return BooleanControl(objectID)
	case kAudioMuteControlClassID: 			return MuteControl(objectID)
	case kAudioSoloControlClassID:			return SoloControl(objectID)
	case kAudioJackControlClassID:			return JackControl(objectID)
	case kAudioLFEMuteControlClassID:		return LFEMuteControl(objectID)
	case kAudioPhantomPowerControlClassID:	return PhantomPowerControl(objectID)
	case kAudioPhaseInvertControlClassID:	return PhaseInvertControl(objectID)
	case kAudioClipLightControlClassID:		return ClipLightControl(objectID)
	case kAudioTalkbackControlClassID:		return TalkbackControl(objectID)
	case kAudioListenbackControlClassID: 	return ListenbackControl(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown boolean control class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return BooleanControl(objectID)
	}
}
