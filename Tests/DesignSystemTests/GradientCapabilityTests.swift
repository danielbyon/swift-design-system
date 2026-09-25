import DesignSystem
import DesignSystemTestSupport
import SwiftUI
import Testing
import Synchronization

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit)
@Test @MainActor
func appKitGradientViewRendersAppearanceColorsStopLocationsAndGeometry() {
    guard let lightAppearance = NSAppearance(named: .aqua),
          let darkAppearance = NSAppearance(named: .darkAqua)
    else {
        Issue.record("AppKit light and dark appearances must be available for gradient rendering.")
        return
    }

    let colorTheme = FixtureGradientDesignSystem().gradientTheme.colorTheme

    func gradient(darkAccentLocation: CGFloat) -> DesignGradient {
        FixtureGradientTheme(
            colorTheme: colorTheme,
            gradient: { _ in
                AdaptiveGradient<FixtureSemanticColor>(
                    light: LinearGradientDefinition(
                        stops: [
                            GradientStop(semanticColor: .content, location: 0),
                            GradientStop(semanticColor: .accent, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    dark: LinearGradientDefinition(
                        stops: [
                            GradientStop(semanticColor: .content, location: 0.15),
                            GradientStop(semanticColor: .accent, location: darkAccentLocation),
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
            }
        ).gradient(for: .hero)
    }

    let host = NSView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    host.appearance = lightAppearance
    let view = DesignGradientView(gradient: gradient(darkAccentLocation: 0.75))
    view.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
    host.addSubview(view)

    var currentDarkAccentLocation: CGFloat = 0.75
    func render(darkAccentLocation: CGFloat) -> NSBitmapImageRep? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 64,
            pixelsHigh: 64,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            return nil
        }

        let previousContext = NSGraphicsContext.current
        defer { NSGraphicsContext.current = previousContext }
        context.cgContext.saveGState()
        defer { context.cgContext.restoreGState() }
        context.cgContext.translateBy(x: 0, y: view.bounds.height)
        context.cgContext.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = context
        if currentDarkAccentLocation != darkAccentLocation {
            view.gradient = gradient(darkAccentLocation: darkAccentLocation)
            currentDarkAccentLocation = darkAccentLocation
        }
        view.draw(view.bounds)
        return bitmap
    }

    guard let lightBitmap = render(darkAccentLocation: 0.75)
    else {
        Issue.record("AppKit must create bitmap contexts for gradient rendering.")
        return
    }

    host.appearance = darkAppearance
    #expect(view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)

    guard let darkBitmap = render(darkAccentLocation: 0.75),
          let shiftedStopBitmap = render(darkAccentLocation: 0.45)
    else {
        Issue.record("AppKit must create bitmap contexts for gradient rendering.")
        return
    }

    func color(_ bitmap: NSBitmapImageRep, x: Int, y: Int) -> NSColor? {
        bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
    }

    guard let lightStart = color(lightBitmap, x: 2, y: 32),
          let lightEnd = color(lightBitmap, x: 62, y: 32),
          let darkStart = color(darkBitmap, x: 2, y: 62),
          let darkEnd = color(darkBitmap, x: 62, y: 2),
          let darkOffAxis = color(darkBitmap, x: 8, y: 8),
          let authoredLocationSample = color(darkBitmap, x: 22, y: 42),
          let shiftedLocationSample = color(shiftedStopBitmap, x: 22, y: 42)
    else {
        Issue.record("Rendered gradient pixels must be readable in device RGB.")
        return
    }

    #expect(lightStart.redComponent < 0.1)
    #expect(lightStart.greenComponent < 0.1)
    #expect(lightStart.blueComponent < 0.1)
    #expect(lightEnd.blueComponent > 0.75)

    #expect(darkStart.greenComponent > 0.95)
    #expect(darkEnd.redComponent > 0.95)
    #expect(darkEnd.greenComponent < 0.05)
    #expect(darkOffAxis.greenComponent > 0.3)
    #expect(darkOffAxis.greenComponent < 0.8)
    #expect(authoredLocationSample.greenComponent > shiftedLocationSample.greenComponent + 0.15)
}

#if canImport(AppKit)
@Test @MainActor
func appKitGradientViewPreservesDisplayP3StopColors() {
    let sourceColor = NumericColor.displayP3(red: 1, green: 0, blue: 0).platformColor
    #expect(sourceColor.cgColor.colorSpace?.name == CGColorSpace.displayP3)

    let colorTheme = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>(
        primitiveColor: { _ in
            NumericColor.displayP3(red: 1, green: 0, blue: 0).platformColor
        },
        semanticColor: { _, palette in
            palette.color(light: .accent, dark: .accent)
        }
    )
    let definition = LinearGradientDefinition<FixtureSemanticColor>(
        stops: [
            GradientStop(semanticColor: .accent, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    let gradient = FixtureGradientTheme(
        colorTheme: colorTheme,
        gradient: { _ in AdaptiveGradient(light: definition, dark: definition) }
    ).gradient(for: .hero)
    let view = DesignGradientView(gradient: gradient)
    view.frame = CGRect(x: 0, y: 0, width: 32, height: 32)

    guard let colorSpace = CGColorSpace(name: CGColorSpace.displayP3),
          let outputColorSpace = NSColorSpace(cgColorSpace: colorSpace)
    else {
        Issue.record("AppKit must create Display P3 color spaces for gradient rendering.")
        return
    }

    func bitmapColor(drawing: (CGContext) -> Void) -> NSColor? {
        guard let cgContext = CGContext(
            data: nil,
            width: 32,
            height: 32,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        else {
            return nil
        }

        drawing(cgContext)

        guard let image = cgContext.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: image)
            .colorAt(x: 16, y: 16)?
            .usingColorSpace(outputColorSpace)
    }

    guard let referenceColor = bitmapColor(drawing: { context in
        context.setFillColor(sourceColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
    }),
    let renderedColor = bitmapColor(drawing: { context in
        let previousContext = NSGraphicsContext.current
        defer { NSGraphicsContext.current = previousContext }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        view.draw(view.bounds)
    })
    else {
        Issue.record("AppKit must render and read Display P3 bitmap colors.")
        return
    }

    #expect(abs(referenceColor.redComponent - renderedColor.redComponent) < 0.005)
    #expect(abs(referenceColor.greenComponent - renderedColor.greenComponent) < 0.005)
    #expect(abs(referenceColor.blueComponent - renderedColor.blueComponent) < 0.005)
}
#endif
#endif

private enum FixturePrimitiveColor: PrimitiveColorToken {
    case ink
    case paper
    case accent
    case darkAccent
}

private enum FixtureSemanticColor: SemanticColorToken {
    case content
    case accent
}

private enum FixtureGradientToken: GradientToken {
    case hero
    case secondary
}

private typealias FixtureGradientTheme = GradientTheme<
    FixturePrimitiveColor,
    FixtureSemanticColor,
    FixtureGradientToken
>

private final class GradientTokenRecorder: @unchecked Sendable {
    private let values = Mutex<[FixtureGradientToken]>([])

    var tokens: [FixtureGradientToken] {
        values.withLock { $0 }
    }

    func record(_ token: FixtureGradientToken) {
        values.withLock { $0.append(token) }
    }
}

private struct FixtureGradientDesignSystem: GradientDesignSystem {
    typealias Primitive = FixturePrimitiveColor
    typealias Semantic = FixtureSemanticColor
    typealias Gradient = FixtureGradientToken

    let gradientTheme: FixtureGradientTheme

    init(onResolveGradient: @escaping @Sendable (FixtureGradientToken) -> Void = { _ in }) {
        let colorTheme = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>(
            primitiveColor: primitiveColor(for:),
            semanticColor: { token, palette in
                switch token {
                case .content:
                    palette.color(light: .ink, dark: .paper)
                case .accent:
                    palette.color(light: .accent, dark: .darkAccent)
                }
            }
        )

        gradientTheme = FixtureGradientTheme(
            colorTheme: colorTheme,
            gradient: { token in
                onResolveGradient(token)
                return switch token {
                case .hero:
                    AdaptiveGradient<FixtureSemanticColor>(
                        light: LinearGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .content, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        dark: LinearGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .accent, location: 0.15),
                                GradientStop(semanticColor: .content, location: 0.55),
                                GradientStop(semanticColor: .accent, location: 0.95),
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                case .secondary:
                    AdaptiveGradient<FixtureSemanticColor>(
                        light: LinearGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .accent, location: 0.2),
                                GradientStop(semanticColor: .content, location: 0.8),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        dark: LinearGradientDefinition(
                            stops: [
                                GradientStop(semanticColor: .content, location: 0),
                                GradientStop(semanticColor: .accent, location: 1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        )
    }
}

private func primitiveColor(for token: FixturePrimitiveColor) -> PlatformColor {
    #if canImport(UIKit)
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    case .accent:
        .blue
    case .darkAccent:
        .red
    }
    #elseif canImport(AppKit)
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    case .accent:
        .blue
    case .darkAccent:
        .red
    }
    #else
    switch token {
    case .ink:
        .black
    case .paper:
        .white
    case .accent:
        .blue
    case .darkAccent:
        .red
    }
    #endif
}

@Test
func gradientResolutionKeepsIndependentAppearanceDefinitionsCoherent() {
    let gradient = FixtureGradientDesignSystem().gradient(for: .hero)
    let light = gradient.resolve(for: .light)
    let dark = gradient.resolve(for: .dark)

    #expect(light.stops.map(\.location) == [0, 1])
    #expect(light.startPoint == .leading)
    #expect(light.endPoint == .trailing)
    #expect(light.stops[0].color == .black)
    #expect(light.stops[1].color == .blue)

    #expect(dark.stops.map(\.location) == [0.15, 0.55, 0.95])
    #expect(dark.startPoint == .bottomLeading)
    #expect(dark.endPoint == .topTrailing)
    #expect(dark.stops[0].color == .red)
    #expect(dark.stops[1].color == .white)
    #expect(dark.stops[2].color == .red)
}

@Test
func resolvedLinearGradientDescriptionAndStopsConformToSendable() {
    requireSendable(ResolvedLinearGradient.self)
    requireSendable(ResolvedLinearGradient.Stop.self)
}

private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

@Test
func gradientPointsExposeNamedPositionsAndPreserveFiniteCoordinatesOutsideUnitSquare() {
    #expect(GradientPoint.center == GradientPoint(x: 0.5, y: 0.5))
    #expect(GradientPoint.topLeading == GradientPoint(x: 0, y: 0))
    #expect(GradientPoint.top == GradientPoint(x: 0.5, y: 0))
    #expect(GradientPoint.topTrailing == GradientPoint(x: 1, y: 0))
    #expect(GradientPoint.leading == GradientPoint(x: 0, y: 0.5))
    #expect(GradientPoint.trailing == GradientPoint(x: 1, y: 0.5))
    #expect(GradientPoint.bottomLeading == GradientPoint(x: 0, y: 1))
    #expect(GradientPoint.bottom == GradientPoint(x: 0.5, y: 1))
    #expect(GradientPoint.bottomTrailing == GradientPoint(x: 1, y: 1))

    let outside = GradientPoint(x: -0.25, y: 1.25)
    let definition = LinearGradientDefinition<FixtureSemanticColor>(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        startPoint: outside,
        endPoint: .center
    )
    let adaptive = AdaptiveGradient(light: definition, dark: definition)
    let gradient = FixtureGradientTheme(
        colorTheme: FixtureGradientDesignSystem().gradientTheme.colorTheme,
        gradient: { _ in adaptive }
    ).gradient(for: .hero)

    #expect(gradient.resolve(for: .light).startPoint == outside)
}

@Test
func designGradientWorksAsDirectAndTypeErasedSwiftUIShapeStyle() {
    let gradient = FixtureGradientDesignSystem().gradient(for: .hero)
    let directShapeStyle = Rectangle().fill(gradient)
    let erasedShapeStyle: AnyShapeStyle = gradient.anyShapeStyle

    var lightEnvironment = EnvironmentValues()
    lightEnvironment.colorScheme = .light
    var darkEnvironment = EnvironmentValues()
    darkEnvironment.colorScheme = .dark

    let lightStyle = gradient.resolve(in: lightEnvironment)
    let darkStyle = gradient.resolve(in: darkEnvironment)
    _ = (directShapeStyle, erasedShapeStyle, lightStyle, darkStyle)
}

@Test
func gradientDesignSystemDerivesItsColorCapabilityFromGradientTheme() {
    let designSystem = FixtureGradientDesignSystem()

    #expect(designSystem.color(for: .content).resolve(for: .light) == .black)
    #expect(designSystem.color(for: .content).resolve(for: .dark) == .white)
    #expect(designSystem.gradient(for: .hero).resolve(for: .light).stops.count == 2)
}

@Test
func gradientValidatorExercisesEveryAppGradientToken() {
    let recorder = GradientTokenRecorder()
    let designSystem = FixtureGradientDesignSystem(onResolveGradient: recorder.record)

    validateGradients(in: designSystem)

    #expect(
        Set(recorder.tokens.map(String.init(describing:)))
            == Set(FixtureGradientToken.allCases.map(String.init(describing:)))
    )
}

#if canImport(UIKit) && !os(watchOS)
@MainActor
private final class PlatformColorSource: @unchecked Sendable {
    let color: UIColor

    init(_ color: UIColor) {
        self.color = color
    }
}

@Test @MainActor
func resolvedUIKitGradientRetainsDynamicUIColorSource() {
    let dynamicColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : .black
    }
    let source = PlatformColorSource(dynamicColor)
    let colors = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>(
        primitiveColor: { _ in source.color },
        semanticColor: { _, palette in palette.color(.ink) }
    )
    let themes = FixtureGradientTheme(
        colorTheme: colors,
        gradient: { _ in
            AdaptiveGradient<FixtureSemanticColor>(
                light: LinearGradientDefinition(
                    stops: [
                        GradientStop(semanticColor: .content, location: 0),
                        GradientStop(semanticColor: .content, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                dark: LinearGradientDefinition(
                    stops: [
                        GradientStop(semanticColor: .content, location: 0),
                        GradientStop(semanticColor: .content, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    )

    #expect(themes.gradient(for: .hero).resolve(for: .light).stops[0].color === dynamicColor)
    #expect(themes.gradient(for: .hero).resolve(for: .dark).stops[0].color === dynamicColor)
}
#elseif canImport(AppKit)
@MainActor
private final class PlatformColorSource: @unchecked Sendable {
    let color: NSColor

    init(_ color: NSColor) {
        self.color = color
    }
}

@Test @MainActor
func resolvedAppKitGradientRetainsDynamicNSColorSource() {
    let dynamicColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .white : .black
    }
    let source = PlatformColorSource(dynamicColor)
    let colors = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>(
        primitiveColor: { _ in source.color },
        semanticColor: { _, palette in palette.color(.ink) }
    )
    let themes = FixtureGradientTheme(
        colorTheme: colors,
        gradient: { _ in
            AdaptiveGradient<FixtureSemanticColor>(
                light: LinearGradientDefinition(
                    stops: [
                        GradientStop(semanticColor: .content, location: 0),
                        GradientStop(semanticColor: .content, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                dark: LinearGradientDefinition(
                    stops: [
                        GradientStop(semanticColor: .content, location: 0),
                        GradientStop(semanticColor: .content, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    )

    #expect(themes.gradient(for: .hero).resolve(for: .light).stops[0].color === dynamicColor)
    #expect(themes.gradient(for: .hero).resolve(for: .dark).stops[0].color === dynamicColor)
}
#endif
