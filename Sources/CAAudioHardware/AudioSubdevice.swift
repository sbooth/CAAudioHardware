//
// Copyright (c) 2020 - 2023 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio subdevice
/// - remark: This class correponds to objects with base class `kAudioSubDeviceClassID`
public class AudioSubdevice: AudioDevice {
}

extension AudioSubdevice {
	/// Returns the extra latency
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyExtraLatency`
	public func extraLatency() throws -> Double {
		return try getProperty(PropertyAddress(kAudioSubDevicePropertyExtraLatency))
	}

	/// Returns the drift compensation
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensation`
	public func driftCompensation() throws -> Bool {
		return try getProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensation), type: UInt32.self) != 0
	}
	/// Sets the drift compensation
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensation`
	public func setDriftCompensation(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensation), to: UInt32(value ? 1 : 0))
	}

	/// Returns the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensationQuality`
	public func driftCompensationQuality() throws -> UInt32 {
		return try getProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensationQuality))
	}
	/// Sets the drift compensation quality
	/// - remark: This corresponds to the property `kAudioSubDevicePropertyDriftCompensationQuality`
	public func setDriftCompensationQuality(_ value: UInt32) throws {
		try setProperty(PropertyAddress(kAudioSubDevicePropertyDriftCompensationQuality), to: value)
	}
}

extension AudioSubdevice {
	/// A thin wrapper around a HAL audio subdevice drift compensation quality setting
	public struct DriftCompensationQuality: RawRepresentable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
		/// Minimum quality
		@available(macOS 13, *)
		public static let min 		= DriftCompensationQuality(rawValue: kAudioSubDeviceDriftCompensationMinQuality)
//		@available(macOS 14, *)
//		public static let min 		= DriftCompensationQuality(rawValue: kAudioAggregateDriftCompensationMinQuality)
		/// Low quality
		@available(macOS 13, *)
		public static let low 		= DriftCompensationQuality(rawValue: kAudioSubDeviceDriftCompensationLowQuality)
//		@available(macOS 14, *)
//		public static let low 		= DriftCompensationQuality(rawValue: kAudioAggregateDriftCompensationLowQuality)
		/// Medium quality
		@available(macOS 13, *)
		public static let medium 	= DriftCompensationQuality(rawValue: kAudioSubDeviceDriftCompensationMediumQuality)
//		@available(macOS 14, *)
//		public static let medium 	= DriftCompensationQuality(rawValue: kAudioAggregateDriftCompensationMediumQuality)
		/// High quality
		@available(macOS 13, *)
		public static let high 		= DriftCompensationQuality(rawValue: kAudioSubDeviceDriftCompensationHighQuality)
//		@available(macOS 14, *)
//		public static let high 		= DriftCompensationQuality(rawValue: kAudioAggregateDriftCompensationHighQuality)
		/// Maximum quality
		@available(macOS 13, *)
		public static let max 		= DriftCompensationQuality(rawValue: kAudioSubDeviceDriftCompensationMaxQuality)
//		@available(macOS 14, *)
//		public static let max 		= DriftCompensationQuality(rawValue: kAudioAggregateDriftCompensationMaxQuality)

		public let rawValue: UInt32

		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}

		public init(integerLiteral value: UInt32) {
			self.rawValue = value
		}

		public init(stringLiteral value: StringLiteralType) {
			self.rawValue = value.fourCC
		}
	}
}

extension AudioSubdevice.DriftCompensationQuality: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if #available(macOS 13.0, *) {
			switch self.rawValue {
			case kAudioSubDeviceDriftCompensationMinQuality:			return "Minimum (0x\(String(self.rawValue, radix: 16)))"
			case kAudioSubDeviceDriftCompensationLowQuality:			return "Low (0x\(String(self.rawValue, radix: 16)))"
			case kAudioSubDeviceDriftCompensationMediumQuality: 		return "Medium (0x\(String(self.rawValue, radix: 16)))"
			case kAudioSubDeviceDriftCompensationHighQuality:			return "High (0x\(String(self.rawValue, radix: 16)))"
			case kAudioSubDeviceDriftCompensationMaxQuality:			return "Maximum (0x\(String(self.rawValue, radix: 16)))"
			default:													return "\(String(self.rawValue, radix: 16))"
			}
		} else {
			return "\(String(self.rawValue, radix: 16))"
		}
	}
}

extension AudioSubdevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioSubdevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioSubdevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed when `selector` in `scope` on `element` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioSubdevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: PropertyChangeNotificationBlock?, on queue: DispatchQueue? = .global(qos: .background)) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block, on: queue)
	}
}

extension AudioObjectSelector where T == AudioSubdevice {
	/// The property selector `kAudioSubDevicePropertyExtraLatency`
	public static let extraLatency = AudioObjectSelector(kAudioSubDevicePropertyExtraLatency)
	/// The property selector `kAudioSubDevicePropertyDriftCompensation`
	public static let driftCompensation = AudioObjectSelector(kAudioSubDevicePropertyDriftCompensation)
	/// The property selector `kAudioSubDevicePropertyDriftCompensationQuality`
	public static let driftCompensationQuality = AudioObjectSelector(kAudioSubDevicePropertyDriftCompensationQuality)
}
