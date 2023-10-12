// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CAAudioHardware",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v12)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CAAudioHardware",
            targets: ["CAAudioHardware"]),
    ],
	dependencies: [
		.package(url: "https://github.com/sbooth/SFBAudioUtilities", branch: "spm")
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
			name: "CAAudioHardware",
			dependencies: [
				.product(name: "CoreAudioExtensions", package: "SFBAudioUtilities")
			]),
        .testTarget(
            name: "CAAudioHardwareTests",
            dependencies: ["CAAudioHardware"]),
    ]
)
