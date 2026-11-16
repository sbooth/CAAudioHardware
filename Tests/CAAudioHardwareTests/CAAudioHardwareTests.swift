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

	func testPropertyListenerRegistration() throws {
		let registration = try AudioSystem.instance.observe(.devices) { _ in }
		XCTAssertEqual(registration.objectID, AudioSystem.instance.objectID)
		try registration.remove()
		// Removing more than once is a no-op
		try registration.remove()

		var registrations = Set<PropertyListenerRegistration>()
		try AudioSystem.instance.observe(.devices) { _ in }.store(in: &registrations)
		try AudioSystem.instance.observe(.devices) { _ in }.store(in: &registrations)
		// Registrations for the same property are independent
		XCTAssertEqual(registrations.count, 2)
		registrations.removeAll()

		// Registration on a caller-specified queue, or a HAL thread
		let queue = DispatchQueue(label: "CAAudioHardwareTests")
		_ = try PropertyListenerRegistration(objectID: AudioSystem.instance.objectID, property: PropertyAddress(kAudioHardwarePropertyDevices), queue: queue) { _ in }
		_ = try PropertyListenerRegistration(objectID: AudioSystem.instance.objectID, property: PropertyAddress(kAudioHardwarePropertyDevices), queue: nil) { _ in }
	}

	func testPropertyValuesYieldsInitialValue() async throws {
		let expected = try AudioDevice.devices
		var iterator = AudioSystem.instance.values(of: .devices, read: { try AudioDevice.devices }).makeAsyncIterator()
		let first = try await iterator.next()
		XCTAssertEqual(first, expected)
	}

	func testPropertyChangesCancellation() async throws {
		let task = Task {
			for try await _ in AudioSystem.instance.changes(of: .devices) {}
		}
		task.cancel()
		_ = await task.result
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
