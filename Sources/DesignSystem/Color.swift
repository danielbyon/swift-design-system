import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A finite set of app-owned primitive color choices.
///
/// Primitive colors provide the single-source values from which semantic colors are composed.
/// The package does not assign names or visual meaning to this vocabulary.
public protocol PrimitiveColorToken: Sendable, CaseIterable {}

/// A finite set of app-owned semantic color choices.
///
/// Semantic colors describe the visual role consumed by feature code and may select different
/// primitive colors for light and dark appearances.
public protocol SemanticColorToken: Sendable, CaseIterable {}

/// The explicit appearance used to resolve a semantic color.
///
/// Native Apple colors selected for an appearance may retain additional system-driven dynamic
/// behavior provided by their original source.
public enum DesignAppearance: Sendable, CaseIterable {
    /// The light appearance.
    case light

    /// The dark appearance.
    case dark
}

/// Stores an app's primitive palette and semantic color composition.
///
/// The resolver closures are synchronous and `@Sendable`. Keep them deterministic, side-effect-free,
/// and inexpensive so semantic lookup remains a pure mapping. Primitive mappings provide one source
/// per token. Semantic mappings receive a palette restricted to the bound primitive token type, so
/// they can create only theme-scoped construction values from primitive tokens.
public struct ColorTheme<Primitive: PrimitiveColorToken, Semantic: SemanticColorToken>: Sendable {
    private let resolvePrimitiveColor: @Sendable (Primitive) -> PlatformColor
    private let resolveSemanticColor: @Sendable (
        Semantic,
        PrimitiveColorPalette
    ) -> ConstructionColor

    /// A construction-only semantic color whose sources came from this theme's primitive palette.
    ///
    /// The initializer and native sources are inaccessible to consumers. The enclosing theme
    /// converts this value to `DesignColor` after the semantic resolver returns it.
    public struct ConstructionColor: Sendable {
        fileprivate let lightSource: PlatformColor
        fileprivate let darkSource: PlatformColor

        fileprivate init(lightSource: PlatformColor, darkSource: PlatformColor) {
            self.lightSource = lightSource
            self.darkSource = darkSource
        }
    }

    /// A construction-only palette bound to this theme's primitive token vocabulary.
    ///
    /// It creates semantic construction values from one primitive token or a light/dark token pair.
    /// The palette is available only to the semantic resolver during theme lookup.
    public struct PrimitiveColorPalette: Sendable {
        private let resolvePrimitiveColor: @Sendable (Primitive) -> PlatformColor

        fileprivate init(resolvePrimitiveColor: @escaping @Sendable (Primitive) -> PlatformColor) {
            self.resolvePrimitiveColor = resolvePrimitiveColor
        }

        /// Creates a construction value that uses one primitive token in both appearances.
        ///
        /// - Parameter token: The primitive color token used for light and dark appearances.
        /// - Returns: A theme-scoped construction value with both sources selected from `token`.
        public func color(_ token: Primitive) -> ConstructionColor {
            let source = resolvePrimitiveColor(token)
            return ConstructionColor(lightSource: source, darkSource: source)
        }

        /// Creates a construction value from primitive tokens selected for each appearance.
        ///
        /// - Parameters:
        ///   - light: The primitive token used in the light appearance.
        ///   - dark: The primitive token used in the dark appearance.
        /// - Returns: A theme-scoped construction value retaining both selected sources.
        public func color(light: Primitive, dark: Primitive) -> ConstructionColor {
            ConstructionColor(
                lightSource: resolvePrimitiveColor(light),
                darkSource: resolvePrimitiveColor(dark)
            )
        }
    }

    /// Creates a color theme from exhaustive primitive and semantic mappings.
    ///
    /// Use switches over the app's finite token enums to keep mappings compiler-checked as the
    /// vocabularies evolve. The semantic resolver can select primitive tokens through `palette`
    /// but cannot create a `DesignColor` from an arbitrary platform color.
    ///
    /// - Parameters:
    ///   - primitiveColor: The single-source native color for each primitive token.
    ///   - semanticColor: A light/dark primitive composition returned by the supplied palette.
    public init(
        primitiveColor: @escaping @Sendable (Primitive) -> PlatformColor,
        semanticColor: @escaping @Sendable (
            Semantic,
            PrimitiveColorPalette
        ) -> ConstructionColor
    ) {
        self.resolvePrimitiveColor = primitiveColor
        self.resolveSemanticColor = semanticColor
    }

    /// Resolves a semantic token while retaining both appearance sources.
    ///
    /// Primitive lookup and construction stay inside the theme; callers receive only the adaptive
    /// semantic `DesignColor`.
    ///
    /// - Parameter token: The semantic color token to resolve.
    /// - Returns: The token's immutable light/dark `DesignColor`.
    public func color(for token: Semantic) -> DesignColor {
        let constructionColor = resolveSemanticColor(
            token,
            PrimitiveColorPalette(resolvePrimitiveColor: resolvePrimitiveColor)
        )
        return DesignColor(
            light: constructionColor.lightSource,
            dark: constructionColor.darkSource
        )
    }
}

/// A design-system capability that resolves app-owned semantic color tokens.
///
/// The conforming app owns the primitive and semantic vocabularies and its immutable color theme.
/// Feature code uses `color(for:)`; primitive lookup remains available only during theme
/// construction.
public protocol ColorDesignSystem: Sendable {
    /// The primitive palette vocabulary used to construct semantic colors.
    associatedtype Primitive: PrimitiveColorToken

    /// The semantic color vocabulary exposed to feature code.
    associatedtype Semantic: SemanticColorToken

    /// The immutable app-owned color theme.
    var colorTheme: ColorTheme<Primitive, Semantic> { get }
}

public extension ColorDesignSystem {
    /// Resolves an app-owned semantic color token.
    ///
    /// - Parameter token: The semantic color token to resolve.
    /// - Returns: The token's adaptive light/dark color.
    func color(for token: Semantic) -> DesignColor {
        colorTheme.color(for: token)
    }
}

/// An immutable semantic color that retains its light and dark native sources.
///
/// A `DesignColor` is created through a `ColorTheme`'s primitive-token-bound palette. Resolve it
/// explicitly with `resolve(for:)` when a concrete appearance is required, or pass it directly
/// to SwiftUI shape-style APIs to adapt to the rendering environment. Platforms that support
/// native dynamic colors also provide `adaptivePlatformColor`; watchOS relies on the adaptive shape
/// style and explicit appearance resolution because SwiftUI has no context-free adaptive `Color`
/// value for an arbitrary app-authored pair.
public struct DesignColor: Sendable, ShapeStyle {
    private let light: PlatformColor
    private let dark: PlatformColor

    fileprivate init(light: PlatformColor, dark: PlatformColor) {
        self.light = light
        self.dark = dark
    }

    /// Resolves this color to the primitive source selected for an explicit appearance.
    ///
    /// The selected source is returned without flattening any dynamic behavior it already has.
    ///
    /// - Parameter appearance: The light or dark semantic appearance to select.
    /// - Returns: The native platform color source selected for `appearance`.
    public func resolve(for appearance: DesignAppearance) -> PlatformColor {
        switch appearance {
        case .light:
            light
        case .dark:
            dark
        }
    }

    /// Converts the source selected for an explicit appearance to SwiftUI `Color`.
    ///
    /// UIKit and AppKit sources are bridged without flattening dynamic behavior they already have.
    /// On platforms where `PlatformColor` is SwiftUI `Color`, the selected source is returned
    /// directly.
    ///
    /// - Parameter appearance: The light or dark semantic appearance to select.
    /// - Returns: A SwiftUI color backed by the selected native source.
    public func swiftUIColor(for appearance: DesignAppearance) -> Color {
        let source = resolve(for: appearance)

        #if canImport(UIKit)
        return Color(uiColor: source)
        #elseif canImport(AppKit)
        return Color(nsColor: source)
        #else
        return source
        #endif
    }

    /// A native dynamic color that selects this color's semantic variant from platform context.
    ///
    /// This convenience exists only when UIKit or AppKit can represent a context-free dynamic
    /// color. The returned native color selects a semantic source and preserves that source's
    /// own dynamic behavior.
    #if canImport(UIKit) && !os(watchOS)
    public var adaptivePlatformColor: PlatformColor {
        let light = self.light
        let dark = self.dark
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
    #elseif canImport(AppKit)
    public var adaptivePlatformColor: PlatformColor {
        let light = self.light
        let dark = self.dark
        return NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }
    #endif

    /// Resolves this color as a SwiftUI style in the supplied environment.
    ///
    /// The environment's color scheme selects the semantic light/dark source. On watchOS this is
    /// the adaptive SwiftUI path for arbitrary app-authored pairs; no context-free adaptive
    /// `Color` is promised there.
    ///
    /// - Parameter environment: The SwiftUI environment used to select an appearance.
    /// - Returns: A SwiftUI color backed by the selected native source.
    public func resolve(in environment: EnvironmentValues) -> Color {
        let appearance: DesignAppearance = environment.colorScheme == .dark ? .dark : .light
        return swiftUIColor(for: appearance)
    }
}
