//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioSubdevice {
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

extension AudioSubdevice.DriftCompensationQuality: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension AudioSubdevice.DriftCompensationQuality: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension AudioSubdevice.DriftCompensationQuality {
	/// Minimum quality
	@available(macOS 13, *)
	public static let min 		= AudioSubdevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMinQuality)
//	@available(macOS 14, *)
//	public static let min 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMinQuality)
	/// Low quality
	@available(macOS 13, *)
	public static let low 		= AudioSubdevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationLowQuality)
//	@available(macOS 14, *)
//	public static let low 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationLowQuality)
	/// Medium quality
	@available(macOS 13, *)
	public static let medium 	= AudioSubdevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMediumQuality)
//	@available(macOS 14, *)
//	public static let medium 	= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMediumQuality)
	/// High quality
	@available(macOS 13, *)
	public static let high 		= AudioSubdevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationHighQuality)
//	@available(macOS 14, *)
//	public static let high 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationHighQuality)
	/// Maximum quality
	@available(macOS 13, *)
	public static let max 		= AudioSubdevice.DriftCompensationQuality(kAudioSubDeviceDriftCompensationMaxQuality)
//	@available(macOS 14, *)
//	public static let max 		= AudioSubdevice.DriftCompensationQuality(kAudioAggregateDriftCompensationMaxQuality)
}

extension AudioSubdevice.DriftCompensationQuality: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if #available(macOS 13.0, *) {
			switch rawValue {
			case kAudioSubDeviceDriftCompensationMinQuality:			return "Minimum"
			case kAudioSubDeviceDriftCompensationLowQuality:			return "Low"
			case kAudioSubDeviceDriftCompensationMediumQuality: 		return "Medium"
			case kAudioSubDeviceDriftCompensationHighQuality:			return "High"
			case kAudioSubDeviceDriftCompensationMaxQuality:			return "Maximum"
			default:													return "0x\(String(self.rawValue, radix: 16))"
			}
		} else {
			return "0x\(String(rawValue, radix: 16))"
		}
	}
}
