import DesignSystem
import SwiftUI
import Synchronization
import Testing
import DesignSystemTestSupport
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private enum FixturePrimitiveColor: PrimitiveColorToken {
    case ink
    case paper
}

private enum FixtureSemanticColor: SemanticColorToken, Hashable {
    case text
    case surface
}

private typealias FixtureColorTheme = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>

private enum NumericPrimitiveColor: PrimitiveColorToken {
    case explicit
}

private enum NumericSemanticColor: SemanticColorToken {
    case content
}

private struct RGBAComponents: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

private func rgbaComponents(of color: PlatformColor) -> RGBAComponents {
    #if canImport(UIKit)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    precondition(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    return RGBAComponents(
        red: Double(red),
        green: Double(green),
        blue: Double(blue),
        alpha: Double(alpha)
    )
    #elseif canImport(AppKit)
    guard let color = color.usingColorSpace(.deviceRGB) else {
        preconditionFailure("The platform color must convert to device RGB for component checks.")
    }
    return RGBAComponents(
        red: Double(color.redComponent),
        green: Double(color.greenComponent),
        blue: Double(color.blueComponent),
        alpha: Double(color.alphaComponent)
    )
    #else
    preconditionFailure("Component checks require UIKit or AppKit.")
    #endif
}

private func expectComponents(
    of color: PlatformColor,
    red: Double,
    green: Double,
    blue: Double,
    alpha: Double,
    accuracy: Double = 0.000_01
) {
    let actual = rgbaComponents(of: color)
    #expect(abs(actual.red - red) < accuracy)
    #expect(abs(actual.green - green) < accuracy)
    #expect(abs(actual.blue - blue) < accuracy)
    #expect(abs(actual.alpha - alpha) < accuracy)
}

private func expectDisplayP3Components(
    of color: PlatformColor,
    red: Double,
    green: Double,
    blue: Double,
    alpha: Double
) {
    let cgColor = color.cgColor
    #expect(cgColor.colorSpace?.name == CGColorSpace.displayP3)
    guard let components = cgColor.components, components.count == 4 else {
        Issue.record("A Display P3 color must expose four components.")
        return
    }
    #expect(abs(Double(components[0]) - red) < 0.000_01)
    #expect(abs(Double(components[1]) - green) < 0.000_01)
    #expect(abs(Double(components[2]) - blue) < 0.000_01)
    #expect(abs(Double(components[3]) - alpha) < 0.000_01)
}

private func expectSRGBColorSpace(_ color: PlatformColor) {
    #expect(color.cgColor.colorSpace?.name == CGColorSpace.sRGB)
}

private struct FixtureColorDesignSystem: ColorDesignSystem {
    let colorTheme: FixtureColorTheme

    init(
        onResolveSemantic: @escaping @Sendable (FixtureSemanticColor) -> Void = { _ in }
    ) {
        colorTheme = ColorTheme(
            primitiveColor: primitiveColor(for:),
            semanticColor: { (token, palette) -> FixtureColorTheme.ConstructionColor in
                onResolveSemantic(token)
                return switch token {
                case .text:
                    palette.color(light: .ink, dark: .paper)
                case .surface:
                    palette.color(light: .paper, dark: .ink)
                }
            }
        )
    }
}

private func primitiveColor(for token: FixturePrimitiveColor) -> PlatformColor {
    #if canImport(UIKit)
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    }
    #elseif canImport(AppKit)
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    }
    #else
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    }
    #endif
}

private func resolvedNumericColor(_ color: NumericColor) -> PlatformColor {
    let theme = ColorTheme<NumericPrimitiveColor, NumericSemanticColor>(
        primitiveColor: { _ in color.platformColor },
        semanticColor: { _, palette in palette.color(.explicit) }
    )
    return theme.color(for: .content).resolve(for: .light)
}

@Test
func numericColorFactoriesPreserveTheirColorSpacesThroughSemanticResolution() {
    let theme = ColorTheme<NumericPrimitiveColor, NumericSemanticColor>(
        primitiveColor: { _ in
            NumericColor.sRGB(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8).platformColor
        },
        semanticColor: { _, palette in palette.color(.explicit) }
    )

    let resolved = theme.color(for: .content)

    expectComponents(of: resolved.resolve(for: .light), red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
    expectComponents(of: resolved.resolve(for: .dark), red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
    expectSRGBColorSpace(resolved.resolve(for: .light))
    expectSRGBColorSpace(resolved.resolve(for: .dark))

    let displayP3 = resolvedNumericColor(NumericColor.displayP3(
        red: 0.15,
        green: 0.35,
        blue: 0.75,
        alpha: 0.65
    ))
    expectDisplayP3Components(of: displayP3, red: 0.15, green: 0.35, blue: 0.75, alpha: 0.65)

    let grayscale = resolvedNumericColor(NumericColor.grayscale(white: 0.42, alpha: 0.7))
    expectComponents(of: grayscale, red: 0.42, green: 0.42, blue: 0.42, alpha: 0.7)
}

@Test
func numericColorHexFactoriesDecodeTheirDocumentedUInt32BitRanges() {
    let rgb = resolvedNumericColor(NumericColor.hexRGB(0xAB12_3456))
    expectSRGBColorSpace(rgb)
    expectComponents(
        of: rgb,
        red: 0x12 / 255,
        green: 0x34 / 255,
        blue: 0x56 / 255,
        alpha: 1
    )

    let rgba = resolvedNumericColor(NumericColor.hexRGBA(0x12_3456_78))
    expectSRGBColorSpace(rgba)
    expectComponents(
        of: rgba,
        red: 0x12 / 255,
        green: 0x34 / 255,
        blue: 0x56 / 255,
        alpha: 0x78 / 255
    )
}

#if !DEBUG
@Test
func numericColorClampsFiniteOutOfRangeChannelsInRelease() {
    let srgbBelow = resolvedNumericColor(
        NumericColor.sRGB(red: -0.25, green: 1.25, blue: -0.5, alpha: -0.25)
    )
    expectComponents(of: srgbBelow, red: 0, green: 1, blue: 0, alpha: 0)

    let srgbAbove = resolvedNumericColor(
        NumericColor.sRGB(red: 1.5, green: -0.5, blue: 1.25, alpha: 1.5)
    )
    expectComponents(of: srgbAbove, red: 1, green: 0, blue: 1, alpha: 1)

    let displayP3 = resolvedNumericColor(NumericColor.displayP3(
        red: -0.5,
        green: 1.5,
        blue: 1.25,
        alpha: -0.5
    ))
    expectDisplayP3Components(of: displayP3, red: 0, green: 1, blue: 1, alpha: 0)

    expectComponents(
        of: resolvedNumericColor(NumericColor.grayscale(white: -0.5, alpha: 1.5)),
        red: 0,
        green: 0,
        blue: 0,
        alpha: 1
    )
    expectComponents(
        of: resolvedNumericColor(NumericColor.grayscale(white: 1.5, alpha: -0.5)),
        red: 1,
        green: 1,
        blue: 1,
        alpha: 0
    )
}

@Test
func numericColorRecoversNonfiniteChannelsInRelease() {
    let srgb = resolvedNumericColor(
        NumericColor.sRGB(red: .nan, green: .infinity, blue: -.infinity, alpha: .nan)
    )
    expectComponents(of: srgb, red: 0, green: 0, blue: 0, alpha: 1)

    let displayP3 = resolvedNumericColor(NumericColor.displayP3(
        red: .infinity,
        green: .nan,
        blue: -.infinity,
        alpha: .infinity
    ))
    expectDisplayP3Components(of: displayP3, red: 0, green: 0, blue: 0, alpha: 1)

    let grayscale = resolvedNumericColor(NumericColor.grayscale(white: .nan, alpha: .infinity))
    expectComponents(of: grayscale, red: 0, green: 0, blue: 0, alpha: 1)
}
#endif

private struct NonHashablePrimitiveColor: PrimitiveColorToken {
    let value: Int

    static var allCases: [Self] { [Self(value: 0)] }
}

private struct NonHashableSemanticColor: SemanticColorToken {
    let value: Int

    static var allCases: [Self] { [Self(value: 0)] }
}

@Test
func colorThemeResolvesEverySemanticTokenForBothAppearances() {
    let designSystem = FixtureColorDesignSystem()

    for token in FixtureSemanticColor.allCases {
        let designColor = designSystem.color(for: token)
        switch token {
        case .text:
            #expect(designColor.resolve(for: .light) == .black)
            #expect(designColor.resolve(for: .dark) == .white)
        case .surface:
            #expect(designColor.resolve(for: .light) == .white)
            #expect(designColor.resolve(for: .dark) == .black)
        }
    }
}

@Test
func colorValidatorCoversTheCompleteSemanticVocabulary() {
    let observedTokens = Mutex<Set<FixtureSemanticColor>>([])
    let designSystem = FixtureColorDesignSystem { token in
        _ = observedTokens.withLock { $0.insert(token) }
    }

    validateColors(in: designSystem)

    let coveredTokens = observedTokens.withLock { $0 }
    #expect(Set(FixtureSemanticColor.allCases).isSubset(of: coveredTokens))
}

@Test
func designColorAdaptsAsASwiftUIShapeStyle() {
    let designColor = FixtureColorDesignSystem().color(for: .text)

    var lightEnvironment = EnvironmentValues()
    lightEnvironment.colorScheme = .light
    var darkEnvironment = EnvironmentValues()
    darkEnvironment.colorScheme = .dark

    let lightStyle = designColor.resolve(in: lightEnvironment)
    let darkStyle = designColor.resolve(in: darkEnvironment)
    let explicitLightColor = designColor.swiftUIColor(for: .light)
    let explicitDarkColor = designColor.swiftUIColor(for: .dark)
    let renderedShape = Rectangle().fill(designColor)

    #expect(explicitLightColor == swiftUIColor(black: true))
    #expect(explicitDarkColor == swiftUIColor(black: false))
    #expect(lightStyle == swiftUIColor(black: true))
    #expect(darkStyle == swiftUIColor(black: false))
    #expect(lightStyle == explicitLightColor)
    #expect(darkStyle == explicitDarkColor)
    _ = renderedShape
}

private func swiftUIColor(black: Bool) -> Color {
    #if canImport(UIKit)
    Color(uiColor: black ? .black : .white)
    #elseif canImport(AppKit)
    Color(nsColor: black ? .black : .white)
    #else
    black ? .black : .white
    #endif
}

@Test
func colorTokenMarkersDoNotRequireHashableOrRawValueIdentity() {
    let theme = ColorTheme<NonHashablePrimitiveColor, NonHashableSemanticColor>(
        primitiveColor: { _ in .black },
        semanticColor: { _, palette in
            palette.color(NonHashablePrimitiveColor(value: 0))
        }
    )

    let resolved = theme.color(for: NonHashableSemanticColor(value: 0))

    #expect(resolved.resolve(for: .light) == .black)
    #expect(resolved.resolve(for: .dark) == .black)
}

#if canImport(UIKit)
@Test
func adaptivePlatformColorSelectsTheUIKitTraitVariant() {
    let adaptiveColor = FixtureColorDesignSystem().color(for: .text).adaptivePlatformColor
    let lightColor = adaptiveColor.resolvedColor(
        with: UITraitCollection(userInterfaceStyle: .light)
    )
    let darkColor = adaptiveColor.resolvedColor(
        with: UITraitCollection(userInterfaceStyle: .dark)
    )

    #expect(lightColor.isEqual(UIColor.black))
    #expect(darkColor.isEqual(UIColor.white))
}
#elseif canImport(AppKit)
@Test
func adaptivePlatformColorSelectsTheNativeAppearanceVariant() {
    let adaptiveColor = FixtureColorDesignSystem().color(for: .text).adaptivePlatformColor
    let lightAppearance = NSAppearance(named: .aqua)!
    let darkAppearance = NSAppearance(named: .darkAqua)!
    let resolvedLight = resolve(adaptiveColor, under: lightAppearance)
    let resolvedDark = resolve(adaptiveColor, under: darkAppearance)

    #expect(resolvedLight == NSColor.black.usingColorSpace(.deviceRGB))
    #expect(resolvedDark == NSColor.white.usingColorSpace(.deviceRGB))
}

private func resolve(_ color: NSColor, under appearance: NSAppearance) -> NSColor? {
    var resolvedColor: NSColor?
    appearance.performAsCurrentDrawingAppearance {
        resolvedColor = color.usingColorSpace(.deviceRGB)
    }
    return resolvedColor
}

@Test
func explicitPlatformResolutionRetainsDynamicPrimitiveSources() {
    let dynamicSource = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .white : .black
    }
    let theme = ColorTheme<DynamicPrimitiveColor, DynamicSemanticColor>(
        primitiveColor: { _ in dynamicSource },
        semanticColor: { _, palette in palette.color(.dynamic) }
    )
    let designColor = theme.color(for: .content)

    #expect(designColor.resolve(for: .light) === dynamicSource)
    #expect(designColor.resolve(for: .dark) === dynamicSource)
}

private enum DynamicPrimitiveColor: PrimitiveColorToken {
    case dynamic
}

private enum DynamicSemanticColor: SemanticColorToken {
    case content
}
#endif
