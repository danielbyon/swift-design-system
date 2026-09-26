import DesignSystem
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Demonstrates shared SwiftUI styling and passes resolved values into native adapters.
///
/// The view owns the environment lookup. UIKit and AppKit representables receive concrete colors
/// and gradients through their initializers, keeping native rendering independent from app theme
/// lookup.
struct ExampleFeatureView: View {
    @Environment(\.exampleDesignSystem) private var designSystem

    var body: some View {
        let cardSize = designSystem.size(for: .featureCard)
        let cardRadius = designSystem.cornerRadius(for: .card)
        let linearGradient = designSystem.gradient(for: .featureLinear)
        let radialGradient = designSystem.gradient(for: .featureRadial)
        let angularGradient = designSystem.gradient(for: .featureAngular)
        let accentColor = designSystem.color(for: .accent)

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
                    .foregroundStyle(accentColor)
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

            #if canImport(UIKit) && !os(watchOS)
            ExampleNativeAccentLabel(color: accentColor.adaptivePlatformColor)
                .accessibilityLabel("Native semantic accent color")
            HStack(spacing: designSystem.spacing(for: .contentGap)) {
                Text("Native angular gradient")
                ExampleNativeGradientView(gradient: angularGradient)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                    .accessibilityLabel("Native angular semantic gradient")
            }
            #elseif canImport(AppKit)
            ExampleNativeAccentLabel(color: accentColor.adaptivePlatformColor)
                .accessibilityLabel("Native semantic accent color")
            HStack(spacing: designSystem.spacing(for: .contentGap)) {
                Text("Native angular gradient")
                ExampleNativeGradientView(gradient: angularGradient)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                    .accessibilityLabel("Native angular semantic gradient")
            }
                .frame(
                    maxWidth: designSystem.dimension(for: .detailPanelWidth),
                    alignment: .leading
                )
            #endif
        }
        .padding(designSystem.spacing(for: .screenInset))
    }
}

#if canImport(UIKit) && !os(watchOS)
/// Displays a resolved semantic color in a UIKit-native label.
private struct ExampleNativeAccentLabel: UIViewRepresentable {
    let color: PlatformColor

    init(color: PlatformColor) {
        self.color = color
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.text = "Resolved accent from the app design system"
        label.textColor = color
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.textColor = color
    }
}

/// Renders a resolved semantic gradient using the package's UIKit view adapter.
private struct ExampleNativeGradientView: UIViewRepresentable {
    let gradient: DesignGradient

    init(gradient: DesignGradient) {
        self.gradient = gradient
    }

    func makeUIView(context: Context) -> DesignGradientView {
        DesignGradientView(gradient: gradient)
    }

    func updateUIView(_ view: DesignGradientView, context: Context) {
        view.gradient = gradient
    }
}
#elseif canImport(AppKit)
/// Displays a resolved semantic color in an AppKit-native text field.
private struct ExampleNativeAccentLabel: NSViewRepresentable {
    let color: PlatformColor

    init(color: PlatformColor) {
        self.color = color
    }

    func makeNSView(context: Context) -> NSTextField {
        let label = NSTextField(labelWithString: "Resolved accent from the app design system")
        label.textColor = color
        return label
    }

    func updateNSView(_ label: NSTextField, context: Context) {
        label.textColor = color
    }
}

/// Renders a resolved semantic gradient using the package's AppKit view adapter.
private struct ExampleNativeGradientView: NSViewRepresentable {
    let gradient: DesignGradient

    init(gradient: DesignGradient) {
        self.gradient = gradient
    }

    func makeNSView(context: Context) -> DesignGradientView {
        DesignGradientView(gradient: gradient)
    }

    func updateNSView(_ view: DesignGradientView, context: Context) {
        view.gradient = gradient
    }
}
#endif
