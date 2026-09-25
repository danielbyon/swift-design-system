import SwiftUI

/// A finite set of app-owned semantic gradient choices.
///
/// Gradient tokens identify visual roles in an application. The package supplies the mapping and
/// rendering mechanics but does not assign names or visual meaning to the app's vocabulary.
public protocol GradientToken: Sendable, CaseIterable {}

/// A normalized point used to describe linear-gradient geometry independently of view size.
///
/// Coordinates are fractions of the rendered view's width and height. Finite values outside `0...1`
/// are preserved so callers can extend a gradient beyond the view's bounds.
public struct GradientPoint: Sendable, Equatable {
    /// The horizontal coordinate as a fraction of the view's width.
    public let x: CGFloat

    /// The vertical coordinate as a fraction of the view's height.
    public let y: CGFloat

    /// Creates a normalized point without restricting finite coordinates to the unit square.
    ///
    /// - Parameters:
    ///   - x: The horizontal coordinate as a fraction of the view's width.
    ///   - y: The vertical coordinate as a fraction of the view's height.
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    /// The center of a view.
    public static let center = Self(x: 0.5, y: 0.5)

    /// The center of the top edge of a view.
    public static let top = Self(x: 0.5, y: 0)

    /// The center of the bottom edge of a view.
    public static let bottom = Self(x: 0.5, y: 1)

    /// The center of the leading edge of a view.
    public static let leading = Self(x: 0, y: 0.5)

    /// The center of the trailing edge of a view.
    public static let trailing = Self(x: 1, y: 0.5)

    /// The top-leading corner of a view.
    public static let topLeading = Self(x: 0, y: 0)

    /// The top-trailing corner of a view.
    public static let topTrailing = Self(x: 1, y: 0)

    /// The bottom-leading corner of a view.
    public static let bottomLeading = Self(x: 0, y: 1)

    /// The bottom-trailing corner of a view.
    public static let bottomTrailing = Self(x: 1, y: 1)
}

/// A gradient stop that references an app-owned semantic color token.
public struct GradientStop<Semantic: SemanticColorToken>: Sendable {
    /// The semantic color token used by this stop.
    public let semanticColor: Semantic

    /// The normalized position of the stop along the gradient.
    public let location: CGFloat

    /// Creates a stop from a semantic color token and its authored location.
    ///
    /// - Parameters:
    ///   - semanticColor: The semantic color token used by this stop.
    ///   - location: The stop location. Issue #7 preserves authored locations; malformed-location
    ///     recovery belongs to a later gradient capability.
    public init(semanticColor: Semantic, location: CGFloat) {
        self.semanticColor = semanticColor
        self.location = location
    }
}

/// A complete linear gradient definition for one semantic color vocabulary.
///
/// Each definition owns its ordered stops and both normalized geometry endpoints. Adaptive
/// definitions can therefore use different stop counts, locations, and geometry for each
/// appearance.
public struct LinearGradientDefinition<Semantic: SemanticColorToken>: Sendable {
    /// The stops authored for this definition.
    public let stops: [GradientStop<Semantic>]

    /// The normalized beginning point of the gradient.
    public let startPoint: GradientPoint

    /// The normalized ending point of the gradient.
    public let endPoint: GradientPoint

    /// Creates a complete linear definition from semantic stops and normalized endpoints.
    ///
    /// - Parameters:
    ///   - stops: The semantic color stops in authored order.
    ///   - startPoint: The normalized beginning point.
    ///   - endPoint: The normalized ending point.
    public init(
        stops: [GradientStop<Semantic>],
        startPoint: GradientPoint,
        endPoint: GradientPoint
    ) {
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

/// Complete independent light and dark linear-gradient definitions.
public struct AdaptiveGradient<Semantic: SemanticColorToken>: Sendable {
    /// The definition used for light appearance.
    public let light: LinearGradientDefinition<Semantic>

    /// The definition used for dark appearance.
    public let dark: LinearGradientDefinition<Semantic>

    /// Creates an adaptive gradient from full light and dark definitions.
    ///
    /// - Parameters:
    ///   - light: The complete light-appearance definition.
    ///   - dark: The complete dark-appearance definition.
    public init(
        light: LinearGradientDefinition<Semantic>,
        dark: LinearGradientDefinition<Semantic>
    ) {
        self.light = light
        self.dark = dark
    }
}

private struct AdaptiveDesignGradientStop: Sendable {
    let color: DesignColor
    let location: CGFloat
}

private struct AdaptiveDesignLinearGradient: Sendable {
    let stops: [AdaptiveDesignGradientStop]
    let startPoint: GradientPoint
    let endPoint: GradientPoint

    func resolve(for appearance: DesignAppearance) -> ResolvedLinearGradient {
        ResolvedLinearGradient(
            stops: stops.map { stop in
                ResolvedLinearGradient.Stop(
                    color: stop.color.resolve(for: appearance),
                    location: stop.location
                )
            },
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

/// A resolved linear gradient description containing native color sources and authored geometry.
///
/// The selected colors remain `PlatformColor` values. Native view adapters may convert them to
/// drawable color representations while drawing under the current system appearance.
public struct ResolvedLinearGradient: Sendable {
    /// One native color source and its authored stop location.
    public struct Stop: Sendable {
        /// The selected native color source, retaining any dynamic behavior it already provides.
        public let color: PlatformColor

        /// The authored normalized position of this stop.
        public let location: CGFloat

        fileprivate init(color: PlatformColor, location: CGFloat) {
            self.color = color
            self.location = location
        }
    }

    /// The native color sources and authored locations in the selected definition.
    public let stops: [Stop]

    /// The authored normalized beginning point.
    public let startPoint: GradientPoint

    /// The authored normalized ending point.
    public let endPoint: GradientPoint

    fileprivate init(stops: [Stop], startPoint: GradientPoint, endPoint: GradientPoint) {
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

/// An immutable adaptive semantic gradient usable as a SwiftUI shape style.
///
/// The value retains separate resolved light and dark definitions. Explicit native resolution picks
/// one definition first, then selects every semantic stop using that same appearance.
public struct DesignGradient: Sendable, ShapeStyle {
    private let light: AdaptiveDesignLinearGradient
    private let dark: AdaptiveDesignLinearGradient

    fileprivate init(light: AdaptiveDesignLinearGradient, dark: AdaptiveDesignLinearGradient) {
        self.light = light
        self.dark = dark
    }

    /// Resolves one complete definition and all of its native color sources for an appearance.
    ///
    /// Native colors are returned without conversion to `CGColor`, preserving system-driven dynamic
    /// color behavior for callers that perform further native rendering.
    ///
    /// - Parameter appearance: The appearance used for the entire definition and every stop.
    /// - Returns: The selected native linear-gradient description.
    public func resolve(for appearance: DesignAppearance) -> ResolvedLinearGradient {
        switch appearance {
        case .light:
            light.resolve(for: .light)
        case .dark:
            dark.resolve(for: .dark)
        }
    }

    /// Resolves this value as a SwiftUI linear gradient in the supplied environment.
    ///
    /// The environment selects one complete appearance definition before any stop is bridged to
    /// SwiftUI, so one rendered gradient cannot mix semantic light and dark variants.
    ///
    /// - Parameter environment: The SwiftUI environment used to select the appearance.
    /// - Returns: A SwiftUI linear-gradient shape style.
    public func resolve(in environment: EnvironmentValues) -> SwiftUI.LinearGradient {
        let appearance: DesignAppearance = environment.colorScheme == .dark ? .dark : .light
        let definition = appearance == .dark ? dark : light
        let stops = definition.stops.map { stop in
            SwiftUI.Gradient.Stop(
                color: stop.color.swiftUIColor(for: appearance),
                location: stop.location
            )
        }
        return SwiftUI.LinearGradient(
            gradient: SwiftUI.Gradient(stops: stops),
            startPoint: SwiftUI.UnitPoint(x: definition.startPoint.x, y: definition.startPoint.y),
            endPoint: SwiftUI.UnitPoint(x: definition.endPoint.x, y: definition.endPoint.y)
        )
    }

    /// An explicitly type-erased SwiftUI shape style for APIs that require `AnyShapeStyle`.
    public var anyShapeStyle: AnyShapeStyle {
        AnyShapeStyle(self)
    }
}

/// Owns one color theme and an exhaustive semantic-gradient mapping.
///
/// Gradient definitions reference only the theme's semantic color vocabulary. Primitive color
/// mapping remains encapsulated by the composed `ColorTheme`, making it the single color source for
/// any design system that uses this gradient theme.
public struct GradientTheme<
    Primitive: PrimitiveColorToken,
    Semantic: SemanticColorToken,
    Gradient: GradientToken
>: Sendable {
    /// The single color theme composed by this gradient theme.
    public let colorTheme: ColorTheme<Primitive, Semantic>

    private let resolveGradient: @Sendable (Gradient) -> AdaptiveGradient<Semantic>

    /// Creates a gradient theme from its color theme and exhaustive gradient-token resolver.
    ///
    /// Use a switch over the app's finite `Gradient` vocabulary so adding a token requires an
    /// intentional mapping update.
    ///
    /// - Parameters:
    ///   - colorTheme: The color theme used to resolve semantic stops.
    ///   - gradient: The complete adaptive linear definition for each gradient token.
    public init(
        colorTheme: ColorTheme<Primitive, Semantic>,
        gradient: @escaping @Sendable (Gradient) -> AdaptiveGradient<Semantic>
    ) {
        self.colorTheme = colorTheme
        self.resolveGradient = gradient
    }

    /// Resolves an app-owned gradient token into an immutable adaptive design gradient.
    ///
    /// Semantic color tokens are resolved once into `DesignColor` values while both complete
    /// appearance definitions remain available for coherent later resolution.
    ///
    /// - Parameter token: The gradient token to resolve.
    /// - Returns: An immutable value suitable for SwiftUI and native rendering adapters.
    public func gradient(for token: Gradient) -> DesignGradient {
        let authored = resolveGradient(token)
        return DesignGradient(
            light: resolve(authored.light),
            dark: resolve(authored.dark)
        )
    }

    private func resolve(
        _ definition: LinearGradientDefinition<Semantic>
    ) -> AdaptiveDesignLinearGradient {
        AdaptiveDesignLinearGradient(
            stops: definition.stops.map { stop in
                AdaptiveDesignGradientStop(
                    color: colorTheme.color(for: stop.semanticColor),
                    location: stop.location
                )
            },
            startPoint: definition.startPoint,
            endPoint: definition.endPoint
        )
    }
}

/// A semantic-gradient capability that refines the app's semantic-color capability.
///
/// Conforming design systems author only `gradientTheme`. The inherited color theme is derived from
/// that same value, so gradient and color resolution cannot use independent color configurations.
public protocol GradientDesignSystem: ColorDesignSystem {
    /// The app-owned semantic gradient vocabulary.
    associatedtype Gradient: GradientToken

    /// The single app-authored theme containing both color and gradient mappings.
    var gradientTheme: GradientTheme<Primitive, Semantic, Gradient> { get }
}

public extension GradientDesignSystem {
    /// The color theme owned by `gradientTheme`, satisfying the inherited color capability.
    var colorTheme: ColorTheme<Primitive, Semantic> {
        gradientTheme.colorTheme
    }

    /// Resolves an app-owned semantic gradient token.
    ///
    /// - Parameter token: The gradient token to resolve.
    /// - Returns: The token's immutable adaptive `DesignGradient`.
    func gradient(for token: Gradient) -> DesignGradient {
        gradientTheme.gradient(for: token)
    }
}
