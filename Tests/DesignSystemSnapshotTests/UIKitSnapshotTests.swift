#if canImport(UIKit) && !os(watchOS)
import DesignSystem
import SnapshotTesting
import Testing
import UIKit

private enum SnapshotGeometry {
    static let size = CGSize(width: 64, height: 64)
}

@MainActor
private final class AdaptiveColorSnapshotView: UIView {
    private let color: UIColor

    init(color: UIColor) {
        self.color = color
        super.init(frame: CGRect(origin: .zero, size: SnapshotGeometry.size))
        isOpaque = true
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("AdaptiveColorSnapshotView does not support storyboard construction.")
    }

    override func draw(_ rect: CGRect) {
        color.setFill()
        UIRectFill(bounds)
    }
}

@Suite(.snapshots)
struct UIKitSnapshotTests {
    @Test(arguments: SnapshotAppearance.allCases)
    @MainActor
    func adaptiveColor(appearance: SnapshotAppearance) {
        let color = SnapshotDesignSystem()
            .colorTheme
            .color(for: .accent)
            .adaptivePlatformColor
        let view = AdaptiveColorSnapshotView(color: color)
        view.overrideUserInterfaceStyle = appearance.userInterfaceStyle

        assertUIKitSnapshot(
            of: view,
            appearance: appearance,
            named: "adaptive-color-\(appearance.rawValue)",
            testName: #function,
            file: #filePath,
            line: #line
        )
    }

    @Test(arguments: SnapshotAppearance.allCases)
    @MainActor
    func linearGradient(appearance: SnapshotAppearance) {
        assertGradient(.linear, appearance: appearance, name: "linear-gradient", testName: #function)
    }

    @Test(arguments: SnapshotAppearance.allCases)
    @MainActor
    func radialGradient(appearance: SnapshotAppearance) {
        assertGradient(.radial, appearance: appearance, name: "radial-gradient", testName: #function)
    }

    @Test(arguments: SnapshotAppearance.allCases)
    @MainActor
    func angularGradient(appearance: SnapshotAppearance) {
        assertGradient(.angular, appearance: appearance, name: "angular-gradient", testName: #function)
    }

    @MainActor
    private func assertGradient(
        _ token: SnapshotGradientToken,
        appearance: SnapshotAppearance,
        name: String,
        testName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = DesignGradientView(gradient: SnapshotDesignSystem().gradientTheme.gradient(for: token))
        view.frame = CGRect(origin: .zero, size: SnapshotGeometry.size)
        view.overrideUserInterfaceStyle = appearance.userInterfaceStyle

        assertUIKitSnapshot(
            of: view,
            appearance: appearance,
            named: "\(name)-\(appearance.rawValue)",
            testName: testName,
            file: file,
            line: line
        )
    }
}

@MainActor
private func assertUIKitSnapshot<View: UIView>(
    of view: View,
    appearance: SnapshotAppearance,
    named name: String,
    testName: String,
    file: StaticString,
    line: UInt
) {
    let traits = UITraitCollection { traits in
        traits.userInterfaceStyle = appearance.userInterfaceStyle
        traits.displayScale = 1
    }

    assertSnapshot(
        of: view,
        as: Snapshotting<UIView, UIImage>.image(
            precision: 1,
            perceptualPrecision: 1,
            size: SnapshotGeometry.size,
            traits: traits
        ),
        named: name,
        record: SnapshotRecordingMode.current,
        file: file,
        testName: testName,
        line: line
    )
}

private extension SnapshotAppearance {
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}
#endif
