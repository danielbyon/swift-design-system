import CoreGraphics

#if canImport(UIKit) && !os(watchOS)
import CoreGraphics
import UIKit

/// A native UIKit view that draws a resolved semantic gradient.
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
        let colors = resolvedStops(resolved).map { stop in
            stop.color.resolvedColor(with: traitCollection).cgColor
        }
        drawResolvedGradient(
            resolved,
            colors: colors,
            in: context,
            bounds: bounds
        )
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

/// A native AppKit view that draws a resolved semantic gradient.
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
            colors = resolvedStops(resolved).map { $0.color.cgColor }
        }
        drawResolvedGradient(resolved, colors: colors, in: context, bounds: bounds)
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

private func resolvedStops(_ gradient: ResolvedGradient) -> [ResolvedLinearGradient.Stop] {
    switch gradient {
    case let .linear(value): value.stops
    case let .radial(value): value.stops
    case let .angular(value): value.stops
    }
}

private func drawResolvedGradient(
    _ gradient: ResolvedGradient,
    colors: [CGColor],
    in context: CGContext,
    bounds: CGRect
) {
    let stops = resolvedStops(gradient)
    guard colors.count == stops.count else { return }

    switch gradient {
    case let .linear(value):
        drawLinearGradient(value, colors: colors, in: context, bounds: bounds)
    case let .radial(value):
        drawRadialGradient(value, colors: colors, in: context, bounds: bounds)
    case let .angular(value):
        drawAngularGradient(value, colors: colors, in: context, bounds: bounds)
    }
}

private func drawRadialGradient(
    _ gradient: ResolvedRadialGradient,
    colors: [CGColor],
    in context: CGContext,
    bounds: CGRect
) {
    guard colors.count == gradient.stops.count,
          let drawable = makeGradient(gradient.stops, colors: colors)
    else { return }

    let center = CGPoint(
        x: bounds.minX + gradient.center.x * bounds.width,
        y: bounds.minY + gradient.center.y * bounds.height
    )
    let radiusScale = min(bounds.width, bounds.height)
    context.drawRadialGradient(
        drawable,
        startCenter: center,
        startRadius: gradient.startRadius * radiusScale,
        endCenter: center,
        endRadius: gradient.endRadius * radiusScale,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

private func drawAngularGradient(
    _ gradient: ResolvedAngularGradient,
    colors: [CGColor],
    in context: CGContext,
    bounds: CGRect
) {
    guard colors.count == gradient.stops.count,
          let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)
    else { return }

    let fullTurn = 2 * CGFloat.pi
    let authoredSpan = gradient.endAngle.radians - gradient.startAngle.radians
    let isNegativeOversweep = authoredSpan < -fullTurn
    let isReversed = authoredSpan < 0
    let sweep = abs(authoredSpan)
    let renderingStart: CGFloat
    if isNegativeOversweep {
        renderingStart = gradient.startAngle.radians
    } else if isReversed {
        renderingStart = gradient.endAngle.radians
    } else {
        renderingStart = gradient.startAngle.radians
    }
    let angularLocations: [CGFloat]
    let angularColors: [CGColor]
    if isReversed {
        let reversedStops = Array(zip(gradient.stops.map(\.location), colors).reversed())
        angularLocations = reversedStops.map { 1 - $0.0 }
        angularColors = reversedStops.map(\.1)
    } else {
        angularLocations = gradient.stops.map(\.location)
        angularColors = colors
    }
    let isOverswept = authoredSpan > fullTurn
    let effectiveStart = isOverswept
        ? renderingStart + sweep - fullTurn
        : renderingStart
    let sweepFraction = isOverswept ? 1 : sweep / fullTurn

    var mappedColors: [CGColor]
    var locations: [CGFloat]
    if isNegativeOversweep {
        // SwiftUI samples a negative multi-turn sweep backward through one full revolution.
        let turnFraction = fullTurn / sweep
        guard let finalColor = interpolatedAngularColor(
            at: turnFraction,
            locations: angularLocations,
            colors: angularColors,
            colorSpace: colorSpace
        ) else { return }
        mappedColors = [angularColors[0]]
        locations = [0]
        for (location, color) in zip(angularLocations, angularColors)
        where location > 0 && location < turnFraction {
            mappedColors.append(color)
            locations.append(location / turnFraction)
        }
        mappedColors.append(finalColor)
        locations.append(1)
    } else if isOverswept {
        let lastTurnStart = max(0, 1 - fullTurn / sweep)
        guard let firstColor = interpolatedAngularColor(
            at: lastTurnStart,
            locations: angularLocations,
            colors: angularColors,
            colorSpace: colorSpace
        ) else { return }
        mappedColors = [firstColor]
        locations = [0]
        for (location, color) in zip(angularLocations, angularColors) where location >= lastTurnStart {
            mappedColors.append(color)
            locations.append((location - lastTurnStart) / (1 - lastTurnStart))
        }
        if locations.last != 1 {
            mappedColors.append(angularColors[angularColors.count - 1])
            locations.append(1)
        }
    } else {
        mappedColors = [angularColors[0]]
        locations = [0]
        for (location, color) in zip(angularLocations, angularColors) {
            mappedColors.append(color)
            locations.append(location * sweepFraction)
        }
        if sweepFraction < 1 {
            let missingAreaMidpoint = (sweepFraction + 1) / 2
            mappedColors.append(angularColors[angularColors.count - 1])
            locations.append(sweepFraction)
            mappedColors.append(angularColors[angularColors.count - 1])
            locations.append(missingAreaMidpoint)
            mappedColors.append(angularColors[0])
            locations.append(missingAreaMidpoint)
            mappedColors.append(angularColors[0])
            locations.append(1)
        } else {
            mappedColors.append(angularColors[angularColors.count - 1])
            locations.append(1)
        }
    }

    guard let drawable = CGGradient(
        colorsSpace: colorSpace,
        colors: mappedColors as CFArray,
        locations: locations
    )
    else { return }

    let center = CGPoint(
        x: bounds.minX + gradient.center.x * bounds.width,
        y: bounds.minY + gradient.center.y * bounds.height
    )
    context.saveGState()
    defer { context.restoreGState() }
    context.addRect(bounds)
    context.clip()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: effectiveStart)
    CGContextDrawConicGradient(context, drawable, .zero, 0)
}

private func interpolatedAngularColor(
    at location: CGFloat,
    locations: [CGFloat],
    colors: [CGColor],
    colorSpace: CGColorSpace
) -> CGColor? {
    guard colors.count == locations.count,
          let first = colors.first,
          let last = colors.last
    else {
        return nil
    }
    if location <= locations[0] {
        return first.converted(to: colorSpace, intent: .defaultIntent, options: nil)
    }

    for upperIndex in 1..<locations.count {
        let lowerLocation = locations[upperIndex - 1]
        let upperLocation = locations[upperIndex]
        guard location <= upperLocation else { continue }

        if location == upperLocation || upperLocation == lowerLocation {
            var matchingIndex = upperIndex
            while matchingIndex + 1 < locations.count,
                  locations[matchingIndex + 1] == upperLocation {
                matchingIndex += 1
            }
            return colors[matchingIndex].converted(
                to: colorSpace,
                intent: .defaultIntent,
                options: nil
            )
        }

        let lowerColor = colors[upperIndex - 1].converted(
            to: colorSpace,
            intent: .defaultIntent,
            options: nil
        )
        let upperColor = colors[upperIndex].converted(
            to: colorSpace,
            intent: .defaultIntent,
            options: nil
        )
        guard let lowerComponents = lowerColor?.components,
              let upperComponents = upperColor?.components,
              lowerComponents.count == upperComponents.count,
              lowerComponents.count == 4
        else { return nil }

        let fraction = (location - lowerLocation) / (upperLocation - lowerLocation)
        let components = zip(lowerComponents, upperComponents).map { lower, upper in
            lower + (upper - lower) * fraction
        }
        return CGColor(colorSpace: colorSpace, components: components)
    }
    return last.converted(to: colorSpace, intent: .defaultIntent, options: nil)
}

private func makeGradient(
    _ stops: [ResolvedLinearGradient.Stop],
    colors: [CGColor]
) -> CGGradient? {
    guard colors.count == stops.count,
          let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)
    else { return nil }
    return CGGradient(
        colorsSpace: colorSpace,
        colors: colors as CFArray,
        locations: stops.map(\.location)
    )
}
