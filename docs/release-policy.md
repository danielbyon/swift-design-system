# Release policy

## Versioning

Semantic Versioning compatibility guarantees begin at `1.0.0`. A patch release contains
backward-compatible fixes; a minor release adds backward-compatible capabilities; and a major
release may make incompatible API or behavior changes. Increasing a supported platform's minimum
deployment version is a breaking change and requires a major release. A major release does not
require a prior deprecation cycle for removed or changed APIs.

Release tags use unprefixed `MAJOR.MINOR.PATCH` versions, such as `1.0.0`. Each published version is
distributed through a GitHub Release for its matching tag, with release notes describing user-visible
changes, compatibility or deployment-floor changes, and migration information where relevant.

## Dependencies

The shipping `DesignSystem` target has no external package dependencies. `DesignSystemTestSupport`
depends on `DesignSystem`. The package declares `swift-snapshot-testing` for the
`DesignSystemSnapshotTests` test target only; it is not a dependency of either shipping library
product. Keep snapshot-testing and other test-only dependencies out of the shipping `DesignSystem`
target.

`Package.swift` compatibility ranges govern dependency resolution for package consumers.
`Package.resolved` pins the dependency graph used to verify this repository. Changes to dependency
ranges or lockfile pins must be deliberate and verified through the full `make all` release gate.
Released package behavior must not depend on arbitrary dependency branches such as `main`; use
compatible version ranges for dependencies that affect released behavior.
