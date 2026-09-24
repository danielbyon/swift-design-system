import DesignSystem
import Testing

/// Records one Swift Testing issue for each spacing token that resolves to a non-finite value.
///
/// The validator visits every token in the design system's complete spacing vocabulary. A
/// best-effort token description appears in each issue for diagnostic context only; it does not
/// define token identity or alter the resolved value.
public func validateSpacing<System: SpacingDesignSystem>(in designSystem: System) {
    for token in System.Spacing.allCases {
        let value = designSystem.spacing(for: token)
        if !value.isFinite {
            Issue.record(
                "Spacing token \(String(describing: token)) resolved to a non-finite value."
            )
        }
    }
}
