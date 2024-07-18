//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A clock source for an audio device
	public struct ClockSource: Equatable, Hashable, Sendable {
		/// Returns the owning audio device ID
		public let deviceID: AudioObjectID
		/// Returns the clock source scope
		public let scope: PropertyScope
		/// Returns the clock source ID
		public let id: UInt32

		/// Returns the clock source name
		public var name: String {
			get throws {
				try getPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyClockSourceNameForIDCFString), scope: scope), translatingValue: id, toType: CFString.self) as String
			}
		}

		/// Returns the clock source kind
		public var kind: UInt32 {
			get throws {
				try getPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyClockSourceKindForID), scope: scope), translatingValue: id)
			}
		}
	}
}

extension AudioDevice.ClockSource: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)')>"
		}
	}
}
