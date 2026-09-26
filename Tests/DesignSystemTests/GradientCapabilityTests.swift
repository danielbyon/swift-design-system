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

@Test @MainActor
func swiftUIRadialFillUsesTheMinimumRenderedDimensionForItsRadius() {
    let gradient = makeGradient(for: .radial(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startRadius: 0,
        endRadius: 1.5
    ))
    let content = Rectangle()
        .fill(gradient)
        .frame(width: 64, height: 32)
        .environment(\.colorScheme, .light)
    let renderer = ImageRenderer(content: content)
    renderer.scale = 1

    guard let image = renderer.cgImage else {
        Issue.record("SwiftUI must render geometry-aware radial gradients to an image.")
        return
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let center = bitmap.colorAt(x: 32, y: 16)?.usingColorSpace(.deviceRGB),
          let nearRadius = bitmap.colorAt(x: 32, y: 2)?.usingColorSpace(.deviceRGB),
          let nearWideEdge = bitmap.colorAt(x: 2, y: 16)?.usingColorSpace(.deviceRGB)
    else {
        Issue.record("SwiftUI radial-render pixels must be readable in device RGB.")
        return
    }

    #expect(center.blueComponent < 0.1)
    #expect(nearRadius.blueComponent > 0.2)
    #expect(nearRadius.blueComponent < 0.7)
    #expect(nearWideEdge.blueComponent > 0.45)
    #expect(nearWideEdge.blueComponent < 0.8)
}

@Test @MainActor
func designGradientFillPreservesCustomShapeSizingForUnspecifiedProposals() {
    let gradient = makeGradient(for: .linear(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    ))

    func renderedSize<Content: View>(of content: Content) -> CGSize? {
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = .unspecified
        renderer.scale = 1
        guard let image = renderer.cgImage else { return nil }
        return CGSize(width: image.width, height: image.height)
    }

    guard let normalFillSize = renderedSize(
        of: DistinctiveSizeShape().fill(Color.clear).fixedSize()
    ),
    let designGradientFillSize = renderedSize(
        of: DistinctiveSizeShape().fill(gradient).fixedSize()
    )
    else {
        Issue.record("SwiftUI must render both custom-shape fills to images.")
        return
    }

    #expect(normalFillSize == CGSize(width: 83, height: 37))
    #expect(designGradientFillSize == normalFillSize)
}

@Test @MainActor
func appKitRadialAndAngularViewsMatchSwiftUIGradientRendering() {
    guard let lightAppearance = NSAppearance(named: .aqua) else {
        Issue.record("AppKit light appearance must be available for gradient rendering.")
        return
    }

    let radial = makeMonochromeGradient(for: .radial(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startRadius: 0,
        endRadius: 1
    ))
    let angular = makeMonochromeGradient(for: .angular(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startAngle: GradientAngle.degrees(-90),
        endAngle: GradientAngle.degrees(180)
    ))
    let multiTurnAngular = makeMonochromeGradient(for: .angular(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startAngle: GradientAngle.degrees(-450),
        endAngle: GradientAngle.degrees(630)
    ))
    let negativeMultiTurnAngular = makeMonochromeGradient(for: .angular(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startAngle: GradientAngle.degrees(-450),
        endAngle: GradientAngle.degrees(-1530)
    ))
    let negativeNonIntegralMultiTurnAngular = makeMonochromeGradient(for: .angular(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startAngle: GradientAngle.degrees(0),
        endAngle: GradientAngle.degrees(-450)
    ))
    let reverseAngular = makeMonochromeGradient(for: .angular(
        stops: [
            GradientStop(semanticColor: .content, location: 0),
            GradientStop(semanticColor: .accent, location: 1),
        ],
        center: .center,
        startAngle: GradientAngle.degrees(180),
        endAngle: GradientAngle.degrees(-90)
    ))
    func swiftUIBitmap(_ gradient: DesignGradient, size: CGSize) -> NSBitmapImageRep? {
        let content = Rectangle()
            .fill(gradient)
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        guard let image = renderer.cgImage else { return nil }
        return NSBitmapImageRep(cgImage: image)
    }

    func appKitBitmap(_ gradient: DesignGradient, size: CGSize) -> NSBitmapImageRep? {
        let host = NSView(frame: CGRect(origin: .zero, size: size))
        host.appearance = lightAppearance
        let view = DesignGradientView(gradient: gradient)
        view.frame = host.bounds
        host.addSubview(view)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else { return nil }

        let previousContext = NSGraphicsContext.current
        defer { NSGraphicsContext.current = previousContext }
        context.cgContext.saveGState()
        defer { context.cgContext.restoreGState() }
        context.cgContext.translateBy(x: 0, y: size.height)
        context.cgContext.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = context
        view.draw(view.bounds)
        return bitmap
    }

    func expectPixelsToMatch(
        _ label: String,
        _ designGradient: DesignGradient,
        size: CGSize,
        at points: [(Int, Int)]
    ) {
        guard let reference = swiftUIBitmap(designGradient, size: size),
              let native = appKitBitmap(designGradient, size: size)
        else {
            Issue.record("\(label): SwiftUI and AppKit must render the gradient to images.")
            return
        }

        for (x, y) in points {
            guard let expected = reference.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                  let actual = native.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
            else {
                Issue.record("\(label) pixels at (\(x), \(y)) must be readable in device RGB.")
                continue
            }
            let expectedComponents = (expected.redComponent, expected.greenComponent, expected.blueComponent)
            let actualComponents = (actual.redComponent, actual.greenComponent, actual.blueComponent)
            #expect(
                abs(expected.redComponent - actual.redComponent) < 0.1,
                "\(label) at (\(x), \(y)): expected \(expectedComponents), got \(actualComponents)."
            )
            #expect(
                abs(expected.greenComponent - actual.greenComponent) < 0.1,
                "\(label) at (\(x), \(y)): expected \(expectedComponents), got \(actualComponents)."
            )
            #expect(
                abs(expected.blueComponent - actual.blueComponent) < 0.1,
                "\(label) at (\(x), \(y)): expected \(expectedComponents), got \(actualComponents)."
            )
        }
    }

    expectPixelsToMatch("radial", radial, size: CGSize(width: 64, height: 32), at: [(32, 16), (32, 2), (4, 16)])
    expectPixelsToMatch(
        "angular",
        angular,
        size: CGSize(width: 64, height: 64),
        at: [(32, 2), (62, 32), (32, 62), (2, 32), (46, 46), (18, 18)]
    )
    expectPixelsToMatch(
        "multi-turn angular",
        multiTurnAngular,
        size: CGSize(width: 64, height: 64),
        at: [(32, 2), (62, 32), (32, 62), (2, 32), (18, 18)]
    )
    expectPixelsToMatch(
        "negative multi-turn angular",
        negativeMultiTurnAngular,
        size: CGSize(width: 64, height: 64),
        at: [(32, 2), (62, 32), (32, 62), (2, 32), (46, 46), (10, 20)]
    )
    expectPixelsToMatch(
        "negative non-integral multi-turn angular",
        negativeNonIntegralMultiTurnAngular,
        size: CGSize(width: 64, height: 64),
        at: [(32, 2), (62, 32), (32, 62), (2, 32), (46, 46), (10, 20)]
    )
    expectPixelsToMatch(
        "reverse angular",
        reverseAngular,
        size: CGSize(width: 64, height: 64),
        at: [(32, 2), (62, 32), (32, 62), (2, 32), (46, 46), (18, 18), (10, 20), (20, 10)]
    )
}

#if !DEBUG
@Test @MainActor
func radialGenericShapeStyleUsesTransparentReleaseFallback() {
    let gradient = FixtureGradientDesignSystem().gradient(for: .radial)
    let renderer = ImageRenderer(
        content: Rectangle()
            .fill(gradient.anyShapeStyle)
            .frame(width: 32, height: 32)
    )
    renderer.scale = 1

    guard let image = renderer.cgImage else {
        Issue.record("SwiftUI must render the generic radial fallback to an image.")
        return
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    #expect(bitmap.colorAt(x: 16, y: 16)?.alphaComponent == 0)
}
#endif

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

private struct DistinctiveSizeShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        CGSize(width: 83, height: 37)
    }
}

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
    case radial
    case angular
    case mixed
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
                case .radial:
                    AdaptiveGradient<FixtureSemanticColor>(
                        light: .radial(
                            RadialGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .content, location: 0),
                                    GradientStop(semanticColor: .accent, location: 1),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 1
                            )
                        ),
                        dark: .radial(
                            RadialGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .accent, location: 0),
                                    GradientStop(semanticColor: .content, location: 1),
                                ],
                                center: .bottomTrailing,
                                startRadius: 0.25,
                                endRadius: 1.5
                            )
                        )
                    )
                case .angular:
                    AdaptiveGradient<FixtureSemanticColor>(
                        light: .angular(
                            AngularGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .content, location: 0),
                                    GradientStop(semanticColor: .accent, location: 1),
                                ],
                                center: .center,
                                startAngle: GradientAngle.degrees(-90),
                                endAngle: GradientAngle.degrees(270)
                            )
                        ),
                        dark: .angular(
                            AngularGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .accent, location: 0),
                                    GradientStop(semanticColor: .content, location: 1),
                                ],
                                center: .topLeading,
                                startAngle: GradientAngle.radians(-2 * .pi),
                                endAngle: GradientAngle.radians(4 * .pi)
                            )
                        )
                    )
                case .mixed:
                    AdaptiveGradient<FixtureSemanticColor>(
                        light: .radial(
                            RadialGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .content, location: 0),
                                    GradientStop(semanticColor: .accent, location: 1),
                                ],
                                center: .top,
                                startRadius: 0,
                                endRadius: 0.8
                            )
                        ),
                        dark: .angular(
                            AngularGradientDefinition(
                                stops: [
                                    GradientStop(semanticColor: .accent, location: 0),
                                    GradientStop(semanticColor: .content, location: 1),
                                ],
                                center: .bottom,
                                startAngle: GradientAngle.degrees(135),
                                endAngle: GradientAngle.degrees(855)
                            )
                        )
                    )
                }
            }
        )
    }
}

private func makeGradient(for definition: GradientDefinition<FixtureSemanticColor>) -> DesignGradient {
    let colorTheme = FixtureGradientDesignSystem().gradientTheme.colorTheme
    return FixtureGradientTheme(
        colorTheme: colorTheme,
        gradient: { _ in AdaptiveGradient(light: definition, dark: definition) }
    ).gradient(for: .hero)
}


private func resolvedStops(for gradient: DesignGradient) -> [ResolvedLinearGradient.Stop] {
    switch gradient.resolve(for: .light) {
    case let .linear(value):
        return value.stops
    case let .radial(value):
        return value.stops
    case let .angular(value):
        return value.stops
    }
}

@MainActor
private func smokeRenderGradient(_ gradient: DesignGradient) {
    #if canImport(UIKit) && !os(watchOS)
    let size = CGSize(width: 64, height: 64)
    let view = DesignGradientView(gradient: gradient)
    view.frame = CGRect(origin: .zero, size: size)
    let renderer = UIGraphicsImageRenderer(size: size)
    for style in [UIUserInterfaceStyle.light, .dark] {
        view.overrideUserInterfaceStyle = style
        _ = renderer.image { _ in
            view.draw(view.bounds)
        }
    }
    #elseif canImport(AppKit)
    let size = CGSize(width: 64, height: 64)
    let view = DesignGradientView(gradient: gradient)
    view.frame = CGRect(origin: .zero, size: size)
    for name in [NSAppearance.Name.aqua, .darkAqua] {
        guard let appearance = NSAppearance(named: name) else {
            Issue.record("AppKit appearance must be available for gradient recovery rendering.")
            continue
        }
        view.appearance = appearance

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            Issue.record("AppKit must create a bitmap context for gradient recovery rendering.")
            continue
        }

        let previousContext = NSGraphicsContext.current
        defer { NSGraphicsContext.current = previousContext }
        context.cgContext.saveGState()
        defer { context.cgContext.restoreGState() }
        context.cgContext.translateBy(x: 0, y: size.height)
        context.cgContext.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = context
        view.draw(view.bounds)
    }
    #endif
}

private func makeMonochromeGradient(
    for definition: GradientDefinition<FixtureSemanticColor>
) -> DesignGradient {
    let colorTheme = ColorTheme<FixturePrimitiveColor, FixtureSemanticColor>(
        primitiveColor: { token in
            switch token {
            case .ink, .darkAccent: .black
            case .paper, .accent: .white
            }
        },
        semanticColor: { token, palette in
            switch token {
            case .content:
                palette.color(light: .ink, dark: .paper)
            case .accent:
                palette.color(light: .accent, dark: .darkAccent)
            }
        }
    )
    return FixtureGradientTheme(
        colorTheme: colorTheme,
        gradient: { _ in AdaptiveGradient(light: definition, dark: definition) }
    ).gradient(for: .hero)
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
    let light = resolvedLinear(gradient, for: .light)
    let dark = resolvedLinear(gradient, for: .dark)

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
func adaptiveGradientResolvesDifferentKindsAndColorsForEachAppearance() {
    let gradient = FixtureGradientDesignSystem().gradient(for: .mixed)

    guard case let .radial(light) = gradient.resolve(for: .light) else {
        Issue.record("The light appearance must resolve its radial definition.")
        return
    }
    guard case let .angular(dark) = gradient.resolve(for: .dark) else {
        Issue.record("The dark appearance must resolve its angular definition.")
        return
    }

    #expect(light.center == .top)
    #expect(light.startRadius == 0)
    #expect(light.endRadius == 0.8)
    #expect(light.stops.map(\.location) == [0, 1])
    #expect(light.stops[0].color == .black)
    #expect(light.stops[1].color == .blue)

    #expect(dark.center == .bottom)
    #expect(dark.startAngle == GradientAngle.degrees(135))
    #expect(dark.endAngle == GradientAngle.degrees(855))
    #expect(dark.stops[0].color == .red)
    #expect(dark.stops[1].color == .white)
}

@Test
func gradientAngleUsesCanonicalRadiansWithoutNormalizingRevolutions() {
    let negativeDegrees = GradientAngle.degrees(-450)
    let equivalentRadians = GradientAngle.radians(-2.5 * .pi)
    let multipleRadians = GradientAngle.radians(4 * .pi)

    #expect(abs(negativeDegrees.radians - (-2.5 * .pi)) < 1e-12)
    #expect(negativeDegrees == equivalentRadians)
    #expect(GradientAngle.degrees(180) == GradientAngle.radians(.pi))
    #expect(GradientAngle.degrees(360) != GradientAngle.radians(0))
    #expect(multipleRadians.radians == 4 * .pi)
}

@Test
func oneStopDefinitionsDuplicateTheirColorAndEmptyDefinitionsResolveTransparentStops() {
    let oneStopDefinition = GradientDefinition<FixtureSemanticColor>.linear(
        stops: [GradientStop(semanticColor: .accent, location: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )
    let emptyDefinition = GradientDefinition<FixtureSemanticColor>.linear(
        stops: [],
        startPoint: .leading,
        endPoint: .trailing
    )

    guard case let .linear(oneStop) = makeGradient(for: oneStopDefinition).resolve(for: .light),
          case let .linear(empty) = makeGradient(for: emptyDefinition).resolve(for: .light)
    else {
        Issue.record("Linear definitions must resolve to linear gradient descriptions.")
        return
    }

    #expect(oneStop.stops.map(\.location) == [0, 1])
    #expect(oneStop.stops[0].color == oneStop.stops[1].color)
    #expect(empty.stops.map(\.location) == [0, 1])
    #expect(empty.stops.allSatisfy { $0.color.cgColor.alpha == 0 })
}

@Test
func radialAndAngularDefinitionsNormalizeOneStopAndKeepEmptyStopsEmptyUntilResolution() {
    let radial = RadialGradientDefinition<FixtureSemanticColor>(
        stops: [GradientStop(semanticColor: .accent, location: 0.5)],
        center: .center,
        startRadius: 0,
        endRadius: 1
    )
    let emptyAngular = AngularGradientDefinition<FixtureSemanticColor>(
        stops: [],
        center: .center,
        startAngle: GradientAngle.degrees(-90),
        endAngle: GradientAngle.degrees(270)
    )

    #expect(radial.stops.map(\.location) == [0, 1])
    #expect(radial.stops[0].semanticColor == radial.stops[1].semanticColor)
    #expect(emptyAngular.stops.isEmpty)

    guard case let .radial(resolvedRadial) = makeGradient(for: .radial(radial)).resolve(for: .light),
          case let .angular(resolvedAngular) = makeGradient(for: .angular(emptyAngular)).resolve(for: .light)
    else {
        Issue.record("Radial and angular definitions must preserve their gradient kinds.")
        return
    }

    #expect(resolvedRadial.stops.map(\.location) == [0, 1])
    #expect(resolvedAngular.stops.map(\.location) == [0, 1])
    #expect(resolvedAngular.stops.allSatisfy { $0.color.cgColor.alpha == 0 })
}

#if !DEBUG
@Test
@MainActor
func malformedGradientGeometryAndStopsRecoverDeterministicallyInRelease() {
    let point = GradientPoint(x: .infinity, y: .nan)
    let finiteOutsidePoint = GradientPoint(x: -0.25, y: 1.25)
    let angle = GradientAngle.degrees(.nan)
    let endAngle = GradientAngle.radians(.infinity)
    let stops = [
        GradientStop(semanticColor: FixtureSemanticColor.content, location: 0.8),
        GradientStop(semanticColor: .accent, location: 0.2),
        GradientStop(semanticColor: .content, location: 0.2),
        GradientStop(semanticColor: .accent, location: .nan),
        GradientStop(semanticColor: .content, location: -1),
        GradientStop(semanticColor: .accent, location: 1.5),
    ]
    #expect(stops.map(\.location) == [0.8, 0.2, 0.2, 0, 0, 1])
    let linear = LinearGradientDefinition(
        stops: stops,
        startPoint: point,
        endPoint: finiteOutsidePoint
    )
    let radial = RadialGradientDefinition(
        stops: stops,
        center: point,
        startRadius: -0.5,
        endRadius: -1
    )
    let invertedRadii = RadialGradientDefinition<FixtureSemanticColor>(
        stops: [],
        center: .center,
        startRadius: 0.75,
        endRadius: 0.25
    )
    let angular = AngularGradientDefinition(
        stops: stops,
        center: point,
        startAngle: angle,
        endAngle: endAngle
    )
    let linearGradient = makeGradient(for: .linear(linear))
    let radialGradient = makeGradient(for: .radial(radial))
    let invertedGradient = makeGradient(for: .radial(invertedRadii))
    let angularGradient = makeGradient(for: .angular(angular))

    guard case let .linear(resolvedLinear) = linearGradient.resolve(for: .light),
          case let .radial(resolvedRadial) = radialGradient.resolve(for: .light),
          case let .radial(resolvedInvertedRadii) = invertedGradient.resolve(for: .light),
          case let .angular(resolvedAngular) = angularGradient.resolve(for: .light)
    else {
        Issue.record("Recovered public gradient values must preserve their gradient kinds.")
        return
    }

    #expect(point.x == 0)
    #expect(point.y == 0)
    #expect(finiteOutsidePoint == GradientPoint(x: -0.25, y: 1.25))
    #expect(angle.radians == 0)
    #expect(endAngle.radians == 0)
    #expect(resolvedLinear.startPoint == point)
    #expect(resolvedLinear.endPoint == finiteOutsidePoint)
    #expect(radial.startRadius == 0)
    #expect(radial.endRadius == 0)
    #expect(invertedRadii.startRadius == 0.75)
    #expect(invertedRadii.endRadius == 0.75)
    #expect(angular.startAngle.radians == 0)
    #expect(resolvedRadial.center == point)
    #expect(resolvedRadial.startRadius == 0)
    #expect(resolvedRadial.endRadius == 0)
    #expect(resolvedInvertedRadii.startRadius == 0.75)
    #expect(resolvedInvertedRadii.endRadius == 0.75)
    #expect(resolvedAngular.center == point)
    #expect(resolvedAngular.startAngle.radians == 0)
    #expect(resolvedAngular.endAngle.radians == 0)
    #expect(radial.stops.map(\.location) == [0, 0, 0.2, 0.2, 0.8, 1])
    #expect(resolvedRadial.stops.map(\.location) == [0, 0, 0.2, 0.2, 0.8, 1])

    let colorSystem = FixtureGradientDesignSystem()
    let expectedColors = [
        colorSystem.color(for: .accent).resolve(for: .light).cgColor,
        colorSystem.color(for: .content).resolve(for: .light).cgColor,
        colorSystem.color(for: .accent).resolve(for: .light).cgColor,
        colorSystem.color(for: .content).resolve(for: .light).cgColor,
        colorSystem.color(for: .content).resolve(for: .light).cgColor,
        colorSystem.color(for: .accent).resolve(for: .light).cgColor,
    ]
    for (stop, expectedColor) in zip(resolvedRadial.stops, expectedColors) {
        #expect(stop.color.cgColor == expectedColor)
    }

    for gradient in [linearGradient, radialGradient, invertedGradient, angularGradient] {
        smokeRenderGradient(gradient)
    }
}

@Test @MainActor
func oneStopAndEmptyGradientsRecoverThroughPublicResolutionInRelease() {
    let oneStop = GradientStop(semanticColor: FixtureSemanticColor.accent, location: 0.4)
    let oneStopDefinitions: [GradientDefinition<FixtureSemanticColor>] = [
        .linear(stops: [oneStop], startPoint: .leading, endPoint: .trailing),
        .radial(stops: [oneStop], center: .center, startRadius: 0, endRadius: 1),
        .angular(
            stops: [oneStop],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(180)
        ),
    ]
    let emptyDefinitions: [GradientDefinition<FixtureSemanticColor>] = [
        .linear(stops: [], startPoint: .leading, endPoint: .trailing),
        .radial(stops: [], center: .center, startRadius: 0, endRadius: 1),
        .angular(stops: [], center: .center, startAngle: .degrees(0), endAngle: .degrees(180)),
    ]
    let accent = FixtureGradientDesignSystem()
        .color(for: .accent)
        .resolve(for: .light)
        .cgColor

    for definition in oneStopDefinitions {
        let gradient = makeGradient(for: definition)
        let stops = resolvedStops(for: gradient)

        #expect(stops.map(\.location) == [0, 1])
        #expect(stops[0].color.cgColor == accent)
        #expect(stops[0].color.cgColor == stops[1].color.cgColor)
        smokeRenderGradient(gradient)
    }

    for definition in emptyDefinitions {
        let gradient = makeGradient(for: definition)
        let stops = resolvedStops(for: gradient)

        #expect(stops.map(\.location) == [0, 1])
        #expect(stops.allSatisfy { $0.color.cgColor.alpha == 0 })
        smokeRenderGradient(gradient)
    }
}
#endif

@Test
func resolvedRadialAndAngularGradientValuesConformToSendable() {
    requireSendable(ResolvedGradient.self)
    requireSendable(ResolvedLinearGradient.self)
    requireSendable(ResolvedRadialGradient.self)
    requireSendable(ResolvedAngularGradient.self)

    let radial = FixtureGradientDesignSystem().gradient(for: .radial).resolve(for: .dark)
    let angular = FixtureGradientDesignSystem().gradient(for: .angular).resolve(for: .dark)
    #expect({ if case .radial = radial { true } else { false } }())
    guard case let .angular(description) = angular else {
        Issue.record("The angular fixture must resolve to an angular description.")
        return
    }
    #expect(description.startAngle.radians == -2 * .pi)
    #expect(description.endAngle.radians == 4 * .pi)
}

@Test
func resolvedLinearGradientDescriptionAndStopsConformToSendable() {
    requireSendable(ResolvedLinearGradient.self)
    requireSendable(ResolvedLinearGradient.Stop.self)
}

private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

private func resolvedLinear(
    _ gradient: DesignGradient,
    for appearance: DesignAppearance
) -> ResolvedLinearGradient {
    guard case let .linear(value) = gradient.resolve(for: appearance) else {
        preconditionFailure("The fixture must resolve to a linear gradient.")
    }
    return value
}

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

    #expect(resolvedLinear(gradient, for: .light).startPoint == outside)
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
    #expect(resolvedLinear(designSystem.gradient(for: .hero), for: .light).stops.count == 2)
}

@Test
func gradientValidatorExercisesEveryAppGradientToken() {
    let recorder = GradientTokenRecorder()
    let designSystem = FixtureGradientDesignSystem(onResolveGradient: recorder.record)

    validateGradients(in: designSystem)

    #expect(
        recorder.tokens.map(String.init(describing:))
            == FixtureGradientToken.allCases.map(String.init(describing:))
    )
}

#if canImport(UIKit) && !os(watchOS) || canImport(AppKit)
@Test @MainActor
func nativeGradientValidatorExercisesEveryAppGradientTokenOnce() {
    let recorder = GradientTokenRecorder()
    let designSystem = FixtureGradientDesignSystem(onResolveGradient: recorder.record)

    validateNativeGradients(in: designSystem)

    #expect(
        recorder.tokens.map(String.init(describing:))
            == FixtureGradientToken.allCases.map(String.init(describing:))
    )
}
#endif

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

    #expect(resolvedLinear(themes.gradient(for: .hero), for: .light).stops[0].color === dynamicColor)
    #expect(resolvedLinear(themes.gradient(for: .hero), for: .dark).stops[0].color === dynamicColor)
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

    #expect(resolvedLinear(themes.gradient(for: .hero), for: .light).stops[0].color === dynamicColor)
    #expect(resolvedLinear(themes.gradient(for: .hero), for: .dark).stops[0].color === dynamicColor)
}
#endif
