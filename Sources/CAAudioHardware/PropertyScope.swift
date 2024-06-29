//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A thin wrapper around a HAL audio object property scope
public struct PropertyScope: Equatable, Hashable, Sendable {
	/// The underlying Core Audio `AudioObjectPropertyScope`
	public let rawValue: AudioObjectPropertyScope

	/// Creates a new instance with the specified value
	/// - parameter value: The value to use for the new instance
	public init(_ value: AudioObjectPropertyScope) {
		self.rawValue = value
	}
}

extension PropertyScope: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt32) {
		self.rawValue = value
	}
}

extension PropertyScope: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.rawValue = value.fourCC
	}
}

extension PropertyScope {
	/// Global scope
	public static let global 		= PropertyScope(kAudioObjectPropertyScopeGlobal)
	/// Input scope
	public static let input 		= PropertyScope(kAudioObjectPropertyScopeInput)
	/// Output scope
	public static let output 		= PropertyScope(kAudioObjectPropertyScopeOutput)
	/// Play-through scope
	public static let playThrough 	= PropertyScope(kAudioObjectPropertyScopePlayThrough)
	/// Wildcard scope
	public static let wildcard 		= PropertyScope(kAudioObjectPropertyScopeWildcard)
}

extension PropertyScope {
	/// Returns `true` if `lhs` and `rhs` are congruent.
	public static func ~== (lhs: PropertyScope, rhs: PropertyScope) -> Bool {
		lhs.rawValue == rhs.rawValue || lhs.rawValue == kAudioObjectPropertyScopeWildcard || rhs.rawValue == kAudioObjectPropertyScopeWildcard
	}
}

extension PropertyScope: CustomStringConvertible {
	public var description: String {
		switch rawValue {
		case kAudioObjectPropertyScopeGlobal:
			return "global"
		case kAudioObjectPropertyScopeInput:
			return "input"
		case kAudioObjectPropertyScopeOutput:
			return "output"
		case kAudioObjectPropertyScopePlayThrough:
			return "playthrough"
		case kAudioObjectPropertyScopeWildcard:
			return "wildcard"
		default:
			return "'\(rawValue.fourCC)'"
		}
	}
}
