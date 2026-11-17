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

extension BooleanControl {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<BooleanControl>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<BooleanControl>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<BooleanControl>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<BooleanControl>, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<BooleanControl>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<BooleanControl>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<BooleanControl>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

extension AudioObjectSelector where T == BooleanControl {
	/// The property selector `kAudioBooleanControlPropertyValue`
	public static let value = AudioObjectSelector(kAudioBooleanControlPropertyValue)
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
