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
        assert(x.isFinite, "Gradient point x coordinates must be finite.")
        assert(y.isFinite, "Gradient point y coordinates must be finite.")
        self.x = x.isFinite ? x : 0
        self.y = y.isFinite ? y : 0
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

/// A gradient stop that references an app-owned semantic color token at a normalized location.
public struct GradientStop<Semantic: SemanticColorToken>: Sendable {
    /// The semantic color token used by this stop.
    public let semanticColor: Semantic

    /// The normalized position of the stop along the gradient.
    public let location: CGFloat

    /// Creates a stop from a semantic color token and its authored location.
    ///
    /// - Parameters:
    ///   - semanticColor: The semantic color token used by this stop.
    ///   - location: The normalized position along the gradient. Non-finite and out-of-range values
    ///     assert in development; release construction repairs non-finite values to zero and clamps
    ///     finite values to `0...1`.
    public init(semanticColor: Semantic, location: CGFloat) {
        assert(
            location.isFinite && (0...1).contains(location),
            "Gradient stop locations must be finite and in the inclusive 0...1 range."
        )
        self.semanticColor = semanticColor
        self.location = location.isFinite ? min(1, max(0, location)) : 0
    }
}

/// An angular-gradient angle stored as radians.
///
/// Values are not normalized, so negative angles and values spanning multiple revolutions preserve
/// their authored angular meaning. Degree construction converts to this canonical representation,
/// so equivalent degree and radian inputs compare as the same value. Non-finite input asserts in
/// development and recovers to zero radians in release.
public struct GradientAngle: Sendable, Equatable {
    /// The canonical angle in radians, without revolution normalization.
    public let radians: CGFloat

    private init(radians: CGFloat) {
        self.radians = radians
    }

    /// Creates an angle from degrees.
    ///
    /// A non-finite value asserts in development and becomes zero radians in release.
    public static func degrees(_ degrees: CGFloat) -> Self {
        assert(degrees.isFinite, "Gradient angles must be finite.")
        let radians = degrees.isFinite ? (degrees / 180) * .pi : 0
        return Self(radians: radians)
    }

    /// Creates an angle from radians.
    ///
    /// A non-finite value asserts in development and becomes zero radians in release.
    public static func radians(_ radians: CGFloat) -> Self {
        assert(radians.isFinite, "Gradient angles must be finite.")
        return Self(radians: radians.isFinite ? radians : 0)
    }
}

/// A complete radial gradient definition for one semantic color vocabulary.
///
/// Radii are normalized against the smaller rendered dimension: a radius of `1` is one full
/// minimum dimension, and values greater than `1` extend beyond the shape.
public struct RadialGradientDefinition<Semantic: SemanticColorToken>: Sendable {
    /// The stops authored for this definition.
    public let stops: [GradientStop<Semantic>]

    /// The normalized center of the gradient.
    public let center: GradientPoint

    /// The normalized radius at the beginning of the gradient.
    public let startRadius: CGFloat

    /// The normalized radius at the end of the gradient.
    public let endRadius: CGFloat

    /// Creates a radial definition with normalized center and radii.
    public init(
        stops: [GradientStop<Semantic>],
        center: GradientPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) {
        let safeStartRadius = nonnegativeRadius(startRadius, name: "startRadius")
        let safeEndRadius = nonnegativeRadius(endRadius, name: "endRadius")
        assert(safeEndRadius >= safeStartRadius, "Radial endRadius must be at least startRadius.")

        self.stops = normalizedGradientStops(stops)
        self.center = center
        self.startRadius = safeStartRadius
        self.endRadius = max(safeStartRadius, safeEndRadius)
    }
}

/// A complete angular gradient definition for one semantic color vocabulary.
public struct AngularGradientDefinition<Semantic: SemanticColorToken>: Sendable {
    /// The stops authored for this definition.
    public let stops: [GradientStop<Semantic>]

    /// The normalized center of the gradient.
    public let center: GradientPoint

    /// The angle where the gradient begins.
    public let startAngle: GradientAngle

    /// The angle where the gradient ends.
    public let endAngle: GradientAngle

    /// Creates an angular definition with normalized center and authored angles.
    public init(
        stops: [GradientStop<Semantic>],
        center: GradientPoint,
        startAngle: GradientAngle,
        endAngle: GradientAngle
    ) {
        self.stops = normalizedGradientStops(stops)
        self.center = center
        self.startAngle = startAngle
        self.endAngle = endAngle
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
        self.stops = normalizedGradientStops(stops)
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

/// A complete gradient definition whose geometry is linear, radial, or angular.
public enum GradientDefinition<Semantic: SemanticColorToken>: Sendable {
    /// A linear gradient between normalized endpoints.
    case linear(LinearGradientDefinition<Semantic>)
    /// A radial gradient with normalized radii.
    case radial(RadialGradientDefinition<Semantic>)
    /// An angular gradient with authored start and end angles.
    case angular(AngularGradientDefinition<Semantic>)

    /// Creates a linear definition from its stops and endpoints.
    public static func linear(
        stops: [GradientStop<Semantic>],
        startPoint: GradientPoint,
        endPoint: GradientPoint
    ) -> Self {
        .linear(LinearGradientDefinition(stops: stops, startPoint: startPoint, endPoint: endPoint))
    }

    /// Creates a radial definition from its stops, center, and normalized radii.
    public static func radial(
        stops: [GradientStop<Semantic>],
        center: GradientPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) -> Self {
        .radial(RadialGradientDefinition(
            stops: stops,
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        ))
    }

    /// Creates an angular definition from its stops, center, and authored angles.
    public static func angular(
        stops: [GradientStop<Semantic>],
        center: GradientPoint,
        startAngle: GradientAngle,
        endAngle: GradientAngle
    ) -> Self {
        .angular(AngularGradientDefinition(
            stops: stops,
            center: center,
            startAngle: startAngle,
            endAngle: endAngle
        ))
    }
}

/// Complete independent light and dark gradient definitions.
public struct AdaptiveGradient<Semantic: SemanticColorToken>: Sendable {
    /// The definition used for light appearance.
    public let light: GradientDefinition<Semantic>

    /// The definition used for dark appearance.
    public let dark: GradientDefinition<Semantic>

    /// Creates an adaptive gradient from full light and dark definitions, which may use different kinds.
    ///
    /// - Parameters:
    ///   - light: The complete light-appearance definition.
    ///   - dark: The complete dark-appearance definition.
    public init(
        light: GradientDefinition<Semantic>,
        dark: GradientDefinition<Semantic>
    ) {
        self.light = light
        self.dark = dark
    }

    /// Creates an adaptive gradient from independent linear definitions.
    public init(
        light: LinearGradientDefinition<Semantic>,
        dark: LinearGradientDefinition<Semantic>
    ) {
        self.init(light: .linear(light), dark: .linear(dark))
    }
}

private func normalizedGradientStops<Semantic: SemanticColorToken>(
    _ stops: [GradientStop<Semantic>]
) -> [GradientStop<Semantic>] {
    let orderedStops = stops.enumerated().sorted { lhs, rhs in
        lhs.element.location == rhs.element.location
            ? lhs.offset < rhs.offset
            : lhs.element.location < rhs.element.location
    }
    let sortedStops = orderedStops.map(\.element)

    guard sortedStops.count == 1, let only = sortedStops.first else { return sortedStops }
    return [
        GradientStop(semanticColor: only.semanticColor, location: 0),
        GradientStop(semanticColor: only.semanticColor, location: 1),
    ]
}

private func nonnegativeRadius(_ radius: CGFloat, name: String) -> CGFloat {
    assert(radius.isFinite && radius >= 0, "Radial \(name) must be finite and nonnegative.")
    return radius.isFinite ? max(0, radius) : 0
}

private struct AdaptiveDesignGradientStop: Sendable {
    let color: DesignColor
    let location: CGFloat
}

private enum AdaptiveDesignGradientDefinition: Sendable {
    case linear(
        stops: [AdaptiveDesignGradientStop],
        startPoint: GradientPoint,
        endPoint: GradientPoint
    )
    case radial(
        stops: [AdaptiveDesignGradientStop],
        center: GradientPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    )
    case angular(
        stops: [AdaptiveDesignGradientStop],
        center: GradientPoint,
        startAngle: GradientAngle,
        endAngle: GradientAngle
    )

    func resolve(for appearance: DesignAppearance) -> ResolvedGradient {
        switch self {
        case let .linear(stops, startPoint, endPoint):
            .linear(ResolvedLinearGradient(
                stops: resolveStops(stops, for: appearance),
                startPoint: startPoint,
                endPoint: endPoint
            ))
        case let .radial(stops, center, startRadius, endRadius):
            .radial(ResolvedRadialGradient(
                stops: resolveStops(stops, for: appearance),
                center: center,
                startRadius: startRadius,
                endRadius: endRadius
            ))
        case let .angular(stops, center, startAngle, endAngle):
            .angular(ResolvedAngularGradient(
                stops: resolveStops(stops, for: appearance),
                center: center,
                startAngle: startAngle,
                endAngle: endAngle
            ))
        }
    }

    func swiftUIStyle(
        for appearance: DesignAppearance,
        availableSize: CGSize?
    ) -> AnyShapeStyle {
        switch self {
        case let .linear(stops, startPoint, endPoint):
            return AnyShapeStyle(SwiftUI.LinearGradient(
                gradient: SwiftUI.Gradient(stops: swiftUIStops(stops, for: appearance)),
                startPoint: swiftUIUnitPoint(startPoint),
                endPoint: swiftUIUnitPoint(endPoint)
            ))
        case let .radial(stops, center, startRadius, endRadius):
            guard let availableSize else {
                assertionFailure(
                    "Radial DesignGradient requires Shape.fill(_:style:) so its normalized radii can use rendered bounds."
                )
                return AnyShapeStyle(SwiftUI.Color.clear)
            }
            let radiusScale = min(availableSize.width, availableSize.height)
            return AnyShapeStyle(SwiftUI.RadialGradient(
                gradient: SwiftUI.Gradient(stops: swiftUIStops(stops, for: appearance)),
                center: swiftUIUnitPoint(center),
                startRadius: startRadius * radiusScale,
                endRadius: endRadius * radiusScale
            ))
        case let .angular(stops, center, startAngle, endAngle):
            return AnyShapeStyle(SwiftUI.AngularGradient(
                gradient: SwiftUI.Gradient(stops: swiftUIStops(stops, for: appearance)),
                center: swiftUIUnitPoint(center),
                startAngle: .radians(startAngle.radians),
                endAngle: .radians(endAngle.radians)
            ))
        }
    }
}

private func resolveStops(
    _ stops: [AdaptiveDesignGradientStop],
    for appearance: DesignAppearance
) -> [ResolvedLinearGradient.Stop] {
    guard !stops.isEmpty else {
        return [
            ResolvedLinearGradient.Stop(color: .clear, location: 0),
            ResolvedLinearGradient.Stop(color: .clear, location: 1),
        ]
    }
    return stops.map { stop in
        ResolvedLinearGradient.Stop(
            color: stop.color.resolve(for: appearance),
            location: stop.location
        )
    }
}

private func swiftUIStops(
    _ stops: [AdaptiveDesignGradientStop],
    for appearance: DesignAppearance
) -> [SwiftUI.Gradient.Stop] {
    guard !stops.isEmpty else {
        return [
            SwiftUI.Gradient.Stop(color: .clear, location: 0),
            SwiftUI.Gradient.Stop(color: .clear, location: 1),
        ]
    }
    return stops.map { stop in
        SwiftUI.Gradient.Stop(
            color: stop.color.swiftUIColor(for: appearance),
            location: stop.location
        )
    }
}

private func swiftUIUnitPoint(_ point: GradientPoint) -> SwiftUI.UnitPoint {
    SwiftUI.UnitPoint(x: point.x, y: point.y)
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

/// A resolved radial gradient with native colors and normalized geometry.
public struct ResolvedRadialGradient: Sendable {
    /// The native color sources and normalized locations in the selected definition.
    public let stops: [ResolvedLinearGradient.Stop]

    /// The authored normalized center.
    public let center: GradientPoint

    /// The authored normalized starting radius.
    public let startRadius: CGFloat

    /// The authored normalized ending radius.
    public let endRadius: CGFloat

    fileprivate init(
        stops: [ResolvedLinearGradient.Stop],
        center: GradientPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) {
        self.stops = stops
        self.center = center
        self.startRadius = startRadius
        self.endRadius = endRadius
    }
}

/// A resolved angular gradient with native colors and exact authored angles.
public struct ResolvedAngularGradient: Sendable {
    /// The native color sources and normalized locations in the selected definition.
    public let stops: [ResolvedLinearGradient.Stop]

    /// The authored normalized center.
    public let center: GradientPoint

    /// The exact authored start angle in canonical radians.
    public let startAngle: GradientAngle

    /// The exact authored end angle in canonical radians.
    public let endAngle: GradientAngle

    fileprivate init(
        stops: [ResolvedLinearGradient.Stop],
        center: GradientPoint,
        startAngle: GradientAngle,
        endAngle: GradientAngle
    ) {
        self.stops = stops
        self.center = center
        self.startAngle = startAngle
        self.endAngle = endAngle
    }
}

/// A resolved gradient description containing the geometry for its selected kind.
public enum ResolvedGradient: Sendable {
    /// A resolved linear gradient.
    case linear(ResolvedLinearGradient)
    /// A resolved radial gradient.
    case radial(ResolvedRadialGradient)
    /// A resolved angular gradient.
    case angular(ResolvedAngularGradient)
}

/// An immutable adaptive semantic gradient usable as a SwiftUI shape style.
///
/// The value retains separate resolved light and dark definitions. Explicit native resolution picks
/// one definition first, then selects every semantic stop using that same appearance.
public struct DesignGradient: Sendable, ShapeStyle {
    private let light: AdaptiveDesignGradientDefinition
    private let dark: AdaptiveDesignGradientDefinition

    fileprivate init(light: AdaptiveDesignGradientDefinition, dark: AdaptiveDesignGradientDefinition) {
        self.light = light
        self.dark = dark
    }

    /// Resolves one complete definition and all of its native color sources for an appearance.
    ///
    /// Native colors are returned without conversion to `CGColor`, preserving system-driven dynamic
    /// color behavior for callers that perform further native rendering.
    ///
    /// - Parameter appearance: The appearance used for the entire definition and every stop.
    /// - Returns: The selected native gradient description.
    public func resolve(for appearance: DesignAppearance) -> ResolvedGradient {
        switch appearance {
        case .light:
            light.resolve(for: .light)
        case .dark:
            dark.resolve(for: .dark)
        }
    }

    /// Resolves this value as a SwiftUI shape style in the supplied environment.
    ///
    /// The environment selects one complete appearance definition before any stop is bridged to
    /// SwiftUI, so one rendered gradient cannot mix semantic light and dark variants.
    ///
    /// Radial definitions require rendered bounds and therefore assert in development and return a
    /// transparent style in release. Use `Shape.fill(_:style:)` to render radial gradients.
    ///
    /// - Parameter environment: The SwiftUI environment used to select the appearance.
    /// - Returns: A SwiftUI shape style that faithfully represents linear and angular definitions.
    public func resolve(in environment: EnvironmentValues) -> AnyShapeStyle {
        let appearance: DesignAppearance = environment.colorScheme == .dark ? .dark : .light
        let definition = appearance == .dark ? dark : light
        return definition.swiftUIStyle(for: appearance, availableSize: nil)
    }

    fileprivate func swiftUIStyle(
        in environment: EnvironmentValues,
        availableSize: CGSize
    ) -> AnyShapeStyle {
        let appearance: DesignAppearance = environment.colorScheme == .dark ? .dark : .light
        let definition = appearance == .dark ? dark : light
        return definition.swiftUIStyle(for: appearance, availableSize: availableSize)
    }

    /// An explicitly type-erased SwiftUI shape style for APIs that require `AnyShapeStyle`.
    public var anyShapeStyle: AnyShapeStyle {
        AnyShapeStyle(self)
    }
}

/// Measures the shape's rendered bounds before converting normalized radial radii to points.
private struct GeometryAwareGradientFill<ContentShape: Shape>: View {
    let shape: ContentShape
    let gradient: DesignGradient
    let fillStyle: FillStyle

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        shape
            .fill(Color.clear, style: fillStyle)
            .allowsHitTesting(false)
            .overlay {
                GeometryReader { geometry in
                    shape
                        .fill(
                            swiftUIStyle(for: geometry.size),
                            style: fillStyle
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
    }

    private func swiftUIStyle(for size: CGSize) -> AnyShapeStyle {
        var environment = EnvironmentValues()
        environment.colorScheme = colorScheme
        return gradient.swiftUIStyle(in: environment, availableSize: size)
    }
}

public extension Shape {
    /// Fills the shape with a design gradient using its actual rendered bounds.
    ///
    /// The measured size is required to interpret normalized radial radii. A radius of `1` maps to
    /// the smaller rendered dimension, and radii greater than `1` remain valid.
    func fill(_ gradient: DesignGradient, style: FillStyle = FillStyle()) -> some View {
        GeometryAwareGradientFill(shape: self, gradient: gradient, fillStyle: style)
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
    ///   - gradient: The complete adaptive definition for each gradient token.
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
        _ definition: GradientDefinition<Semantic>
    ) -> AdaptiveDesignGradientDefinition {
        switch definition {
        case let .linear(linear):
            .linear(
                stops: resolve(linear.stops),
                startPoint: linear.startPoint,
                endPoint: linear.endPoint
            )
        case let .radial(radial):
            .radial(
                stops: resolve(radial.stops),
                center: radial.center,
                startRadius: radial.startRadius,
                endRadius: radial.endRadius
            )
        case let .angular(angular):
            .angular(
                stops: resolve(angular.stops),
                center: angular.center,
                startAngle: angular.startAngle,
                endAngle: angular.endAngle
            )
        }
    }

    private func resolve(_ stops: [GradientStop<Semantic>]) -> [AdaptiveDesignGradientStop] {
        stops.map { stop in
            AdaptiveDesignGradientStop(
                color: colorTheme.color(for: stop.semanticColor),
                location: stop.location
            )
        }
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
