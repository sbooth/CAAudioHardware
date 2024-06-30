//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A high-pass filter setting for an audio device
	public struct HighPassFilterSetting: Equatable, Hashable/*, Sendable*/ {
		/// Returns the owning audio device
		public let device: AudioDevice
		/// Returns the high-pass filter setting scope
		public let scope: PropertyScope
		/// Returns the high-pass filter setting ID
		public let id: UInt32

		/// Returns the high-pass filter setting name
		public func name() throws -> String {
			return try device.nameOfHighPassFilterSetting(id, inScope: scope)
		}
	}
}

extension AudioDevice.HighPassFilterSetting: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(name)\" on \(device.debugDescription)>"
		} else {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') on \(device.debugDescription))>"
		}
	}
}
