//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio

/// A HAL audio process object
///
/// This class has three scopes (`kAudioObjectPropertyScopeGlobal`, `kAudioObjectPropertyScopeInput`, `kAudioObjectPropertyScopeOutput`) and a single element (`kAudioObjectPropertyElementMain`)
/// - remark: This class correponds to objects with base class `kAudioProcessClassID`
@available(macOS 14.2, *)
public class AudioProcess: AudioObject, @unchecked Sendable {
	/// Returns the available audio processes
	/// - remark: This corresponds to the property`kAudioHardwarePropertyProcessObjectList` on `kAudioObjectSystemObject`
	public static var processes: [AudioProcess] {
		get throws {
			// Revisit if a subclass of `AudioProcess` is added
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyProcessObjectList)).map { AudioProcess($0) }
		}
	}

	/// Returns an initialized `AudioProcess` for `pid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslatePIDToProcessObject` on `kAudioObjectSystemObject`
	/// - parameter pid: The pid of the desired process
	public static func makeProcess(forPID pid: pid_t) throws -> AudioProcess? {
		var qualifier = pid
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslatePIDToProcessObject), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}

		// Revisit if a subclass of `AudioProcess` is added
		return AudioProcess(objectID)
	}

	/// Returns the PID
	/// - remark: This corresponds to the property `kAudioProcessPropertyPID`
	public var pid: pid_t {
		get throws {
			try getProperty(PropertyAddress(kAudioProcessPropertyPID))
		}
	}

	/// Returns the bundle ID
	/// - remark: This corresponds to the property `kAudioProcessPropertyBundleID`
	public var bundleID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioProcessPropertyBundleID), type: CFString.self) as String
		}
	}

	/// Returns the devices
	/// - remark: This corresponds to the property `kAudioProcessPropertyDevices`
	/// - parameter scope: The desired scope
	public func devices(inScope scope: PropertyScope) throws -> [AudioDevice] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioProcessPropertyDevices), scope: scope)).map { try makeAudioDevice($0) }
	}

	/// Returns `true` if the process is running
	/// - remark: This corresponds to the property `kAudioProcessPropertyIsRunning`
	public var isRunning: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioProcessPropertyIsRunning), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the process is running input
	/// - remark: This corresponds to the property `kAudioProcessPropertyIsRunningInput`
	public var isRunningInput: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioProcessPropertyIsRunningInput), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the process is running output
	/// - remark: This corresponds to the property `kAudioProcessPropertyIsRunningOutput`
	public var isRunningOutput: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioProcessPropertyIsRunningOutput), type: UInt32.self) != 0
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString), pid \(try pid), \(try isRunning ? "running" : "not running")>"
		} catch {
			return super.debugDescription
		}
	}
}

@available(macOS 14.2, *)
extension AudioProcess {
	/// Returns `true` if `self` has `selector`
	/// - parameter selector: The selector of the desired property
	public func hasSelector(_ selector: AudioObjectSelector<AudioProcess>) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Returns `true` if `selector` is settable
	/// - parameter selector: The selector of the desired property
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioProcess>) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue)))
	}

	/// Registers `block` to be performed when `selector` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioProcess>, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue)), notifyOnQueue: queue, perform: block)
	}
}

@available(macOS 14.2, *)
extension AudioObjectSelector where T == AudioProcess {
	/// The property selector `kAudioProcessPropertyPID`
	public static let pid = AudioObjectSelector(kAudioProcessPropertyPID)
	/// The property selector `kAudioProcessPropertyBundleID`
	public static let bundleID = AudioObjectSelector(kAudioProcessPropertyBundleID)
	/// The property selector `kAudioProcessPropertyDevices`
	public static let devices = AudioObjectSelector(kAudioProcessPropertyDevices)
	/// The property selector `kAudioProcessPropertyIsRunning`
	public static let isRunning = AudioObjectSelector(kAudioProcessPropertyIsRunning)
	/// The property selector `kAudioProcessPropertyIsRunningInput`
	public static let isRunningInput = AudioObjectSelector(kAudioProcessPropertyIsRunningInput)
	/// The property selector `kAudioProcessPropertyIsRunningOutput`
	public static let isRunningOutput = AudioObjectSelector(kAudioProcessPropertyIsRunningOutput)

	// TODO: kAudioProcessPropertyIsMuted is documented in AudioHardware.h but the definition is missing
}
