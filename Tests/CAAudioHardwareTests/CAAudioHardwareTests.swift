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
		XCTAssertThrowsError(try AudioObject.make(kAudioObjectUnknown)) { error in
			XCTAssertEqual((error as NSError).code, Int(kAudioHardwareBadObjectError))
		}
		// The typed factories reject it the same way
		XCTAssertThrowsError(try makeAudioDevice(kAudioObjectUnknown)) { error in
			XCTAssertEqual((error as NSError).code, Int(kAudioHardwareBadObjectError))
		}
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

	func testObserveWithQueue() throws {
		let queue = DispatchQueue(label: "CAAudioHardwareTests.observe")
		let key = DispatchSpecificKey<Bool>()
		queue.setSpecific(key: key, value: true)

		let called = XCTestExpectation(description: "Handler called")
		called.assertForOverFulfill = false
		let observation = try AudioSystem.instance.observe(.processIsAudible, queue: queue) { _ in
			XCTAssertEqual(DispatchQueue.getSpecific(key: key), true, "Handler was not invoked on the requested queue")
			called.fulfill()
		}

		// kAudioHardwarePropertyProcessIsAudible is local to this process and settable
		let original = try AudioSystem.instance.processIsAudible
		defer {
			try? AudioSystem.instance.setProcessIsAudible(original)
		}
		try AudioSystem.instance.setProcessIsAudible(!original)

		guard XCTWaiter().wait(for: [called], timeout: 2) == .completed else {
			throw XCTSkip("Changing kAudioHardwarePropertyProcessIsAudible did not deliver a notification")
		}
		try observation.invalidate()
	}

	func testPropertyObservation() throws {
		let observation = try AudioSystem.instance.observe(.devices) { _ in }
		XCTAssertEqual(observation.objectID, AudioSystem.instance.objectID)
		try observation.invalidate()
		// Invalidating more than once is a no-op
		try observation.invalidate()

		var observations = Set<PropertyObservation>()
		try AudioSystem.instance.observe(.devices) { _ in }.store(in: &observations)
		try AudioSystem.instance.observe(.devices) { _ in }.store(in: &observations)
		// Observations of the same property are independent
		XCTAssertEqual(observations.count, 2)
		observations.removeAll()

		// Observation on a caller-specified queue, or a HAL thread
		let queue = DispatchQueue(label: "CAAudioHardwareTests")
		_ = try PropertyObservation(objectID: AudioSystem.instance.objectID, property: PropertyAddress(kAudioHardwarePropertyDevices), queue: queue) { _ in }
		_ = try PropertyObservation(objectID: AudioSystem.instance.objectID, property: PropertyAddress(kAudioHardwarePropertyDevices), queue: nil) { _ in }
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
