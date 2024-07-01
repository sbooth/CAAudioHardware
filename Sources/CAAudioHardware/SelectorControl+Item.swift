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
		public func name() throws -> String {
			var qualifier = id
			return try getAudioObjectProperty(PropertyAddress(kAudioSelectorControlPropertyItemName), from: controlID, type: CFString.self, qualifier: PropertyQualifier(&qualifier)) as String
		}

		/// Returns the item kind
		public func kind() throws -> UInt32 {
			var qualifier = id
			return try getAudioObjectProperty(PropertyAddress(kAudioSelectorControlPropertyItemKind), from: controlID, qualifier: PropertyQualifier(&qualifier))
		}
	}
}

extension SelectorControl.Item: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): '\(id.fourCC)' \"\(name)\">"
		} else {
			return "<\(type(of: self)): '\(id.fourCC)'>"
		}
	}
}
