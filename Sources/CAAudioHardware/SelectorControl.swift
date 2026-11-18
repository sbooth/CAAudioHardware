//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio selector control object
/// - remark: This class correponds to objects with base class `kAudioSelectorControlClassID`
public class SelectorControl: AudioControl, @unchecked Sendable {
	/// Returns the selected items
	/// - remark: This corresponds to the property `kAudioSelectorControlPropertyCurrentItem`
	public var currentItem: [UInt32] {
		get throws {
			try getProperty(PropertyAddress(kAudioSelectorControlPropertyCurrentItem))
		}
	}
	/// Sets the selected items
	/// - remark: This corresponds to the property `kAudioSelectorControlPropertyCurrentItem`
	public func setCurrentItem(_ value: [UInt32]) throws {
		try setProperty(PropertyAddress((kAudioSelectorControlPropertyCurrentItem)), to: value)
	}

	/// Returns the available items
	/// - remark: This corresponds to the property `kAudioSelectorControlPropertyAvailableItems`
	public var availableItems: [UInt32] {
		get throws {
			try getProperty(PropertyAddress(kAudioSelectorControlPropertyAvailableItems))
		}
	}

	/// Returns the name of `itemID`
	/// - remark: This corresponds to the property `kAudioSelectorControlPropertyItemName`
	public func nameOfItem(_ itemID: UInt32) throws -> String {
		var qualifier = itemID
		return try getProperty(PropertyAddress(kAudioSelectorControlPropertyItemName), type: CFString.self, qualifier: PropertyQualifier(&qualifier)) as String
	}

	/// Returns the kind of `itemID`
	/// - remark: This corresponds to the property `kAudioSelectorControlPropertyItemKind`
	public func kindOfItem(_ itemID: UInt32) throws -> UInt32 {
		var qualifier = itemID
		return try getProperty(PropertyAddress(kAudioSelectorControlPropertyItemKind), qualifier: PropertyQualifier(&qualifier))
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element)), [\(try currentItem.map({ "'\($0.fourCC)'" }).joined(separator: ", "))]>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioObjectSelector where T: SelectorControl {
	/// The property selector `kAudioSelectorControlPropertyCurrentItem`
	public static var currentItem: Self { Self(kAudioSelectorControlPropertyCurrentItem) }
	/// The property selector `kAudioSelectorControlPropertyAvailableItems`
	public static var availableItems: Self { Self(kAudioSelectorControlPropertyAvailableItems) }
	/// The property selector `kAudioSelectorControlPropertyItemName`
	public static var itemName: Self { Self(kAudioSelectorControlPropertyItemName) }
	/// The property selector `kAudioSelectorControlPropertyItemKind`
	public static var itemKind: Self { Self(kAudioSelectorControlPropertyItemKind) }
}

// MARK: -

/// A HAL audio data source control
/// - remark: This class correponds to objects with base class `kAudioDataSourceControlClassID`
public class DataSourceControl: SelectorControl, @unchecked Sendable {
}

/// A HAL audio data destination control
/// - remark: This class correponds to objects with base class `kAudioDataDestinationControlClassID`
public class DataDestinationControl: SelectorControl, @unchecked Sendable {
}

/// A HAL audio clock source control
/// - remark: This class correponds to objects with base class `kAudioClockSourceControlClassID`
public class ClockSourceControl: SelectorControl, @unchecked Sendable {
}

/// A HAL audio line level control
/// - remark: This class correponds to objects with base class `kAudioLineLevelControlClassID`
public class LineLevelControl: SelectorControl, @unchecked Sendable {
}

/// A HAL audio high pass filter control
/// - remark: This class correponds to objects with base class `kAudioHighPassFilterControlClassID`
public class HighPassFilterControl: SelectorControl, @unchecked Sendable {
}

/// Creates and returns an initialized `SelectorControl` or subclass.
func makeSelectorControl(_ objectID: AudioObjectID) throws -> SelectorControl {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid selector control object id")
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let objectClass = try AudioObject.getClass(objectID)

	switch objectClass {
	case kAudioSelectorControlClassID: 			return SelectorControl(objectID)
	case kAudioDataSourceControlClassID: 		return DataSourceControl(objectID)
	case kAudioDataDestinationControlClassID: 	return DataDestinationControl(objectID)
	case kAudioClockSourceControlClassID: 		return ClockSourceControl(objectID)
	case kAudioLineLevelControlClassID: 		return LineLevelControl(objectID)
	case kAudioHighPassFilterControlClassID: 	return HighPassFilterControl(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown selector control class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return SelectorControl(objectID)
	}
}
