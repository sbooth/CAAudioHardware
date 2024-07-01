//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A play-through destination for an audio device
	public struct PlayThroughDestination: Equatable, Hashable, Sendable {
		/// Returns the owning audio device ID
		public let deviceID: AudioObjectID
		/// Returns the play-through destination ID
		public let id: UInt32

		/// Returns the play-through destination name
		public var name: String {
			get throws {
				return try getAudioObjectProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruDestinationNameForIDCFString), scope: .playThrough), from: deviceID, translatingValue: id, toType: CFString.self) as String
			}
		}
	}
}

extension AudioDevice.PlayThroughDestination: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): '\(id.fourCC)' \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): '\(id.fourCC)'>"
		}
	}
}
