//
// SPDX-FileCopyrightText: 2026 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// An active audio object property listener
///
/// The listener remains registered with the HAL until ``remove()`` is called
/// or the registration is deallocated, whichever comes first.
/// Keep a strong reference to the registration for as long as change notifications are needed.
public final class PropertyListenerRegistration: Hashable, @unchecked Sendable {
	/// The observed audio object
	public let objectID: AudioObjectID
	/// The observed property
	public let property: PropertyAddress

	/// The dispatch queue on which `block` is invoked
	private let queue: DispatchQueue?
	/// The listener block registered with the HAL
	private let block: AudioObjectPropertyListenerBlock
	/// `true` if `block` is currently registered with the HAL
	private let isRegistered = UnfairLock(uncheckedState: false)

	/// Registers a property listener that invokes `handler` on `queue`
	///
	/// This initializer corresponds directly to `AudioObjectAddPropertyListenerBlock`.
	/// If `queue` is `nil` the HAL invokes `handler` on an internal thread; `handler` may then run
	/// concurrently with other listeners and must not block.
	/// - parameter objectID: The audio object to observe
	/// - parameter property: The property to observe
	/// - parameter queue: The dispatch queue on which `handler` will be invoked, or `nil` to use a HAL thread
	/// - parameter handler: A closure to invoke when `property` changes
	/// - throws: An error if the property listener could not be registered
	public init(objectID: AudioObjectID, property: PropertyAddress, queue: DispatchQueue?, handler: @escaping AudioObject.PropertyChangeNotificationBlock) throws {
		self.objectID = objectID
		self.property = property
		self.queue = queue
		self.block = { inNumberAddresses, inAddresses in
			// `inAddresses` is only valid for the duration of the callback
			let addresses = UnsafeBufferPointer(start: inAddresses, count: Int(inNumberAddresses))
			handler(addresses.map { PropertyAddress($0) })
		}

		var address = property.rawValue
		let result = AudioObjectAddPropertyListenerBlock(objectID, &address, queue, block)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectAddPropertyListenerBlock (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The listener block for the property \(property.selector) on audio object 0x\(objectID.hexString) could not be added.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}

		isRegistered.withLockUnchecked { $0 = true }
	}

	/// Registers a property listener that invokes `handler` serially on a private dispatch queue
	///
	/// Invocations of `handler` never overlap and are delivered in the order the HAL reports changes.
	/// - parameter objectID: The audio object to observe
	/// - parameter property: The property to observe
	/// - parameter handler: A closure to invoke when `property` changes
	/// - throws: An error if the property listener could not be registered
	public convenience init(objectID: AudioObjectID, property: PropertyAddress, handler: @escaping AudioObject.PropertyChangeNotificationBlock) throws {
		let queue = DispatchQueue(label: "CAAudioHardware.PropertyListener (0x\(objectID.hexString), \(property.selector))")
		try self.init(objectID: objectID, property: property, queue: queue, handler: handler)
	}

	deinit {
		// Errors are logged by `remove()`
		try? remove()
	}

	/// Removes the property listener
	///
	/// Calling this method more than once has no effect.
	/// - important: Do not call this method from within the listener's own change handler.
	/// - throws: An error if the property listener could not be removed
	public func remove() throws {
		let wasRegistered = isRegistered.withLockUnchecked { isRegistered -> Bool in
			defer {
				isRegistered = false
			}
			return isRegistered
		}
		guard wasRegistered else {
			return
		}

		var address = property.rawValue
		let result = AudioObjectRemovePropertyListenerBlock(objectID, &address, queue, block)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectRemovePropertyListenerBlock (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The listener block for the property \(property.selector) on audio object 0x\(objectID.hexString) could not be removed.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}
	}

	/// Stores `self` in `set`, tying the listener's lifetime to the set
	/// - parameter set: The set in which to store `self`
	public func store(in set: inout Set<PropertyListenerRegistration>) {
		set.insert(self)
	}

	// Equatable
	public static func == (lhs: PropertyListenerRegistration, rhs: PropertyListenerRegistration) -> Bool {
		lhs === rhs
	}

	// Hashable
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}
