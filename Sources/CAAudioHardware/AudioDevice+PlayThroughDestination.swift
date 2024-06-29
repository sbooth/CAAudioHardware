//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A play-through destination for an audio device
	public struct PlayThroughDestination: Equatable, Hashable/*, Sendable*/ {
		/// Returns the owning audio device
		public let device: AudioDevice
		/// Returns the play-through destination ID
		public let id: UInt32

		/// Returns the play-through destination name
		public func name() throws -> String {
			return try device.nameOfPlayThroughDestination(id)
		}
	}
}

extension AudioDevice.PlayThroughDestination: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): '\(id.fourCC)' \"\(name)\" on AudioDevice 0x\(String(device.objectID, radix: 16, uppercase: false))>"
		} else {
			return "<\(type(of: self)): '\(id.fourCC)' on AudioDevice 0x\(String(device.objectID, radix: 16, uppercase: false)))>"
		}
	}
}
