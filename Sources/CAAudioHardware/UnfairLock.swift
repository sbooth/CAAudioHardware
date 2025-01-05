//
// Copyright © 2018-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import os.lock

/// An unfair lock protecting mutable state.
/// - note: The interface is modeled on `OSAllocatedUnfairLock`.
struct UnfairLock<State>: @unchecked Sendable {
	/// Storage for the underlying `os_unfair_lock` and protected state.
	@usableFromInline
	let storage: Storage

	/// Initializes a new unfair lock protecting non-sendable state.
	/// - parameter initialState: The initial state.
	init(uncheckedState initialState: State) {
		self.storage = Storage(initialState: initialState)
	}

	/// Acquires the lock, executes a sendable closure, and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure`.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLock<R>(_ closure: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
		try withLockUnchecked(closure)
	}

	/// Acquires the lock, executes a closure, and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure`.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockUnchecked<R>(_ closure: (inout State) throws -> R) rethrows -> R {
		storage.lock()
		defer {
			storage.unlock()
		}
		return try closure(&storage.state)
	}

	/// Attempts to acquire the lock, and if successful executes a sendable closure and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure` or `nil` if the lock could not be acquired.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockIfAvailable<R>(_ closure: @Sendable (inout State) throws -> R) rethrows -> R? where R: Sendable {
		try withLockIfAvailableUnchecked(closure)
	}

	/// Attempts to acquire the lock, and if successful executes a closure and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure` or `nil` if the lock could not be acquired.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockIfAvailableUnchecked<R>(_ closure: (inout State) throws -> R) rethrows -> R? {
		guard storage.lockIfAvailable() else {
			return nil
		}
		defer {
			storage.unlock()
		}
		return try closure(&storage.state)
	}

	/// The ownership status of an unfair lock.
	enum Ownership {
		/// The lock is owned by the calling thread.
		case owner
		/// The lock is not owned by the calling thread.
		case notOwner
	}

	/// Asserts if the lock fails an ownership status check.
	/// - parameter condition: The ownership status to check.
	func precondition(_ condition: Ownership) {
		switch condition {
		case .owner:
			storage.assertOwner()
		case .notOwner:
			storage.assertNotOwner()
		}
	}
}

extension UnfairLock where State == () {
	/// Initializes a new unfair lock.
	init() {
		self.storage = Storage(initialState: ())
	}

	/// Acquires the lock.
	@inlinable @available(*, noasync)
	func lock() {
		storage.lock()
	}

	/// Attempts to acquire the lock.
	/// - returns: `true` if the lock was acquired.
	@inlinable @available(*, noasync)
	func lockIfAvailable() -> Bool {
		storage.lockIfAvailable()
	}

	/// Releases the lock.
	@inlinable @available(*, noasync)
	func unlock() {
		storage.unlock()
	}

	/// Acquires the lock, executes a sendable closure, and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure`.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLock<R>(_ closure: @Sendable () throws -> R) rethrows -> R where R: Sendable {
		try withLockUnchecked(closure)
	}

	/// Acquires the lock, executes a closure, and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure`.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockUnchecked<R>(_ closure: () throws -> R) rethrows -> R {
		storage.lock()
		defer {
			storage.unlock()
		}
		return try closure()
	}

	/// Attempts to acquire the lock, and if successful executes a sendable closure and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure` or `nil` if the lock could not be acquired.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockIfAvailable<R>(_ closure: @Sendable () throws -> R) rethrows -> R? where R: Sendable {
		try withLockIfAvailableUnchecked(closure)
	}

	/// Attempts to acquire the lock, and if successful executes a closure and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure` or `nil` if the lock could not be acquired.
	/// - throws: Any error thrown by `closure`.
	@inlinable
	func withLockIfAvailableUnchecked<R>(_ closure: () throws -> R) rethrows -> R? {
		guard storage.lockIfAvailable() else {
			return nil
		}
		defer {
			storage.unlock()
		}
		return try closure()
	}
}

extension UnfairLock where State: Sendable
{
	/// Initializes a new unfair lock protecting sendable state.
	/// - parameter initialState: The initial state.
	init(initialState: State) {
		self.storage = Storage(initialState: initialState)
	}
}

extension UnfairLock {
	/// Storage for the underlying `os_unfair_lock` and protected state.
	final class Storage {
		/// The underlying `os_unfair_lock_t`.
		private let os_lock: os_unfair_lock_t

		/// The mutable state protected by `os_lock`.
		@usableFromInline
		var state: State

		/// Initializes a new unfair lock protecting mutable state.
		/// - parameter initialState: The starting state.
		init(initialState: State) {
			os_lock = .allocate(capacity: 1)
			os_lock.initialize(to: os_unfair_lock())
			state = initialState
		}

		deinit {
			os_lock.deinitialize(count: 1)
			os_lock.deallocate()
		}

		/// Acquires the lock.
		@inlinable @available(*, noasync)
		func lock() {
			os_unfair_lock_lock(os_lock)
		}

		/// Attempts to acquire the lock.
		/// - returns: `true` if the lock was acquired.
		@inlinable @available(*, noasync)
		func lockIfAvailable() -> Bool {
			os_unfair_lock_trylock(os_lock)
		}

		/// Releases the lock.
		@inlinable @available(*, noasync)
		func unlock() {
			os_unfair_lock_unlock(os_lock)
		}

		/// Asserts that the calling thread is the current owner of the lock.
		@inlinable
		func assertOwner() {
			os_unfair_lock_assert_owner(os_lock)
		}

		/// Asserts that the calling thread is not the current owner of the lock.
		@inlinable
		func assertNotOwner() {
			os_unfair_lock_assert_not_owner(os_lock)
		}
	}
}
