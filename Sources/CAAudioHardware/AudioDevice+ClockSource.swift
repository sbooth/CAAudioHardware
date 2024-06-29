//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A clock source for an audio device
	public struct ClockSource: Equatable, Hashable/*, Sendable*/ {
		/// Returns the owning audio device
		public let device: AudioDevice
		/// Returns the clock source scope
		public let scope: PropertyScope
		/// Returns the clock source ID
		public let id: UInt32

		/// Returns the clock source name
		public func name() throws -> String {
			return try device.nameOfClockSource(id, inScope: scope)
		}

		/// Returns the clock source kind
		public func kind() throws -> UInt32 {
			return try device.kindOfClockSource(id, inScope: scope)
		}
	}
}

extension AudioDevice.ClockSource: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(name)\" on \(device.debugDescription)>"
		} else {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') on \(device.debugDescription))>"
		}
	}
}
