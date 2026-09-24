#if canImport(UIKit)
import UIKit

/// The native color value used by the currently available Apple UI framework.
///
/// UIKit is selected on iOS-family platforms, including Mac Catalyst. Platforms without UIKit
/// or AppKit use SwiftUI's `Color` as the native color value.
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit

/// The native color value used by the currently available Apple UI framework.
///
/// UIKit is selected on iOS-family platforms, including Mac Catalyst. Platforms without UIKit
/// or AppKit use SwiftUI's `Color` as the native color value.
public typealias PlatformColor = NSColor
#elseif canImport(SwiftUI)
import SwiftUI

/// The native color value used by the currently available Apple UI framework.
///
/// UIKit is selected on iOS-family platforms, including Mac Catalyst. Platforms without UIKit
/// or AppKit use SwiftUI's `Color` as the native color value.
public typealias PlatformColor = Color
#endif
