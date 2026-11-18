//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio level control object
/// - remark: This class correponds to objects with base class `kAudioLevelControlClassID`
public class LevelControl: AudioControl, @unchecked Sendable {
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

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element)), \(try scalarValue)>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioObjectSelector where T: LevelControl {
	/// The property selector `kAudioLevelControlPropertyScalarValue`
	public static var scalarValue: Self { Self(kAudioLevelControlPropertyScalarValue) }
	/// The property selector `kAudioLevelControlPropertyDecibelValue`
	public static var decibelValue: Self { Self(kAudioLevelControlPropertyDecibelValue) }
	/// The property selector `kAudioLevelControlPropertyDecibelRange`
	public static var decibelRange: Self { Self(kAudioLevelControlPropertyDecibelRange) }
	/// The property selector `kAudioLevelControlPropertyConvertScalarToDecibels`
	public static var scalarToDecibels: Self { Self(kAudioLevelControlPropertyConvertScalarToDecibels) }
	/// The property selector `kAudioLevelControlPropertyConvertDecibelsToScalar`
	public static var decibelsToScalar: Self { Self(kAudioLevelControlPropertyConvertDecibelsToScalar) }
}

// MARK: -

/// A HAL audio volume control object
/// - remark: This class correponds to objects with base class `kAudioVolumeControlClassID`
public class VolumeControl: LevelControl, @unchecked Sendable {
}

/// A HAL audio LFE volume control object
/// - remark: This class correponds to objects with base class `kAudioLFEVolumeControlClassID`
public class LFEVolumeControl: LevelControl, @unchecked Sendable {
}

// MARK: -

/// Creates and returns an initialized `LevelControl` or subclass.
func makeLevelControl(_ objectID: AudioObjectID) throws -> LevelControl {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid level control object id")
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let objectClass = try AudioObject.getClass(objectID)

	switch objectClass {
	case kAudioLevelControlClassID: 			return LevelControl(objectID)
	case kAudioVolumeControlClassID: 			return VolumeControl(objectID)
	case kAudioLFEVolumeControlClassID: 		return LFEVolumeControl(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown level control class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return LevelControl(objectID)
	}
}
