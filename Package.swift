// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OrbitalLayout",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "OrbitalLayout", targets: ["OrbitalLayout"]),
    ],
    targets: [
        .target(
            name: "OrbitalLayout",
            dependencies: [],
            path: "Sources",
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "OrbitalLayoutTests",
            dependencies: ["OrbitalLayout"],
            path: "OrbitalLayoutTests"
        ),
    ]
)