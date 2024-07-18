//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A channel nominal line level for an audio device
	public struct ChannelNominalLineLevel: Equatable, Hashable, Sendable {
		/// Returns the owning audio device ID
		public let deviceID: AudioObjectID
		/// Returns the channel nominal line level scope
		public let scope: PropertyScope
		/// Returns the channel nominal line level ID
		public let id: UInt32

		/// Returns the channel nominal line level name
		public var name: String {
			get throws {
				try getPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyChannelNominalLineLevelNameForIDCFString), scope: scope), translatingValue: id, toType: CFString.self) as String
			}
		}
	}
}

extension AudioDevice.ChannelNominalLineLevel: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)')>"
		}
	}
}
