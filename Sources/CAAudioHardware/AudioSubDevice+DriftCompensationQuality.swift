//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioSubDevice {
	/// A thin wrapper around a HAL audio subdevice drift compensation quality setting
	public struct DriftCompensationQuality: Equatable, Hashable, Sendable {
		/// The underlying Core Audio audio subdevice drift compensation quality setting
		public let rawValue: UInt32

		/// Creates a new instance with the specified value
		/// - parameter value: The value to use for the new instance
		public init(_ rawValue: UInt32) {
			self.rawValue = rawValue
		}
	}
}

extension AudioSubDevice.DriftCompensationQuality: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension AudioSubDevice.DriftCompensationQuality: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension AudioSubDevice.DriftCompensationQuality {
	/// Minimum quality
	@available(macOS 13, *)
	public static let min 		= AudioSubDevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMinQuality)
//	@available(macOS 14, *)
//	public static let min 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMinQuality)
	/// Low quality
	@available(macOS 13, *)
	public static let low 		= AudioSubDevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationLowQuality)
//	@available(macOS 14, *)
//	public static let low 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationLowQuality)
	/// Medium quality
	@available(macOS 13, *)
	public static let medium 	= AudioSubDevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMediumQuality)
//	@available(macOS 14, *)
//	public static let medium 	= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMediumQuality)
	/// High quality
	@available(macOS 13, *)
	public static let high 		= AudioSubDevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationHighQuality)
//	@available(macOS 14, *)
//	public static let high 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationHighQuality)
	/// Maximum quality
	@available(macOS 13, *)
	public static let max 		= AudioSubDevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMaxQuality)
//	@available(macOS 14, *)
//	public static let max 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMaxQuality)
}

extension AudioSubDevice.DriftCompensationQuality: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if #available(macOS 13.0, *) {
			switch rawValue {
			case kAudioSubDeviceDriftCompensationMinQuality:			return "Minimum"
			case kAudioSubDeviceDriftCompensationLowQuality:			return "Low"
			case kAudioSubDeviceDriftCompensationMediumQuality: 		return "Medium"
			case kAudioSubDeviceDriftCompensationHighQuality:			return "High"
			case kAudioSubDeviceDriftCompensationMaxQuality:			return "Maximum"
			default:													return "0x\(rawValue.hexString)"
			}
		} else {
			return "0x\(rawValue.hexString)"
		}
	}
}
