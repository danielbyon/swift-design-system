import CoreGraphics

#if canImport(UIKit) && !os(watchOS)
import CoreGraphics
import UIKit

/// A native UIKit view that draws a resolved semantic linear gradient.
///
/// The view consumes only `DesignGradient`; it does not know the app's token types or theme. It
/// resolves the current semantic appearance while drawing and redraws when UIKit reports an
/// interface-style change, preserving dynamic behavior in the source `UIColor` values.
@MainActor
public final class DesignGradientView: UIView {
    /// The adaptive gradient rendered by this view.
    public var gradient: DesignGradient? {
        didSet { setNeedsDisplay() }
    }

    /// Creates a view that renders the supplied design gradient.
    public init(gradient: DesignGradient) {
        self.gradient = gradient
        super.init(frame: .zero)
        isOpaque = false
        contentMode = .redraw
        observeAppearanceChanges()
    }

    /// Creates an empty gradient view for native view construction APIs.
    public override init(frame: CGRect) {
        gradient = nil
        super.init(frame: frame)
        isOpaque = false
        contentMode = .redraw
        observeAppearanceChanges()
    }

    /// Creates an empty gradient view from a storyboard or archive.
    public required init?(coder: NSCoder) {
        gradient = nil
        super.init(coder: coder)
        isOpaque = false
        contentMode = .redraw
        observeAppearanceChanges()
    }

    public override func draw(_ rect: CGRect) {
        guard let gradient, let context = UIGraphicsGetCurrentContext() else { return }
        let appearance: DesignAppearance = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        let resolved = gradient.resolve(for: appearance)
        let colors = resolved.stops.map { stop in
            stop.color.resolvedColor(with: traitCollection).cgColor
        }
        drawLinearGradient(resolved, colors: colors, in: context, bounds: bounds)
    }

    private func observeAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.setNeedsDisplay()
        }
    }
}

#elseif canImport(AppKit)
import AppKit
import CoreGraphics

/// A native AppKit view that draws a resolved semantic linear gradient.
///
/// The view consumes only `DesignGradient`; it does not know the app's token types or theme. It
/// resolves the current effective appearance while drawing and redraws when AppKit reports an
/// appearance change, preserving dynamic behavior in the source `NSColor` values.
@MainActor
public final class DesignGradientView: NSView {
    /// The adaptive gradient rendered by this view.
    public var gradient: DesignGradient? {
        didSet { needsDisplay = true }
    }

    /// Creates a view that renders the supplied design gradient.
    public init(gradient: DesignGradient) {
        self.gradient = gradient
        super.init(frame: .zero)
        wantsLayer = false
    }

    /// Creates an empty gradient view for native view construction APIs.
    public override init(frame frameRect: NSRect) {
        gradient = nil
        super.init(frame: frameRect)
        wantsLayer = false
    }

    /// Creates an empty gradient view from a storyboard or archive.
    public required init?(coder: NSCoder) {
        gradient = nil
        super.init(coder: coder)
        wantsLayer = false
    }

    public override var isFlipped: Bool { true }

    public override func draw(_ dirtyRect: NSRect) {
        guard let gradient, let context = NSGraphicsContext.current?.cgContext else { return }
        let appearance: DesignAppearance = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            == .darkAqua ? .dark : .light
        let resolved = gradient.resolve(for: appearance)
        var colors: [CGColor] = []
        effectiveAppearance.performAsCurrentDrawingAppearance {
            colors = resolved.stops.map { $0.color.cgColor }
        }
        drawLinearGradient(resolved, colors: colors, in: context, bounds: bounds)
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
#endif

private func drawLinearGradient(
    _ gradient: ResolvedLinearGradient,
    colors: [CGColor],
    in context: CGContext,
    bounds: CGRect
) {
    guard colors.count == gradient.stops.count else { return }
    // Display P3 is device-independent and retains wide-gamut semantic color stops.
    guard let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) else { return }
    let locations = gradient.stops.map(\.location)
    guard let drawable = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
    else { return }

    let start = CGPoint(
        x: bounds.minX + gradient.startPoint.x * bounds.width,
        y: bounds.minY + gradient.startPoint.y * bounds.height
    )
    let end = CGPoint(
        x: bounds.minX + gradient.endPoint.x * bounds.width,
        y: bounds.minY + gradient.endPoint.y * bounds.height
    )
    context.drawLinearGradient(
        drawable,
        start: start,
        end: end,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}
