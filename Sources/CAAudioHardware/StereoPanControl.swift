//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
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

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<StereoPanControl>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<StereoPanControl>, on queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<StereoPanControl>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<StereoPanControl>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<StereoPanControl>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

extension AudioObjectSelector where T == StereoPanControl {
	/// The property selector `kAudioStereoPanControlPropertyValue`
	public static let value = AudioObjectSelector(kAudioStereoPanControlPropertyValue)
	/// The property selector `kAudioStereoPanControlPropertyPanningChannels`
	public static let panningChannels = AudioObjectSelector(kAudioStereoPanControlPropertyPanningChannels)
}
