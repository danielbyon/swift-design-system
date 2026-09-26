import DesignSystem
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Spacing roles used by the shared example feature.
enum ExampleSpacing: SpacingToken {
    case screenInset
    case sectionGap
    case contentGap
}

/// One-dimensional layout measurements used by the shared example feature.
enum ExampleDimension: DimensionToken {
    case headerHeight
    case captionHeight
    #if canImport(AppKit)
    /// Width of the native detail row shown by the AppKit host.
    case detailPanelWidth
    #endif
}

enum ExampleSize: SizeToken {
    case featureCard
}

enum ExampleCornerRadius: CornerRadiusToken {
    case card
}

enum ExampleStrokeWidth: StrokeWidthToken {
    case cardOutline
}

enum ExampleOpacity: OpacityToken {
    case secondaryContent
}

enum ExamplePrimitiveColor: PrimitiveColorToken {
    case numericInk
    case paper
    case nativeAccent
    case assetAccent
}

enum ExampleSemanticColor: SemanticColorToken {
    case primaryText
    case surface
    case accent
}

enum ExampleGradientToken: GradientToken {
    case featureLinear
    case featureRadial
    case featureAngular
}

/// The immutable app-owned vocabulary and resolver shared by every example host.
///
/// The concrete value keeps color, gradient, and scalar choices in the example app. The package
/// supplies capability interfaces and rendering mechanics only.
struct ExampleDesignSystem: SpacingDesignSystem, DimensionDesignSystem, SizeDesignSystem,
    CornerRadiusDesignSystem, StrokeWidthDesignSystem, OpacityDesignSystem, GradientDesignSystem {
    typealias Spacing = ExampleSpacing
    typealias Dimension = ExampleDimension
    typealias Size = ExampleSize
    typealias CornerRadius = ExampleCornerRadius
    typealias StrokeWidth = ExampleStrokeWidth
    typealias Opacity = ExampleOpacity
    typealias Primitive = ExamplePrimitiveColor
    typealias Semantic = ExampleSemanticColor
    typealias Gradient = ExampleGradientToken

    /// The default example configuration supplied by the app-owned SwiftUI environment.
    static let standard = Self()

    let gradientTheme = GradientTheme<
        ExamplePrimitiveColor,
        ExampleSemanticColor,
        ExampleGradientToken
    >(
        colorTheme: ColorTheme<ExamplePrimitiveColor, ExampleSemanticColor>(
            primitiveColor: { token in
                switch token {
                case .numericInk:
                    NumericColor.sRGB(red: 0.13, green: 0.16, blue: 0.21).platformColor
                case .paper:
                    NumericColor.grayscale(white: 0.96).platformColor
                case .nativeAccent:
                    nativeDynamicAccentColor()
                case .assetAccent:
                    assetAccentColor()
                }
            },
            semanticColor: { token, palette in
                switch token {
                case .primaryText:
                    palette.color(light: .numericInk, dark: .paper)
                case .surface:
                    palette.color(light: .paper, dark: .numericInk)
                case .accent:
                    palette.color(light: .nativeAccent, dark: .assetAccent)
                }
            }
        ),
        gradient: { token in
            switch token {
            case .featureLinear:
                AdaptiveGradient<ExampleSemanticColor>(
                    light: LinearGradientDefinition(
                        stops: [
                            GradientStop<ExampleSemanticColor>(semanticColor: .surface, location: 0),
                            GradientStop<ExampleSemanticColor>(semanticColor: .accent, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    dark: LinearGradientDefinition(
                        stops: [
                            GradientStop<ExampleSemanticColor>(semanticColor: .primaryText, location: 0.1),
                            GradientStop<ExampleSemanticColor>(semanticColor: .accent, location: 0.9),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            case .featureRadial:
                AdaptiveGradient<ExampleSemanticColor>(
                    light: .radial(
                        RadialGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .surface, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 1
                        )
                    ),
                    dark: .radial(
                        RadialGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .primaryText, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            center: .topTrailing,
                            startRadius: 0.15,
                            endRadius: 1.1
                        )
                    )
                )
            case .featureAngular:
                AdaptiveGradient<ExampleSemanticColor>(
                    light: .angular(
                        AngularGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .surface, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            center: .center,
                            startAngle: GradientAngle.degrees(-90),
                            endAngle: GradientAngle.degrees(270)
                        )
                    ),
                    dark: .angular(
                        AngularGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .primaryText, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            center: .center,
                            startAngle: GradientAngle.radians(0),
                            endAngle: GradientAngle.radians(2 * .pi)
                        )
                    )
                )
            }
        }
    )

    func spacing(for token: Spacing) -> CGFloat {
        switch token {
        case .screenInset:
            24
        case .sectionGap:
            16
        case .contentGap:
            8
        }
    }

    func dimension(for token: Dimension) -> CGFloat {
        switch token {
        case .headerHeight:
            28
        case .captionHeight:
            20
        #if canImport(AppKit)
        case .detailPanelWidth:
            320
        #endif
        }
    }

    func size(for token: Size) -> CGSize {
        switch token {
        case .featureCard:
            CGSize(width: 280, height: 120)
        }
    }

    func cornerRadius(for token: CornerRadius) -> CGFloat {
        switch token {
        case .card:
            12
        }
    }

    func strokeWidth(for token: StrokeWidth) -> CGFloat {
        switch token {
        case .cardOutline:
            1
        }
    }

    func opacity(for token: Opacity) -> Double {
        switch token {
        case .secondaryContent:
            0.72
        }
    }
}

/// Builds the app's system-aware accent source on UIKit and AppKit platforms.
private func nativeDynamicAccentColor() -> PlatformColor {
    #if canImport(UIKit) && os(watchOS)
    UIColor(Color.accentColor)
    #elseif canImport(UIKit)
    UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemOrange : .systemBlue
    }
    #elseif canImport(AppKit)
    NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .systemOrange : .systemBlue
    }
    #else
    Color.accentColor
    #endif
}

/// Loads the example asset-catalog color while keeping that resource app-owned.
private func assetAccentColor() -> PlatformColor {
    #if canImport(UIKit)
    UIColor(Color(.exampleAccent))
    #elseif canImport(AppKit)
    NSColor(resource: .exampleAccent)
    #else
    Color(.exampleAccent)
    #endif
}
