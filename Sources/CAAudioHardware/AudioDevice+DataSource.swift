//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A data source for an audio device
	public struct DataSource: Equatable, Hashable/*, Sendable*/ {
		/// Returns the owning audio device
		public let device: AudioDevice
		/// Returns the data source scope
		public let scope: PropertyScope
		/// Returns the data source ID
		public let id: UInt32

		/// Returns the data source name
		public func name() throws -> String {
			return try device.nameOfDataSource(id, inScope: scope)
		}

		/// Returns the data source kind
		public func kind() throws -> UInt32 {
			return try device.kindOfDataSource(id, inScope: scope)
		}
	}
}

extension AudioDevice.DataSource: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(name)\" on \(device.debugDescription)>"
		} else {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') on \(device.debugDescription))>"
		}
	}
}
