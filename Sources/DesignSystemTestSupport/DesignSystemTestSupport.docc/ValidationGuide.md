# Validating an App Design System

Import `DesignSystemTestSupport` in the app's test target and pass its concrete design-system value
to the validators for each capability it implements:

```swift
import DesignSystemTestSupport
import Testing

@Test
func designSystemValuesFollowTheirScalarContracts() {
    let designSystem = AppDesignSystem.standard

    validateSpacing(in: designSystem)
    validateDimensions(in: designSystem)
    validateSizes(in: designSystem)
    validateCornerRadii(in: designSystem)
    validateStrokeWidths(in: designSystem)
    validateOpacities(in: designSystem)
}
```

Call the color and gradient validators when the value conforms to those capabilities:

```swift
@Test
func designSystemColorAndGradientPathsCanResolve() {
    let designSystem = AppDesignSystem.standard

    validateColors(in: designSystem)
    validateGradients(in: designSystem)
}
```

Each helper checks the complete `CaseIterable` token set and records every issue it detects so one
test run can report several problems. The helpers exercise public APIs; they do not inspect private
mapping storage.

## Scalar expectations

| Validator | Expected resolved values |
| --- | --- |
| `validateSpacing(in:)` | Finite logical-point values. |
| `validateDimensions(in:)` | Finite, nonnegative logical-point values. |
| `validateSizes(in:)` | Finite, nonnegative width and height components in logical points. |
| `validateCornerRadii(in:)` | Finite, nonnegative logical-point values. |
| `validateStrokeWidths(in:)` | Finite, nonnegative logical-point values. |
| `validateOpacities(in:)` | Finite, unitless values in the inclusive `0...1` range. |

Scalar helpers only record Swift Testing issues. Production capability calls keep returning the
app-authored values unchanged, including values that fail these conventions.

## Color and gradient coverage

`validateColors(in:)` enumerates semantic color tokens, resolves light and dark appearances, and
exercises SwiftUI resolution plus context-free UIKit or AppKit adapters when the current platform
supports them. It does not impose a numeric range on app-authored native color sources.

`validateGradients(in:)` enumerates gradient tokens, resolves both appearances, and exercises
bounds-aware SwiftUI fills for linear, radial, and angular definitions. Generic SwiftUI style
resolution is also exercised for linear and angular gradients. A radial gradient needs rendered
bounds; its generic style path has a documented transparent fallback when bounds are unavailable.

On UIKit and AppKit platforms, `validateNativeGradients(in:)` is a separate `@MainActor` helper. It
draws each gradient into temporary images in light and dark appearances to smoke-test native
rendering. It does not compare pixels or require golden fixtures. Use it only from a test that can
run on the corresponding UI framework.

## Separate test expectations from production recovery

The compiler checks protocol conformance, concrete associated token types, and exhaustive mappings
where the app uses switches. These validators check only the stated value expectations and public
resolution paths. They do not clamp or repair scalar values.

Color and gradient constructors have their own documented debug assertions and deterministic release
recovery for malformed numeric inputs. That construction policy is separate from TestSupport. App
rules that go further, such as contrast ratios, branded color restrictions, or a preferred spacing
scale, belong in consumer tests, lint, or other app-owned tooling.
