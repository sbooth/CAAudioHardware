//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A high-pass filter setting for an audio device
	public struct HighPassFilterSetting: Equatable, Hashable, Sendable {
		/// Returns the owning audio device ID
		public let deviceID: AudioObjectID
		/// Returns the high-pass filter setting scope
		public let scope: PropertyScope
		/// Returns the high-pass filter setting ID
		public let id: UInt32

		/// Returns the high-pass filter setting name
		public var name: String {
			get throws {
				try getAudioObjectPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyHighPassFilterSettingNameForIDCFString), scope: scope), translatingValue: id, toType: CFString.self) as String
			}
		}
	}
}

extension AudioDevice.HighPassFilterSetting: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)')>"
		}
	}
}
