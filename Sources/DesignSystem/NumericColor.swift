import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An immutable color authored from normalized numeric components.
///
/// Color components use unitless values in the inclusive `0...1` range. Every malformed numeric
/// channel asserts in debug builds. In release builds, finite out-of-range channels clamp to the
/// nearest boundary, non-finite red, green, blue, and grayscale channels recover to zero, and a
/// non-finite alpha channel recovers to one. Repair happens when a factory creates the value, before
/// conversion to a platform color, and is deterministic, silent, and nonthrowing.
///
/// The value is `Sendable` and can be converted to the platform-native color type with
/// `platformColor`.
public struct NumericColor: Sendable {
    private enum RGBColorSpace: Sendable {
        case sRGB
        case displayP3
    }

    private enum Components: Sendable {
        case rgb(
            colorSpace: RGBColorSpace,
            red: Double,
            green: Double,
            blue: Double,
            alpha: Double
        )
        case grayscale(white: Double, alpha: Double)
    }

    private let components: Components

    private init(
        colorSpace: RGBColorSpace,
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double
    ) {
        components = .rgb(
            colorSpace: colorSpace,
            red: Self.normalized(red, fallback: 0, channel: "red"),
            green: Self.normalized(green, fallback: 0, channel: "green"),
            blue: Self.normalized(blue, fallback: 0, channel: "blue"),
            alpha: Self.normalized(alpha, fallback: 1, channel: "alpha")
        )
    }

    private init(white: Double, alpha: Double) {
        components = .grayscale(
            white: Self.normalized(white, fallback: 0, channel: "grayscale"),
            alpha: Self.normalized(alpha, fallback: 1, channel: "alpha")
        )
    }

    /// Creates a color from normalized sRGB channels.
    ///
    /// - Parameters:
    ///   - red: The normalized red component.
    ///   - green: The normalized green component.
    ///   - blue: The normalized blue component.
    ///   - alpha: The normalized opacity, defaulting to fully opaque.
    /// - Returns: A color retaining its sRGB component values.
    public static func sRGB(
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double = 1
    ) -> Self {
        Self(colorSpace: .sRGB, red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Creates a color from normalized Display P3 channels.
    ///
    /// Conversion through `platformColor` retains the Display P3 color space rather than
    /// translating the components to sRGB.
    ///
    /// - Parameters:
    ///   - red: The normalized red component.
    ///   - green: The normalized green component.
    ///   - blue: The normalized blue component.
    ///   - alpha: The normalized opacity, defaulting to fully opaque.
    /// - Returns: A color retaining its Display P3 component values.
    public static func displayP3(
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double = 1
    ) -> Self {
        Self(colorSpace: .displayP3, red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Creates a color from normalized grayscale and opacity values.
    ///
    /// - Parameters:
    ///   - white: The normalized grayscale brightness, where zero is black and one is white.
    ///   - alpha: The normalized opacity, defaulting to fully opaque.
    /// - Returns: A grayscale color retaining its white and alpha values.
    public static func grayscale(white: Double, alpha: Double = 1) -> Self {
        Self(white: white, alpha: alpha)
    }

    /// Creates an opaque sRGB color from the low 24 bits interpreted as `RRGGBB`.
    ///
    /// The upper eight bits are ignored, so this total `UInt32` API accepts every integer value
    /// without a separate assertion or recovery policy.
    ///
    /// - Parameter value: A `UInt32`; its low 24 bits encode red, green, and blue bytes in that
    ///   order from most significant to least significant.
    /// - Returns: The decoded opaque sRGB color.
    public static func hexRGB(_ value: UInt32) -> Self {
        sRGB(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// Creates an sRGB color from all 32 bits interpreted as `RRGGBBAA`.
    ///
    /// The alpha byte is the least-significant byte. This total `UInt32` API consumes every bit
    /// without a separate assertion or recovery policy.
    ///
    /// - Parameter value: A `UInt32` whose bytes encode red, green, blue, then alpha from most
    ///   significant to least significant.
    /// - Returns: The decoded sRGB color.
    public static func hexRGBA(_ value: UInt32) -> Self {
        sRGB(
            red: Double((value >> 24) & 0xFF) / 255,
            green: Double((value >> 16) & 0xFF) / 255,
            blue: Double((value >> 8) & 0xFF) / 255,
            alpha: Double(value & 0xFF) / 255
        )
    }

    /// Converts this value to the native color type used by the current Apple platform.
    ///
    /// The selected color space is retained. Numeric-channel repair, when needed in release
    /// builds, has already completed during construction.
    public var platformColor: PlatformColor {
        switch components {
        case let .rgb(colorSpace, red, green, blue, alpha):
            #if canImport(UIKit)
            switch colorSpace {
            case .sRGB:
                UIColor(
                    red: CGFloat(red),
                    green: CGFloat(green),
                    blue: CGFloat(blue),
                    alpha: CGFloat(alpha)
                )
            case .displayP3:
                UIColor(
                    displayP3Red: CGFloat(red),
                    green: CGFloat(green),
                    blue: CGFloat(blue),
                    alpha: CGFloat(alpha)
                )
            }
            #elseif canImport(AppKit)
            switch colorSpace {
            case .sRGB:
                NSColor(
                    srgbRed: CGFloat(red),
                    green: CGFloat(green),
                    blue: CGFloat(blue),
                    alpha: CGFloat(alpha)
                )
            case .displayP3:
                NSColor(
                    displayP3Red: CGFloat(red),
                    green: CGFloat(green),
                    blue: CGFloat(blue),
                    alpha: CGFloat(alpha)
                )
            }
            #else
            switch colorSpace {
            case .sRGB:
                Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
            case .displayP3:
                Color(.displayP3, red: red, green: green, blue: blue, opacity: alpha)
            }
            #endif
        case let .grayscale(white, alpha):
            #if canImport(UIKit)
            UIColor(white: CGFloat(white), alpha: CGFloat(alpha))
            #elseif canImport(AppKit)
            NSColor(white: CGFloat(white), alpha: CGFloat(alpha))
            #else
            Color(.sRGB, white: white, opacity: alpha)
            #endif
        }
    }

    private static func normalized(_ value: Double, fallback: Double, channel: String) -> Double {
        if value.isFinite {
            assert((0...1).contains(value), "NumericColor \(channel) must be in the normalized 0...1 range.")
            return min(max(value, 0), 1)
        }

        assert(value.isFinite, "NumericColor \(channel) must be finite.")
        return fallback
    }
}
