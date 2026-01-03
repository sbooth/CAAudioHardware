//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

extension AudioDevice {
	/// A data source for an audio device
	public struct DataSource: Equatable, Hashable, Sendable {
		/// Returns the owning audio device ID
		public let deviceID: AudioObjectID
		/// Returns the data source scope
		public let scope: PropertyScope
		/// Returns the data source ID
		public let id: UInt32

		/// Returns the data source name
		public var name: String {
			get throws {
				try getPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyDataSourceNameForIDCFString), scope: scope), translatingValue: id, toType: CFString.self) as String
			}
		}

		/// Returns the data source kind
		public var kind: UInt32 {
			get throws {
				try getPropertyData(objectID: deviceID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyDataSourceKindForID), scope: scope), translatingValue: id)
			}
		}
	}
}

extension AudioDevice.DataSource: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)') \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): (\(scope), '\(id.fourCC)')>"
		}
	}
}
