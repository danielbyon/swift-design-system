/*
 DesignSystemTestSupport provides Swift Testing helpers for consuming apps' test targets. Each
 capability validator enumerates its app-owned token vocabulary and exercises public DesignSystem
 APIs. Scalar validators report every detected issue without changing authored values. Color and
 gradient validators exercise public appearance and rendering paths; native gradient drawing is
 isolated to the main actor on platforms that provide UIKit or AppKit.
 */

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

/// Validates gradient token enumeration, appearance resolution, and supported SwiftUI style paths.
///
/// The validator visits the complete gradient vocabulary, resolves both appearances through public
/// native-preserving descriptions, and constructs bounds-aware SwiftUI fills for every gradient kind.
/// It also resolves generic SwiftUI styles for linear and angular gradients. Radial gradients are
/// omitted from that generic style path because it has no rendered bounds; their generic release
/// fallback is transparent. Native `DesignGradientView` drawing is available separately through
/// `validateNativeGradients(in:)` on supported platforms.
///
/// - Parameter designSystem: The app-owned design system whose semantic gradients are exercised.
public func validateGradients<System: GradientDesignSystem>(in designSystem: System) {
    var lightEnvironment = EnvironmentValues()
    lightEnvironment.colorScheme = .light
    var darkEnvironment = EnvironmentValues()
    darkEnvironment.colorScheme = .dark

    for token in System.Gradient.allCases {
        let gradient = designSystem.gradient(for: token)
        _ = Rectangle().fill(gradient).environment(\.colorScheme, .light)
        _ = Rectangle().fill(gradient).environment(\.colorScheme, .dark)

        switch gradient.resolve(for: .light) {
        case .linear, .angular:
            _ = gradient.resolve(in: lightEnvironment)
            _ = Rectangle().fill(gradient.anyShapeStyle).environment(\.colorScheme, .light)
        case .radial:
            break
        }

        switch gradient.resolve(for: .dark) {
        case .linear, .angular:
            _ = gradient.resolve(in: darkEnvironment)
            _ = Rectangle().fill(gradient.anyShapeStyle).environment(\.colorScheme, .dark)
        case .radial:
            break
        }
    }
}

#if canImport(UIKit) && !os(watchOS)
/// Smoke-renders every semantic gradient through the public native view in light and dark styles.
///
/// Use this main-actor helper from consumer tests that can exercise UIKit. It draws into temporary
/// images to execute native rendering without comparing pixels or requiring golden fixtures.
///
/// - Parameter designSystem: The app-owned design system whose semantic gradients are rendered.
@MainActor
public func validateNativeGradients<System: GradientDesignSystem>(in designSystem: System) {
    let size = CGSize(width: 64, height: 64)
    let renderer = UIGraphicsImageRenderer(size: size)

    for token in System.Gradient.allCases {
        let view = DesignGradientView(gradient: designSystem.gradient(for: token))
        view.frame = CGRect(origin: .zero, size: size)

        for style in [UIUserInterfaceStyle.light, .dark] {
            view.overrideUserInterfaceStyle = style
            _ = renderer.image { _ in
                view.draw(view.bounds)
            }
        }
    }
}
#elseif canImport(AppKit)
/// Smoke-renders every semantic gradient through the public native view in light and dark appearances.
///
/// Use this main-actor helper from consumer tests that can exercise AppKit. It draws into temporary
/// bitmaps to execute native rendering without comparing pixels or requiring golden fixtures.
///
/// - Parameter designSystem: The app-owned design system whose semantic gradients are rendered.
@MainActor
public func validateNativeGradients<System: GradientDesignSystem>(in designSystem: System) {
    let size = CGSize(width: 64, height: 64)
    let appearances: [(NSAppearance.Name, String)] = [(.aqua, "light"), (.darkAqua, "dark")]

    for token in System.Gradient.allCases {
        let view = DesignGradientView(gradient: designSystem.gradient(for: token))
        view.frame = CGRect(origin: .zero, size: size)

        for (appearanceName, label) in appearances {
            guard let appearance = NSAppearance(named: appearanceName) else {
                Issue.record("AppKit \(label) appearance must be available for gradient rendering.")
                continue
            }
            view.appearance = appearance

            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size.width),
                pixelsHigh: Int(size.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ), let context = NSGraphicsContext(bitmapImageRep: bitmap)
            else {
                Issue.record("AppKit must create a bitmap context for gradient rendering.")
                continue
            }

            let previousContext = NSGraphicsContext.current
            defer { NSGraphicsContext.current = previousContext }
            context.cgContext.saveGState()
            defer { context.cgContext.restoreGState() }
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            NSGraphicsContext.current = context
            view.draw(view.bounds)
        }
    }
}
#endif
