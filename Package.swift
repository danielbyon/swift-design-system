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
    ],
    // Swift 6 language mode enforces complete strict-concurrency checking.
    swiftLanguageModes: [.v6]
)
