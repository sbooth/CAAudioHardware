//
// Copyright (c) 2020 - 2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio

/// A thin wrapper around a variable-length `AudioBufferList` structure
public class AudioBufferListWrapper {
	/// The underlying memory
	let ptr: UnsafePointer<UInt8>

	/// Creates a new `AudioBufferListWrapper` instance
	/// - note: The returned object assumes ownership of `mem`
	init(_ mem: UnsafePointer<UInt8>) {
		ptr = mem
	}

	deinit {
		ptr.deallocate()
	}

	/// Returns the buffer list's `mNumberBuffers`
	public var numberBuffers: UInt32 {
		return ptr.withMemoryRebound(to: AudioBufferList.self, capacity: 1) { $0.pointee.mNumberBuffers }
	}

	/// Returns the buffer list's `mBuffers`
	public var buffers: UnsafeBufferPointer<AudioBuffer> {
		let count = Int(numberBuffers)
		let offset = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)!
		let bufPtr = UnsafeRawPointer(ptr.advanced(by: offset)).assumingMemoryBound(to: AudioBuffer.self)
		return UnsafeBufferPointer<AudioBuffer>(start: bufPtr, count: count)
	}

	/// Performs `block` with a pointer to the underlying `AudioBufferList` structure
	public func withUnsafePointer<T>(_ block: (UnsafePointer<AudioBufferList>) throws -> T) rethrows -> T {
		return try ptr.withMemoryRebound(to: AudioBufferList.self, capacity: 1) { return try block($0) }
	}
}

extension AudioBufferListWrapper: CustomDebugStringConvertible {
	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		return "<\(type(of: self)): mNumberBuffers = \(numberBuffers), mBuffers = [\(buffers.map({ "<\(type(of: $0)): mNumberChannels = \($0.mNumberChannels), mDataByteSize = \($0.mDataByteSize), mData = \($0.mData?.debugDescription ?? "nil")>" }).joined(separator: ", "))]>"
	}
}
