//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

// MARK: - Low-Level Property Support

/// Returns the size in bytes of `property` from `objectID`
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to query
/// - parameter qualifier: An optional property qualifier
/// - throws: An exception if the object does not have the requested property or the property value could not be retrieved
public func audioObjectPropertySize(_ property: PropertyAddress, from objectID: AudioObjectID, qualifier: PropertyQualifier? = nil) throws -> Int {
	var propertyAddress = property.rawValue
	var dataSize: UInt32 = 0
	let result = AudioObjectGetPropertyDataSize(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, &dataSize)
	guard result == kAudioHardwareNoError else {
		os_log(.error, log: audioObjectLog, "AudioObjectGetPropertyDataSize (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
		let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Size information for the property \(property.selector) in scope \(property.scope) on audio object 0x\(String(objectID, radix: 16, uppercase: false)) could not be retrieved.", comment: "")]
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
	}
	return Int(dataSize)
}

/// Reads `size` bytes of `property` from `objectID` into `ptr`
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to query
/// - parameter ptr: A pointer to receive the property's value
/// - parameter size: The number of bytes to read
/// - parameter qualifier: An optional property qualifier
/// - throws: An exception if the object does not have the requested property or the property value could not be retrieved
public func readAudioObjectProperty<T>(_ property: PropertyAddress, from objectID: AudioObjectID, into ptr: UnsafeMutablePointer<T>, size: Int = MemoryLayout<T>.stride, qualifier: PropertyQualifier? = nil) throws {
	var propertyAddress = property.rawValue
	var dataSize = UInt32(size)
	let result = AudioObjectGetPropertyData(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, &dataSize, ptr)
	guard result == kAudioHardwareNoError else {
		os_log(.error, log: audioObjectLog, "AudioObjectGetPropertyData (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
		let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The property \(property.selector) in scope \(property.scope) on audio object 0x\(String(objectID, radix: 16, uppercase: false)) could not be retrieved.", comment: "")]
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
	}
}

/// Writes `size` bytes from `ptr` to `property` on `objectID`
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to change
/// - parameter ptr: A pointer to the desired property value
/// - parameter size: The number of bytes to write
/// - parameter qualifier: An optional property qualifier
/// - throws: An exception if the object does not have the requested property, the property is not settable, or the property value could not be set
public func writeAudioObjectProperty<T>(_ property: PropertyAddress, on objectID: AudioObjectID, from ptr: UnsafePointer<T>, size: Int = MemoryLayout<T>.stride, qualifier: PropertyQualifier? = nil) throws {
	var propertyAddress = property.rawValue
	let dataSize = UInt32(size)
	let result = AudioObjectSetPropertyData(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, dataSize, ptr)
	guard result == kAudioHardwareNoError else {
		os_log(.error, log: audioObjectLog, "AudioObjectSetPropertyData (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
		let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The property \(property.selector) in scope \(property.scope) on audio object 0x\(String(objectID, radix: 16, uppercase: false)) could not be set.", comment: "")]
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
	}
}

// MARK: - Typed Scalar Property Retrieval

/// Returns the numeric value of `property`
/// - note: The underlying audio object property must be backed by an equivalent native C type of `T`
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to query
/// - parameter type: The underlying numeric type
/// - parameter qualifier: An optional property qualifier
/// - parameter initialValue: An optional initial value for `outData` when calling `AudioObjectGetPropertyData`
/// - throws: An error if `objectID` does not have `property` or the property value could not be retrieved
public func getAudioObjectProperty<T: Numeric>(_ property: PropertyAddress, from objectID: AudioObjectID, type: T.Type = T.self, qualifier: PropertyQualifier? = nil, initialValue: T = 0) throws -> T {
	var value = initialValue
	try readAudioObjectProperty(property, from: objectID, into: &value, qualifier: qualifier)
	return value
}

/// Returns the Core Foundation object value of `property`
/// - note: The underlying audio object property must be backed by a Core Foundation object and return a `CFType` with a +1 retain count
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to query
/// - parameter type: The underlying `CFType`
/// - parameter qualifier: An optional property qualifier
/// - throws: An error if `objectID` does not have `property` or the property value could not be retrieved
public func getAudioObjectProperty<T: CFTypeRef>(_ property: PropertyAddress, from objectID: AudioObjectID, type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> T {
	var value: Unmanaged<T>?
	try readAudioObjectProperty(property, from: objectID, into: &value, qualifier: qualifier)
	return value!.takeRetainedValue()
}

// MARK: - Typed Array Property Retrieval

/// Returns the array value of `property`
/// - note: The underlying audio object property must be backed by a C array of `T`
/// - parameter property: The address of the desired property
/// - parameter objectID: The audio object to query
/// - parameter type: The underlying array element type
/// - parameter qualifier: An optional property qualifier
/// - throws: An error if `objectID` does not have `property` or the property value could not be retrieved
public func getAudioObjectProperty<T>(_ property: PropertyAddress, from objectID: AudioObjectID, elementType type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> [T] {
	let dataSize = try audioObjectPropertySize(property, from: objectID, qualifier: qualifier)
	let count = dataSize / MemoryLayout<T>.stride
	let array = try [T](unsafeUninitializedCapacity: count) { (buffer, initializedCount) in
		try readAudioObjectProperty(property, from: objectID, into: buffer.baseAddress!, size: dataSize, qualifier: qualifier)
		initializedCount = count
	}
	return array
}
