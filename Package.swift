// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "CAAudioHardware",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "CAAudioHardware",
			targets: ["CAAudioHardware"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "CAAudioHardware",
			linkerSettings: [
				.linkedFramework("CoreAudio"),
				.linkedFramework("AVFAudio"),
			]),
		.testTarget(
			name: "CAAudioHardwareTests",
			dependencies: ["CAAudioHardware"]),
	]
)
