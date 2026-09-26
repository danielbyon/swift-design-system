import DesignSystem

enum SnapshotAppearance: String, CaseIterable, Sendable {
    case light
    case dark
}

enum SnapshotPrimitiveColor: PrimitiveColorToken {
    case ink
    case paper
    case blue
    case orange
}

enum SnapshotSemanticColor: SemanticColorToken {
    case canvas
    case accent
}

enum SnapshotGradientToken: GradientToken {
    case linear
    case radial
    case angular
}

typealias SnapshotGradientTheme = GradientTheme<
    SnapshotPrimitiveColor,
    SnapshotSemanticColor,
    SnapshotGradientToken
>

/// An immutable, package-owned color and gradient vocabulary for native rendering snapshots.
struct SnapshotDesignSystem: Sendable {
    let colorTheme: ColorTheme<SnapshotPrimitiveColor, SnapshotSemanticColor>
    let gradientTheme: SnapshotGradientTheme

    init() {
        let colorTheme = ColorTheme<SnapshotPrimitiveColor, SnapshotSemanticColor>(
            primitiveColor: { token in
                switch token {
                case .ink:
                    NumericColor.sRGB(red: 0.055, green: 0.075, blue: 0.14).platformColor
                case .paper:
                    NumericColor.sRGB(red: 0.95, green: 0.94, blue: 0.9).platformColor
                case .blue:
                    NumericColor.sRGB(red: 0.1, green: 0.4, blue: 0.88).platformColor
                case .orange:
                    NumericColor.sRGB(red: 0.96, green: 0.36, blue: 0.08).platformColor
                }
            },
            semanticColor: { token, palette in
                switch token {
                case .canvas:
                    palette.color(light: .paper, dark: .ink)
                case .accent:
                    palette.color(light: .blue, dark: .orange)
                }
            }
        )

        self.colorTheme = colorTheme
        self.gradientTheme = SnapshotGradientTheme(
            colorTheme: colorTheme,
            gradient: { token in
                let lightStops = [
                    GradientStop(semanticColor: SnapshotSemanticColor.canvas, location: 0),
                    GradientStop(semanticColor: SnapshotSemanticColor.accent, location: 1),
                ]
                let darkStops = [
                    GradientStop(semanticColor: SnapshotSemanticColor.accent, location: 0),
                    GradientStop(semanticColor: SnapshotSemanticColor.canvas, location: 1),
                ]

                switch token {
                case .linear:
                    return AdaptiveGradient(
                        light: .linear(stops: lightStops, startPoint: .leading, endPoint: .trailing),
                        dark: .linear(
                            stops: darkStops,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                case .radial:
                    return AdaptiveGradient(
                        light: .radial(
                            stops: lightStops,
                            center: .center,
                            startRadius: 0,
                            endRadius: 1
                        ),
                        dark: .radial(
                            stops: darkStops,
                            center: .topTrailing,
                            startRadius: 0.1,
                            endRadius: 1.25
                        )
                    )
                case .angular:
                    return AdaptiveGradient(
                        light: .angular(
                            stops: lightStops,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        dark: .angular(
                            stops: darkStops,
                            center: .center,
                            startAngle: .radians(0),
                            endAngle: .radians(2 * .pi)
                        )
                    )
                }
            }
        )
    }
}
