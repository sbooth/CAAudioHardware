//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A thin wrapper around a HAL audio device transport type
	public struct TransportType: Equatable, Hashable, Sendable {
		/// The underlying Core Audio audio device transport type
		public let rawValue: UInt32

		/// Creates a new instance with the specified value
		/// - parameter value: The value to use for the new instance
		public init(_ value: UInt32) {
			self.rawValue = value
		}
	}
}

extension AudioDevice.TransportType: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension AudioDevice.TransportType: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension AudioDevice.TransportType {
	/// Unknown
	public static let unknown 			= AudioDevice.TransportType(kAudioDeviceTransportTypeUnknown)
	/// Built-in
	public static let builtIn 			= AudioDevice.TransportType(kAudioDeviceTransportTypeBuiltIn)
	/// Aggregate device
	public static let aggregate 		= AudioDevice.TransportType(kAudioDeviceTransportTypeAggregate)
	/// Virtual device
	public static let virtual 			= AudioDevice.TransportType(kAudioDeviceTransportTypeVirtual)
	/// PCI
	public static let pci 				= AudioDevice.TransportType(kAudioDeviceTransportTypePCI)
	/// USB
	public static let usb 				= AudioDevice.TransportType(kAudioDeviceTransportTypeUSB)
	/// FireWire
	public static let fireWire 			= AudioDevice.TransportType(kAudioDeviceTransportTypeFireWire)
	/// Bluetooth
	public static let bluetooth 		= AudioDevice.TransportType(kAudioDeviceTransportTypeBluetooth)
	/// Bluetooth Low Energy
	public static let bluetoothLE 		= AudioDevice.TransportType(kAudioDeviceTransportTypeBluetoothLE)
	/// HDMI
	public static let hdmi 				= AudioDevice.TransportType(kAudioDeviceTransportTypeHDMI)
	/// DisplayPort
	public static let displayPort 		= AudioDevice.TransportType(kAudioDeviceTransportTypeDisplayPort)
	/// AirPlay
	public static let airPlay 			= AudioDevice.TransportType(kAudioDeviceTransportTypeAirPlay)
	/// AVB
	public static let avb 				= AudioDevice.TransportType(kAudioDeviceTransportTypeAVB)
	/// Thunderbolt
	public static let thunderbolt 		= AudioDevice.TransportType(kAudioDeviceTransportTypeThunderbolt)
	/// Continuity Capture Wired
	public static let continuityCaptureWired 		= AudioDevice.TransportType(kAudioDeviceTransportTypeContinuityCaptureWired)
	/// Continuity Capture Wireless
	public static let continuityCaptureWireless 	= AudioDevice.TransportType(kAudioDeviceTransportTypeContinuityCaptureWireless)
	/// Continuity Capture
	@available(macOS, introduced: 13.0, deprecated: 13.0, message: "Please use .continuityCaptureWired and .continuityCaptureWireless to describe Continuity Capture devices.")
	public static let continuityCapture 			= AudioDevice.TransportType(kAudioDeviceTransportTypeContinuityCapture)
}

extension AudioDevice.TransportType: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		switch self.rawValue {
		case kAudioDeviceTransportTypeUnknown:			return "Unknown"
		case kAudioDeviceTransportTypeBuiltIn:			return "Built-in"
		case kAudioDeviceTransportTypeAggregate: 		return "Aggregate"
		case kAudioDeviceTransportTypeVirtual:			return "Virtual"
		case kAudioDeviceTransportTypePCI:				return "PCI"
		case kAudioDeviceTransportTypeUSB:				return "USB"
		case kAudioDeviceTransportTypeFireWire:			return "FireWire"
		case kAudioDeviceTransportTypeBluetooth:		return "Bluetooth"
		case kAudioDeviceTransportTypeBluetoothLE: 		return "Bluetooth Low Energy"
		case kAudioDeviceTransportTypeHDMI:				return "HDMI"
		case kAudioDeviceTransportTypeDisplayPort:		return "DisplayPort"
		case kAudioDeviceTransportTypeAirPlay:			return "AirPlay"
		case kAudioDeviceTransportTypeAVB:				return "AVB"
		case kAudioDeviceTransportTypeThunderbolt: 		return "Thunderbolt"
			// kAudioDeviceTransportTypeContinuityCaptureWired
		case 0x63637764 /* 'ccwd' */: 					return "Continuity Capture Wired"
			// kAudioDeviceTransportTypeContinuityCaptureWireless
		case 0x6363776c /* 'ccwl' */: 					return "Continuity Capture Wireless"
			// kAudioDeviceTransportTypeContinuityCapture
		case 0x63636170 /* 'ccap' */: 					return "Continuity Capture"
		default:										return "\(self.rawValue)"
		}
	}
}
