//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioStream {
	/// A thin wrapper around a HAL audio stream terminal type
	public struct TerminalType: Equatable, Hashable, Sendable {
		/// The underlying Core Audio audio stream terminal type
		public let rawValue: UInt32

		/// Creates a new instance with the specified value
		/// - parameter value: The value to use for the new instance
		public init(_ rawValue: UInt32) {
			self.rawValue = rawValue
		}
	}
}

extension AudioStream.TerminalType: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension AudioStream.TerminalType: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension AudioStream.TerminalType {
	/// Unknown
	public static let unknown 					= AudioStream.TerminalType(kAudioStreamTerminalTypeUnknown)
	/// Line level
	public static let line 						= AudioStream.TerminalType(kAudioStreamTerminalTypeLine)
	/// Digital audio interface
	public static let digitalAudioInterface 	= AudioStream.TerminalType(kAudioStreamTerminalTypeDigitalAudioInterface)
	/// Spekaer
	public static let speaker 					= AudioStream.TerminalType(kAudioStreamTerminalTypeSpeaker)
	/// Headphones
	public static let headphones 				= AudioStream.TerminalType(kAudioStreamTerminalTypeHeadphones)
	/// LFE speaker
	public static let lfeSpeaker 				= AudioStream.TerminalType(kAudioStreamTerminalTypeLFESpeaker)
	/// Telephone handset speaker
	public static let receiverSpeaker 			= AudioStream.TerminalType(kAudioStreamTerminalTypeReceiverSpeaker)
	/// Microphone
	public static let microphone 				= AudioStream.TerminalType(kAudioStreamTerminalTypeMicrophone)
	/// Headset microphone
	public static let headsetMicrophone 		= AudioStream.TerminalType(kAudioStreamTerminalTypeHeadsetMicrophone)
	/// Telephone handset microphone
	public static let receiverMicrophone 		= AudioStream.TerminalType(kAudioStreamTerminalTypeReceiverMicrophone)
	/// TTY
	public static let tty 						= AudioStream.TerminalType(kAudioStreamTerminalTypeTTY)
	/// HDMI
	public static let hdmi 						= AudioStream.TerminalType(kAudioStreamTerminalTypeHDMI)
	/// DisplayPort
	public static let displayPort 				= AudioStream.TerminalType(kAudioStreamTerminalTypeDisplayPort)
}

extension AudioStream.TerminalType: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		switch self.rawValue {
		case kAudioStreamTerminalTypeUnknown:					return "Unknown"
		case kAudioStreamTerminalTypeLine:						return "Line Level"
		case kAudioStreamTerminalTypeDigitalAudioInterface: 	return "Digital Audio Interface"
		case kAudioStreamTerminalTypeSpeaker:					return "Speaker"
		case kAudioStreamTerminalTypeHeadphones:				return "Headphones"
		case kAudioStreamTerminalTypeLFESpeaker:				return "LFE Speaker"
		case kAudioStreamTerminalTypeReceiverSpeaker:			return "Receiver Speaker"
		case kAudioStreamTerminalTypeMicrophone: 				return "Microphone"
		case kAudioStreamTerminalTypeHeadsetMicrophone:			return "Headset Microphone"
		case kAudioStreamTerminalTypeReceiverMicrophone:		return "Receiver Microphone"
		case kAudioStreamTerminalTypeTTY:						return "TTY"
		case kAudioStreamTerminalTypeHDMI:						return "HDMI"
		case kAudioStreamTerminalTypeDisplayPort:				return "DisplayPort"
		default: 												return "\(self.rawValue)"
		}
	}
}
