//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio level control object
/// - remark: This class correponds to objects with base class `kAudioLevelControlClassID`
public class LevelControl: AudioControl {
	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element)), \(try scalarValue)>"
		} catch {
			return super.debugDescription
		}
	}
}

extension LevelControl {
	/// Returns the control's scalar value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyScalarValue`
	public var scalarValue: Float {
		get throws {
			try getProperty(PropertyAddress(kAudioLevelControlPropertyScalarValue))
		}
	}
	/// Sets the control's scalar value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyScalarValue`
	public func setScalarValue(_ value: Float) throws {
		try setProperty(PropertyAddress(kAudioLevelControlPropertyScalarValue), to: value)
	}

	/// Returns the control's decibel value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyDecibelValue`
	public var decibelValue: Float {
		get throws {
			try getProperty(PropertyAddress(kAudioLevelControlPropertyDecibelValue))
		}
	}
	/// Sets the control's decibel value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyDecibelValue`
	public func setDecibelValue(_ value: Float) throws {
		try setProperty(PropertyAddress(kAudioLevelControlPropertyDecibelValue), to: value)
	}

	/// Returns the decibel range
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyDecibelRange`
	public var decibelRange: ClosedRange<Float> {
		get throws {
			let value: AudioValueRange = try getProperty(PropertyAddress(kAudioLevelControlPropertyDecibelRange))
			return Float(value.mMinimum) ... Float(value.mMaximum)
		}
	}

	/// Converts `scalar` to decibels and returns the converted value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyConvertScalarToDecibels`
	/// - parameter scalar: The value to convert
	public func convertToDecibels(fromScalar scalar: Float) throws -> Float {
		return try getProperty(PropertyAddress(kAudioLevelControlPropertyConvertScalarToDecibels), initialValue: scalar)
	}

	/// Converts `decibels` to scalar and returns the converted value
	/// - remark: This corresponds to the property `kAudioLevelControlPropertyConvertDecibelsToScalar`
	/// - parameter decibels: The value to convert
	public func convertToScalar(fromDecibels decibels: Float) throws -> Float {
		return try getProperty(PropertyAddress(kAudioLevelControlPropertyConvertDecibelsToScalar), initialValue: decibels)
	}
}

extension LevelControl {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<LevelControl>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<LevelControl>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<LevelControl>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}
}

extension AudioObjectSelector where T == LevelControl {
	/// The property selector `kAudioLevelControlPropertyScalarValue`
	public static let scalarValue = AudioObjectSelector(kAudioLevelControlPropertyScalarValue)
	/// The property selector `kAudioLevelControlPropertyDecibelValue`
	public static let decibelValue = AudioObjectSelector(kAudioLevelControlPropertyDecibelValue)
	/// The property selector `kAudioLevelControlPropertyDecibelRange`
	public static let decibelRange = AudioObjectSelector(kAudioLevelControlPropertyDecibelRange)
	/// The property selector `kAudioLevelControlPropertyConvertScalarToDecibels`
	public static let scalarToDecibels = AudioObjectSelector(kAudioLevelControlPropertyConvertScalarToDecibels)
	/// The property selector `kAudioLevelControlPropertyConvertDecibelsToScalar`
	public static let decibelsToScalar = AudioObjectSelector(kAudioLevelControlPropertyConvertDecibelsToScalar)
}

// MARK: -

/// A HAL audio volume control object
/// - remark: This class correponds to objects with base class `kAudioVolumeControlClassID`
public class VolumeControl: LevelControl {
}

/// A HAL audio LFE volume control object
/// - remark: This class correponds to objects with base class `kAudioLFEVolumeControlClassID`
public class LFEVolumeControl: LevelControl {
}

// MARK: -

/// Creates and returns an initialized `LevelControl` or subclass.
func makeLevelControl(_ objectID: AudioObjectID) throws -> LevelControl {
	precondition(objectID != kAudioObjectUnknown)
	precondition(objectID != kAudioObjectSystemObject)

	let objectClass = try AudioObjectClass(objectID)

	switch objectClass {
	case kAudioLevelControlClassID: 			return LevelControl(objectID)
	case kAudioVolumeControlClassID: 			return VolumeControl(objectID)
	case kAudioLFEVolumeControlClassID: 		return LFEVolumeControl(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown level control class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return LevelControl(objectID)
	}
}
