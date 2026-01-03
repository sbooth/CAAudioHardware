//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
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
	public static func readRawPropertyData(objectID: AudioObjectID, property: PropertyAddress, into buffer: UnsafeMutableRawPointer, size: Int, qualifier: PropertyQualifier? = nil) throws -> Int {
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
	/// - parameter data: A pointer to the desired property data
	/// - parameter size: The number of bytes to write
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func writeRawPropertyData(objectID: AudioObjectID, property: PropertyAddress, data: UnsafeRawPointer, size: Int, qualifier: PropertyQualifier? = nil) throws {
		var propertyAddress = property.rawValue
		let dataSize = UInt32(size)
		let result = AudioObjectSetPropertyData(objectID, &propertyAddress, qualifier?.size ?? 0, qualifier?.value, dataSize, data)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioObjectSetPropertyData (0x%x, %{public}@) failed: '%{public}@'", objectID, property.description, UInt32(result).fourCC)
			let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The property \(property.selector) in scope \(property.scope) on audio object 0x\(objectID.hexString) could not be set.", comment: "")]
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: userInfo)
		}
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
		try withUnsafeMutablePointer(to: &value) {
			_ = try readRawPropertyData(objectID: objectID, property: property, into: $0, size: MemoryLayout<T>.stride, qualifier: qualifier)
		}
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
		_ = try readRawPropertyData(objectID: objectID, property: property, into: &value, size: MemoryLayout<T>.stride, qualifier: qualifier)
		return value!.takeRetainedValue()
	}

	/// Returns the `AudioValueRange` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioValueRange`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData(objectID: AudioObjectID, property: PropertyAddress, qualifier: PropertyQualifier? = nil) throws -> AudioValueRange {
		var value = AudioValueRange()
		_ = try readRawPropertyData(objectID: objectID, property: property, into: &value, size: MemoryLayout<AudioValueRange>.stride, qualifier: qualifier)
		return value
	}

	/// Returns the `AudioStreamBasicDescription` value of `property`
	/// - note: The underlying audio object property must be backed by `AudioStreamBasicDescription`
	/// - parameter objectID: The audio object to query
	/// - parameter property: The address of the desired property
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property or the property data could not be retrieved
	public static func getPropertyData(objectID: AudioObjectID, property: PropertyAddress, qualifier: PropertyQualifier? = nil) throws -> AudioStreamBasicDescription {
		var value = AudioStreamBasicDescription()
		_ = try readRawPropertyData(objectID: objectID, property: property, into: &value, size: MemoryLayout<AudioStreamBasicDescription>.stride, qualifier: qualifier)
		return value
	}

	/// Sets the value of `property` on `objectID` to `value`
	/// - parameter objectID: The audio object to change
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func setPropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, value: T, qualifier: PropertyQualifier? = nil) throws {
		try withUnsafePointer(to: value) {
			try writeRawPropertyData(objectID: objectID, property: property, data: $0, size: MemoryLayout<T>.stride, qualifier: qualifier)
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
			_ = try readRawPropertyData(objectID: objectID, property: property, into: buffer.baseAddress!, size: dataSize, qualifier: qualifier)
			initializedCount = count
		}
		return array
	}

	/// Sets the array value of `property` on `objectID` to `value`
	/// - note: The underlying audio object property must be backed by a C array of `T`
	/// - parameter objectID: The audio object to change
	/// - parameter property: The address of the desired property
	/// - parameter value: The desired value
	/// - parameter qualifier: An optional property qualifier
	/// - throws: An error if the object does not have the requested property, the property is not settable, or the property data could not be set
	public static func setPropertyData<T>(objectID: AudioObjectID, property: PropertyAddress, to value: [T], qualifier: PropertyQualifier? = nil) throws {
#if false
		// Compiler warning: "Forming 'UnsafeRawPointer' to a variable of type '[T]'; this is likely incorrect because 'T' may contain an object reference."
		try writeRawPropertyData(objectID: objectID, property: property, data: value, size: MemoryLayout<T>.stride * value.count)
#else
		try value.withUnsafeBytes {
			try writeRawPropertyData(objectID: objectID, property: property, data: $0.baseAddress!, size: MemoryLayout<T>.stride * value.count)
		}
#endif
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
				_ = try readRawPropertyData(objectID: objectID, property: property, into: &translation, size: MemoryLayout<AudioValueTranslation>.stride, qualifier: qualifier)
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
				_ = try readRawPropertyData(objectID: objectID, property: property, into: &translation, size: MemoryLayout<AudioValueTranslation>.stride, qualifier: qualifier)
			}
		}
		return outputData!.takeRetainedValue()
	}
}
