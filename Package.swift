// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-design-system",
    platforms: [
        .iOS(.v27),
        .macOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "DesignSystemTestSupport", targets: ["DesignSystemTestSupport"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.19.6"
        ),
    ],
    targets: [
        .target(name: "DesignSystem"),
        .target(
            name: "DesignSystemTestSupport",
            dependencies: ["DesignSystem"]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem", "DesignSystemTestSupport"]
        ),
        .testTarget(
            name: "DesignSystemSnapshotTests",
            dependencies: [
                "DesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__", "README.md"]
        ),
    ],
    // Swift 6 language mode enforces complete strict-concurrency checking.
    swiftLanguageModes: [.v6]
)
