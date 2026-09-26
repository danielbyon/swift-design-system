# swift-design-system

`swift-design-system` provides reusable, strongly typed design-system mechanics for Apple apps.
Each app keeps ownership of its design vocabulary, values, themes, and visual identity.

## Platforms and toolchain

The package supports iOS and iPadOS 27 and later, including Mac Catalyst; macOS 27 and later; tvOS 27 and
later; watchOS 27 and later; and visionOS 27 and later. These deployment floors follow the latest
major Apple operating-system releases supported by the package. Only the current stable Xcode
toolchain is supported; the project does not maintain a historical Xcode compatibility matrix. Its
package manifest requires Swift tools 6.4, and the library is compiled in Swift 6 language mode with
strict concurrency checking.

## Add the package

After the 1.0.0 release is published, add the package to your app's `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/danielbyon/swift-design-system",
        from: "1.0.0"
    ),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "DesignSystem", package: "swift-design-system"),
        ]
    ),
    .testTarget(
        name: "MyAppTests",
        dependencies: [
            .product(name: "DesignSystem", package: "swift-design-system"),
            .product(name: "DesignSystemTestSupport", package: "swift-design-system"),
        ]
    ),
]
```

Import `DesignSystem` where app code defines and resolves design values. Import
`DesignSystemTestSupport` only in test targets that validate an app-owned design system.

## App-owned design systems

Define finite Swift token types and the mappings that give those tokens meaning in your app. Compose
the capabilities your app uses into an immutable design-system value, and keep theme and SwiftUI
environment integration with the app. The package provides the shared resolution mechanics and
native framework adapters; it does not supply app-specific token names, palettes, assets, or a
global current theme.

See the [application integration guide](Sources/DesignSystem/DesignSystem.docc/ApplicationIntegration.md)
for token and theme patterns, and the [DesignSystem API documentation](Sources/DesignSystem/DesignSystem.docc/DesignSystem.md).
For consumer-side validation, see the [DesignSystemTestSupport API documentation](Sources/DesignSystemTestSupport/DesignSystemTestSupport.docc/DesignSystemTestSupport.md)
and its [validation guide](Sources/DesignSystemTestSupport/DesignSystemTestSupport.docc/ValidationGuide.md).
The [example Xcode project](Examples/DesignSystemExamples.xcodeproj) shows the package used by
example apps across the supported Apple platforms.

## Release-readiness gate

Maintainers use `make all` as the single release-readiness command. It runs debug and release tests,
builds the platform examples including Mac Catalyst, runs the iOS/UIKit and macOS/AppKit snapshot
suites, and builds both public DocC catalogs.

## License and project policy

This project is available under the [MIT License](LICENSE). It is maintained by its owner, has no
consumer support channel, and does not accept external pull requests. GitHub Issues are used by the
maintainer to track engineering work; they are not a consumer support queue. Read the
[governance policy](docs/governance.md) and [release policy](docs/release-policy.md) before relying
on the project or its versioning guarantees.
