import DesignSystem
import SwiftUI

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
    case ink
    case paper
}

private enum ExampleSemanticColor: SemanticColorToken {
    case primaryText
    case surface
}

private struct ExampleDesignSystem: SpacingDesignSystem, DimensionDesignSystem, SizeDesignSystem,
    CornerRadiusDesignSystem, StrokeWidthDesignSystem, OpacityDesignSystem, ColorDesignSystem {
    typealias Spacing = ExampleSpacing
    typealias Dimension = ExampleDimension
    typealias Size = ExampleSize
    typealias CornerRadius = ExampleCornerRadius
    typealias StrokeWidth = ExampleStrokeWidth
    typealias Opacity = ExampleOpacity
    typealias Primitive = ExamplePrimitiveColor
    typealias Semantic = ExampleSemanticColor

    let colorTheme = ColorTheme<ExamplePrimitiveColor, ExampleSemanticColor>(
        primitiveColor: { token in
            switch token {
            case .ink:
                .black
            case .paper:
                .white
            }
        },
        semanticColor: { token, palette in
            switch token {
            case .primaryText:
                palette.color(light: .ink, dark: .paper)
            case .surface:
                palette.color(light: .paper, dark: .ink)
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

@main
struct DesignSystemExampleApp: App {
    private let designSystem = ExampleDesignSystem()

    var body: some Scene {
        WindowGroup {
            let cardSize = designSystem.size(for: .featureCard)
            let cardRadius = designSystem.cornerRadius(for: .card)

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
                }
                .frame(width: cardSize.width, height: cardSize.height, alignment: .leading)
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
