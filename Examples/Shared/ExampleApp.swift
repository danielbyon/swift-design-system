import DesignSystem
import SwiftUI

private enum ExampleSpacing: SpacingToken {
    case screenInset
    case sectionGap
    case contentGap
}

private enum ExamplePrimitiveColor: PrimitiveColorToken {
    case ink
    case paper
}

private enum ExampleSemanticColor: SemanticColorToken {
    case primaryText
    case surface
}

private struct ExampleDesignSystem: SpacingDesignSystem, ColorDesignSystem {
    typealias Spacing = ExampleSpacing
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
}

@main
struct DesignSystemExampleApp: App {
    private let designSystem = ExampleDesignSystem()

    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: designSystem.spacing(for: .sectionGap)) {
                Text("DesignSystem example host")

                VStack(alignment: .leading, spacing: designSystem.spacing(for: .contentGap)) {
                    Text("Semantic colors and spacing")
                        .foregroundStyle(designSystem.color(for: .primaryText))
                    Text("Layout values come from the app's design system.")
                        .foregroundStyle(designSystem.color(for: .primaryText))
                }
                .padding(designSystem.spacing(for: .contentGap))
                .background(designSystem.color(for: .surface))
            }
            .padding(designSystem.spacing(for: .screenInset))
        }
    }
}
