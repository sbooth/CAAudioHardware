//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio stereo pan control object
/// - remark: This class correponds to objects with base class `kAudioStereoPanControlClassID`
public class StereoPanControl: AudioControl, @unchecked Sendable {
	/// Returns the control's value
	/// - remark: This corresponds to the property `kAudioStereoPanControlPropertyValue`
	public var value: Float {
		get throws {
			try getProperty(PropertyAddress(kAudioStereoPanControlPropertyValue))
		}
	}
	/// Sets the control's value
	/// - remark: This corresponds to the property `kAudioStereoPanControlPropertyValue`
	public func setValue(_ value: Float) throws {
		try setProperty(PropertyAddress(kAudioStereoPanControlPropertyValue), to: value)
	}

	/// Returns the control's panning channels
	/// - remark: This corresponds to the property `kAudioStereoPanControlPropertyPanningChannels`
	public var panningChannels: (PropertyElement, PropertyElement) {
		get throws {
			let channels = try getProperty(PropertyAddress(kAudioStereoPanControlPropertyPanningChannels), elementType: UInt32.self)
			precondition(channels.count == 2, "Unexpected array length for kAudioStereoPanControlPropertyPanningChannels")
			return (PropertyElement(channels[0]), PropertyElement(channels[1]))
		}
	}
	/// Sets the control's panning channels
	/// - remark: This corresponds to the property `kAudioStereoPanControlPropertyPanningChannels`
	public func setPanningChannels(_ value: (PropertyElement, PropertyElement)) throws {
		try setProperty(PropertyAddress(kAudioStereoPanControlPropertyPanningChannels), to: [value.0.rawValue, value.1.rawValue])
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			let panningChannels = try self.panningChannels
			return "<\(type(of: self)): 0x\(objectID.hexString), (\(try scope), \(try element)), \(try value), (\(panningChannels.0), \(panningChannels.1))>"
		} catch {
			return super.debugDescription
		}
	}
}

extension StereoPanControl {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<StereoPanControl>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<StereoPanControl>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<StereoPanControl>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
	}
}

extension AudioObjectSelector where T == StereoPanControl {
	/// The property selector `kAudioStereoPanControlPropertyValue`
	public static let value = AudioObjectSelector(kAudioStereoPanControlPropertyValue)
	/// The property selector `kAudioStereoPanControlPropertyPanningChannels`
	public static let panningChannels = AudioObjectSelector(kAudioStereoPanControlPropertyPanningChannels)
}
