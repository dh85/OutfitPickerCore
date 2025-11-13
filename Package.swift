// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OutfitPickerCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "OutfitPickerCore", targets: ["OutfitPickerCore"])
    ],
    targets: [
        // Library
        .target(
            name: "OutfitPickerCore",
            path: "Sources/OutfitPickerCore"
        ),

        // Test Support — regular target (not testTarget)
        .target(
            name: "OutfitPickerTestSupport",
            dependencies: ["OutfitPickerCore"],
            path: "Sources/OutfitPickerTestSupport"   // or "Tests/OutfitPickerTestSupport" if you didn't move it
        ),

        // Tests
        .testTarget(
            name: "OutfitPickerCoreTests",
            dependencies: [
                "OutfitPickerCore",
                "OutfitPickerTestSupport"
            ],
            path: "Tests/OutfitPickerCoreTests"
        ),
    ]
)
