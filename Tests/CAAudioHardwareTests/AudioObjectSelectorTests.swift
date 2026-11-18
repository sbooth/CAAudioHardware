//
// SPDX-FileCopyrightText: 2026 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import XCTest
import CoreAudio
@testable import CAAudioHardware

final class AudioObjectSelectorTests: XCTestCase {
	// MARK: - Inheritance

	func testSubclassesInheritSuperclassSelectors() {
		// AudioAggregateDevice → AudioDevice → AudioClockDevice → AudioObject
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.fullSubDeviceList.rawValue, kAudioAggregateDevicePropertyFullSubDeviceList)
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.streams.rawValue, kAudioDevicePropertyStreams)
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.clockDomain.rawValue, kAudioDevicePropertyClockDomain)
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.name.rawValue, kAudioObjectPropertyName)

		// MuteControl → BooleanControl → AudioControl → AudioObject, with no selectors of its own
		XCTAssertEqual(AudioObjectSelector<MuteControl>.value.rawValue, kAudioBooleanControlPropertyValue)
		XCTAssertEqual(AudioObjectSelector<MuteControl>.scope.rawValue, kAudioControlPropertyScope)
		XCTAssertEqual(AudioObjectSelector<MuteControl>.name.rawValue, kAudioObjectPropertyName)

		// VolumeControl → LevelControl → AudioControl → AudioObject
		XCTAssertEqual(AudioObjectSelector<VolumeControl>.scalarValue.rawValue, kAudioLevelControlPropertyScalarValue)
		XCTAssertEqual(AudioObjectSelector<VolumeControl>.element.rawValue, kAudioControlPropertyElement)
	}

	// MARK: - Selectors declared by both a class and a superclass

	func testSubclassSelectorIsUsedWhenNamesMatch() {
		// kAudioDevicePropertyDeviceUID ('uid ') and kAudioClockDevicePropertyDeviceUID ('cuid') differ
		XCTAssertEqual(AudioObjectSelector<AudioClockDevice>.deviceUID.rawValue, kAudioClockDevicePropertyDeviceUID)
		XCTAssertEqual(AudioObjectSelector<AudioDevice>.deviceUID.rawValue, kAudioDevicePropertyDeviceUID)
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.deviceUID.rawValue, kAudioDevicePropertyDeviceUID)

		XCTAssertEqual(AudioObjectSelector<AudioDevice>.clockDevice.rawValue, kAudioDevicePropertyClockDevice)
		XCTAssertEqual(AudioObjectSelector<AudioAggregateDevice>.clockDevice.rawValue, kAudioAggregateDevicePropertyClockDevice)

		XCTAssertEqual(AudioObjectSelector<AudioClockDevice>.latency.rawValue, kAudioClockDevicePropertyLatency)
		XCTAssertEqual(AudioObjectSelector<AudioDevice>.latency.rawValue, kAudioDevicePropertyLatency)
	}

	// MARK: - Methods on real objects

	func testSystemSelectors() throws {
		XCTAssertTrue(AudioSystem.instance.hasSelector(.devices))
		XCTAssertEqual(AudioSystem.instance.hasSelector(.name), AudioSystem.instance.hasProperty(PropertyAddress(kAudioObjectPropertyName)))
		_ = try AudioSystem.instance.isSelectorSettable(.processIsAudible)
	}

	func testDeviceSelectors() throws {
		guard let device = try AudioDevice.devices.first else {
			throw XCTSkip("No audio devices")
		}

		// Resolves to kAudioDevicePropertyDeviceUID; devices do not support kAudioClockDevicePropertyDeviceUID
		XCTAssertTrue(device.hasSelector(.deviceUID))
		XCTAssertFalse((device as AudioClockDevice).hasSelector(.deviceUID))

		XCTAssertTrue(device.hasSelector(.nominalSampleRate))
		XCTAssertTrue(device.hasSelector(.name))

		// Device scopes
		XCTAssertEqual(device.hasSelector(.streams, inScope: .global), device.hasProperty(PropertyAddress(kAudioDevicePropertyStreams)))
		_ = device.hasSelector(.streams, inScope: .output, onElement: .main)

		let observation = try device.observe(.nominalSampleRate) { _ in }
		try observation.invalidate()
		let scopedObservation = try device.observe(.streams, inScope: .output) { _ in }
		try scopedObservation.invalidate()
	}

	func testProcessScopes() throws {
		guard #available(macOS 14.2, *) else {
			throw XCTSkip("Audio processes require macOS 14.2")
		}
		guard let process = try AudioProcess.processes.first else {
			throw XCTSkip("No audio processes")
		}

		// kAudioProcessPropertyDevices is read per direction
		for scope in [PropertyScope.input, .output] {
			XCTAssertEqual(process.hasSelector(.devices, inScope: scope), process.hasProperty(PropertyAddress(PropertySelector(kAudioProcessPropertyDevices), scope: scope)))
		}
		XCTAssertEqual(process.hasSelector(.devices), process.hasProperty(PropertyAddress(PropertySelector(kAudioProcessPropertyDevices))))

		let observation = try process.observe(.devices, inScope: .output) { _ in }
		try observation.invalidate()
	}

	func testScopeAndElementDefaults() throws {
		guard let device = try AudioDevice.devices.first else {
			throw XCTSkip("No audio devices")
		}
		let elementName = PropertySelector(kAudioObjectPropertyElementName)

		// Element only: the scope defaults to global
		XCTAssertEqual(device.hasSelector(.elementName, onElement: 1), device.hasProperty(PropertyAddress(elementName, element: 1)))
		// Scope only: the element defaults to main
		XCTAssertEqual(device.hasSelector(.elementName, inScope: .output), device.hasProperty(PropertyAddress(elementName, scope: .output)))
		// Both
		XCTAssertEqual(device.hasSelector(.elementName, inScope: .output, onElement: 1), device.hasProperty(PropertyAddress(elementName, scope: .output, element: 1)))

		// A value statically typed as AudioObject still accepts a scope and element
		let object: AudioObject = device
		XCTAssertEqual(object.hasSelector(.elementName, inScope: .output, onElement: 1), device.hasProperty(PropertyAddress(elementName, scope: .output, element: 1)))

		// Every call shape for the queue and main actor variants
		let queue = DispatchQueue(label: "AudioObjectSelectorTests")
		try device.observe(.elementName, onElement: 1) { _ in }.invalidate()
		try device.observe(.elementName, onElement: 1, queue: queue) { _ in }.invalidate()
		try device.observe(.elementName, inScope: .output, queue: queue) { _ in }.invalidate()
		try device.observeOnMainActor(.elementName, onElement: 1) { _ in }.invalidate()
	}

	// MARK: - Stored selectors typed as a superclass

	func testStoredSuperclassSelectorOnDevice() throws {
		guard let device = try AudioDevice.devices.first else {
			throw XCTSkip("No audio devices")
		}
		let name: AudioObjectSelector<AudioObject> = .name
		XCTAssertEqual(name.isSupported(by: device), device.hasSelector(.name))
		XCTAssertEqual(name.isSupported(by: device, inScope: .output, onElement: 1), device.hasSelector(.name, inScope: .output, onElement: 1))
	}

	func testStoredSuperclassSelectorOnAggregateDevice() throws {
		// A stored AudioObjectSelector<AudioDevice> used with an AudioAggregateDevice; the calls below
		// only compile if the selector-first forms accept subclass instances
		let streams: AudioObjectSelector<AudioDevice> = .streams

		guard let aggregate = try AudioDevice.devices.lazy.compactMap({ $0 as? AudioAggregateDevice }).first else {
			throw XCTSkip("No aggregate devices")
		}

		XCTAssertEqual(streams.isSupported(by: aggregate), aggregate.hasSelector(.streams))
		XCTAssertEqual(streams.isSupported(by: aggregate, inScope: .output), aggregate.hasSelector(.streams, inScope: .output))
		if streams.isSupported(by: aggregate) {
			XCTAssertEqual(try streams.isSettable(on: aggregate), try aggregate.isSelectorSettable(.streams))
		}

		let queue = DispatchQueue(label: "AudioObjectSelectorTests")
		try streams.observe(on: aggregate) { _ in }.invalidate()
		try streams.observe(on: aggregate, inScope: .output, queue: queue) { _ in }.invalidate()
		try streams.observeOnMainActor(on: aggregate) { _ in }.invalidate()
		_ = streams.changes(on: aggregate)
		_ = streams.values(on: aggregate, inScope: .output) { true }
	}
}
