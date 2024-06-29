//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A thin wrapper around a HAL audio object property element
public struct PropertyElement: RawRepresentable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
	public let rawValue: AudioObjectPropertyElement

	/// Creates a new instance with the specified value
	/// - parameter value: The value to use for the new instance
	public init(_ value: AudioObjectPropertyElement) {
		self.rawValue = value
	}

	public init(rawValue: AudioObjectPropertyElement) {
		self.rawValue = rawValue
	}

	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}

	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension PropertyElement {
	/// Main element
	public static let main 		= PropertyElement(kAudioObjectPropertyElementMain)
	/// Master element
	@available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "main")
	public static let master 	= PropertyElement(kAudioObjectPropertyElementMaster)
	/// Wildcard element
	public static let wildcard 	= PropertyElement(kAudioObjectPropertyElementWildcard)
}

extension PropertyElement {
	/// Returns `true` if `lhs` and `rhs` are congruent.
	public static func ~== (lhs: PropertyElement, rhs: PropertyElement) -> Bool {
		lhs.rawValue == rhs.rawValue || lhs.rawValue == kAudioObjectPropertyElementWildcard || rhs.rawValue == kAudioObjectPropertyElementWildcard
	}
}

extension PropertyElement: CustomStringConvertible {
	public var description: String {
		switch rawValue {
		case kAudioObjectPropertyElementMain:
			return "main"
		case kAudioObjectPropertyElementWildcard:
			return "wildcard"
		default:
			return "\(rawValue)"
		}
	}
}
