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
	targets: [
		.target(
			name: "CAAudioHardware",
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
