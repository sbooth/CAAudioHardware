//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

extension SelectorControl {
	/// An item in a selector control
	public struct Item {
		/// The owning selector control
		public let control: SelectorControl
		/// The item ID
		public let id: UInt32

		/// Returns the item name
		public func name() throws -> String {
			return try control.nameOfItem(id)
		}

		/// Returns the item kind
		public func kind() throws -> UInt32 {
			return try control.kindOfItem(id)
		}
	}
}

extension SelectorControl.Item: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		if let name = try? name() {
			return "<\(type(of: self)): '\(id.fourCC)' \"\(name)\" on \(control.debugDescription)>"
		} else {
			return "<\(type(of: self)): '\(id.fourCC)' on \(control.debugDescription)>"
		}
	}
}
