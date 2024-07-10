//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio object
public class AudioObject: Equatable, Hashable, CustomDebugStringConvertible {
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

	/// An audio object property listener block and associated dispatch queue.
	typealias PropertyListener = (block: AudioObjectPropertyListenerBlock, queue: DispatchQueue?)

	/// Registered audio object property listeners
	private let propertyListeners = UnfairLock(uncheckedState: [PropertyAddress: PropertyListener]())

	/// Removes all property listeners
	/// - note: Errors are logged but otherwise ignored
	func removeAllPropertyListeners() {
		propertyListeners.withLockUnchecked {
			for (property, listener) in $0 {
				var address = property.rawValue
				let result = AudioObjectRemovePropertyListenerBlock(objectID, &address, listener.queue, listener.block)
				if result != kAudioHardwareNoError {
					os_log(.error, log: audioObjectLog, "AudioObjectRemovePropertyListenerBlock (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
				}
			}
			$0.removeAll()
		}
	}

	deinit {
		removeAllPropertyListeners()
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
	public typealias PropertyChangeNotificationBlock = (_ changes: [PropertyAddress]) -> Void

	/// Registers `block` to be performed when `property` changes
	/// - parameter property: The property to observe
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when `property` changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public final func whenPropertyChanges(_ property: PropertyAddress, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		var address = property.rawValue

		// Remove the existing listener, if any, for the property
		let listener = propertyListeners.withLockUnchecked {
			$0.removeValue(forKey: property)
		}

		if let listener {
			let result = AudioObjectRemovePropertyListenerBlock(objectID, &address, listener.queue, listener.block)
			guard result == kAudioHardwareNoError else {
				os_log(.error, log: audioObjectLog, "AudioObjectRemovePropertyListenerBlock (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
				let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The listener block for the property \(property.selector) on audio object 0x\(objectID.hexString) could not be removed.", comment: "")]
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
			}
		}

		if let block {
			let listenerBlock: AudioObjectPropertyListenerBlock = { inNumberAddresses, inAddresses in
				let count = Int(inNumberAddresses)
				let addresses = UnsafeBufferPointer(start: inAddresses, count: count)
				let array = [PropertyAddress](unsafeUninitializedCapacity: count) { (buffer, initializedCount) in
					for i in 0 ..< count {
						buffer[i] = PropertyAddress(addresses[i])
					}
					initializedCount = count
				}
				block(array)
			}

			let listener: PropertyListener = (block: listenerBlock, queue: queue)

			let result = AudioObjectAddPropertyListenerBlock(objectID, &address, listener.queue, listener.block)
			guard result == kAudioHardwareNoError else {
				os_log(.error, log: audioObjectLog, "AudioObjectAddPropertyListenerBlock (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
				let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The listener block for the property \(property.selector) on audio object 0x\(objectID.hexString) could not be added.", comment: "")]
				throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
			}

			propertyListeners.withLockUnchecked {
				$0[property] = listener
			}
		}
	}

	// A textual representation of this instance, suitable for debugging.
	public var debugDescription: String {
		return "<\(type(of: self)): 0x\(objectID.hexString)>"
	}
}

// MARK: - Scalar Properties

extension AudioObject {
	/// Returns the numeric value of `property`
	/// - note: The underlying audio object property must be backed by an equivalent native C type of `T`
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying numeric type
	/// - parameter qualifier: An optional property qualifier
	/// - parameter initialValue: An optional initial value for `outData` when calling `AudioObjectGetPropertyData`
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T: Numeric>(_ property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil, initialValue: T = 0) throws -> T {
		return try getAudioObjectProperty(property, from: objectID, type: type, qualifier: qualifier, initialValue: initialValue)
	}

	/// Returns the Core Foundation object value of `property`
	/// - note: The underlying audio object property must be backed by a Core Foundation object and return a `CFType` with a +1 retain count
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying `CFType`
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T: CFTypeRef>(_ property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> T {
		return try getAudioObjectProperty(property, from: objectID, type: type, qualifier: qualifier)
	}

	/// Returns the `AudioValueRange` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioValueRange`
	/// - parameter property: The address of the desired property
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty(_ property: PropertyAddress) throws -> AudioValueRange {
		var value = AudioValueRange()
		try readAudioObjectProperty(property, from: objectID, into: &value)
		return value
	}

	/// Returns the `AudioStreamBasicDescription` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioStreamBasicDescription`
	/// - parameter property: The address of the desired property
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty(_ property: PropertyAddress) throws -> AudioStreamBasicDescription {
		var value = AudioStreamBasicDescription()
		try readAudioObjectProperty(property, from: objectID, into: &value)
		return value
	}

	/// Sets the value of `property` to `value`
	/// - note: The underlying audio object property must be backed by `T`
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - throws: An error if `self` does not have `property`, `property` is not settable, or the property value could not be set
	public func setProperty<T>(_ property: PropertyAddress, to value: T) throws {
		var data = value
		try writeAudioObjectProperty(property, on: objectID, from: &data)
	}
}

// MARK: - Array Properties

extension AudioObject {
	/// Returns the array value of `property`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying array element type
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if `self` does not have `property` or the property value could not be retrieved
	public func getProperty<T>(_ property: PropertyAddress, elementType type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> [T] {
		return try getAudioObjectProperty(property, from: objectID, elementType: type, qualifier: qualifier)
	}

	/// Sets the value of `property` to `value`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - throws: An error if `self` does not have `property`, `property` is not settable, or the property value could not be set
	public func setProperty<T>(_ property: PropertyAddress, to value: [T]) throws {
		var data = value
		let dataSize = MemoryLayout<T>.stride * value.count
		try writeAudioObjectProperty(property, on: objectID, from: &data, size: dataSize)
	}
}

// MARK: - Translated Properties

extension AudioObject {
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
		return try getAudioObjectProperty(property, from: objectID, translatingValue: value, toType: type, qualifier: qualifier)
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
		return try getAudioObjectProperty(property, from: objectID, translatingValue: value, toType: type, qualifier: qualifier)
	}
}

// MARK: - Base Audio Object Properties

extension AudioObject {
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

	/// Returns the audio object's owning object
	/// - remark: This corresponds to the property `kAudioObjectPropertyOwner`
	/// - note: The system audio object does not have an owner
	public var owner: AudioObject {
		get throws {
			try AudioObject.make(getProperty(PropertyAddress(kAudioObjectPropertyOwner)))
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
}

// MARK: - Helpers

/// Returns the value of `kAudioObjectPropertyClass` for `objectID`
func AudioObjectClass(_ objectID: AudioObjectID) throws -> AudioClassID {
	var value: AudioClassID = 0
	try readAudioObjectProperty(PropertyAddress(kAudioObjectPropertyClass), from: objectID, into: &value)
	return value
}

/// Returns the value of `kAudioObjectPropertyBaseClass` for `objectID`
func AudioObjectBaseClass(_ objectID: AudioObjectID) throws -> AudioClassID {
	var value: AudioClassID = 0
	try readAudioObjectProperty(PropertyAddress(kAudioObjectPropertyBaseClass), from: objectID, into: &value)
	return value
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
	/// Whenever possible this will return a specialized subclass exposing additional functionality
	/// - parameter objectID: The audio object ID
	public static func make(_ objectID: AudioObjectID) throws -> AudioObject {
		guard objectID != kAudioObjectUnknown else {
			os_log(.error, log: audioObjectLog, "kAudioObjectUnknown is not a valid AudioObjectID")
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError), userInfo: nil)
		}

		if objectID == kAudioObjectSystemObject {
			return AudioSystemObject.instance
		}

		let baseClass = try AudioObjectBaseClass(objectID)

		switch baseClass {
		case kAudioObjectClassID: 			return try makeAudioObject(objectID);

		case kAudioBoxClassID: 				return AudioBox(objectID) 				// Revisit if a subclass of `AudioBox` is added
		case kAudioClockDeviceClassID: 		return AudioClockDevice(objectID) 		// Revisit if a subclass of `AudioClockDevice` is added

		case kAudioControlClassID: 			return try makeAudioControl(objectID, baseClass: baseClass)
		case kAudioBooleanControlClassID: 	return try makeAudioControl(objectID, baseClass: baseClass)
		case kAudioLevelControlClassID: 	return try makeAudioControl(objectID, baseClass: baseClass)
		case kAudioSelectorControlClassID: 	return try makeAudioControl(objectID, baseClass: baseClass)

		case kAudioDeviceClassID: 			return try makeAudioDevice(objectID)
		case kAudioPlugInClassID: 			return try makeAudioPlugIn(objectID)
		case kAudioStreamClassID: 			return AudioStream(objectID) 			// Revisit if a subclass of `AudioStream` is added

		default: 							break
		}

		if #available(macOS 14.2, *) {
			switch baseClass {
			case kAudioProcessClassID:		return AudioProcess(objectID)			// Revisit if a subclass of `AudioProcess` is added
			case kAudioTapClassID: 			return AudioTap(objectID)				// Revisit if a subclass of `AudioTap` is added
			case kAudioSubTapClassID: 		return AudioSubtap(objectID)			// Revisit if a subclass of `AudioSubtap` is added
			default: 						break
			}
		}

		os_log(.debug, log: audioObjectLog, "Unknown audio object base class '%{public}@' for audio object 0x%{public}@", baseClass.fourCC, objectID.hexString)
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

	/// Registers `block` to be performed when `selector` in `scope` on `element` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioObject>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, on queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), on: queue, perform: block)
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

/// Creates and returns an initialized `AudioObject` or subclass.
func makeAudioObject(_ objectID: AudioObjectID) throws -> AudioObject {
	precondition(objectID != kAudioObjectUnknown)
	precondition(objectID != kAudioObjectSystemObject)

	let objectClass = try AudioObjectClass(objectID)

	switch objectClass {
	case kAudioObjectClassID: 		return AudioObject(objectID)
	case kAudioBoxClassID: 			return AudioBox(objectID)
	case kAudioClockDeviceClassID: 	return AudioClockDevice(objectID)
	case kAudioControlClassID: 		return AudioControl(objectID)
	case kAudioDeviceClassID: 		return AudioDevice(objectID)
	case kAudioPlugInClassID: 		return AudioPlugIn(objectID)
	case kAudioStreamClassID: 		return AudioStream(objectID)
	default: 						break
	}

	if #available(macOS 14.2, *) {
		switch objectClass {
		case kAudioProcessClassID: 	return AudioProcess(objectID)
		case kAudioTapClassID: 		return AudioTap(objectID)
		case kAudioSubTapClassID: 	return AudioSubtap(objectID)
		default: 					break
		}
	}

	os_log(.debug, log: audioObjectLog, "Unknown audio object class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
	return AudioObject(objectID)
}
