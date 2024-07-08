// swift-tools-version: 5.6
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
		.package(url: "https://github.com/sbooth/FourCC", from: "0.1.0"),
		.package(url: "https://github.com/sbooth/CoreAudioExtensions", from: "0.2.0"),
	],
	targets: [
		.target(
			name: "CAAudioHardware",
			dependencies: [
				.product(name: "FourCC", package: "FourCC"),
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
