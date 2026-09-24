import DesignSystem
import SwiftUI

private enum ExampleSpacing: SpacingToken {
    case screenInset
    case sectionGap
    case contentGap
}

private struct ExampleDesignSystem: SpacingDesignSystem {
    typealias Spacing = ExampleSpacing

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
                    Text("Semantic spacing")
                    Text("Layout values come from the app's design system.")
                }
            }
            .padding(designSystem.spacing(for: .screenInset))
        }
    }
}
