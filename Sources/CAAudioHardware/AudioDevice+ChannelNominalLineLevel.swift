//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A channel nominal line level for an audio device
	public struct ChannelNominalLineLevel: Equatable, Hashable/*, Sendable*/ {
		/// Returns the owning audio device
		public let device: AudioDevice
		/// Returns the channel nominal line level scope
		public let scope: PropertyScope
		/// Returns the channel nominal line level ID
		public let id: UInt32

		/// Returns the channel nominal line level name
		public func name() throws -> String {
			return try device.nameOfChannelNominalLineLevel(id, inScope: scope)
		}
	}
}

extension AudioDevice.ChannelNominalLineLevel: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(name)\" on \(device.debugDescription)>"
		} else {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') on \(device.debugDescription))>"
		}
	}
}
