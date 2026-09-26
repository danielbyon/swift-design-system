import SwiftUI

/// Supplies the example app's concrete design system to SwiftUI feature views.
private struct ExampleDesignSystemEnvironmentKey: EnvironmentKey {
    static let defaultValue = ExampleDesignSystem.standard
}

extension EnvironmentValues {
    /// The app-owned design system consumed by the shared example feature.
    var exampleDesignSystem: ExampleDesignSystem {
        get { self[ExampleDesignSystemEnvironmentKey.self] }
        set { self[ExampleDesignSystemEnvironmentKey.self] = newValue }
    }
}
