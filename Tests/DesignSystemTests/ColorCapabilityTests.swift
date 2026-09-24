import DesignSystem
import SwiftUI
import Synchronization
import Testing
import DesignSystemTestSupport

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
