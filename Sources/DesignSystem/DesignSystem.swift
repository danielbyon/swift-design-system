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
