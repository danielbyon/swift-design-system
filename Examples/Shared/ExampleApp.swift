import DesignSystem
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private enum ExampleSpacing: SpacingToken {
    case screenInset
    case sectionGap
    case contentGap
}

private enum ExampleDimension: DimensionToken {
    case headerHeight
    case captionHeight
}

private enum ExampleSize: SizeToken {
    case featureCard
}

private enum ExampleCornerRadius: CornerRadiusToken {
    case card
}

private enum ExampleStrokeWidth: StrokeWidthToken {
    case cardOutline
}

private enum ExampleOpacity: OpacityToken {
    case secondaryContent
}

private enum ExamplePrimitiveColor: PrimitiveColorToken {
    case numericInk
    case paper
    case nativeAccent
    case assetAccent
}

private enum ExampleSemanticColor: SemanticColorToken {
    case primaryText
    case surface
    case accent
}

private enum ExampleGradientToken: GradientToken {
    case featureLinear
    case featureRadial
    case featureAngular
}

private struct ExampleDesignSystem: SpacingDesignSystem, DimensionDesignSystem, SizeDesignSystem,
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

#if canImport(UIKit) && !os(watchOS)
private struct ExampleNativeGradientView: UIViewRepresentable {
    let gradient: DesignGradient

    func makeUIView(context: Context) -> DesignGradientView {
        DesignGradientView(gradient: gradient)
    }

    func updateUIView(_ view: DesignGradientView, context: Context) {
        view.gradient = gradient
    }
}
#elseif canImport(AppKit)
private struct ExampleNativeGradientView: NSViewRepresentable {
    let gradient: DesignGradient

    func makeNSView(context: Context) -> DesignGradientView {
        DesignGradientView(gradient: gradient)
    }

    func updateNSView(_ view: DesignGradientView, context: Context) {
        view.gradient = gradient
    }
}
#endif

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

private func assetAccentColor() -> PlatformColor {
    #if canImport(UIKit)
    UIColor(Color(.exampleAccent))
    #elseif canImport(AppKit)
    NSColor(resource: .exampleAccent)
    #else
    Color(.exampleAccent)
    #endif
}

@main
struct DesignSystemExampleApp: App {
    private let designSystem = ExampleDesignSystem()

    var body: some Scene {
        WindowGroup {
            let cardSize = designSystem.size(for: .featureCard)
            let cardRadius = designSystem.cornerRadius(for: .card)
            let linearGradient = designSystem.gradient(for: .featureLinear)
            let radialGradient = designSystem.gradient(for: .featureRadial)
            let angularGradient = designSystem.gradient(for: .featureAngular)

            VStack(alignment: .leading, spacing: designSystem.spacing(for: .sectionGap)) {
                Text("DesignSystem example host")

                VStack(alignment: .leading, spacing: designSystem.spacing(for: .contentGap)) {
                    Text("Scalar capabilities and semantic colors")
                        .font(.headline)
                        .foregroundStyle(designSystem.color(for: .primaryText))
                        .frame(height: designSystem.dimension(for: .headerHeight))
                    Text("Logical-point layout values come from the app's design system.")
                        .foregroundStyle(designSystem.color(for: .primaryText))
                        .opacity(designSystem.opacity(for: .secondaryContent))
                        .frame(height: designSystem.dimension(for: .captionHeight))
                    Text("Native dynamic and asset-backed color sources")
                        .foregroundStyle(designSystem.color(for: .accent))
                    HStack(spacing: designSystem.spacing(for: .contentGap)) {
                        RoundedRectangle(cornerRadius: cardRadius)
                            .fill(linearGradient)
                        RoundedRectangle(cornerRadius: cardRadius)
                            .fill(radialGradient)
                        RoundedRectangle(cornerRadius: cardRadius)
                            .fill(angularGradient)
                    }
                        .frame(height: 48)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Linear, radial, and angular semantic gradients")
                    #if canImport(UIKit) && !os(watchOS)
                    ExampleNativeGradientView(gradient: angularGradient)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                        .accessibilityLabel("Native angular semantic gradient")
                    #elseif canImport(AppKit)
                    ExampleNativeGradientView(gradient: angularGradient)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                        .accessibilityLabel("Native angular semantic gradient")
                    #endif
                }
                .frame(
                    maxWidth: cardSize.width,
                    minHeight: cardSize.height,
                    maxHeight: cardSize.height,
                    alignment: .leading
                )
                .padding(designSystem.spacing(for: .contentGap))
                .background {
                    RoundedRectangle(cornerRadius: cardRadius)
                        .fill(designSystem.color(for: .surface))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cardRadius)
                        .stroke(
                            designSystem.color(for: .primaryText),
                            lineWidth: designSystem.strokeWidth(for: .cardOutline)
                        )
                }
            }
            .padding(designSystem.spacing(for: .screenInset))
        }
    }
}
