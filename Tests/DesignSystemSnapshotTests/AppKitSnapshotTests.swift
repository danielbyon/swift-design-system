#if canImport(AppKit)
import AppKit
import DesignSystem
import SnapshotTesting
import Testing

private enum SnapshotGeometry {
    static let pixels = 64
    static let size = NSSize(width: pixels, height: pixels)
}

@MainActor
private final class AdaptiveColorSnapshotView: NSView {
    private let color: NSColor

    init(color: NSColor, appearance: NSAppearance) {
        self.color = color
        super.init(frame: NSRect(origin: .zero, size: SnapshotGeometry.size))
        self.appearance = appearance
        wantsLayer = false
    }

    required init?(coder: NSCoder) {
        fatalError("AdaptiveColorSnapshotView does not support archive construction.")
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            color.setFill()
            NSBezierPath(rect: bounds).fill()
        }
    }
}

@Suite(.snapshots)
struct AppKitSnapshotTests {
    @Test(arguments: SnapshotAppearance.allCases)
    @MainActor
    func adaptiveColor(appearance: SnapshotAppearance) {
        let color = SnapshotDesignSystem()
            .colorTheme
            .color(for: .accent)
            .adaptivePlatformColor
        let view = AdaptiveColorSnapshotView(color: color, appearance: appearance.nsAppearance)

        assertAppKitSnapshot(
            of: view,
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
        view.frame = NSRect(origin: .zero, size: SnapshotGeometry.size)
        view.appearance = appearance.nsAppearance

        assertAppKitSnapshot(
            of: view,
            named: "\(name)-\(appearance.rawValue)",
            testName: testName,
            file: file,
            line: line
        )
    }
}

@MainActor
private func assertAppKitSnapshot<View: NSView>(
    of view: View,
    named name: String,
    testName: String,
    file: StaticString,
    line: UInt
) {
    let renderedImage = renderAtOnePixelPerPoint(view)
    assertSnapshot(
        of: renderedImage,
        as: Snapshotting<NSImage, NSImage>.image(precision: 1, perceptualPrecision: 1),
        named: name,
        record: SnapshotRecordingMode.current,
        file: file,
        testName: testName,
        line: line
    )
}

@MainActor
private func renderAtOnePixelPerPoint(_ view: NSView) -> NSImage {
    view.frame = NSRect(origin: .zero, size: SnapshotGeometry.size)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: SnapshotGeometry.pixels,
        pixelsHigh: SnapshotGeometry.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        Issue.record("AppKit must provide a fixed-size bitmap context for snapshot rendering.")
        return NSImage(size: SnapshotGeometry.size)
    }

    bitmap.size = SnapshotGeometry.size
    let previousContext = NSGraphicsContext.current
    NSGraphicsContext.current = NSGraphicsContext(
        cgContext: bitmapContext.cgContext,
        flipped: true
    )
    defer { NSGraphicsContext.current = previousContext }

    view.draw(view.bounds)

    let image = NSImage(size: SnapshotGeometry.size)
    image.addRepresentation(bitmap)
    return image
}

private extension SnapshotAppearance {
    var nsAppearance: NSAppearance {
        NSAppearance(named: self == .dark ? .darkAqua : .aqua)!
    }
}
#endif
