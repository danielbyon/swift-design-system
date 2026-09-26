# Application Integration

Use the package to define how app-owned values are represented and resolved. Keep product meaning
and the concrete design system in the application.

## Keep token vocabularies in the app

Each token family is a finite app-owned Swift type that conforms to its corresponding token
protocol. A case names a design decision, such as `screenInset` or `primaryText`; it is not a
string key and does not move the vocabulary into the package.

Conform one immutable concrete value to the capabilities the application uses. For example, a
spacing-only capability can be implemented directly:

```swift
enum AppSpacing: SpacingToken {
    case screenInset
}

struct AppDesignSystem: SpacingDesignSystem {
    typealias Spacing = AppSpacing

    static let standard = Self()

    func spacing(for token: Spacing) -> CGFloat {
        switch token {
        case .screenInset: 24
        }
    }
}
```

The complete example app expands this pattern to spacing, dimensions, sizes, corner radii, stroke
widths, opacity, primitive and semantic colors, and semantic gradients. Its ``GradientTheme`` owns
the one ``ColorTheme`` used for both semantic color lookup and gradient stops. A gradient therefore
references semantic color roles rather than defining a second primitive palette.

Use exhaustive switches for finite token mappings. When a token case is added, the compiler points
to mappings that need an intentional value. Keep the aggregate concrete and immutable; the package
does not provide a global current design system or a runtime theme selector.

## Give SwiftUI an app-owned environment entry

SwiftUI environment keys belong beside the app's concrete design system. The key can default to a
standard immutable value, and shared feature views can read that typed value at one feature seam:

```swift
private struct AppDesignSystemKey: EnvironmentKey {
    static let defaultValue = AppDesignSystem.standard
}

extension EnvironmentValues {
    var appDesignSystem: AppDesignSystem {
        get { self[AppDesignSystemKey.self] }
        set { self[AppDesignSystemKey.self] = newValue }
    }
}

struct FeatureView: View {
    @Environment(\.appDesignSystem) private var designSystem

    var body: some View {
        Text("Account")
            .padding(designSystem.spacing(for: .screenInset))
    }
}
```

This keeps SwiftUI environment ownership with the feature that needs it. The package stays usable
from non-SwiftUI code and does not own an environment key or an application default.

## Resolve once and inject into native views

Feature code that bridges to UIKit or AppKit should pass resolved values through explicit
initializers. The native adapter receives a platform color or ``DesignGradient``; it does not query
SwiftUI's environment or recreate token mappings.

```swift
let accent = designSystem.color(for: .accent)
let gradient = designSystem.gradient(for: .hero)

NativeAccentLabel(color: accent.adaptivePlatformColor)
NativeGradientView(gradient: gradient)
```

Use `adaptivePlatformColor` only in the UIKit or AppKit branches where that property is available.
The color and gradient still come from the same app-owned design system that SwiftUI uses. A native
adapter is a rendering bridge, not another theme.

Keep app assets in the consuming app's asset catalogs and target resources. The package does not
bundle or name those resources. The example keeps its asset-backed primitive alongside its five
application hosts.

## Let appearance-aware sources follow the system

``DesignColor`` retains a light and dark native source. SwiftUI style rendering uses the current
color-scheme environment; native dynamic colors select the semantic source from UIKit traits or the
AppKit effective appearance. The selected primitive may itself remain dynamic, as with an asset
catalog color or a system color.

For SwiftUI-only contexts such as watchOS, use the adaptive shape-style path or explicitly resolve
with a SwiftUI `EnvironmentValues` value. The package does not promise a context-free adaptive
`UIColor`/`NSColor` on watchOS; ``DesignColor/adaptivePlatformColor`` is conditionally available
only where UIKit outside watchOS or AppKit can supply that behavior.

## Keep resolution predictable under concurrency

Capability resolution is synchronous and nonthrowing. Keep mapping closures deterministic,
side-effect-free, and inexpensive. The public token protocols and immutable resolved values use
`Sendable` where their contracts allow it. UI rendering adapters are main-actor work; token enums
and the design-system model do not need main-actor isolation.

## Know which layer enforces each rule

The package combines several kinds of guarantees. They serve different purposes:

| Layer | What it guarantees | What it does not guarantee |
| --- | --- | --- |
| Swift compiler | Concrete associated token types, protocol conformance, `Sendable` checking, and exhaustive switches over finite vocabularies. | That an app-authored number follows a visual convention or that a palette has sufficient contrast. |
| `DesignSystemTestSupport` | Test issues for the documented scalar expectations and smoke coverage of public color and gradient paths. | Production mutation, an exhaustive visual review, or policy beyond the validator's stated checks. |
| Color and gradient value construction | Debug assertions and deterministic release recovery for malformed numeric color channels and gradient geometry or stops, as documented by each API. | Sanitization of app-authored scalar resolvers or validation of product-specific color choices. |
| Consumer conventions and lint | Additional app policy, such as contrast targets, preferred spacing scales, or naming rules. | Compiler guarantees unless the convention is expressed as code or tooling. |

Scalar resolvers return app-authored values unchanged. TestSupport expects finite spacing; finite,
nonnegative dimensions, size components, corner radii, and stroke widths; and finite opacity values
within `0...1`. Those expectations are test feedback, not hidden production clamping.
