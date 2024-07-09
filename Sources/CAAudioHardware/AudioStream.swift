//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import CoreAudioExtensions

/// A HAL audio stream object
///
/// This class has a single scope (`kAudioObjectPropertyScopeGlobal`), a main element (`kAudioObjectPropertyElementMain`), and an element for each channel
/// - remark: This class correponds to objects with base class `kAudioStreamClassID`
public class AudioStream: AudioObject {
	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), \(try isActive ? "active" : "inactive"), \(try direction ? "output" : "input"), starting channel = \(try startingChannel), virtual format = \(try virtualFormat.streamDescription), physical format = \(try physicalFormat.streamDescription)>"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioStream {
	/// Returns `true` if the stream is active
	/// - remark: This corresponds to the property `kAudioStreamPropertyIsActive`
	public var isActive: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioStreamPropertyIsActive), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if `self` is an output stream
	/// - remark: This corresponds to the property `kAudioStreamPropertyDirection`
	public var direction: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioStreamPropertyDirection), type: UInt32.self) == 0
		}
	}

	/// Returns the terminal type
	/// - remark: This corresponds to the property `kAudioStreamPropertyTerminalType`
	public var terminalType: TerminalType {
		get throws {
			TerminalType(try getProperty(PropertyAddress(kAudioStreamPropertyTerminalType), type: UInt32.self))
		}
	}

	/// Returns the starting channel
	/// - remark: This corresponds to the property `kAudioStreamPropertyStartingChannel`
	public var startingChannel: PropertyElement {
		get throws {
			PropertyElement(try getProperty(PropertyAddress(kAudioStreamPropertyStartingChannel), type: UInt32.self))
		}
	}

	/// Returns the latency
	/// - remark: This corresponds to the property `kAudioStreamPropertyLatency`
	public var latency: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioStreamPropertyLatency))
		}
	}

	/// Returns the virtual format
	/// - remark: This corresponds to the property `kAudioStreamPropertyVirtualFormat`
	public var virtualFormat: AudioStreamBasicDescription {
		get throws {
			try getProperty(PropertyAddress(kAudioStreamPropertyVirtualFormat))
		}
	}
	/// Sets the virtual format
	/// - remark: This corresponds to the property `kAudioStreamPropertyVirtualFormat`
	public func setVirtualFormat(_ value: AudioStreamBasicDescription) throws {
		return try setProperty(PropertyAddress(kAudioStreamPropertyVirtualFormat), to: value)
	}

	/// Returns the available virtual formats
	/// - remark: This corresponds to the property `kAudioStreamPropertyAvailableVirtualFormats`
	public var availableVirtualFormats: [(AudioStreamBasicDescription, ClosedRange<Double>)] {
		get throws {
			let value = try getProperty(PropertyAddress(kAudioStreamPropertyAvailableVirtualFormats), elementType: AudioStreamRangedDescription.self)
			return value.map { ($0.mFormat, $0.mSampleRateRange.mMinimum ... $0.mSampleRateRange.mMaximum) }
		}
	}

	/// Returns the physical format
	/// - remark: This corresponds to the property `kAudioStreamPropertyPhysicalFormat`
	public var physicalFormat: AudioStreamBasicDescription {
		get throws {
			try getProperty(PropertyAddress(kAudioStreamPropertyPhysicalFormat))
		}
	}
	/// Sets the physical format
	/// - remark: This corresponds to the property `kAudioStreamPropertyPhysicalFormat`
	public func setPhysicalFormat(_ value: AudioStreamBasicDescription) throws {
		return try setProperty(PropertyAddress(kAudioStreamPropertyPhysicalFormat), to: value)
	}

	/// Returns the available physical formats
	/// - remark: This corresponds to the property `kAudioStreamPropertyAvailablePhysicalFormats`
	public var availablePhysicalFormats: [(AudioStreamBasicDescription, ClosedRange<Double>)] {
		get throws {
			let value = try getProperty(PropertyAddress(kAudioStreamPropertyAvailablePhysicalFormats), elementType: AudioStreamRangedDescription.self)
			return value.map { ($0.mFormat, $0.mSampleRateRange.mMinimum ... $0.mSampleRateRange.mMaximum) }
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
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioStream>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
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
