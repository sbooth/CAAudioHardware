//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio object
public class AudioObject: Equatable, Hashable, @unchecked Sendable, CustomDebugStringConvertible {
	/// The underlying audio object ID
	public final let objectID: AudioObjectID

	/// Initializes an `AudioObject` with `objectID`
	/// - precondition: `objectID` != `kAudioObjectUnknown`
	/// - parameter objectID: The HAL audio object ID
	init(_ objectID: AudioObjectID) {
		precondition(objectID != kAudioObjectUnknown)
		self.objectID = objectID
	}

	// Equatable
	public static func == (lhs: AudioObject, rhs: AudioObject) -> Bool {
		lhs.objectID == rhs.objectID
	}

	// Hashable
	public func hash(into hasher: inout Hasher) {
		hasher.combine(objectID)
	}

	/// Returns `true` if `self` has `property`
	/// - parameter property: The property to query
	public final func hasProperty(_ property: PropertyAddress) -> Bool {
		var address = property.rawValue
		return AudioObjectHasProperty(objectID, &address)
	}

	/// Returns `true` if `property` is settable
	/// - parameter property: The property to query
	/// - throws: An error if `self` does not have `property`
	public final func isPropertySettable(_ property: PropertyAddress) throws -> Bool {
		var address = property.rawValue

		var settable: DarwinBoolean = false
		let result = AudioObjectIsPropertySettable(objectID, &address, &settable)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectIsPropertySettable (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Mutability information for the property \(property.selector) in scope \(property.scope) on audio object 0x\(objectID.hexString) could not be retrieved.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}

		return settable.boolValue
	}

	/// A block called with one or more changed audio object properties
	/// - parameter changes: An array of changed property addresses
	public typealias PropertyChangeNotificationBlock = @Sendable (_ changes: [PropertyAddress]) -> Void

	/// A main actor-isolated block called with one or more changed audio object properties
	/// - parameter changes: An array of changed property addresses
	public typealias MainActorPropertyChangeNotificationBlock = @MainActor @Sendable (_ changes: [PropertyAddress]) -> Void

	/// Registers `block` to be performed when `property` changes
	///
	/// `block` is invoked serially on a private dispatch queue. To choose the queue on which `block`
	/// is invoked, use ``observe(_:queue:perform:)``.
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter property: The property to observe
	/// - parameter block: A closure to invoke when `property` changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public final func observe(_ property: PropertyAddress, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try PropertyObservation(objectID: objectID, property: property, perform: block)
	}

	/// Registers `block` to be performed on `queue` when `property` changes
	///
	/// To have the HAL invoke `block` on one of its internal threads, create a
	/// ``PropertyObservation`` with a `nil` queue.
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter property: The property to observe
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when `property` changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public final func observe(_ property: PropertyAddress, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try PropertyObservation(objectID: objectID, property: property, queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `property` changes
	///
	/// `block` is invoked synchronously on the main queue when the HAL delivers the change notification.
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter property: The property to observe
	/// - parameter block: A main actor-isolated closure to invoke when `property` changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public final func observeOnMainActor(_ property: PropertyAddress, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try PropertyObservation(objectID: objectID, property: property, queue: .main) { changes in
			MainActor.assumeIsolated {
				block(changes)
			}
		}
	}

	/// Returns an asynchronous sequence of change notifications for `property`
	///
	/// Each element is the array of changed property addresses delivered by the HAL.
	/// The property listener is removed when iteration ends or the consuming task is cancelled.
	/// - note: If the property listener cannot be registered the sequence throws the error on first iteration
	/// - parameter property: The property to observe
	/// - returns: An asynchronous sequence of change notifications
	public final func changes(of property: PropertyAddress) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		let (stream, continuation) = AsyncThrowingStream.makeStream(of: [PropertyAddress].self)
		do {
			let observation = try observe(property) { changes in
				continuation.yield(changes)
			}
			continuation.onTermination = { _ in
				try? observation.invalidate()
			}
		} catch {
			continuation.finish(throwing: error)
		}
		return stream
	}

	/// Returns an asynchronous sequence of values for `property`
	///
	/// The sequence yields the current value first and a new value each time `property` changes.
	/// If the consumer falls behind, intermediate values are dropped and only the most recent is delivered.
	/// The property listener is removed when iteration ends or the consuming task is cancelled.
	/// - note: The sequence throws if the property listener cannot be registered or `read` throws
	/// - parameter property: The property to observe
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public final func values<Value: Sendable>(of property: PropertyAddress, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		let (stream, continuation) = AsyncThrowingStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
		let yieldCurrentValue: @Sendable () -> Void = {
			do {
				continuation.yield(try read())
			} catch {
				continuation.finish(throwing: error)
			}
		}
		do {
			// All reads happen on one serial queue so values are yielded in order
			let queue = DispatchQueue(label: "CAAudioHardware.AudioObject.values (0x\(objectID.hexString), \(property.selector))")
			let observation = try PropertyObservation(objectID: objectID, property: property, queue: queue) { _ in
				yieldCurrentValue()
			}
			continuation.onTermination = { _ in
				try? observation.invalidate()
			}
			// Read the initial value after registering so no change is missed
			queue.async(execute: yieldCurrentValue)
		} catch {
			continuation.finish(throwing: error)
		}
		return stream
	}

	// MARK: - Scalar Properties

	/// Returns the numeric value of `property`
	/// - note: The underlying audio object property must be backed by an equivalent native C type of `T`
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying numeric type
	/// - parameter qualifier: An optional property qualifier
	/// - parameter initialValue: An optional initial value for `outData` when calling `AudioObjectGetPropertyData`
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T: Numeric>(_ property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil, initialValue: T = 0) throws -> T {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, type: type, qualifier: qualifier, initialValue: initialValue)
	}

	/// Returns the Core Foundation object value of `property`
	/// - note: The underlying audio object property must be backed by a Core Foundation object and return a `CFType` with a +1 retain count
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying `CFType`
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T: CFTypeRef>(_ property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> T {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, type: type, qualifier: qualifier)
	}

	/// Returns the `AudioValueRange` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioValueRange`
	/// - parameter property: The address of the desired property
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty(_ property: PropertyAddress, qualifier: PropertyQualifier? = nil) throws -> AudioValueRange {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, qualifier: qualifier)
	}

	/// Returns the `AudioStreamBasicDescription` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioStreamBasicDescription`
	/// - parameter property: The address of the desired property
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty(_ property: PropertyAddress, qualifier: PropertyQualifier? = nil) throws -> AudioStreamBasicDescription {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, qualifier: qualifier)
	}

	/// Sets the value of `property` to `value`
	/// - note: The underlying audio object property must be backed by `T`
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property`, `property` is not settable, or the property value could not be set
	public func setProperty<T>(_ property: PropertyAddress, to value: T, qualifier: PropertyQualifier? = nil) throws {
		try AudioObject.setPropertyData(objectID: objectID, property: property, value: value, qualifier: qualifier)
	}

	// MARK: - Array Properties

	/// Returns the array value of `property`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying array element type
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T>(_ property: PropertyAddress, elementType type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> [T] {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, elementType: type, qualifier: qualifier)
	}

	/// Sets the value of `property` to `value`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property`, `property` is not settable, or the property value could not be set
	public func setProperty<T>(_ property: PropertyAddress, to value: [T], qualifier: PropertyQualifier? = nil) throws {
		try AudioObject.setPropertyData(objectID: objectID, property: property, to: value, qualifier: qualifier)
	}

	// MARK: - Translated Properties

	/// Returns `value` translated to a numeric type using `property`
	/// - note: The underlying audio object property must be backed by `AudioValueTranslation`
	/// - note: The `AudioValueTranslation` input type must be `In`
	/// - note: The `AudioValueTranslation` output type must be `Out`
	/// - parameter property: The address of the desired property
	/// - parameter value: The input value to translate
	/// - parameter type: The output type of the translation
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<In, Out: Numeric>(_ property: PropertyAddress, translatingValue value: In, toType type: Out.Type = Out.self, qualifier: PropertyQualifier? = nil) throws -> Out {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, translatingValue: value, toType: type, qualifier: qualifier)
	}

	/// Returns `value` translated to a Core Foundation type using `property`
	/// - note: The underlying audio object property must be backed by `AudioValueTranslation`
	/// - note: The `AudioValueTranslation` input type must be `In`
	/// - note: The `AudioValueTranslation` output type must be a `CFType` with a +1 retain count
	/// - parameter property: The address of the desired property
	/// - parameter value: The input value to translate
	/// - parameter type: The output type of the translation
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<In, Out: CFTypeRef>(_ property: PropertyAddress, translatingValue value: In, toType type: Out.Type = Out.self, qualifier: PropertyQualifier? = nil) throws -> Out {
		return try AudioObject.getPropertyData(objectID: objectID, property: property, translatingValue: value, toType: type, qualifier: qualifier)
	}

	// MARK: - Base Audio Object Properties

	/// Returns the bundle ID of the plug-in that instantiated the object
	/// - remark: This corresponds to the property `kAudioObjectPropertyCreator`
	public var creator: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyCreator), type: CFString.self) as String
		}
	}

	// kAudioObjectPropertyListenerAdded and kAudioObjectPropertyListenerRemoved omitted

	/// Returns the base class of the underlying HAL audio object
	/// - remark: This corresponds to the property `kAudioObjectPropertyBaseClass`
	public var baseClass: AudioClassID {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyBaseClass))
		}
	}

	/// Returns the class of the underlying HAL audio object
	/// - remark: This corresponds to the property `kAudioObjectPropertyClass`
	public var `class`: AudioClassID {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyClass))
		}
	}

	/// Returns the audio object's owning object  or `nil` if this is the system audio object
	/// - remark: This corresponds to the property `kAudioObjectPropertyOwner`
	public var owner: AudioObject? {
		get throws {
			let objectID: AudioObjectID = try getProperty(PropertyAddress(kAudioObjectPropertyOwner))
			guard objectID != kAudioObjectUnknown else {
				return nil
			}
			return try AudioObject.make(objectID)
		}
	}

	/// Returns the audio object's name
	/// - remark: This corresponds to the property `kAudioObjectPropertyName`
	public var name: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyName), type: CFString.self) as String
		}
	}

	/// Returns the audio object's model name
	/// - remark: This corresponds to the property `kAudioObjectPropertyModelName`
	public var modelName: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyModelName), type: CFString.self) as String
		}
	}

	/// Returns the audio object's manufacturer
	/// - remark: This corresponds to the property `kAudioObjectPropertyManufacturer`
	public var manufacturer: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyManufacturer), type: CFString.self) as String
		}
	}

	/// Returns the name of `element`
	/// - remark: This corresponds to the property `kAudioObjectPropertyElementName`
	/// - parameter element: The desired element
	/// - parameter scope: The desired scope
	public func nameOfElement(_ element: PropertyElement, inScope scope: PropertyScope = .global) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioObjectPropertyElementName), scope: scope, element: element), type: CFString.self) as String
	}

	/// Returns the category name of `element` in `scope`
	/// - remark: This corresponds to the property `kAudioObjectPropertyElementCategoryName`
	/// - parameter element: The desired element
	/// - parameter scope: The desired scope
	public func categoryNameOfElement(_ element: PropertyElement, inScope scope: PropertyScope = .global) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioObjectPropertyElementCategoryName), scope: scope, element: element), type: CFString.self) as String
	}

	/// Returns the number name of `element`
	/// - remark: This corresponds to the property `kAudioObjectPropertyElementNumberName`
	public func numberNameOfElement(_ element: PropertyElement, inScope scope: PropertyScope = .global) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioObjectPropertyElementNumberName), scope: scope, element: element), type: CFString.self) as String
	}

	/// Returns the audio objects owned by `self`
	/// - remark: This corresponds to the property `kAudioObjectPropertyOwnedObjects`
	public var ownedObjects: [AudioObject] {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyOwnedObjects)).map { try AudioObject.make($0) }
		}
	}
	/// Returns the audio objects owned by `self`
	/// - remark: This corresponds to the property `kAudioObjectPropertyOwnedObjects`
	/// - parameter type: An array of `AudioClassID`s to which the returned objects will be restricted
	public func ownedObjectsOfType(_ type: [AudioClassID]) throws -> [AudioObject] {
		var qualifierData = type
		let qualifierDataSize = MemoryLayout<AudioClassID>.stride * type.count
		let qualifier = PropertyQualifier(value: &qualifierData, size: UInt32(qualifierDataSize))
		return try getProperty(PropertyAddress(kAudioObjectPropertyOwnedObjects), qualifier: qualifier).map { try AudioObject.make($0) }
	}

	/// Returns `true` if the audio object's hardware is drawing attention to itself
	/// - remark: This corresponds to the property `kAudioObjectPropertyIdentify`
	public var identify: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyIdentify), type: UInt32.self) != 0
		}
	}
	/// Sets whether the audio object's hardware should draw attention to itself
	/// - remark: This corresponds to the property `kAudioObjectPropertyIdentify`
	/// - parameter value: Whether the audio hardware should draw attention to itself
	public func setIdentify(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioObjectPropertyIdentify), to: UInt32(value ? 1 : 0))
	}

	/// Returns the audio object's serial number
	/// - remark: This corresponds to the property `kAudioObjectPropertySerialNumber`
	public var serialNumber: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertySerialNumber), type: CFString.self) as String
		}
	}

	/// Returns the audio object's firmware version
	/// - remark: This corresponds to the property `kAudioObjectPropertyFirmwareVersion`
	public var firmwareVersion: String {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyFirmwareVersion), type: CFString.self) as String
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		return "<\(type(of: self)): 0x\(objectID.hexString)>"
	}
}

// MARK: - Helpers

extension AudioObject {
	/// Returns the value of `kAudioObjectPropertyClass` for `objectID`
	static func getClass(_ objectID: AudioObjectID) throws -> AudioClassID {
		return try AudioObject.getPropertyData(objectID: objectID, property: PropertyAddress(kAudioObjectPropertyClass))
	}

	/// Returns the value of `kAudioObjectPropertyBaseClass` for `objectID`
	static func getBaseClass(_ objectID: AudioObjectID) throws -> AudioClassID {
		return try AudioObject.getPropertyData(objectID: objectID, property: PropertyAddress(kAudioObjectPropertyBaseClass))
	}
}

/// The log for `AudioObject` and subclasses
let audioObjectLog = OSLog(subsystem: "org.sbooth.CAAudioHardware", category: "AudioObject")

// MARK: - AudioObject Creation

// Class clusters in the Objective-C sense can't be implemented in Swift
// since Swift initializers don't return a value.
//
// Ideally `AudioObject.init(_ objectID: AudioObjectID)` would initialize and return
// the appropriate subclass, but since that isn't possible,
// `AudioObject.init(_ objectID: AudioObjectID)` has internal access and
// the factory method `AudioObject.make(_ objectID: AudioObjectID)` is public.

extension AudioObject {
	/// Creates and returns an initialized `AudioObject`
	///
	/// Whenever possible this will return a specialized subclass exposing additional functionality.
	/// The subclass is chosen using the object's class (`kAudioObjectPropertyClass`). If the class is
	/// not one this library recognizes, the object's base class (`kAudioObjectPropertyBaseClass`) is used
	/// instead, when the object provides one.
	/// - parameter objectID: The audio object ID
	/// - throws: An error if the class of `objectID` could not be determined
	public static func make(_ objectID: AudioObjectID) throws -> AudioObject {
		if objectID == kAudioObjectSystemObject {
			return AudioSystem.instance
		}

		let objectClass = try AudioObject.getClass(objectID)
		if let object = makeAudioObject(objectID, ofClass: objectClass) {
			return object
		}

		// Not every object provides a base class (audio plug-ins, for example), so failing to read it is not an error
		if let baseClass = try? AudioObject.getBaseClass(objectID), let object = makeAudioObject(objectID, ofClass: baseClass) {
			os_log(.debug, log: audioObjectLog, "Unknown audio object class '%{public}@' for audio object 0x%{public}@; using base class '%{public}@'", objectClass.fourCC, objectID.hexString, baseClass.fourCC)
			return object
		}

		os_log(.debug, log: audioObjectLog, "Unknown audio object class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return AudioObject(objectID)
	}
}

// MARK: -

/// A thin wrapper around a HAL audio object property selector for a specific `AudioObject` subclass
public struct AudioObjectSelector<T: AudioObject>: Equatable, Hashable, Sendable {
	/// The underlying `AudioObjectPropertySelector` value
	let rawValue: AudioObjectPropertySelector

	/// Creates a new instance with the specified value
	/// - parameter value: The value to use for the new instance
	init(_ value: AudioObjectPropertySelector) {
		self.rawValue = value
	}
}

extension AudioObject {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed serially on a private dispatch queue when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Registers `block` to be performed on `queue` when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: The dispatch queue on which `block` will be invoked
	/// - parameter block: A closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observe(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, queue: DispatchQueue, perform block: @escaping PropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observe(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), queue: queue, perform: block)
	}

	/// Registers `block` to be performed on the main actor when `selector` in `scope` on `element` changes
	/// - important: The listener remains active only while the returned observation is alive.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter block: A main actor-isolated closure to invoke when the property changes
	/// - returns: The property observation
	/// - throws: An error if the property listener could not be registered
	public func observeOnMainActor(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, perform block: @escaping MainActorPropertyChangeNotificationBlock) throws -> PropertyObservation {
		try observeOnMainActor(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), perform: block)
	}

	/// Returns an asynchronous sequence of change notifications for `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - returns: An asynchronous sequence of change notifications
	public func changes(of selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> AsyncThrowingStream<[PropertyAddress], any Error> {
		changes(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns an asynchronous sequence of values for `selector` in `scope` on `element`
	///
	/// The sequence yields the current value first and a new value each time the property changes.
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter read: A closure returning the property's current value
	/// - returns: An asynchronous sequence of property values
	public func values<Value: Sendable>(of selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, read: @escaping @Sendable () throws -> Value) -> AsyncThrowingStream<Value, any Error> {
		values(of: PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), read: read)
	}
}

extension AudioObjectSelector where T == AudioObject {
	/// The wildcard property selector `kAudioObjectPropertySelectorWildcard`
	public static let wildcard = AudioObjectSelector(kAudioObjectPropertySelectorWildcard)

	/// The property selector `kAudioObjectPropertyCreator`
	public static let creator = AudioObjectSelector(kAudioObjectPropertyCreator)
	// kAudioObjectPropertyListenerAdded and kAudioObjectPropertyListenerRemoved omitted

	/// The property selector `kAudioObjectPropertyBaseClass`
	public static let baseClass = AudioObjectSelector(kAudioObjectPropertyBaseClass)
	/// The property selector `kAudioObjectPropertyClass`
	public static let `class` = AudioObjectSelector(kAudioObjectPropertyClass)
	/// The property selector `kAudioObjectPropertyOwner`
	public static let owner = AudioObjectSelector(kAudioObjectPropertyOwner)
	/// The property selector `kAudioObjectPropertyName`
	public static let name = AudioObjectSelector(kAudioObjectPropertyName)
	/// The property selector `kAudioObjectPropertyModelName`
	public static let modelName = AudioObjectSelector(kAudioObjectPropertyModelName)
	/// The property selector `kAudioObjectPropertyManufacturer`
	public static let manufacturer = AudioObjectSelector(kAudioObjectPropertyManufacturer)
	/// The property selector `kAudioObjectPropertyElementName`
	public static let elementName = AudioObjectSelector(kAudioObjectPropertyElementName)
	/// The property selector `kAudioObjectPropertyElementCategoryName`
	public static let elementCategoryName = AudioObjectSelector(kAudioObjectPropertyElementCategoryName)
	/// The property selector `kAudioObjectPropertyElementNumberName`
	public static let elementNumberName = AudioObjectSelector(kAudioObjectPropertyElementNumberName)
	/// The property selector `kAudioObjectPropertyOwnedObjects`
	public static let ownedObjects = AudioObjectSelector(kAudioObjectPropertyOwnedObjects)
	/// The property selector `kAudioObjectPropertyIdentify`
	public static let identify = AudioObjectSelector(kAudioObjectPropertyIdentify)
	/// The property selector `kAudioObjectPropertySerialNumber`
	public static let serialNumber = AudioObjectSelector(kAudioObjectPropertySerialNumber)
	/// The property selector `kAudioObjectPropertyFirmwareVersion`
	public static let firmwareVersion = AudioObjectSelector(kAudioObjectPropertyFirmwareVersion)
}

extension AudioObjectSelector: CustomStringConvertible {
	public var description: String {
		return "\(type(of: T.self)): '\(rawValue.fourCC)'"
	}
}

// MARK: -

/// Creates and returns an initialized `AudioObject` subclass for `classID`, or `nil` if `classID` is not recognized
/// - parameter objectID: The audio object ID
/// - parameter classID: The class or base class of `objectID`
func makeAudioObject(_ objectID: AudioObjectID, ofClass classID: AudioClassID) -> AudioObject? {
	precondition(objectID != kAudioObjectSystemObject)

	switch classID {
	case kAudioObjectClassID: 					return AudioObject(objectID)

	case kAudioBoxClassID: 						return AudioBox(objectID)
	case kAudioClockDeviceClassID: 				return AudioClockDevice(objectID)
	case kAudioStreamClassID: 					return AudioStream(objectID)

	case kAudioPlugInClassID: 					return AudioPlugIn(objectID)
	case kAudioTransportManagerClassID: 		return AudioTransportManager(objectID)

	case kAudioDeviceClassID: 					return AudioDevice(objectID)
	case kAudioAggregateDeviceClassID: 			return AudioAggregateDevice(objectID)
	case kAudioEndPointDeviceClassID: 			return AudioEndpointDevice(objectID)
	case kAudioEndPointClassID: 				return AudioEndpoint(objectID)
	case kAudioSubDeviceClassID: 				return AudioSubdevice(objectID)

	case kAudioControlClassID: 					return AudioControl(objectID)
	case kAudioSliderControlClassID: 			return SliderControl(objectID)
	case kAudioStereoPanControlClassID: 		return StereoPanControl(objectID)

	case kAudioBooleanControlClassID: 			return BooleanControl(objectID)
	case kAudioMuteControlClassID: 				return MuteControl(objectID)
	case kAudioSoloControlClassID: 				return SoloControl(objectID)
	case kAudioJackControlClassID: 				return JackControl(objectID)
	case kAudioLFEMuteControlClassID: 			return LFEMuteControl(objectID)
	case kAudioPhantomPowerControlClassID: 		return PhantomPowerControl(objectID)
	case kAudioPhaseInvertControlClassID: 		return PhaseInvertControl(objectID)
	case kAudioClipLightControlClassID: 		return ClipLightControl(objectID)
	case kAudioTalkbackControlClassID: 			return TalkbackControl(objectID)
	case kAudioListenbackControlClassID: 		return ListenbackControl(objectID)

	case kAudioLevelControlClassID: 			return LevelControl(objectID)
	case kAudioVolumeControlClassID: 			return VolumeControl(objectID)
	case kAudioLFEVolumeControlClassID: 		return LFEVolumeControl(objectID)

	case kAudioSelectorControlClassID: 			return SelectorControl(objectID)
	case kAudioDataSourceControlClassID: 		return DataSourceControl(objectID)
	case kAudioDataDestinationControlClassID: 	return DataDestinationControl(objectID)
	case kAudioClockSourceControlClassID: 		return ClockSourceControl(objectID)
	case kAudioLineLevelControlClassID: 		return LineLevelControl(objectID)
	case kAudioHighPassFilterControlClassID: 	return HighPassFilterControl(objectID)

	default: 									break
	}

	if #available(macOS 14.2, *) {
		switch classID {
		case kAudioProcessClassID: 				return AudioProcess(objectID)
		case kAudioTapClassID: 					return AudioTap(objectID)
		case kAudioSubTapClassID: 				return AudioSubtap(objectID)
		default: 								break
		}
	}

	return nil
}

/// Creates and returns an initialized `T` or subclass
///
/// If `objectID` is not an instance of `T` or a subclass, as when its class is not recognized,
/// the object returned by `fallback` is used.
/// - parameter objectID: The audio object ID
/// - parameter fallback: A closure returning an instance of `T` for `objectID`
/// - throws: An error if `objectID` is `kAudioObjectSystemObject` or its class could not be determined
func makeAudioObject<T: AudioObject>(_ objectID: AudioObjectID, fallback: (AudioObjectID) -> T) throws -> T {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid object id for %{public}@", String(describing: T.self))
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let object = try AudioObject.make(objectID)
	if let object = object as? T {
		return object
	}

	os_log(.debug, log: audioObjectLog, "Audio object 0x%{public}@ (%{public}@) is not %{public}@", objectID.hexString, String(describing: type(of: object)), String(describing: T.self))
	return fallback(objectID)
}
