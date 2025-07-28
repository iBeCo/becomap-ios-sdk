// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "becomap-ios-sdk",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "becomap-ios-sdk",
            targets: ["becomap"])
    ],
    targets: [
        .binaryTarget(
            name: "becomap",
            path: "Sources/becomap_ios.xcframework")
    ]
)
