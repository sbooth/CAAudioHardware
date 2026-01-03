// swift-tools-version: 6.0
//
// SPDX-FileCopyrightText: 2023 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import PackageDescription

let package = Package(
	name: "CAAudioHardware",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		.library(
			name: "CAAudioHardware",
			targets: [
				"CAAudioHardware",
			]),
	],
	dependencies: [
		.package(url: "https://github.com/sbooth/CoreAudioExtensions", from: "0.3.0"),
	],
	targets: [
		.target(
			name: "CAAudioHardware",
			dependencies: [
				.product(name: "CoreAudioExtensions", package: "CoreAudioExtensions"),
			],
			linkerSettings: [
				.linkedFramework("CoreAudio"),
				.linkedFramework("AVFAudio"),
			]),
		.testTarget(
			name: "CAAudioHardwareTests",
			dependencies: [
				"CAAudioHardware",
			]),
	]
)
