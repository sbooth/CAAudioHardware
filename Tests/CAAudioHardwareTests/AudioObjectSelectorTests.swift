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
}
