//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio slider control object
/// - remark: This class correponds to objects with base class `kAudioSliderControlClassID`
public class SliderControl: AudioControl {
	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(String(objectID, radix: 16, uppercase: false)), (\(try scope()), \(try element())), \(try value())>"
		} catch {
			return super.debugDescription
		}
	}
}

extension SliderControl {
	/// Returns the control's value
	/// - remark: This corresponds to the property `kAudioSliderControlPropertyValue`
	public func value() throws -> UInt32 {
		return try getProperty(PropertyAddress(kAudioSliderControlPropertyValue))
	}
	/// Sets the control's value
	/// - remark: This corresponds to the property `kAudioSliderControlPropertyValue`
	public func setValue(_ value: UInt32) throws {
		try setProperty(PropertyAddress(kAudioSliderControlPropertyValue), to: value)
	}

	/// Returns the available control values
	/// - remark: This corresponds to the property `kAudioSliderControlPropertyRange`
	public func range() throws -> ClosedRange<UInt32> {
		let value = try getProperty(PropertyAddress(kAudioSliderControlPropertyRange), elementType: UInt32.self)
		precondition(value.count == 2, "Unexpected array length for kAudioSliderControlPropertyRange")
		return value[0] ... value[1]
	}
}

extension AudioObjectSelector where T == SliderControl {
	/// The property selector `kAudioSliderControlPropertyValue`
	public static let value = AudioObjectSelector(kAudioSliderControlPropertyValue)
	/// The property selector `kAudioSliderControlPropertyRange`
	public static let range = AudioObjectSelector(kAudioSliderControlPropertyRange)
}
