import DesignSystem
import SwiftUI
import Testing

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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


/// Reports every dimension token that resolves to a non-finite or negative logical-point value.
///
/// The validator enumerates the complete public token vocabulary and continues after each issue.
/// It records test issues only; production resolution is not sanitized or changed.
///
/// - Parameter designSystem: The app-owned design system whose dimensions are checked.
public func validateDimensions<System: DimensionDesignSystem>(in designSystem: System) {
    for token in System.Dimension.allCases {
        let value = designSystem.dimension(for: token)
        if !value.isFinite {
            Issue.record(
                "Dimension token \(String(describing: token)) resolved to a non-finite value."
            )
        } else if value < 0 {
            Issue.record(
                "Dimension token \(String(describing: token)) resolved to a negative value."
            )
        }
    }
}

/// Reports every size component that is non-finite or negative in logical points.
///
/// The validator checks width and height independently, enumerates the complete public token
/// vocabulary, and continues after each issue. It records test issues only; production resolution
/// is not sanitized or changed.
///
/// - Parameter designSystem: The app-owned design system whose sizes are checked.
public func validateSizes<System: SizeDesignSystem>(in designSystem: System) {
    for token in System.Size.allCases {
        let size = designSystem.size(for: token)
        for (component, value) in [("width", size.width), ("height", size.height)] {
            if !value.isFinite {
                Issue.record(
                    "Size token \(String(describing: token)) has a non-finite \(component) component."
                )
            } else if value < 0 {
                Issue.record(
                    "Size token \(String(describing: token)) has a negative \(component) component."
                )
            }
        }
    }
}

/// Reports every corner-radius token that resolves to a non-finite or negative logical-point value.
///
/// The validator enumerates the complete public token vocabulary and continues after each issue.
/// It records test issues only; production resolution is not sanitized or changed.
///
/// - Parameter designSystem: The app-owned design system whose corner radii are checked.
public func validateCornerRadii<System: CornerRadiusDesignSystem>(in designSystem: System) {
    for token in System.CornerRadius.allCases {
        let value = designSystem.cornerRadius(for: token)
        if !value.isFinite {
            Issue.record(
                "Corner-radius token \(String(describing: token)) resolved to a non-finite value."
            )
        } else if value < 0 {
            Issue.record(
                "Corner-radius token \(String(describing: token)) resolved to a negative value."
            )
        }
    }
}

/// Reports every stroke-width token that resolves to a non-finite or negative logical-point value.
///
/// The validator enumerates the complete public token vocabulary and continues after each issue.
/// It records test issues only; production resolution is not sanitized or changed.
///
/// - Parameter designSystem: The app-owned design system whose stroke widths are checked.
public func validateStrokeWidths<System: StrokeWidthDesignSystem>(in designSystem: System) {
    for token in System.StrokeWidth.allCases {
        let value = designSystem.strokeWidth(for: token)
        if !value.isFinite {
            Issue.record(
                "Stroke-width token \(String(describing: token)) resolved to a non-finite value."
            )
        } else if value < 0 {
            Issue.record(
                "Stroke-width token \(String(describing: token)) resolved to a negative value."
            )
        }
    }
}

/// Reports every opacity token that is non-finite or outside the normalized unitless `0...1` range.
///
/// The validator enumerates the complete public token vocabulary and continues after each issue.
/// It records test issues only; production resolution is not sanitized or changed.
///
/// - Parameter designSystem: The app-owned design system whose opacity values are checked.
public func validateOpacities<System: OpacityDesignSystem>(in designSystem: System) {
    for token in System.Opacity.allCases {
        let value = designSystem.opacity(for: token)
        if !value.isFinite {
            Issue.record(
                "Opacity token \(String(describing: token)) resolved to a non-finite value."
            )
        } else if value < 0 || value > 1 {
            Issue.record(
                "Opacity token \(String(describing: token)) resolved outside the inclusive 0...1 range."
            )
        }
    }
}

/// Smoke-tests every semantic color and its public appearance-resolution paths.
///
/// The validator visits the complete semantic vocabulary, resolves both explicit appearances,
/// and exercises SwiftUI plus any context-free UIKit or AppKit adapter available on the current
/// platform. It does not impose validation rules on app-authored primitive color values.
///
/// - Parameter designSystem: The app-owned design system whose semantic colors are exercised.
public func validateColors<System: ColorDesignSystem>(in designSystem: System) {
    var lightEnvironment = EnvironmentValues()
    lightEnvironment.colorScheme = .light
    var darkEnvironment = EnvironmentValues()
    darkEnvironment.colorScheme = .dark

    for token in System.Semantic.allCases {
        let color = designSystem.color(for: token)
        _ = color.resolve(for: .light)
        _ = color.resolve(for: .dark)
        _ = color.resolve(in: lightEnvironment)
        _ = color.resolve(in: darkEnvironment)

        #if canImport(UIKit) && !os(watchOS)
        let adaptiveColor = color.adaptivePlatformColor
        _ = adaptiveColor.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        _ = adaptiveColor.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )
        #elseif canImport(AppKit)
        let adaptiveColor = color.adaptivePlatformColor
        let appearances = [NSAppearance(named: .aqua), NSAppearance(named: .darkAqua)]
        for appearance in appearances.compactMap({ $0 }) {
            appearance.performAsCurrentDrawingAppearance {
                _ = adaptiveColor.usingColorSpace(.deviceRGB)
            }
        }
        #endif
    }
}
