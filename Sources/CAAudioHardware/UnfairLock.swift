//
// Copyright © 2018-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import os.lock

/// A Swift-safe `os_unfair_lock` wrapper.
final class UnfairLock: @unchecked Sendable {
	/// The underlying `os_unfair_lock_t`
	private let os_lock: os_unfair_lock_t

	/// Initializes a new unfair lock.
	init() {
		os_lock = .allocate(capacity: 1)
		os_lock.initialize(to: os_unfair_lock())
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

	/// The ownership status of an unfair lock
	enum Ownership {
		/// The lock is owned by the caller
		case owner
		/// The lock is not owned by the caller
		case notOwner
	}

	/// Asserts if the lock fails an ownership status check.
	/// - parameter condition: The ownership status to check
	func precondition(_ condition: Ownership) {
		switch condition {
		case .owner:
			os_unfair_lock_assert_owner(os_lock)
		case .notOwner:
			os_unfair_lock_assert_not_owner(os_lock)
		}
	}

	/// Acquires the lock, executes a closure, and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure`.
	/// - throws: Any error thrown by `closure`
	@inlinable
	func withLock<T>(_ closure: @Sendable () throws -> T) rethrows -> T where T: Sendable {
		lock()
		defer { unlock() }
		return try closure()
	}

	/// Attempts to acquire the lock, and if successful executes a closure and releases the lock when the closure completes.
	/// - parameter closure: A closure to run.
	/// - returns: The value returned by `closure` or `nil` if the lock could not be acquired.
	/// - throws: Any error thrown by `closure`
	@inlinable
	func withLockIfAvailable<T>(_ closure: @Sendable () throws -> T) rethrows -> T? where T: Sendable {
		guard lockIfAvailable() else {
			return nil
		}
		defer { unlock() }
		return try closure()
	}
}
