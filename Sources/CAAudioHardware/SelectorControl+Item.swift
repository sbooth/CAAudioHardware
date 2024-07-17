//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension SelectorControl {
	/// An item in a selector control
	public struct Item: Equatable, Hashable, Sendable {
		/// The owning selector control ID
		public let controlID: AudioObjectID
		/// The item ID
		public let id: UInt32

		/// Returns the item name
		public var name: String {
			get throws {
				var qualifier = id
				return try getAudioObjectPropertyData(objectID: controlID, property: PropertyAddress(kAudioSelectorControlPropertyItemName), type: CFString.self, qualifier: PropertyQualifier(&qualifier)) as String
			}
		}

		/// Returns the item kind
		public var kind: UInt32 {
			get throws {
				var qualifier = id
				return try getAudioObjectPropertyData(objectID: controlID, property: PropertyAddress(kAudioSelectorControlPropertyItemKind), qualifier: PropertyQualifier(&qualifier))
			}
		}
	}
}

extension SelectorControl.Item: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		do {
			return "<\(type(of: self)): '\(id.fourCC)' \"\(try name)\">"
		} catch {
			return "<\(type(of: self)): '\(id.fourCC)'>"
		}
	}
}
