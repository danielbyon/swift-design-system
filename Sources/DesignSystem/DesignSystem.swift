import CoreGraphics

/// A semantic spacing choice defined by an application.
public protocol SpacingToken: Sendable, CaseIterable {}

/// Resolves application-owned spacing tokens to scalar layout values.
public protocol SpacingDesignSystem: Sendable {
    /// The complete set of spacing choices supported by this design system.
    associatedtype Spacing: SpacingToken

    /// Returns the value authored for a spacing token without changing it.
    func spacing(for token: Spacing) -> CGFloat
}


/// An application-defined one-dimensional layout measurement in logical points.
///
/// `DesignSystemTestSupport.validateDimensions(in:)` expects each resolved value to be finite and
/// nonnegative. Production resolvers return app-authored values unchanged and do not enforce or
/// repair that expectation.
public protocol DimensionToken: Sendable, CaseIterable {}

/// Resolves application-owned dimension tokens to logical-point layout values.
///
/// Resolution is synchronous and nonthrowing. The package does not clamp, sanitize, substitute, or
/// otherwise change a value returned by the application. Tests can use
/// `DesignSystemTestSupport.validateDimensions(in:)` to report non-finite or negative values.
public protocol DimensionDesignSystem: Sendable {
    /// The complete app-authored set of dimension choices in logical points. TestSupport expects
    /// finite, nonnegative values, and production resolution does not repair violations.
    associatedtype Dimension: DimensionToken

    /// Returns the app-authored dimension in logical points without changing it.
    ///
    /// Production resolution does not enforce the finite, nonnegative expectation used by
    /// `DesignSystemTestSupport.validateDimensions(in:)`.
    func dimension(for token: Dimension) -> CGFloat
}

/// An application-defined two-dimensional layout size whose components use logical points.
///
/// `DesignSystemTestSupport.validateSizes(in:)` expects both width and height to be finite and
/// nonnegative. Production resolvers return app-authored values unchanged and do not enforce or
/// repair that expectation.
public protocol SizeToken: Sendable, CaseIterable {}

/// Resolves application-owned size tokens to native two-dimensional layout values.
///
/// Width and height use logical points. Resolution is synchronous and nonthrowing; the package
/// does not clamp, sanitize, substitute, or otherwise change values returned by the application.
/// Tests can use `DesignSystemTestSupport.validateSizes(in:)` to report non-finite or negative
/// components.
public protocol SizeDesignSystem: Sendable {
    /// The complete app-authored set of size choices. Width and height use logical points;
    /// TestSupport expects finite, nonnegative components and production resolution does not repair
    /// violations.
    associatedtype Size: SizeToken

    /// Returns the app-authored width and height in logical points without changing them.
    ///
    /// Production resolution does not enforce the finite, nonnegative component expectations used
    /// by `DesignSystemTestSupport.validateSizes(in:)`.
    func size(for token: Size) -> CGSize
}

/// An application-defined corner radius measured in logical points.
///
/// `DesignSystemTestSupport.validateCornerRadii(in:)` expects resolved values to be finite and
/// nonnegative. Production resolvers return app-authored values unchanged and do not enforce or
/// repair that expectation.
public protocol CornerRadiusToken: Sendable, CaseIterable {}

/// Resolves application-owned corner-radius tokens to logical-point values.
///
/// Resolution is synchronous and nonthrowing. The package does not clamp, sanitize, substitute, or
/// otherwise change a value returned by the application. Tests can use
/// `DesignSystemTestSupport.validateCornerRadii(in:)` to report non-finite or negative values.
public protocol CornerRadiusDesignSystem: Sendable {
    /// The complete app-authored set of corner-radius choices, measured in logical points.
    /// TestSupport expects finite, nonnegative values, and production resolution does not repair
    /// violations.
    associatedtype CornerRadius: CornerRadiusToken

    /// Returns the app-authored corner radius in logical points without changing it.
    ///
    /// Production resolution does not enforce the finite, nonnegative expectation used by
    /// `DesignSystemTestSupport.validateCornerRadii(in:)`.
    func cornerRadius(for token: CornerRadius) -> CGFloat
}

/// An application-defined stroke width measured in logical points.
///
/// `DesignSystemTestSupport.validateStrokeWidths(in:)` expects resolved values to be finite and
/// nonnegative. Production resolvers return app-authored values unchanged and do not enforce or
/// repair that expectation.
public protocol StrokeWidthToken: Sendable, CaseIterable {}

/// Resolves application-owned stroke-width tokens to logical-point values.
///
/// Resolution is synchronous and nonthrowing. The package does not clamp, sanitize, substitute, or
/// otherwise change a value returned by the application. Tests can use
/// `DesignSystemTestSupport.validateStrokeWidths(in:)` to report non-finite or negative values.
public protocol StrokeWidthDesignSystem: Sendable {
    /// The complete app-authored set of stroke-width choices, measured in logical points.
    /// TestSupport expects finite, nonnegative values, and production resolution does not repair
    /// violations.
    associatedtype StrokeWidth: StrokeWidthToken

    /// Returns the app-authored stroke width in logical points without changing it.
    ///
    /// Production resolution does not enforce the finite, nonnegative expectation used by
    /// `DesignSystemTestSupport.validateStrokeWidths(in:)`.
    func strokeWidth(for token: StrokeWidth) -> CGFloat
}

/// An application-defined opacity token expected to resolve to a normalized, unitless value.
///
/// `DesignSystemTestSupport.validateOpacities(in:)` expects finite values in the inclusive
/// `0...1` range. Production resolvers return app-authored values unchanged and do not enforce or
/// repair that expectation.
public protocol OpacityToken: Sendable, CaseIterable {}

/// Resolves application-owned opacity tokens to normalized, unitless `Double` values.
///
/// Resolution is synchronous and nonthrowing. The package does not clamp, sanitize, substitute, or
/// otherwise change a value returned by the application. Tests can use
/// `DesignSystemTestSupport.validateOpacities(in:)` to report non-finite values and values outside
/// the inclusive `0...1` range.
public protocol OpacityDesignSystem: Sendable {
    /// The complete app-authored set of normalized, unitless opacity choices. TestSupport expects
    /// finite values in inclusive `0...1`, and production resolution does not repair violations.
    associatedtype Opacity: OpacityToken

    /// Returns the app-authored, unitless opacity without changing it.
    ///
    /// Production resolution does not enforce the finite `0...1` expectation used by
    /// `DesignSystemTestSupport.validateOpacities(in:)`.
    func opacity(for token: Opacity) -> Double
}
