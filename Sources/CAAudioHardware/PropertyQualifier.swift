//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation

/// A HAL audio object property qualifier
public struct PropertyQualifier {
	/// The property qualifier's value
	public let value: UnsafeRawPointer
	/// The property qualifier's size
	public let size: UInt32

	/// Creates a new instance with the specified value and size
	/// - parameter value: A pointer to the qualifier data
	/// - parameter size: The size in bytes of the data pointed to by `value`
	public init(value: UnsafeRawPointer, size: UInt32) {
		self.value = value
		self.size = size
	}

	/// Creates a new instance with the specified value
	///
	/// `size` is initlalized to `MemoryLayout<T>.stride`
	/// - parameter value: A pointer to the qualifier data
	public init<T>(_ value: UnsafePointer<T>) {
		self.value = UnsafeRawPointer(value)
		self.size = UInt32(MemoryLayout<T>.stride)
	}
}

extension PropertyQualifier: CustomStringConvertible {
	public var description: String {
		"<PropertyQualifier: \(value.debugDescription), \(size) bytes>"
	}
}
