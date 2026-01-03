//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A thin wrapper around a HAL audio object property selector
public struct PropertySelector: Equatable, Hashable, Sendable {
	/// The underlying Core Audio `AudioObjectPropertySelector`
	public let rawValue: AudioObjectPropertySelector

	/// Creates a new instance with the specified value
	/// - parameter value: The value to use for the new instance
	public init(_ value: AudioObjectPropertySelector) {
		self.rawValue = value
	}
}

extension PropertySelector: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension PropertySelector: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension PropertySelector {
	/// Wildcard selector
	public static let wildcard = PropertySelector(kAudioObjectPropertySelectorWildcard)
}

infix operator ~==: ComparisonPrecedence
extension PropertySelector {
	/// Returns `true` if `lhs` and `rhs` are congruent.
	public static func ~== (lhs: PropertySelector, rhs: PropertySelector) -> Bool {
		lhs.rawValue == rhs.rawValue || lhs.rawValue == kAudioObjectPropertySelectorWildcard || rhs.rawValue == kAudioObjectPropertySelectorWildcard
	}
}

extension PropertySelector: CustomStringConvertible {
	public var description: String {
		switch rawValue {
		case kAudioObjectPropertySelectorWildcard:
			return "wildcard"
		default:
			return "'\(rawValue.fourCC)'"
		}
	}
}
