//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A thin wrapper around a HAL audio object property address
public struct PropertyAddress: Equatable, Hashable, Sendable {
	/// The underlying Core Audio `AudioObjectPropertyAddress`
	public let rawValue: AudioObjectPropertyAddress

	/// Creates a new instance with the specified value
	/// - parameter value: The value to use for the new instance
	public init(_ value: AudioObjectPropertyAddress) {
		self.rawValue = value
	}

	// Equatable
	public static func == (lhs: PropertyAddress, rhs: PropertyAddress) -> Bool {
		lhs.rawValue.mSelector == rhs.rawValue.mSelector && lhs.rawValue.mScope == rhs.rawValue.mScope && lhs.rawValue.mElement == rhs.rawValue.mElement
	}

	// Hashable
	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue.mSelector)
		hasher.combine(rawValue.mScope)
		hasher.combine(rawValue.mElement)
	}
}

extension PropertyAddress {
	/// Initializes a new `PropertyAddress` with the specified raw selector, scope, and element values
	/// - parameter selector: The desired raw selector value
	/// - parameter scope: The desired raw scope value
	/// - parameter element: The desired raw element value
	public init(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) {
		self.rawValue = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
	}

	/// Initializes a new `PropertyAddress` with the specified selector, scope, and element
	/// - parameter selector: The desired selector
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public init(_ selector: PropertySelector, scope: PropertyScope = .global, element: PropertyElement = .main) {
		self.rawValue = AudioObjectPropertyAddress(mSelector: selector.rawValue, mScope: scope.rawValue, mElement: element.rawValue)
	}
}

extension PropertyAddress {
	/// The property's selector
	public var selector: PropertySelector {
		PropertySelector(rawValue.mSelector)
	}

	/// The property's scope
	public var scope: PropertyScope {
		PropertyScope(rawValue.mScope)
	}

	/// The property's element
	public var element: PropertyElement {
		PropertyElement(rawValue.mElement)
	}
}

extension PropertyAddress {
	/// Returns `true` if `lhs` and `rhs` are congruent.
	public static func ~== (lhs: PropertyAddress, rhs: PropertyAddress) -> Bool {
//		lhs.selector ~== rhs.selector && lhs.scope ~== rhs.scope && lhs.element ~== rhs.element
		let l = lhs.rawValue
		let r = rhs.rawValue
		return (l.mSelector == r.mSelector || l.mSelector == kAudioObjectPropertySelectorWildcard || r.mSelector == kAudioObjectPropertySelectorWildcard)
		&& (l.mScope == r.mScope || l.mScope == kAudioObjectPropertyScopeWildcard || r.mScope == kAudioObjectPropertyScopeWildcard)
		&& (l.mElement == r.mElement || l.mElement == kAudioObjectPropertyElementWildcard || r.mElement == kAudioObjectPropertyElementWildcard)
	}
}

extension PropertyAddress: CustomStringConvertible {
	public var description: String {
		"(\(selector.description), \(scope.description), \(element.description))"
	}
}
