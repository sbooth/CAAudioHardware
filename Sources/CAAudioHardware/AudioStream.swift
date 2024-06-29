//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A HAL audio stream object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`), a main element (`kAudioObjectPropertyElementMain`), and an element for each channel
/// - remark: This class correponds to objects with base class `kAudioStreamClassID`
public class AudioStream: AudioObject {
	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(String(objectID, radix: 16, uppercase: false)), \(try isActive() ? "active" : "inactive"), \(try direction() ? "output" : "input"), starting channel = \(try startingChannel()), virtual format = \(try virtualFormat()), physical format = \(try physicalFormat())>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioStream {
	/// Returns `true` if the stream is active
	/// - remark: This corresponds to the property `kAudioStreamPropertyIsActive`
	public func isActive() throws -> Bool {
		return try getProperty(PropertyAddress(kAudioStreamPropertyIsActive), type: UInt32.self) != 0
	}

	/// Returns `true` if `self` is an output stream
	/// - remark: This corresponds to the property `kAudioStreamPropertyDirection`
	public func direction() throws -> Bool {
		return try getProperty(PropertyAddress(kAudioStreamPropertyDirection), type: UInt32.self) == 0
	}

	/// Returns the terminal type
	/// - remark: This corresponds to the property `kAudioStreamPropertyTerminalType`
	public func terminalType() throws -> TerminalType {
		return AudioStream.TerminalType(try getProperty(PropertyAddress(kAudioStreamPropertyTerminalType), type: UInt32.self))
	}

	/// Returns the starting channel
	/// - remark: This corresponds to the property `kAudioStreamPropertyStartingChannel`
	public func startingChannel() throws -> PropertyElement {
		return PropertyElement(try getProperty(PropertyAddress(kAudioStreamPropertyStartingChannel), type: UInt32.self))
	}

	/// Returns the latency
	/// - remark: This corresponds to the property `kAudioStreamPropertyLatency`
	public func latency() throws -> UInt32 {
		return try getProperty(PropertyAddress(kAudioStreamPropertyLatency))
	}

	/// Returns the virtual format
	/// - remark: This corresponds to the property `kAudioStreamPropertyVirtualFormat`
	public func virtualFormat() throws -> AudioStreamBasicDescription {
		return try getProperty(PropertyAddress(kAudioStreamPropertyVirtualFormat))
	}
	/// Sets the virtual format
	/// - remark: This corresponds to the property `kAudioStreamPropertyVirtualFormat`
	public func setVirtualFormat(_ value: AudioStreamBasicDescription) throws {
		return try setProperty(PropertyAddress(kAudioStreamPropertyVirtualFormat), to: value)
	}

	/// Returns the available virtual formats
	/// - remark: This corresponds to the property `kAudioStreamPropertyAvailableVirtualFormats`
	public func availableVirtualFormats() throws -> [(AudioStreamBasicDescription, ClosedRange<Double>)] {
		let value = try getProperty(PropertyAddress(kAudioStreamPropertyAvailableVirtualFormats), elementType: AudioStreamRangedDescription.self)
		return value.map { ($0.mFormat, $0.mSampleRateRange.mMinimum ... $0.mSampleRateRange.mMaximum) }
	}

	/// Returns the physical format
	/// - remark: This corresponds to the property `kAudioStreamPropertyPhysicalFormat`
	public func physicalFormat() throws -> AudioStreamBasicDescription {
		return try getProperty(PropertyAddress(kAudioStreamPropertyPhysicalFormat))
	}
	/// Sets the physical format
	/// - remark: This corresponds to the property `kAudioStreamPropertyPhysicalFormat`
	public func setPhysicalFormat(_ value: AudioStreamBasicDescription) throws {
		return try setProperty(PropertyAddress(kAudioStreamPropertyPhysicalFormat), to: value)
	}

	/// Returns the available physical formats
	/// - remark: This corresponds to the property `kAudioStreamPropertyAvailablePhysicalFormats`
	public func availablePhysicalFormats() throws -> [(AudioStreamBasicDescription, ClosedRange<Double>)] {
		let value = try getProperty(PropertyAddress(kAudioStreamPropertyAvailablePhysicalFormats), elementType: AudioStreamRangedDescription.self)
		return value.map { ($0.mFormat, $0.mSampleRateRange.mMinimum ... $0.mSampleRateRange.mMaximum) }
	}
}

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

extension AudioStream {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioStream>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioStream>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioStream>, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), on: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioStream {
	/// The property selector `kAudioStreamPropertyIsActive`
	public static let isActive = AudioObjectSelector(kAudioStreamPropertyIsActive)
	/// The property selector `kAudioStreamPropertyDirection`
	public static let direction = AudioObjectSelector(kAudioStreamPropertyDirection)
	/// The property selector `kAudioStreamPropertyTerminalType`
	public static let terminalType = AudioObjectSelector(kAudioStreamPropertyTerminalType)
	/// The property selector `kAudioStreamPropertyStartingChannel`
	public static let startingChannel = AudioObjectSelector(kAudioStreamPropertyStartingChannel)
	/// The property selector `kAudioStreamPropertyLatency`
	public static let latency = AudioObjectSelector(kAudioStreamPropertyLatency)
	/// The property selector `kAudioStreamPropertyVirtualFormat`
	public static let virtualFormat = AudioObjectSelector(kAudioStreamPropertyVirtualFormat)
	/// The property selector `kAudioStreamPropertyAvailableVirtualFormats`
	public static let availableVirtualFormats = AudioObjectSelector(kAudioStreamPropertyAvailableVirtualFormats)
	/// The property selector `kAudioStreamPropertyPhysicalFormat`
	public static let physicalFormat = AudioObjectSelector(kAudioStreamPropertyPhysicalFormat)
	/// The property selector `kAudioStreamPropertyAvailablePhysicalFormats`
	public static let availablePhysicalFormats = AudioObjectSelector(kAudioStreamPropertyAvailablePhysicalFormats)
}
