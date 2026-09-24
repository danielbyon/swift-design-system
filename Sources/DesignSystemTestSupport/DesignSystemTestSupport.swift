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
