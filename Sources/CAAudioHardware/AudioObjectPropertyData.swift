//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

extension AudioObject {

	// MARK: - Property Data Size

	/// Returns the data size in bytes for `property` on `objectID`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter qualifier: An optional property qualifier
	/// - returns: The data size for `property` in bytes
	/// - throws: An error if the object does not have the requested property or the property data size could not be retrieved
	public static func propertyDataSize(objectID: AudioObjectID, property: PropertyAddress, qualifier: PropertyQualifier? = nil) throws -> Int {
		var propertyAddress = property.rawValue
		var dataSize: UInt32 = 0
		let result = AudioObjectGetPropertyDataSize(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, &dataSize)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectGetPropertyDataSize (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Size information for the property \(property.selector) in scope \(property.scope) on audio object 0x\(objectID.hexString) could not be retrieved.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}
		return Int(dataSize)
	}

	// MARK: - Raw Property Data

	/// Reads `size` bytes of data for `property` on `objectID` into `buffer`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter buffer: A pointer to receive the property's data
	/// - parameter size: The number of bytes to read
	/// - parameter qualifier: An optional property qualifier
	/// - returns: The number of bytes written to `buffer`
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func readRawPropertyData(objectID: AudioObjectID, property: PropertyAddress, to buffer: UnsafeMutableRawPointer, size: Int, qualifier: PropertyQualifier? = nil) throws -> Int {
		var propertyAddress = property.rawValue
		var dataSize = UInt32(size)
		let result = AudioObjectGetPropertyData(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, &dataSize, buffer)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectGetPropertyData (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The property \(property.selector) in scope \(property.scope) on audio object 0x\(objectID.hexString) could not be retrieved.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}
		return Int(dataSize)
	}

	/// Writes `size` bytes of data from `buffer` to `property` on `objectID`
	/// - parameter objectID: The audio object to change
	/// - parameter property: The address of the desired property
	/// - parameter ptr: A pointer to the desired property data
	/// - parameter size: The number of bytes to write
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func writeRawPropertyData(objectID: AudioObjectID, property: PropertyAddress, from buffer: UnsafeRawPointer, size: Int, qualifier: PropertyQualifier? = nil) throws {
		var propertyAddress = property.rawValue
		let dataSize = UInt32(size)
		let result = AudioObjectSetPropertyData(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, dataSize, buffer)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectSetPropertyData (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The property \(property.selector) in scope \(property.scope) on audio object 0x\(objectID.hexString) could not be set.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}
	}

	// MARK: - Typed Pointer Property Data

	/// Reads `size` bytes of data for `property` on `objectID` into `ptr`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter ptr: A pointer to receive the property's data
	/// - parameter size: The number of bytes to read
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func readPropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, into ptr: UnsafeMutablePointer<T>, size: Int = MemoryLayout<T>.stride, qualifier: PropertyQualifier? = nil) throws {
		_ = try readRawPropertyData(objectID: objectID, property: property, to: UnsafeMutableRawPointer(ptr), size: size, qualifier: qualifier)
	}

	/// Writes `size` bytes of data from `ptr` to `property` on `objectID`
	/// - parameter objectID: The audio object to change
	/// - parameter property: The address of the desired property
	/// - parameter ptr: A pointer to the desired property data
	/// - parameter size: The number of bytes to write
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func writePropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, from ptr: UnsafePointer<T>, size: Int = MemoryLayout<T>.stride, qualifier: PropertyQualifier? = nil) throws {
		try writeRawPropertyData(objectID: objectID, property: property, from: UnsafeRawPointer(ptr), size: size, qualifier: qualifier)
	}

	// MARK: - Typed Scalar Property Data

	/// Returns the numeric value of `property`
	/// - note: The underlying audio object property must be backed by an equivalent native C type of `T`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying numeric type
	/// - parameter qualifier: An optional property qualifier
	/// - parameter initialValue: An optional initial value for `outData` when calling `AudioObjectGetPropertyData`
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData<T: Numeric>(objectID: AudioObjectID, property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil, initialValue: T = 0) throws -> T {
		var value = initialValue
		try readPropertyData(objectID: objectID, property: property, into: &value, qualifier: qualifier)
		return value
	}

	/// Returns the Core Foundation object value of `property`
	/// - note: The underlying audio object property must be backed by a Core Foundation object and return a `CFType` with a +1 retain count
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying `CFType`
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData<T: CFTypeRef>(objectID: AudioObjectID, property: PropertyAddress, type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> T {
		var value: Unmanaged<T>?
		try readPropertyData(objectID: objectID, property: property, into: &value, qualifier: qualifier)
		return value!.takeRetainedValue()
	}

	/// Writes the value of `property` on `objectID`
	/// - parameter objectID: The audio object to change
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func writePropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, from value: T, qualifier: PropertyQualifier? = nil) throws {
		try withUnsafePointer(to: value) {
			try writePropertyData(objectID: objectID, property: property, from: $0)
		}
	}

	// MARK: - Typed Array Property Data

	/// Returns the array value of `property`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter type: The underlying array element type
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, elementType type: T.Type = T.self, qualifier: PropertyQualifier? = nil) throws -> [T] {
		let dataSize = try AudioObject.propertyDataSize(objectID: objectID, property: property, qualifier: qualifier)
		let count = dataSize / MemoryLayout<T>.stride
		let array = try [T](unsafeUninitializedCapacity: count) { (buffer, initializedCount) in
			try readPropertyData(objectID: objectID, property: property, into: buffer.baseAddress!, size: dataSize, qualifier: qualifier)
			initializedCount = count
		}
		return array
	}

	// MARK: - Translated Property Data

	/// Returns `value` translated to a numeric type using `property`
	/// - note: The underlying audio object property must be backed by `AudioValueTranslation`
	/// - note: The `AudioValueTranslation` input type must be `In`
	/// - note: The `AudioValueTranslation` output type must be `Out`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter value: The input value to translate
	/// - parameter type: The output type of the translation
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData<In, Out: Numeric>(objectID: AudioObjectID, property: PropertyAddress, translatingValue value: In, toType type: Out.Type = Out.self, qualifier: PropertyQualifier? = nil) throws -> Out {
		var inputData = value
		var outputData: Out = 0
		try withUnsafeMutablePointer(to: &inputData) { inputPointer in
			try withUnsafeMutablePointer(to: &outputData) { outputPointer in
				var translation = AudioValueTranslation(mInputData: inputPointer, mInputDataSize: UInt32(MemoryLayout<In>.stride), mOutputData: outputPointer, mOutputDataSize: UInt32(MemoryLayout<Out>.stride))
				try readPropertyData(objectID: objectID, property: property, into: &translation, qualifier: qualifier)
			}
		}
		return outputData
	}

	/// Returns `value` translated to a Core Foundation type using `property`
	/// - note: The underlying audio object property must be backed by `AudioValueTranslation`
	/// - note: The `AudioValueTranslation` input type must be `In`
	/// - note: The `AudioValueTranslation` output type must be a `CFType` with a +1 retain count
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter value: The input value to translate
	/// - parameter type: The output type of the translation
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData<In, Out: CFTypeRef>(objectID: AudioObjectID, property: PropertyAddress, translatingValue value: In, toType type: Out.Type = Out.self, qualifier: PropertyQualifier? = nil) throws -> Out {
		var inputData = value
		var outputData: Unmanaged<Out>?
		try withUnsafeMutablePointer(to: &inputData) { inputPointer in
			try withUnsafeMutablePointer(to: &outputData) { outputPointer in
				var translation = AudioValueTranslation(mInputData: inputPointer, mInputDataSize: UInt32(MemoryLayout<In>.stride), mOutputData: outputPointer, mOutputDataSize: UInt32(MemoryLayout<Out>.stride))
				try readPropertyData(objectID: objectID, property: property, into: &translation, qualifier: qualifier)
			}
		}
		return outputData!.takeRetainedValue()
	}
}
