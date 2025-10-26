//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation
import CoreAudio
import os.log

/// A HAL audio device object
///
/// This class has four scopes (`kAudioObjectPropertyScopeGlobal`, `kAudioObjectPropertyScopeInput`, `kAudioObjectPropertyScopeOutput`, and `kAudioObjectPropertyScopePlayThrough`), a main element (`kAudioObjectPropertyElementMain`), and an element for each channel in each stream
/// - remark: This class correponds to objects with base class `kAudioDeviceClassID`
public class AudioDevice: AudioClockDevice, @unchecked Sendable {
	/// Returns the available audio devices
	/// - remark: This corresponds to the property`kAudioHardwarePropertyDevices` on `kAudioObjectSystemObject`
	public static var devices: [AudioDevice] {
		get throws {
			try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyDevices)).map { try makeAudioDevice($0) }
		}
	}

	/// Returns the default input device
	/// - remark: This corresponds to the property`kAudioHardwarePropertyDefaultInputDevice` on `kAudioObjectSystemObject`
	public static var defaultInputDevice: AudioDevice {
		get throws {
			try makeAudioDevice(getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyDefaultInputDevice)))
		}
	}

	/// Returns the default output device
	/// - remark: This corresponds to the property`kAudioHardwarePropertyDefaultOutputDevice` on `kAudioObjectSystemObject`
	public static var defaultOutputDevice: AudioDevice {
		get throws {
			try makeAudioDevice(getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyDefaultOutputDevice)))
		}
	}

	/// Returns the default system output device
	/// - remark: This corresponds to the property`kAudioHardwarePropertyDefaultSystemOutputDevice` on `kAudioObjectSystemObject`
	public static var defaultSystemOutputDevice: AudioDevice {
		get throws {
			try makeAudioDevice(getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyDefaultSystemOutputDevice)))
		}
	}

	/// Returns an initialized `AudioDevice` with `uid` or `nil` if unknown
	/// - remark: This corresponds to the property `kAudioHardwarePropertyTranslateUIDToDevice` on `kAudioObjectSystemObject`
	/// - parameter uid: The UID of the desired device
	public static func makeDevice(forUID uid: String) throws -> AudioDevice? {
		var qualifier = uid as CFString
		let objectID: AudioObjectID = try getPropertyData(objectID: .systemObject, property: PropertyAddress(kAudioHardwarePropertyTranslateUIDToDevice), qualifier: PropertyQualifier(&qualifier))
		guard objectID != kAudioObjectUnknown else {
			return nil
		}
		return try makeAudioDevice(objectID)
	}

	/// Returns `true` if the device supports input
	///
	/// - note: A device supports input if it has buffers in `kAudioObjectPropertyScopeInput` for the property `kAudioDevicePropertyStreamConfiguration`
	public var supportsInput: Bool {
		get throws {
			try streamConfiguration(inScope: .input).numberBuffers > 0
		}
	}

	/// Returns `true` if the device supports output
	///
	/// - note: A device supports output if it has buffers in `kAudioObjectPropertyScopeOutput` for the property `kAudioDevicePropertyStreamConfiguration`
	public var supportsOutput: Bool {
		get throws {
			try streamConfiguration(inScope: .output).numberBuffers > 0
		}
	}

	// MARK: - Starting and Stopping the Audio Device

	/// Starts IO for the given`IOProc`
	/// - parameter ioProcID: The `IOProc` to start
	/// - remark: If `ioProcID` is `nil` the device is started regardless of whether any `IOProc`s are registered
	public func start(ioProcID: AudioDeviceIOProcID? = nil) throws {
		let result = AudioDeviceStart(objectID, ioProcID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceStart (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
	}

	/// Starts IO for the given `IOProc` and aligns the IO cycle of the device with `time`
	/// - parameter time: The requested start time
	/// - parameter ioProcID: The `AudioDeviceIOProcID` to start.
	/// - parameter flags: Desired flags
	/// - remark: If `ioProcID` is `nil` the device is started regardless of whether any `IOProc`s are registered
	/// - returns: The time at which the `IOProc` will start
	public func start(at time: AudioTimeStamp, flags: UInt32 = 0, ioProcID: AudioDeviceIOProcID? = nil) throws -> AudioTimeStamp {
		var timestamp = time
		let result = AudioDeviceStartAtTime(objectID, ioProcID, &timestamp, flags)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceStartAtTime (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return timestamp
	}

	/// Stops IO for the given `IOProc`
	/// - parameter ioProcID: The `IOProc` to stop
	public func stop(ioProcID: AudioDeviceIOProcID? = nil) throws {
		let result = AudioDeviceStop(objectID, ioProcID)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceStop (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
	}

	// MARK: - Audio Device Timing

	/// Returns the device's current time
	/// - parameter flags: The desired time representations
	public func currentTime(_ flags: AudioTimeStampFlags) throws -> AudioTimeStamp {
		var timestamp = AudioTimeStamp()
		timestamp.mFlags = flags
		let result = AudioDeviceGetCurrentTime(objectID, &timestamp)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceGetCurrentTime (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return timestamp
	}

	/// Returns the device's current time
	public var currentTime: AudioTimeStamp {
		get throws {
			try currentTime(.sampleHostTimeValid)
		}
	}

	/// Returns the time equal to or later than `time` that is the best time to start IO
	/// - parameter time: The requested start time
	/// - parameter flags: Desired flags
	/// - returns: The best time to start IO
	public func nearestStartTime(to time: AudioTimeStamp, flags: UInt32 = 0) throws -> AudioTimeStamp {
		var timestamp = time
		let result = AudioDeviceGetNearestStartTime(objectID, &timestamp, flags)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceGetNearestStartTime (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return timestamp
	}

	/// Translates `time` from one time base to another
	/// - parameter time: The time to translate
	/// - parameter flags: The desired time representations
	public func translateTime(_ time: AudioTimeStamp, flags: AudioTimeStampFlags = .sampleHostTimeValid) throws -> AudioTimeStamp {
		var inTime = time
		var outTime = AudioTimeStamp()
		outTime.mFlags = flags
		let result = AudioDeviceTranslateTime(objectID, &inTime, &outTime)
		guard result == kAudioHardwareNoError else {
			os_log(.error, log: audioObjectLog, "AudioDeviceTranslateTime (0x%x) failed: '%{public}@'", objectID, UInt32(result).fourCC)
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
		}
		return outTime
	}

	// MARK: - Audio Device Base Properties

	/// Returns the configuration application
	/// - remark: This corresponds to the property `kAudioDevicePropertyConfigurationApplication`
	public var configurationApplication: String {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyConfigurationApplication), type: CFString.self) as String
		}
	}

	/// Returns the device UID
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceUID`
	public override var deviceUID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyDeviceUID), type: CFString.self) as String
		}
	}

	/// Returns the model UID
	/// - remark: This corresponds to the property `kAudioDevicePropertyModelUID`
	public var modelUID: String {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyModelUID), type: CFString.self) as String
		}
	}

	/// Returns the transport type
	/// - remark: This corresponds to the property `kAudioDevicePropertyTransportType`
	public override var transportType: TransportType {
		get throws {
			TransportType(try getProperty(PropertyAddress(kAudioDevicePropertyTransportType), type: UInt32.self))
		}
	}

	/// Returns related audio devices
	/// - remark: This corresponds to the property `kAudioDevicePropertyRelatedDevices`
	public var relatedDevices: [AudioDevice] {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyRelatedDevices)).map { try makeAudioDevice($0) }
		}
	}

	/// Returns the clock domain
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockDomain`
	public override var clockDomain: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyClockDomain))
		}
	}

	/// Returns `true` if the device is alive
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceIsAlive`
	public override var isAlive: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyDeviceIsAlive), type: UInt32.self) != 0
		}
	}

	/// Returns `true` if the device is running
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceIsRunning`
	public override var isRunning: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyDeviceIsRunning), type: UInt32.self) != 0
		}
	}
	/// Starts or stops the device
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceIsRunning`
	/// - parameter value: The desired property value
	public func setIsRunning(_ value: Bool) throws {
		try setProperty(PropertyAddress(kAudioDevicePropertyDeviceIsRunning), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if the device can be the default device
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceCanBeDefaultDevice`
	/// - parameter scope: The desired scope
	public func canBeDefault(inScope scope: PropertyScope) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDeviceCanBeDefaultDevice), scope: scope), type: UInt32.self) != 0
	}

	/// Returns `true` if the device can be the system default device
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceCanBeDefaultSystemDevice`
	/// - parameter scope: The desired scope
	public func canBeSystemDefault(inScope scope: PropertyScope) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDeviceCanBeDefaultSystemDevice), scope: scope), type: UInt32.self) != 0
	}

	/// Returns the latency in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyLatency`
	/// - parameter scope: The desired scope
	public func latency(inScope scope: PropertyScope) throws -> Int {
		return Int(try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyLatency), scope: scope), type: UInt32.self))
	}

	/// Returns the input latency in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyLatency` on `kAudioObjectPropertyScopeInput`
	public var inputLatency: Int {
		get throws {
			try latency(inScope: .input)
		}
	}

	/// Returns the output latency in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyLatency` on `kAudioObjectPropertyScopeOutput`
	public var outputLatency: Int {
		get throws {
			try latency(inScope: .output)
		}
	}

	/// Returns the device's streams
	/// - remark: This corresponds to the property `kAudioDevicePropertyStreams`
	/// - parameter scope: The desired scope
	public func streams(inScope scope: PropertyScope) throws -> [AudioStream] {
		// Revisit if a subclass of `AudioStream` is added
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyStreams), scope: scope)).map { AudioStream($0) }
	}

	/// Returns the device's audio controls
	/// - remark: This corresponds to the property `kAudioObjectPropertyControlList`
	public override var controlList: [AudioControl] {
		get throws {
			try getProperty(PropertyAddress(kAudioObjectPropertyControlList)).map { try makeAudioControl($0, baseClass: AudioObject.getBaseClass($0)) }
		}
	}

	/// Returns the safety offset in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertySafetyOffset`
	/// - parameter scope: The desired scope
	public func safetyOffset(inScope scope: PropertyScope) throws -> Int {
		return Int(try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySafetyOffset), scope: scope), type: UInt32.self))
	}

	/// Returns the input safety offset in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertySafetyOffset` on `kAudioDevicePropertyScopeInput`
	public var inputSafetyOffset: Int {
		get throws {
			try safetyOffset(inScope: .input)
		}
	}

	/// Returns the output safety offset in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertySafetyOffset` on `kAudioDevicePropertyScopeOutput`
	public var outputSafetyOffset: Int {
		get throws {
			try safetyOffset(inScope: .output)
		}
	}

	/// Returns the nominal sample rate
	/// - remark: This corresponds to the property `kAudioDevicePropertyNominalSampleRate`
	public override var nominalSampleRate: Double {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyNominalSampleRate))
		}
	}
	/// Sets the nominal sample rate
	/// - remark: This corresponds to the property `kAudioDevicePropertyNominalSampleRate`
	/// - parameter value: The desired property value
	public override func setNominalSampleRate(_ value: Double) throws {
		os_log(.info, log: audioObjectLog, "Setting device 0x%x nominal sample rate to %.2f Hz", objectID, value)
		try setProperty(PropertyAddress(kAudioDevicePropertyNominalSampleRate), to: value)
	}

	/// Returns the available nominal sample rates
	/// - remark: This corresponds to the property `kAudioDevicePropertyAvailableNominalSampleRates`
	public override var availableNominalSampleRates: [ClosedRange<Double>] {
		get throws {
			let value = try getProperty(PropertyAddress(kAudioDevicePropertyAvailableNominalSampleRates), elementType: AudioValueRange.self)
			return value.map { $0.mMinimum ... $0.mMaximum }
		}
	}

	/// Returns the URL of the device's icon
	/// - remark: This corresponds to the property `kAudioDevicePropertyIcon`
	/// - note: This property is not supported by all devices
	public var icon: URL {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyIcon), type: CFURL.self) as URL
		}
	}

	/// Returns `true` if the device is hidden
	/// - remark: This corresponds to the property `kAudioDevicePropertyIsHidden`
	public var isHidden: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyIsHidden), type: UInt32.self) != 0
		}
	}

	/// Returns the preferred stereo channels for the device
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo`
	/// - parameter scope: The desired scope
	public func preferredStereoChannels(inScope scope: PropertyScope) throws -> (PropertyElement, PropertyElement) {
		let channels = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPreferredChannelsForStereo), scope: scope), elementType: UInt32.self)
		precondition(channels.count == 2, "Unexpected array length for kAudioDevicePropertyPreferredChannelsForStereo")
		return (PropertyElement(channels[0]), PropertyElement(channels[1]))
	}
	/// Sets the preferred stereo channels
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo`
	/// - parameter value: The desired property value
	/// - parameter scope: The desired scope
	public func setPreferredStereoChannels(_ value: (PropertyElement, PropertyElement), inScope scope: PropertyScope) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPreferredChannelsForStereo), scope: scope), to: [value.0.rawValue, value.1.rawValue])
	}

	/// Returns the preferred input stereo channels for the device
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo` on `kAudioObjectPropertyScopeInput`
	public var preferredInputStereoChannels: (PropertyElement, PropertyElement) {
		get throws {
			try preferredStereoChannels(inScope: .input)
		}
	}
	/// Sets the preferred input stereo channels
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo` on `kAudioObjectPropertyScopeInput`
	/// - parameter value: The desired property value
	public func setPreferredInputStereoChannels(_ value: (PropertyElement, PropertyElement)) throws {
		try setPreferredStereoChannels(value, inScope: .input)
	}

	/// Returns the preferred output stereo channels for the device
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo` on `kAudioObjectPropertyScopeOutput`
	public var preferredOutputStereoChannels: (PropertyElement, PropertyElement) {
		get throws {
			try preferredStereoChannels(inScope: .output)
		}
	}
	/// Sets the preferred output stereo channels
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelsForStereo` on `kAudioObjectPropertyScopeOutput`
	/// - parameter value: The desired property value
	public func setPreferredOutputStereoChannels(_ value: (PropertyElement, PropertyElement)) throws {
		try setPreferredStereoChannels(value, inScope: .output)
	}

	/// Returns the preferred channel layout
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelLayout`
	/// - parameter scope: The desired scope
	public func preferredChannelLayout(inScope scope: PropertyScope) throws -> AudioChannelLayoutWrapper {
		let property = PropertyAddress(PropertySelector(kAudioDevicePropertyPreferredChannelLayout), scope: scope)
		let dataSize = try AudioObject.propertyDataSize(objectID: objectID, property: property)
		let mem = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
		do {
			_ = try AudioObject.readRawPropertyData(objectID: objectID, property: property, into: mem, size: dataSize)
		} catch let error {
			mem.deallocate()
			throw error
		}
		return AudioChannelLayoutWrapper(mem)
	}
	/// Sets the preferred channel layout
	/// - remark: This corresponds to the property `kAudioDevicePropertyPreferredChannelLayout`
	/// - parameter value: The desired property value
	/// - parameter scope: The desired scope
	public func setPreferredChannelLayout(_ value: UnsafePointer<AudioChannelLayout>, inScope scope: PropertyScope) throws {
		let dataSize = AudioChannelLayout.sizeInBytes(maximumDescriptions: Int(value.pointee.mNumberChannelDescriptions))
		try AudioObject.writeRawPropertyData(objectID: objectID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyPreferredChannelLayout), scope: scope), data: value, size: dataSize)
	}

	// MARK: - Audio Device Properties

	/// Returns any error codes loading the driver plugin
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlugIn`
	public var plugIn: OSStatus {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyPlugIn))
		}
	}

	/// Returns `true` if the device is running somewhere
	/// - remark: This corresponds to the property `kAudioDevicePropertyDeviceIsRunningSomewhere`
	public var isRunningSomewhere: Bool {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyDeviceIsRunningSomewhere), type: UInt32.self) != 0
		}
	}

	/// Returns the owning pid or `-1` if the device is available to all processes
	/// - remark: This corresponds to the property `kAudioDevicePropertyHogMode`
	public var hogMode: pid_t {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyHogMode))
		}
	}
	/// Sets the owning pid
	/// - remark: This corresponds to the property `kAudioDevicePropertyHogMode`
	public func setHogMode(_ value: pid_t) throws {
		try setProperty(PropertyAddress(kAudioDevicePropertyHogMode), to: value)
	}

	// Hog mode helpers

	/// Returns `true` if the device is hogged
	public var isHogged: Bool {
		get throws {
			try hogMode != -1
		}
	}

	/// Returns `true` if the device is hogged and the current process is the owner
	public var isHogOwner: Bool {
		get throws {
			try hogMode == getpid()
		}
	}

	/// Takes hog mode
	public func startHogging() throws {
		let hogpid = try hogMode

		guard hogpid != getpid() else {
			os_log(.debug, log: audioObjectLog, "Ignoring request to take hog mode on already-hogged device 0x%x", objectID)
			return
		}

		if hogpid != -1 {
			os_log(.error, log: audioObjectLog, "Device 0x%x is already hogged by pid %d", objectID, hogpid)
		}

		os_log(.info, log: audioObjectLog, "Taking hog mode for device 0x%x", objectID)
		// The passed value is ignored
		try setHogMode(1)
	}

	/// Releases hog mode if the device is hogged and the current process is the owner
	public func stopHogging() throws {
		let hogpid = try hogMode

		guard hogpid != -1 else {
			os_log(.debug, log: audioObjectLog, "Ignoring request to release hog mode on non-hogged device 0x%x", objectID)
			return
		}

		if hogpid != getpid() {
			os_log(.error, log: audioObjectLog, "Device 0x%x is hogged by pid %d", objectID, hogpid)
		}

		os_log(.info, log: audioObjectLog, "Releasing hog mode for device 0x%x", objectID)
		try setHogMode(-1)
	}

	/// Returns the buffer size in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyBufferFrameSize`
	public var bufferFrameSize: Int {
		get throws {
			Int(try getProperty(PropertyAddress(kAudioDevicePropertyBufferFrameSize), type: UInt32.self))
		}
	}
	/// Sets the buffer size in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyBufferFrameSize`
	public func setBufferFrameSize(_ value: Int) throws {
		try setProperty(PropertyAddress(kAudioDevicePropertyBufferFrameSize), to: UInt32(value))
	}

	/// Returns the minimum and maximum values for the buffer size in frames
	/// - remark: This corresponds to the property `kAudioDevicePropertyBufferFrameSizeRange`
	public var bufferFrameSizeRange: ClosedRange<Int> {
		get throws {
			let value: AudioValueRange = try getProperty(PropertyAddress(kAudioDevicePropertyBufferFrameSizeRange))
			return Int(value.mMinimum) ... Int(value.mMaximum)
		}
	}

	/// Returns the variable buffer frame size
	/// - remark: This corresponds to the property `kAudioDevicePropertyUsesVariableBufferFrameSizes`
	public var usesVariableBufferFrameSizes: UInt32 {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyUsesVariableBufferFrameSizes))
		}
	}

	/// Returns the IO cycle usage
	/// - remark: This corresponds to the property `kAudioDevicePropertyIOCycleUsage`
	public var ioCycleUsage: Float {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyIOCycleUsage))
		}
	}

	/// Returns the stream configuration
	/// - remark: This corresponds to the property `kAudioDevicePropertyStreamConfiguration`
	public func streamConfiguration(inScope scope: PropertyScope) throws -> AudioBufferListWrapper {
		let property = PropertyAddress(PropertySelector(kAudioDevicePropertyStreamConfiguration), scope: scope)
		let dataSize = try AudioObject.propertyDataSize(objectID: objectID, property: property)
		let mem = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
		do {
			_ = try AudioObject.readRawPropertyData(objectID: objectID, property: property, into: mem, size: dataSize)
		} catch let error {
			mem.deallocate()
			throw error
		}
		return AudioBufferListWrapper(mem)
	}

	/// Returns the input stream configuration
	/// - remark: This corresponds to the property `kAudioDevicePropertyStreamConfiguration` on `kAudioObjectPropertyScopeInput`
	public var inputStreamConfiguration: AudioBufferListWrapper {
		get throws {
			try streamConfiguration(inScope: .input)
		}
	}

	/// Returns the output stream configuration
	/// - remark: This corresponds to the property `kAudioDevicePropertyStreamConfiguration` on `kAudioObjectPropertyScopeOutput`
	public var outputStreamConfiguration: AudioBufferListWrapper {
		get throws {
			try streamConfiguration(inScope: .output)
		}
	}

	/// Returns IOProc stream usage
	/// - note: This corresponds to the property `kAudioDevicePropertyIOProcStreamUsage`
	/// - parameter ioProc: The desired IOProc
	public func ioProcStreamUsage(_ ioProc: UnsafeMutableRawPointer, inScope scope: PropertyScope) throws -> AudioHardwareIOProcStreamUsageWrapper {
		let property = PropertyAddress(PropertySelector(kAudioDevicePropertyIOProcStreamUsage), scope: scope)
		let dataSize = try AudioObject.propertyDataSize(objectID: objectID, property: property)
		let mem = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
		UnsafeMutableRawPointer(mem).assumingMemoryBound(to: AudioHardwareIOProcStreamUsage.self).pointee.mIOProc = ioProc
		do {
			_ = try AudioObject.readRawPropertyData(objectID: objectID, property: property, into: mem, size: dataSize)
		} catch let error {
			mem.deallocate()
			throw error
		}
		return AudioHardwareIOProcStreamUsageWrapper(mem)
	}
	/// Sets IOProc stream usage
	/// - note: This corresponds to the property `kAudioDevicePropertyIOProcStreamUsage`
	/// - parameter value: The desired property value
	/// - parameter scope: The desired scope
	public func setIOProcStreamUsage(_ value: UnsafePointer<AudioHardwareIOProcStreamUsage>, inScope scope: PropertyScope) throws {
		let dataSize = AudioHardwareIOProcStreamUsage.sizeInBytes(maximumStreams: Int(value.pointee.mNumberStreams))
		try AudioObject.writeRawPropertyData(objectID: objectID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyIOProcStreamUsage), scope: scope), data: value, size: dataSize)
	}

	/// Returns the actual sample rate
	/// - remark: This corresponds to the property `kAudioDevicePropertyActualSampleRate`
	public var actualSampleRate: Double {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyActualSampleRate))
		}
	}

	/// Returns the UID of the clock device
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockDevice`
	public var clockDevice: String {
		get throws {
			try getProperty(PropertyAddress(kAudioDevicePropertyClockDevice), type: CFString.self) as String
		}
	}

	/// Returns the workgroup to which the device's IOThread belongs
	/// - remark: This corresponds to the property `kAudioDevicePropertyIOThreadOSWorkgroup`
	@available(macOS 11.0, *)
	public func ioThreadOSWorkgroup(inScope scope: PropertyScope = .global) throws -> WorkGroup {
		return try AudioObject.getPropertyData(objectID: objectID, property: PropertyAddress(PropertySelector(kAudioDevicePropertyIOThreadOSWorkgroup), scope: scope), type: os_workgroup_t.self)
	}

	/// Returns `true` if the current process's audio will be zeroed out by the system
	/// - remark: This corresponds to the property `kAudioDevicePropertyProcessMute`
	public func processMute(inScope scope: PropertyScope = .global) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyProcessMute), scope: scope), type: UInt32.self) != 0
	}
	/// Sets whether the current process's audio will be zeroed out by the system
	/// - remark: This corresponds to the property `kAudioDevicePropertyProcessMute`
	public func setProcessMute(_ value: Bool, scope: PropertyScope = .global) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyProcessMute), scope: scope), to: value ? 1 : 0)
	}

	// MARK: - Audio Device Properties Implemented by Audio Controls

	/// Returns `true` if a jack is connected to `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyJackIsConnected`
	public func jackIsConnected(toElement element: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyJackIsConnected), scope: scope, element: element), type: UInt32.self) != 0
	}

	// It would be possible to combine the kAudioDevicePropertyVolume* and kAudioDevicePropertyPlayThruVolume* properties
	// in the following methods based on the scope, choosing the kAudioDevicePropertyPlayThruVolume* variants when scope is
	// kAudioObjectPropertyScopePlayThrough and the kAudioDevicePropertyVolume* properties otherwise. However, it's unclear
	// (to me at least) whether kAudioDevicePropertyPlayThruVolumeScalar, for example, could have a meaning in the
	// kAudioObjectPropertyScopePlayThrough scope. If it could then combining the two sets of properties here would not
	// allow the kAudioDevicePropertyVolume* properties to be set in the kAudioObjectPropertyScopePlayThrough scope.
	// For this reason the kAudioDevicePropertyPlayThruVolume* are given their own methods.

	/// Returns the volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeScalar`
	public func volumeScalar(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeScalar), scope: scope, element: channel))
	}
	/// Sets the volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeScalar`
	public func setVolumeScalar(_ value: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeScalar), scope: scope, element: channel), to: value)
	}

	/// Returns the volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeDecibels`
	public func volumeDecibels(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeDecibels), scope: scope, element: channel))
	}
	/// Sets the volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeDecibels`
	public func setVolumeDecibels(_ value: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeDecibels), scope: scope, element: channel), to: value)
	}

	/// Returns the volume range in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeRangeDecibels`
	public func volumeRangeDecibels(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> ClosedRange<Float> {
		let value: AudioValueRange = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeRangeDecibels), scope: scope, element: channel))
		return Float(value.mMinimum) ... Float(value.mMaximum)
	}

	/// Converts volume `scalar` to decibels and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeScalarToDecibels`
	/// - parameter scalar: The value to convert
	public func convertVolumeToDecibels(fromScalar scalar: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeScalarToDecibels), scope: scope, element: channel), initialValue: scalar)
	}

	/// Converts volume `decibels` to scalar and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertyVolumeDecibelsToScalar`
	/// - parameter decibels: The value to convert
	public func convertVolumeToScalar(fromDecibels decibels: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVolumeDecibelsToScalar), scope: scope, element: channel), initialValue: decibels)
	}

	/// Returns the stereo pan
	/// - remark: This corresponds to the property `kAudioDevicePropertyStereoPan`
	public func stereoPan(inScope scope: PropertyScope) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyStereoPan), scope: scope))
	}
	/// Sets the stereo pan
	/// - remark: This corresponds to the property `kAudioDevicePropertyStereoPan`
	public func setStereoPan(_ value: Float, inScope scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyStereoPan), scope: scope), to: value)
	}

	/// Returns the channels used for stereo panning
	/// - remark: This corresponds to the property `kAudioDevicePropertyStereoPanChannels`
	public func stereoPanChannels(inScope scope: PropertyScope) throws -> (PropertyElement, PropertyElement) {
		let channels = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyStereoPanChannels), scope: scope), elementType: UInt32.self)
		precondition(channels.count == 2, "Unexpected array length for kAudioDevicePropertyStereoPanChannels")
		return (PropertyElement(channels[0]), PropertyElement(channels[1]))
	}
	/// Sets the channels used for stereo panning
	/// - remark: This corresponds to the property `kAudioDevicePropertyStereoPanChannels`
	public func setStereoPanChannels(_ value: (PropertyElement, PropertyElement), inScope scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyStereoPanChannels), scope: scope), to: [value.0.rawValue, value.1.rawValue])
	}

	/// Returns `true` if `element` is muted
	/// - remark: This corresponds to the property `kAudioDevicePropertyMute`
	public func mute(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyMute), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether `element` is muted
	/// - remark: This corresponds to the property `kAudioDevicePropertyMute`
	public func setMute(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyMute), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if only `element` is audible
	/// - remark: This corresponds to the property `kAudioDevicePropertySolo`
	public func solo(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySolo), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether `element` is audible
	/// - remark: This corresponds to the property `kAudioDevicePropertySolo`
	public func setSolo(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySolo), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if phantom power is enabled on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPhantomPower`
	public func phantomPower(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPhantomPower), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether phantom power is enabled on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPhantomPower`
	public func setPhantomPower(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPhantomPower), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if the phase is inverted on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPhaseInvert`
	public func phaseInvert(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPhaseInvert), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether the phase is inverted on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPhaseInvert`
	public func setPhaseInvert(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPhaseInvert), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if the signal exceeded the sample range
	/// - remark: This corresponds to the property `kAudioDevicePropertyClipLight`
	public func clipLight(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClipLight), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether the signal exceeded the sample range
	/// - remark: This corresponds to the property `kAudioDevicePropertyClipLight`
	public func setClipLight(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClipLight), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if talkback is enabled
	/// - remark: This corresponds to the property `kAudioDevicePropertyTalkback`
	public func talkback(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyTalkback), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether talkback is enabled
	/// - remark: This corresponds to the property `kAudioDevicePropertyTalkback`
	public func setTalkback(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyTalkback), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if listenback is enabled
	/// - remark: This corresponds to the property `kAudioDevicePropertyListenback`
	public func listenback(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyListenback), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether listenback is enabled
	/// - remark: This corresponds to the property `kAudioDevicePropertyListenback`
	public func setListenback(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyListenback), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns the IDs of the selected data sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSource`
	public func dataSource(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDataSource), scope: scope))
	}
	/// Sets the IDs of the selected data sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSource`
	public func setDataSource(_ value: [UInt32], scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDataSource), scope: scope), to: value)
	}

	/// Returns the IDs of the available data sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSources`
	public func dataSources(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDataSources), scope: scope))
	}

	/// Returns the name of `dataSourceID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSourceNameForIDCFString`
	public func nameOfDataSource(_ dataSourceID: UInt32, inScope scope: PropertyScope) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDataSourceNameForIDCFString), scope: scope), translatingValue: dataSourceID, toType: CFString.self) as String
	}

	/// Returns the kind of `dataSourceID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSourceKindForID`
	public func kindOfDataSource(_ dataSourceID: UInt32, inScope scope: PropertyScope) throws -> UInt32 {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyDataSourceKindForID), scope: scope), translatingValue: dataSourceID)
	}

	// Data source helpers

	/// Returns the available data sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSources`
	public func availableDataSources(inScope scope: PropertyScope) throws -> [DataSource] {
		return try dataSources(inScope: scope).map { DataSource(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the active data sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyDataSource`
	public func activeDataSources(inScope scope: PropertyScope) throws -> [DataSource] {
		return try dataSource(inScope: scope).map { DataSource(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the IDs of the selected clock sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSource`
	public func clockSource(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClockSource), scope: scope))
	}
	/// Sets the IDs of the selected clock sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSource`
	public func setClockSource(_ value: [UInt32], inScope scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClockSource), scope: scope), to: value)
	}

	/// Returns the IDs of the available clock sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSources`
	public func clockSources(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClockSources), scope: scope))
	}

	/// Returns the name of `clockSourceID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSourceNameForIDCFString`
	public func nameOfClockSource(_ clockSourceID: UInt32, inScope scope: PropertyScope) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClockSourceNameForIDCFString), scope: scope), translatingValue: clockSourceID, toType: CFString.self) as String
	}

	/// Returns the kind of `clockSourceID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSourceKindForID`
	/// - parameter clockSourceID: The desired clock source
	/// - parameter scope: The desired scope
	/// - throws: An error if the property could not be retrieved
	public func kindOfClockSource(_ clockSourceID: UInt32, inScope scope: PropertyScope) throws -> UInt32 {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyClockSourceKindForID), scope: scope), translatingValue: clockSourceID)
	}

	// Clock source helpers

	/// Returns the available clock sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSources`
	public func availableClockSources(inScope scope: PropertyScope) throws -> [ClockSource] {
		return try clockSources(inScope: scope).map { ClockSource(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the active clock sources
	/// - remark: This corresponds to the property `kAudioDevicePropertyClockSource`
	public func activeClockSources(inScope scope: PropertyScope) throws -> [ClockSource] {
		return try clockSource(inScope: scope).map { ClockSource(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns `true` if play-through is enabled
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThru`
	public func playThrough(onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThru), scope: .playThrough, element: element), type: UInt32.self) != 0
	}

	/// Returns `true` if only play-through `element` is audible
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruSolo`
	public func playThroughSolo(onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruSolo), scope: .playThrough, element: element), type: UInt32.self) != 0
	}
	/// Sets whether play-through `element` is audible
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruSolo`
	public func setPlayThroughSolo(_ value: Bool, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruSolo), scope: .playThrough, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns the play-through volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeScalar`
	public func playThroughVolumeScalar(forChannel channel: PropertyElement = .main) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeScalar), scope: .playThrough, element: channel))
	}
	/// Sets the play-through volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeScalar`
	public func setPlayThroughVolumeScalar(_ value: Float, forChannel channel: PropertyElement = .main) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeScalar), scope: .playThrough, element: channel), to: value)
	}

	/// Returns the play-through volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeDecibels`
	public func playThroughVolumeDecibels(forChannel channel: PropertyElement = .main) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeDecibels), scope: .playThrough, element: channel))
	}
	/// Sets the play-through volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeDecibels`
	public func setPlayThroughVolumeDecibels(_ value: Float, forChannel channel: PropertyElement = .main) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeDecibels), scope: .playThrough, element: channel), to: value)
	}

	/// Returns the play-through volume range in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeRangeDecibels`
	public func playThroughVolumeRangeDecibels(forChannel channel: PropertyElement = .main) throws -> ClosedRange<Float> {
		let value: AudioValueRange = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeRangeDecibels), scope: .playThrough, element: channel))
		return Float(value.mMinimum) ... Float(value.mMaximum)
	}

	/// Converts play-through volume `scalar` to decibels and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeScalarToDecibels`
	/// - parameter scalar: The value to convert
	public func convertPlayThroughVolumeToDecibels(fromScalar scalar: Float, forChannel channel: PropertyElement = .main) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeScalarToDecibels), scope: .playThrough, element: channel), initialValue: scalar)
	}

	/// Converts play-through volume `decibels` to scalar and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruVolumeDecibelsToScalar`
	/// - parameter decibels: The value to convert
	public func convertPlayThroughVolumeToScalar(fromDecibels decibels: Float, forChannel channel: PropertyElement = .main) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruVolumeDecibelsToScalar), scope: .playThrough, element: channel), initialValue: decibels)
	}

	/// Returns the play-through stereo pan
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruStereoPan`
	public var playThroughStereoPan: Float {
		get throws {
			try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruStereoPan), scope: .playThrough))
		}
	}
	/// Sets the play-through stereo pan
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruStereoPan`
	public func setPlayThroughStereoPan(_ value: Float) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruStereoPan), scope: .playThrough), to: value)
	}

	/// Returns the play-through channels used for stereo panning
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruStereoPanChannels`
	public var playThroughStereoPanChannels: (PropertyElement, PropertyElement) {
		get throws {
			let channels = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruStereoPanChannels), scope: .playThrough), elementType: UInt32.self)
			precondition(channels.count == 2, "Unexpected array length for kAudioDevicePropertyPlayThruStereoPanChannels")
			return (PropertyElement(channels[0]), PropertyElement(channels[1]))
		}
	}
	/// Sets the play-through channels used for stereo panning
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruStereoPanChannels`
	public func setPlayThroughStereoPanChannels(_ value: (PropertyElement, PropertyElement)) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruStereoPanChannels), scope: .playThrough), to: [value.0.rawValue, value.1.rawValue])
	}

	/// Returns the IDs of the selected play-through destinations
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestination`
	public var playThroughDestination: [UInt32] {
		get throws {
			try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruDestination), scope: .playThrough))
		}
	}
	/// Sets the IDs of the selected play-through destinations
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestination`
	public func setPlayThroughDestination(_ value: [UInt32]) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruDestination), scope: .playThrough), to: value)
	}

	/// Returns the IDs of the available play-through destinations
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestinations`
	public var playThroughDestinations: [UInt32] {
		get throws {
			try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruDestinations), scope: .playThrough))
		}
	}

	/// Returns the name of `playThroughDestinationID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestinationNameForIDCFString`
	public func nameOfPlayThroughDestination(_ playThroughDestinationID: UInt32) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyPlayThruDestinationNameForIDCFString), scope: .playThrough), translatingValue: playThroughDestinationID, toType: CFString.self) as String
	}

	// Play-through destination helpers

	/// Returns the available play-through destinations
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestinations`
	public var availablePlayThroughDestinations: [PlayThroughDestination] {
		get throws {
			try playThroughDestinations.map { PlayThroughDestination(deviceID: objectID, id: $0) }
		}
	}

	/// Returns the selected play-through destinations
	/// - remark: This corresponds to the property `kAudioDevicePropertyPlayThruDestination`
	public var selectedPlayThroughDestinations: [PlayThroughDestination] {
		get throws {
			try playThroughDestination.map { PlayThroughDestination(deviceID: objectID, id: $0) }
		}
	}

	/// Returns the IDs of the selected channel nominal line levels
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevel`
	public func channelNominalLineLevel(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyChannelNominalLineLevel), scope: scope))
	}
	/// Sets the IDs of the selected channel nominal line levels
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevel`
	public func setChannelNominalLineLevel(_ value: [UInt32], scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyChannelNominalLineLevel), scope: scope), to: value)
	}

	/// Returns the IDs of the available channel nominal line levels
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevels`
	public func channelNominalLineLevels(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyChannelNominalLineLevels), scope: scope))
	}

	/// Returns the name of `channelNominalLineLevelID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevelNameForIDCFString`
	public func nameOfChannelNominalLineLevel(_ channelNominalLineLevelID: UInt32, inScope scope: PropertyScope) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyChannelNominalLineLevelNameForIDCFString), scope: scope), translatingValue: channelNominalLineLevelID, toType: CFString.self) as String
	}

	// Channel nominal line level helpers

	/// Returns the available channel nominal line levels
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevels`
	public func availableChannelNominalLineLevels(inScope scope: PropertyScope) throws -> [ChannelNominalLineLevel] {
		return try channelNominalLineLevel(inScope: scope).map { ChannelNominalLineLevel(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the selected channel nominal line levels
	/// - remark: This corresponds to the property `kAudioDevicePropertyChannelNominalLineLevel`
	public func selectedChannelNominalLineLevels(inScope scope: PropertyScope) throws -> [ChannelNominalLineLevel] {
		return try channelNominalLineLevels(inScope: scope).map { ChannelNominalLineLevel(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the IDs of the selected high-pass filter settings
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSetting`
	public func highPassFilterSetting(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyHighPassFilterSetting), scope: scope))
	}
	/// Sets the IDs of the selected high-pass filter settings
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSetting`
	public func setHighPassFilterSetting(_ value: [UInt32], scope: PropertyScope) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyHighPassFilterSetting), scope: scope), to: value)
	}

	/// Returns the IDs of the available high-pass filter settings
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSettings`
	public func highPassFilterSettings(inScope scope: PropertyScope) throws -> [UInt32] {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyHighPassFilterSettings), scope: scope))
	}

	/// Returns the name of `highPassFilterSettingID`
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSettingNameForIDCFString`
	public func nameOfHighPassFilterSetting(_ highPassFilterSettingID: UInt32, inScope scope: PropertyScope) throws -> String {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyHighPassFilterSettingNameForIDCFString), scope: scope), translatingValue: highPassFilterSettingID, toType: CFString.self) as String
	}

	// High-pass filter setting helpers

	/// Returns the available high-pass filter settings
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSettings`
	public func availableHighPassFilterSettings(inScope scope: PropertyScope) throws -> [HighPassFilterSetting] {
		return try highPassFilterSettings(inScope: scope).map { HighPassFilterSetting(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the selected high-pass filter settings
	/// - remark: This corresponds to the property `kAudioDevicePropertyHighPassFilterSetting`
	public func selectedHighPassFilterSettings(inScope scope: PropertyScope) throws -> [HighPassFilterSetting] {
		return try highPassFilterSetting(inScope: scope).map { HighPassFilterSetting(deviceID: objectID, scope: scope, id: $0) }
	}

	/// Returns the LFE volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeScalar`
	public func subVolumeScalar(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeScalar), scope: scope, element: channel))
	}
	/// Sets the LFE volume scalar for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeScalar`
	public func setSubVolumeScalar(_ value: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeScalar), scope: scope, element: channel), to: value)
	}

	/// Returns the LFE volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeDecibels`
	public func subVolumeDecibels(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeDecibels), scope: scope, element: channel))
	}
	/// Sets the LFE volume in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeDecibels`
	public func setSubVolumeDecibels(_ value: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws {
		return try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeDecibels), scope: scope, element: channel), to: value)
	}

	/// Returns the LFE volume range in decibels for `channel`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeRangeDecibels`
	public func subVolumeRangeDecibels(forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> ClosedRange<Float> {
		let value: AudioValueRange = try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeRangeDecibels), scope: scope, element: channel))
		return Float(value.mMinimum) ... Float(value.mMaximum)
	}

	/// Converts LFE volume `scalar` to decibels and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeScalarToDecibels`
	/// - parameter scalar: The value to convert
	public func convertSubVolumeToDecibels(fromScalar scalar: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeScalarToDecibels), scope: scope, element: channel), initialValue: scalar)
	}

	/// Converts LFE volume `decibels` to scalar and returns the converted value
	/// - remark: This corresponds to the property `kAudioDevicePropertySubVolumeDecibelsToScalar`
	/// - parameter decibels: The value to convert
	public func convertSubVolumeToScalar(fromDecibels decibels: Float, forChannel channel: PropertyElement = .main, inScope scope: PropertyScope = .global) throws -> Float {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubVolumeDecibelsToScalar), scope: scope, element: channel), initialValue: decibels)
	}

	/// Returns `true` if LFE are muted on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubMute`
	public func subMute(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubMute), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether LFE are muted on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertySubMute`
	public func setSubMute(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertySubMute), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if voice activity detection is enabled on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVoiceActivityDetectionEnable`
	@available(macOS 14, *)
	public func voiceActivityDetectionEnable(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVoiceActivityDetectionEnable), scope: scope, element: element), type: UInt32.self) != 0
	}
	/// Sets whether voice activity detection is enabled on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVoiceActivityDetectionEnable`
	@available(macOS 14, *)
	public func setVoiceActivityDetectionEnable(_ value: Bool, inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws {
		try setProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVoiceActivityDetectionEnable), scope: scope, element: element), to: UInt32(value ? 1 : 0))
	}

	/// Returns `true` if a voice is detected on `element`
	/// - remark: This corresponds to the property `kAudioDevicePropertyVoiceActivityDetectionState`
	@available(macOS 14, *)
	public func voiceActivityDetectionState(inScope scope: PropertyScope, onElement element: PropertyElement = .main) throws -> Bool {
		return try getProperty(PropertyAddress(PropertySelector(kAudioDevicePropertyVoiceActivityDetectionState), scope: scope, element: element), type: UInt32.self) != 0
	}

	// A textual representation of this instance, suitable for debugging.
	public override var debugDescription: String {
		do {
			return "<\(type(of: self)): 0x\(objectID.hexString) \"\(try name)\">"
		} catch {
			return super.debugDescription
		}
	}
}

extension AudioDevice {
	/// Returns `true` if `self` has `selector` in `scope` on `element`
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	public func hasSelector(_ selector: AudioObjectSelector<AudioDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) -> Bool {
		return hasProperty(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Returns `true` if `selector` in `scope` on `element` is settable
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - throws: An error if `self` does not have the requested property
	public func isSelectorSettable(_ selector: AudioObjectSelector<AudioDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main) throws -> Bool {
		return try isPropertySettable(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element))
	}

	/// Registers `block` to be performed when `selector` in `scope` on `element` changes
	/// - parameter selector: The selector of the desired property
	/// - parameter scope: The desired scope
	/// - parameter element: The desired element
	/// - parameter queue: An optional dispatch queue on which `block` will be invoked.
	/// - parameter block: A closure to invoke when the property changes or `nil` to remove the previous value
	/// - throws: An error if the property listener could not be registered
	public func whenSelectorChanges(_ selector: AudioObjectSelector<AudioDevice>, inScope scope: PropertyScope = .global, onElement element: PropertyElement = .main, notifyOnQueue queue: DispatchQueue? = nil, perform block: PropertyChangeNotificationBlock?) throws {
		try whenPropertyChanges(PropertyAddress(PropertySelector(selector.rawValue), scope: scope, element: element), notifyOnQueue: queue, perform: block)
	}
}

extension AudioObjectSelector where T == AudioDevice {
	/// The property selector `kAudioDevicePropertyConfigurationApplication`
	public static let configurationApplication = AudioObjectSelector(kAudioDevicePropertyConfigurationApplication)
	/// The property selector `kAudioDevicePropertyDeviceUID`
	public static let deviceUID = AudioObjectSelector(kAudioDevicePropertyDeviceUID)
	/// The property selector `kAudioDevicePropertyModelUID`
	public static let modelUID = AudioObjectSelector(kAudioDevicePropertyModelUID)
	/// The property selector `kAudioDevicePropertyTransportType`
	public static let transportType = AudioObjectSelector(kAudioDevicePropertyTransportType)
	/// The property selector `kAudioDevicePropertyRelatedDevices`
	public static let relatedDevices = AudioObjectSelector(kAudioDevicePropertyRelatedDevices)
	/// The property selector `kAudioDevicePropertyClockDomain`
	public static let clockDomain = AudioObjectSelector(kAudioDevicePropertyClockDomain)
	/// The property selector `kAudioDevicePropertyDeviceIsAlive`
	public static let deviceIsAlive = AudioObjectSelector(kAudioDevicePropertyDeviceIsAlive)
	/// The property selector `kAudioDevicePropertyDeviceIsRunning`
	public static let deviceIsRunning = AudioObjectSelector(kAudioDevicePropertyDeviceIsRunning)
	/// The property selector `kAudioDevicePropertyDeviceCanBeDefaultDevice`
	public static let deviceCanBeDefaultDevice = AudioObjectSelector(kAudioDevicePropertyDeviceCanBeDefaultDevice)
	/// The property selector `kAudioDevicePropertyDeviceCanBeDefaultSystemDevice`
	public static let deviceCanBeDefaultSystemDevice = AudioObjectSelector(kAudioDevicePropertyDeviceCanBeDefaultSystemDevice)
	/// The property selector `kAudioDevicePropertyLatency`
	public static let latency = AudioObjectSelector(kAudioDevicePropertyLatency)
	/// The property selector `kAudioDevicePropertyStreams`
	public static let streams = AudioObjectSelector(kAudioDevicePropertyStreams)
	/// The property selector `kAudioObjectPropertyControlList`
	public static let controlList = AudioObjectSelector(kAudioObjectPropertyControlList)
	/// The property selector `kAudioDevicePropertySafetyOffset`
	public static let safetyOffset = AudioObjectSelector(kAudioDevicePropertySafetyOffset)
	/// The property selector `kAudioDevicePropertyNominalSampleRate`
	public static let nominalSampleRate = AudioObjectSelector(kAudioDevicePropertyNominalSampleRate)
	/// The property selector `kAudioDevicePropertyAvailableNominalSampleRates`
	public static let availableNominalSampleRates = AudioObjectSelector(kAudioDevicePropertyAvailableNominalSampleRates)
	/// The property selector `kAudioDevicePropertyIcon`
	public static let icon = AudioObjectSelector(kAudioDevicePropertyIcon)
	/// The property selector `kAudioDevicePropertyIsHidden`
	public static let isHidden = AudioObjectSelector(kAudioDevicePropertyIsHidden)
	/// The property selector `kAudioDevicePropertyPreferredChannelsForStereo`
	public static let preferredChannelsForStereo = AudioObjectSelector(kAudioDevicePropertyPreferredChannelsForStereo)
	/// The property selector `kAudioDevicePropertyPreferredChannelLayout`
	public static let preferredChannelLayout = AudioObjectSelector(kAudioDevicePropertyPreferredChannelLayout)

	/// The property selector `kAudioDevicePropertyPlugIn`
	public static let plugIn = AudioObjectSelector(kAudioDevicePropertyPlugIn)
	/// The property selector `kAudioDevicePropertyDeviceHasChanged`
	public static let hasChanged = AudioObjectSelector(kAudioDevicePropertyDeviceHasChanged)
	/// The property selector `kAudioDevicePropertyDeviceIsRunningSomewhere`
	public static let isRunningSomewhere = AudioObjectSelector(kAudioDevicePropertyDeviceIsRunningSomewhere)
	/// The property selector `kAudioDeviceProcessorOverload`
	public static let processorOverload = AudioObjectSelector(kAudioDeviceProcessorOverload)
	/// The property selector `kAudioDevicePropertyIOStoppedAbnormally`
	public static let ioStoppedAbornormally = AudioObjectSelector(kAudioDevicePropertyIOStoppedAbnormally)
	/// The property selector `kAudioDevicePropertyHogMode`
	public static let hogMode = AudioObjectSelector(kAudioDevicePropertyHogMode)
	/// The property selector `kAudioDevicePropertyBufferFrameSize`
	public static let bufferFrameSize = AudioObjectSelector(kAudioDevicePropertyBufferFrameSize)
	/// The property selector `kAudioDevicePropertyBufferFrameSizeRange`
	public static let bufferFrameSizeRange = AudioObjectSelector(kAudioDevicePropertyBufferFrameSizeRange)
	/// The property selector `kAudioDevicePropertyUsesVariableBufferFrameSizes`
	public static let usesVariableBufferFrameSizes = AudioObjectSelector(kAudioDevicePropertyUsesVariableBufferFrameSizes)
	/// The property selector `kAudioDevicePropertyIOCycleUsage`
	public static let ioCycleUsage = AudioObjectSelector(kAudioDevicePropertyIOCycleUsage)
	/// The property selector `kAudioDevicePropertyStreamConfiguration`
	public static let streamConfiguration = AudioObjectSelector(kAudioDevicePropertyStreamConfiguration)
	/// The property selector `kAudioDevicePropertyIOProcStreamUsage`
	public static let ioProcStreamUsage = AudioObjectSelector(kAudioDevicePropertyIOProcStreamUsage)
	/// The property selector `kAudioDevicePropertyActualSampleRate`
	public static let actualSampleRate = AudioObjectSelector(kAudioDevicePropertyActualSampleRate)
	/// The property selector `kAudioDevicePropertyClockDevice`
	public static let clockDevice = AudioObjectSelector(kAudioDevicePropertyClockDevice)
	/// The property selector `kAudioDevicePropertyIOThreadOSWorkgroup`
	public static let ioThreadOSWorkgroup = AudioObjectSelector(kAudioDevicePropertyIOThreadOSWorkgroup)
	/// The property selector `kAudioDevicePropertyProcessMute`
	public static let processMute = AudioObjectSelector(kAudioDevicePropertyProcessMute)

	/// The property selector `kAudioDevicePropertyJackIsConnected`
	public static let jackIsConnected = AudioObjectSelector(kAudioDevicePropertyJackIsConnected)
	/// The property selector `kAudioDevicePropertyVolumeScalar`
	public static let volumeScalar = AudioObjectSelector(kAudioDevicePropertyVolumeScalar)
	/// The property selector `kAudioDevicePropertyVolumeDecibels`
	public static let volumeDecibels = AudioObjectSelector(kAudioDevicePropertyVolumeDecibels)
	/// The property selector `kAudioDevicePropertyVolumeRangeDecibels`
	public static let volumeRangeDecibels = AudioObjectSelector(kAudioDevicePropertyVolumeRangeDecibels)
	/// The property selector `kAudioDevicePropertyVolumeScalarToDecibels`
	public static let volumeScalarToDecibels = AudioObjectSelector(kAudioDevicePropertyVolumeScalarToDecibels)
	/// The property selector `kAudioDevicePropertyVolumeDecibelsToScalar`
	public static let volumeDecibelsToScalar = AudioObjectSelector(kAudioDevicePropertyVolumeDecibelsToScalar)
	/// The property selector `kAudioDevicePropertyStereoPan`
	public static let stereoPan = AudioObjectSelector(kAudioDevicePropertyStereoPan)
	/// The property selector `kAudioDevicePropertyStereoPanChannels`
	public static let stereoPanChannels = AudioObjectSelector(kAudioDevicePropertyStereoPanChannels)
	/// The property selector `kAudioDevicePropertyMute`
	public static let mute = AudioObjectSelector(kAudioDevicePropertyMute)
	/// The property selector `kAudioDevicePropertySolo`
	public static let solo = AudioObjectSelector(kAudioDevicePropertySolo)
	/// The property selector `kAudioDevicePropertyPhantomPower`
	public static let phantomPower = AudioObjectSelector(kAudioDevicePropertyPhantomPower)
	/// The property selector `kAudioDevicePropertyPhaseInvert`
	public static let phaseInvert = AudioObjectSelector(kAudioDevicePropertyPhaseInvert)
	/// The property selector `kAudioDevicePropertyClipLight`
	public static let clipLight = AudioObjectSelector(kAudioDevicePropertyClipLight)
	/// The property selector `kAudioDevicePropertyTalkback`
	public static let talkback = AudioObjectSelector(kAudioDevicePropertyTalkback)
	/// The property selector `kAudioDevicePropertyListenback`
	public static let listenback = AudioObjectSelector(kAudioDevicePropertyListenback)
	/// The property selector `kAudioDevicePropertyDataSource`
	public static let dataSource = AudioObjectSelector(kAudioDevicePropertyDataSource)
	/// The property selector `kAudioDevicePropertyDataSources`
	public static let dataSources = AudioObjectSelector(kAudioDevicePropertyDataSources)
	/// The property selector `kAudioDevicePropertyDataSourceNameForIDCFString`
	public static let dataSourceNameForID = AudioObjectSelector(kAudioDevicePropertyDataSourceNameForIDCFString)
	/// The property selector `kAudioDevicePropertyDataSourceKindForID`
	public static let dataSourceKindForID = AudioObjectSelector(kAudioDevicePropertyDataSourceKindForID)
	/// The property selector `kAudioDevicePropertyClockSource`
	public static let clockSource = AudioObjectSelector(kAudioDevicePropertyClockSource)
	/// The property selector `kAudioDevicePropertyClockSources`
	public static let clockSources = AudioObjectSelector(kAudioDevicePropertyClockSources)
	/// The property selector `kAudioDevicePropertyClockSourceNameForIDCFString`
	public static let clockSourceNameForID = AudioObjectSelector(kAudioDevicePropertyClockSourceNameForIDCFString)
	/// The property selector `kAudioDevicePropertyClockSourceKindForID`
	public static let clockSourceKindForID = AudioObjectSelector(kAudioDevicePropertyClockSourceKindForID)
	/// The property selector `kAudioDevicePropertyPlayThru`
	public static let playThru = AudioObjectSelector(kAudioDevicePropertyPlayThru)
	/// The property selector `kAudioDevicePropertyPlayThruSolo`
	public static let playThruSolo = AudioObjectSelector(kAudioDevicePropertyPlayThruSolo)
	/// The property selector `kAudioDevicePropertyPlayThruVolumeScalar`
	public static let playThruVolumeScalar = AudioObjectSelector(kAudioDevicePropertyPlayThruVolumeScalar)
	/// The property selector `kAudioDevicePropertyPlayThruVolumeDecibels`
	public static let playThruVolumeDecibels = AudioObjectSelector(kAudioDevicePropertyPlayThruVolumeDecibels)
	/// The property selector `kAudioDevicePropertyPlayThruVolumeRangeDecibels`
	public static let playThruVolumeRangeDecibels = AudioObjectSelector(kAudioDevicePropertyPlayThruVolumeRangeDecibels)
	/// The property selector `kAudioDevicePropertyPlayThruVolumeScalarToDecibels`
	public static let playThruVolumeScalarToDecibels = AudioObjectSelector(kAudioDevicePropertyPlayThruVolumeScalarToDecibels)
	/// The property selector `kAudioDevicePropertyPlayThruVolumeDecibelsToScalar`
	public static let playThruVolumeDecibelsToScalar = AudioObjectSelector(kAudioDevicePropertyPlayThruVolumeDecibelsToScalar)
	/// The property selector `kAudioDevicePropertyPlayThruStereoPan`
	public static let playThruStereoPan = AudioObjectSelector(kAudioDevicePropertyPlayThruStereoPan)
	/// The property selector `kAudioDevicePropertyPlayThruStereoPanChannels`
	public static let playThruStereoPanChannels = AudioObjectSelector(kAudioDevicePropertyPlayThruStereoPanChannels)
	/// The property selector `kAudioDevicePropertyPlayThruDestination`
	public static let playThruDestination = AudioObjectSelector(kAudioDevicePropertyPlayThruDestination)
	/// The property selector `kAudioDevicePropertyPlayThruDestinations`
	public static let playThruDestinations = AudioObjectSelector(kAudioDevicePropertyPlayThruDestinations)
	/// The property selector `kAudioDevicePropertyPlayThruDestinationNameForIDCFString`
	public static let playThruDestinationNameForID = AudioObjectSelector(kAudioDevicePropertyPlayThruDestinationNameForIDCFString)
	/// The property selector `kAudioDevicePropertyChannelNominalLineLevel`
	public static let channelNominalLineLevel = AudioObjectSelector(kAudioDevicePropertyChannelNominalLineLevel)
	/// The property selector `kAudioDevicePropertyChannelNominalLineLevels`
	public static let channelNominalLineLevels = AudioObjectSelector(kAudioDevicePropertyChannelNominalLineLevels)
	/// The property selector `kAudioDevicePropertyChannelNominalLineLevelNameForIDCFString`
	public static let channelNominalLineLevelNameForID = AudioObjectSelector(kAudioDevicePropertyChannelNominalLineLevelNameForIDCFString)
	/// The property selector `kAudioDevicePropertyHighPassFilterSetting`
	public static let highPassFilterSetting = AudioObjectSelector(kAudioDevicePropertyHighPassFilterSetting)
	/// The property selector `kAudioDevicePropertyHighPassFilterSettings`
	public static let highPassFilterSettings = AudioObjectSelector(kAudioDevicePropertyHighPassFilterSettings)
	/// The property selector `kAudioDevicePropertyHighPassFilterSettingNameForIDCFString`
	public static let highPassFilterSettingNameForID = AudioObjectSelector(kAudioDevicePropertyHighPassFilterSettingNameForIDCFString)
	/// The property selector `kAudioDevicePropertySubVolumeScalar`
	public static let subVolumeScalar = AudioObjectSelector(kAudioDevicePropertySubVolumeScalar)
	/// The property selector `kAudioDevicePropertySubVolumeDecibels`
	public static let subVolumeDecibels = AudioObjectSelector(kAudioDevicePropertySubVolumeDecibels)
	/// The property selector `kAudioDevicePropertySubVolumeRangeDecibels`
	public static let subVolumeRangeDecibels = AudioObjectSelector(kAudioDevicePropertySubVolumeRangeDecibels)
	/// The property selector `kAudioDevicePropertySubVolumeScalarToDecibels`
	public static let subVolumeScalarToDecibels = AudioObjectSelector(kAudioDevicePropertySubVolumeScalarToDecibels)
	/// The property selector `kAudioDevicePropertySubVolumeDecibelsToScalar`
	public static let subVolumeDecibelsToScalar = AudioObjectSelector(kAudioDevicePropertySubVolumeDecibelsToScalar)
	/// The property selector `kAudioDevicePropertySubMute`
	public static let subMute = AudioObjectSelector(kAudioDevicePropertySubMute)
	/// The property selector `kAudioDevicePropertyVoiceActivityDetectionEnable`
	@available(macOS 14, *)
	public static let voiceActivityDetectionEnable = AudioObjectSelector(kAudioDevicePropertyVoiceActivityDetectionEnable)
	/// The property selector `kAudioDevicePropertyVoiceActivityDetectionState`
	@available(macOS 14, *)
	public static let voiceActivityDetectionState = AudioObjectSelector(kAudioDevicePropertyVoiceActivityDetectionState)
}

// MARK: -

/// Creates and returns an initialized `AudioDevice` or subclass.
func makeAudioDevice(_ objectID: AudioObjectID) throws -> AudioDevice {
	guard objectID != kAudioObjectSystemObject else {
		os_log(.error, log: audioObjectLog, "kAudioObjectSystemObject is not a valid audio device object id")
		throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadObjectError))
	}

	let objectClass = try AudioObject.getClass(objectID)

	switch objectClass {
	case kAudioDeviceClassID: 			return AudioDevice(objectID)
	case kAudioAggregateDeviceClassID: 	return AudioAggregateDevice(objectID)
	case kAudioEndPointDeviceClassID:	return AudioEndpointDevice(objectID)
	case kAudioEndPointClassID:			return AudioEndpoint(objectID)
	case kAudioSubDeviceClassID:		return AudioSubdevice(objectID)
	default:
		os_log(.debug, log: audioObjectLog, "Unknown audio device class '%{public}@' for audio object 0x%{public}@", objectClass.fourCC, objectID.hexString)
		return AudioDevice(objectID)
	}
}
