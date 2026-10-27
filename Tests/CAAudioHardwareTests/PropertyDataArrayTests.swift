//
// SPDX-FileCopyrightText: 2026 Ben Roeder <ben@darkworks.net>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import XCTest
import CoreAudio
@testable import CAAudioHardware

final class PropertyDataArrayTests: XCTestCase {
	func testShortReadReturnsOnlyTheElementsWritten() throws {
		let ids: [AudioObjectID] = try AudioObject.readArray(byteCount: 3 * MemoryLayout<AudioObjectID>.stride) { buffer, size in
			let written: [AudioObjectID] = [41, 42]
			written.withUnsafeBytes { buffer.copyMemory(from: $0.baseAddress!, byteCount: $0.count) }
			return written.count * MemoryLayout<AudioObjectID>.stride
		}
		XCTAssertEqual(ids, [41, 42])
	}

	func testFullReadReturnsEveryElement() throws {
		let ids: [AudioObjectID] = try AudioObject.readArray(byteCount: 2 * MemoryLayout<AudioObjectID>.stride) { buffer, size in
			let written: [AudioObjectID] = [7, 8]
			written.withUnsafeBytes { buffer.copyMemory(from: $0.baseAddress!, byteCount: $0.count) }
			return size
		}
		XCTAssertEqual(ids, [7, 8])
	}

	func testReadIsGivenTheSizeOfTheBuffer() throws {
		var sizeGiven = 0
		let ids: [AudioObjectID] = try AudioObject.readArray(byteCount: 2 * MemoryLayout<AudioObjectID>.stride + 2) { _, size in
			sizeGiven = size
			return 0
		}
		XCTAssertEqual(sizeGiven, 2 * MemoryLayout<AudioObjectID>.stride)
		XCTAssertEqual(ids, [])
	}

	func testEmptyPropertyReadsNothing() throws {
		let ids: [AudioObjectID] = try AudioObject.readArray(byteCount: 0) { _, _ in
			XCTFail("an empty property was read")
			return 0
		}
		XCTAssertEqual(ids, [])
	}
}
