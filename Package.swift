// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
