import XCTest
@testable import CAAudioHardware

final class CAAudioHardwareTests: XCTestCase {
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
