//
// SPDX-FileCopyrightText: 2023 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import XCTest
import CoreAudio
@testable import CAAudioHardware

final class CAAudioHardwareTests: XCTestCase {
	func testObject() {
		XCTAssertThrowsError(try AudioObject.make(kAudioObjectUnknown))
	}

	func testDevices() throws {
		let devices = try AudioDevice.devices
		for device in devices {
			let ownedObjects = try device.ownedObjects
			for ownedObject in ownedObjects {
				let owner = try ownedObject.owner
				XCTAssertEqual(owner, device)
			}

			_ = try device.controlList

			_ = try device.streams(inScope: .output)
			_ = try device.streams(inScope: .input)
		}
	}

	@available(macOS 14.2, *)
	func testAudioProcess() throws {
		let processes = try AudioProcess.processes
		for process in processes {
			_ = try process.pid
		}
	}

	@available(macOS 14.2, *)
	func testTaps() throws {
		let taps = try AudioTap.taps
		for tap in taps {
			_ = try tap.format
		}
	}

	func testUnfairLockCopying() {
		let lock = UnfairLock()
		let copy = lock
		XCTAssertIdentical(lock.storage, copy.storage)
	}

	func testUnfairLockOwnership() {
		let lock = UnfairLock()
		lock.precondition(.notOwner)
		lock.lock()
		lock.precondition(.owner)
		lock.unlock()
		lock.precondition(.notOwner)
	}
}
