// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "Tide",
					  platforms: [.macOS(.v13)],
					  targets: [
					  	.executableTarget(name: "Tide",
											dependencies: [],
											swiftSettings: [.unsafeFlags(["-enable-bare-slash-regex"])]),
					  	.testTarget(name: "TideTests",
									  dependencies: ["Tide"]),
					  ])
