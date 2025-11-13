// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutfitPickerCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "OutfitPickerCore", targets: ["OutfitPickerCore"]),
    ],
    targets: [
        .target(name: "OutfitPickerCore"),
        .testTarget(
            name: "OutfitPickerCoreTests",
            dependencies: ["OutfitPickerCore"]
        ),
    ]
)
