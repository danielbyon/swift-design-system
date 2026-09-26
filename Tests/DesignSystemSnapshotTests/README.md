# Native rendering snapshots

This test target protects 16 representative images: UIKit and AppKit each render one adaptive semantic color and linear, radial, and angular gradients in light and dark appearances. It does not promise identical pixels across frameworks or toolchain generations.

The checked-in baseline is tied to **Xcode 27.0 (build 27A266a)**. SnapshotTesting 1.19.6 records images for comparison; UIKit renders at 64 × 64 points with a 1× display scale, and AppKit draws into an explicit 64 × 64 pixel device-RGB bitmap whose logical size is 64 × 64 points. Each case supplies its appearance directly.

Ordinary snapshot commands compare against existing references and default to `SnapshotTestingConfiguration.Record.never`. Missing or mismatched references fail. `make test` and `make release-test` filter to `DesignSystemTests`, so they keep the functional debug and release checks out of the snapshot target. `make all` runs both functional profiles, the existing example builds, and both native snapshot suites.

## Compare snapshots

Run `make snapshot-test-ios` for UIKit on the iOS Simulator and `make snapshot-test-macos` for AppKit on the macOS host. The default iOS destination is selected by stable name and OS version (`iPhone 18 Pro`, iOS 27.0); override `IOS_SNAPSHOT_DESTINATION` when a future Xcode image has a different simulator name or OS version.

## Re-record snapshots

Before re-recording, verify that `xcodebuild -version` reports Xcode 27.0 and build 27A266a. If the executing toolchain differs, stop and report the mismatch; do not describe images from another toolchain as this baseline. Review any intentional renderer or toolchain change and its visual output before updating references.

Run `make snapshot-record` to execute an explicit `.all` recording pass for both platforms, followed by a normal `.never` comparison pass for both platforms. SnapshotTesting 1.19.6 writes references during `.all` and reports failures asking for a rerun, so the recording pass is expected to return failures. The target's result is determined by the final comparison pass; it succeeds only when both platform suites compare cleanly.
