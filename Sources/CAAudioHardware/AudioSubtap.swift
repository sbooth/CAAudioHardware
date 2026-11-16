//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio subtap object
/// - remark: This class correponds to objects with base class `kAudioSubTapClassID`
@available(macOS 14.2, *)
public class AudioSubtap: AudioObject, @unchecked Sendable {
	/// Returns the extra latency
	/// - remark: This corresponds to the property `kAudioSubTapPropertyExtraLatency`
	/// - parameter scope: The desired scope
	public func extraLatency(inScope scope: PropertyScope) throws -> Double {
		try getProperty(PropertyAddress(PropertySelector(kAudioSubTapPropertyExtraLatency), scope: scope))
	}
	/// Sets the extra latency
	/// - remark: This corresponds to the property `kAudioSubTapPropertyExtraLatency`
	/// - parameter scope: The desired scope
	public func setExtraLatency(_ value: Double, inScope scope: PropertyScope) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioSubTapPropertyExtraLatency), scope: scope), to: value)
	}

	/// Returns the drift compensation
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensation`
	public var driftCompensation: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensation), type: UInt32.self) != 0
		}
	}
	/// Sets the drift compensation
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensation`
	public func setDriftCompensation(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensation), to: UInt32(value ? 1 : 0))
	}

	/// Returns the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensationQuality`
	public var driftCompensationQuality: AudioSubdevice.DriftCompensationQuality {
		get throws {
			try AudioSubdevice.DriftCompensationQuality(getProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensationQuality), type: UInt32.self))
		}
	}
	/// Sets the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubTapPropertyDriftCompensationQuality`
	public func setDriftCompensationQuality(_ value: AudioSubdevice.DriftCompensationQuality) throws {
		try setProperty(PropertyAddress(kAudioSubTapPropertyDriftCompensationQuality), to: value.rawValue)
	}
}

@available(macOS 14.2, *)
extension AudioSubtap {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioSubtap>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioSubtap>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioSubtap>, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observe(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` changes
	/// - important: The listener remains active only while the returned registration is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The listener registration
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioSubtap>, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyListenerRegistration {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue)), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector`
	/// - parameter selector: The selector of the desired property
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioSubtap>) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns an asynchronous sequence of values for `selector`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioSubtap>, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue)), read: read)
	}
}

@available(macOS 14.2, *)
extension AudioObjectSelector where T == AudioSubtap {
	/// The property selector `kAudioSubTapPropertyExtraLatency`
	public static let extraLatency = AudioObjectSelector(kAudioSubTapPropertyExtraLatency)
	/// The property selector `kAudioSubTapPropertyDriftCompensation`
	public static let driftCompensation = AudioObjectSelector(kAudioSubTapPropertyDriftCompensation)
	/// The property selector `kAudioSubTapPropertyDriftCompensationQuality`
	public static let driftCompensationQuality = AudioObjectSelector(kAudioSubTapPropertyDriftCompensationQuality)
}
