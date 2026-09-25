import CoreGraphics
import DesignSystem
import DesignSystemTestSupport
import Synchronization
import Testing

private enum DimensionFixtureToken: DimensionToken {
    case finiteBefore
    case negativeFinite
    case positiveInfinity
    case negativeInfinity
    case notANumber
    case finiteAfter
}

private struct DimensionFixture: DimensionDesignSystem {
    typealias Dimension = DimensionFixtureToken

    func dimension(for token: Dimension) -> CGFloat {
        switch token {
        case .finiteBefore:
            3
        case .negativeFinite:
            -4
        case .positiveInfinity:
            .infinity
        case .negativeInfinity:
            -.infinity
        case .notANumber:
            .nan
        case .finiteAfter:
            9
        }
    }
}

private enum SizeFixtureToken: SizeToken {
    case finiteBefore
    case negativeWidth
    case negativeHeight
    case positiveInfinityWidth
    case negativeInfinityWidth
    case negativeInfinityHeight
    case notANumberWidth
    case notANumberHeight
    case finiteAfter
}

private struct SizeFixture: SizeDesignSystem {
    typealias Size = SizeFixtureToken

    func size(for token: Size) -> CGSize {
        switch token {
        case .finiteBefore:
            CGSize(width: 0, height: 12)
        case .negativeWidth:
            CGSize(width: -2, height: 12)
        case .negativeHeight:
            CGSize(width: 12, height: -2)
        case .positiveInfinityWidth:
            CGSize(width: CGFloat.infinity, height: 12)
        case .negativeInfinityWidth:
            CGSize(width: -CGFloat.infinity, height: 12)
        case .negativeInfinityHeight:
            CGSize(width: 12, height: -CGFloat.infinity)
        case .notANumberWidth:
            CGSize(width: CGFloat.nan, height: 12)
        case .notANumberHeight:
            CGSize(width: 12, height: CGFloat.nan)
        case .finiteAfter:
            CGSize(width: 24, height: 32)
        }
    }
}

private enum CornerRadiusFixtureToken: CornerRadiusToken {
    case finiteBefore
    case negativeFinite
    case positiveInfinity
    case negativeInfinity
    case notANumber
    case finiteAfter
}

private struct CornerRadiusFixture: CornerRadiusDesignSystem {
    typealias CornerRadius = CornerRadiusFixtureToken

    func cornerRadius(for token: CornerRadius) -> CGFloat {
        switch token {
        case .finiteBefore:
            0
        case .negativeFinite:
            -4
        case .positiveInfinity:
            .infinity
        case .negativeInfinity:
            -.infinity
        case .notANumber:
            .nan
        case .finiteAfter:
            12
        }
    }
}

private enum StrokeWidthFixtureToken: StrokeWidthToken {
    case finiteBefore
    case negativeFinite
    case positiveInfinity
    case negativeInfinity
    case notANumber
    case finiteAfter
}

private struct StrokeWidthFixture: StrokeWidthDesignSystem {
    typealias StrokeWidth = StrokeWidthFixtureToken

    func strokeWidth(for token: StrokeWidth) -> CGFloat {
        switch token {
        case .finiteBefore:
            0
        case .negativeFinite:
            -2
        case .positiveInfinity:
            .infinity
        case .negativeInfinity:
            -.infinity
        case .notANumber:
            .nan
        case .finiteAfter:
            3
        }
    }
}

private enum OpacityFixtureToken: OpacityToken {
    case zero
    case one
    case finiteInterior
    case negativeFinite
    case finiteAboveOne
    case positiveInfinity
    case negativeInfinity
    case notANumber
    case finiteAfter
}

private struct OpacityFixture: OpacityDesignSystem {
    typealias Opacity = OpacityFixtureToken

    func opacity(for token: Opacity) -> Double {
        switch token {
        case .zero:
            0
        case .one:
            1
        case .finiteInterior:
            0.5
        case .negativeFinite:
            -0.25
        case .finiteAboveOne:
            1.25
        case .positiveInfinity:
            .infinity
        case .negativeInfinity:
            -.infinity
        case .notANumber:
            .nan
        case .finiteAfter:
            0.75
        }
    }
}

private final class DimensionValidationFixture: DimensionDesignSystem {
    typealias Dimension = DimensionFixtureToken

    private let resolvedTokens = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokens.withLock { $0 }
    }

    func dimension(for token: Dimension) -> CGFloat {
        resolvedTokens.withLock { $0.append(String(describing: token)) }
        return DimensionFixture().dimension(for: token)
    }
}

private final class SizeValidationFixture: SizeDesignSystem {
    typealias Size = SizeFixtureToken

    private let resolvedTokens = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokens.withLock { $0 }
    }

    func size(for token: Size) -> CGSize {
        resolvedTokens.withLock { $0.append(String(describing: token)) }
        return SizeFixture().size(for: token)
    }
}

private final class CornerRadiusValidationFixture: CornerRadiusDesignSystem {
    typealias CornerRadius = CornerRadiusFixtureToken

    private let resolvedTokens = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokens.withLock { $0 }
    }

    func cornerRadius(for token: CornerRadius) -> CGFloat {
        resolvedTokens.withLock { $0.append(String(describing: token)) }
        return CornerRadiusFixture().cornerRadius(for: token)
    }
}

private final class StrokeWidthValidationFixture: StrokeWidthDesignSystem {
    typealias StrokeWidth = StrokeWidthFixtureToken

    private let resolvedTokens = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokens.withLock { $0 }
    }

    func strokeWidth(for token: StrokeWidth) -> CGFloat {
        resolvedTokens.withLock { $0.append(String(describing: token)) }
        return StrokeWidthFixture().strokeWidth(for: token)
    }
}

private final class OpacityValidationFixture: OpacityDesignSystem {
    typealias Opacity = OpacityFixtureToken

    private let resolvedTokens = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokens.withLock { $0 }
    }

    func opacity(for token: Opacity) -> Double {
        resolvedTokens.withLock { $0.append(String(describing: token)) }
        return OpacityFixture().opacity(for: token)
    }
}

private struct ValidScalarToken: DimensionToken, SizeToken, CornerRadiusToken, StrokeWidthToken,
    OpacityToken {
    let value: Int

    static var allCases: [Self] {
        [Self(value: 0), Self(value: 1), Self(value: 2)]
    }
}

private struct ValidScalarDesignSystem: DimensionDesignSystem, SizeDesignSystem, CornerRadiusDesignSystem,
    StrokeWidthDesignSystem, OpacityDesignSystem {
    typealias Dimension = ValidScalarToken
    typealias Size = ValidScalarToken
    typealias CornerRadius = ValidScalarToken
    typealias StrokeWidth = ValidScalarToken
    typealias Opacity = ValidScalarToken

    func dimension(for token: Dimension) -> CGFloat {
        CGFloat(token.value)
    }

    func size(for token: Size) -> CGSize {
        CGSize(width: CGFloat(token.value), height: CGFloat(token.value))
    }

    func cornerRadius(for token: CornerRadius) -> CGFloat {
        CGFloat(token.value)
    }

    func strokeWidth(for token: StrokeWidth) -> CGFloat {
        CGFloat(token.value)
    }

    func opacity(for token: Opacity) -> Double {
        Double(token.value) / 2
    }
}

private let expectedDimensionIssueTokens = [
    DimensionFixtureToken.negativeFinite,
    .positiveInfinity,
    .negativeInfinity,
    .notANumber,
].map { String(describing: $0) }

private let expectedDimensionIssueMessages = [
    "Dimension token negativeFinite resolved to a negative value.",
    "Dimension token positiveInfinity resolved to a non-finite value.",
    "Dimension token negativeInfinity resolved to a non-finite value.",
    "Dimension token notANumber resolved to a non-finite value.",
]

private let capturedDimensionIssues = Mutex<[String]>([])

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard expectedDimensionIssueTokens.contains(where: { comment.contains($0) }) else {
        return true
    }

    capturedDimensionIssues.withLock { $0.append(comment) }
    return false
})
func dimensionValidatorReportsEveryInvalidTokenAndContinues() {
    capturedDimensionIssues.withLock { $0.removeAll() }

    let designSystem = DimensionValidationFixture()
    validateDimensions(in: designSystem)

    let expectedVocabulary = DimensionFixtureToken.allCases
        .map { String(describing: $0) }
        .sorted()
    #expect(designSystem.resolutionHistory.sorted() == expectedVocabulary)
    #expect(capturedDimensionIssues.withLock { $0 }.sorted() == expectedDimensionIssueMessages.sorted())
    #expect(designSystem.dimension(for: .negativeFinite) == -4)
    #expect(designSystem.dimension(for: .positiveInfinity) == .infinity)
    #expect(designSystem.dimension(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.dimension(for: .notANumber).isNaN)
}

private let expectedSizeIssueTokens = [
    SizeFixtureToken.negativeWidth,
    .negativeHeight,
    .positiveInfinityWidth,
    .negativeInfinityWidth,
    .negativeInfinityHeight,
    .notANumberWidth,
    .notANumberHeight,
].map { String(describing: $0) }

private let expectedSizeIssueMessages = [
    "Size token negativeWidth has a negative width component.",
    "Size token negativeHeight has a negative height component.",
    "Size token positiveInfinityWidth has a non-finite width component.",
    "Size token negativeInfinityWidth has a non-finite width component.",
    "Size token negativeInfinityHeight has a non-finite height component.",
    "Size token notANumberWidth has a non-finite width component.",
    "Size token notANumberHeight has a non-finite height component.",
]

private let capturedSizeIssues = Mutex<[String]>([])

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard expectedSizeIssueTokens.contains(where: { comment.contains($0) }) else {
        return true
    }

    capturedSizeIssues.withLock { $0.append(comment) }
    return false
})
func sizeValidatorChecksBothComponentsAndContinues() {
    capturedSizeIssues.withLock { $0.removeAll() }

    let designSystem = SizeValidationFixture()
    validateSizes(in: designSystem)

    let expectedVocabulary = SizeFixtureToken.allCases
        .map { String(describing: $0) }
        .sorted()
    #expect(designSystem.resolutionHistory.sorted() == expectedVocabulary)
    let capturedComments = capturedSizeIssues.withLock { $0 }
    #expect(capturedComments.sorted() == expectedSizeIssueMessages.sorted())

    let comments = capturedComments
    #expect(comments.contains { $0.contains("negativeWidth") && $0.contains("width") })
    #expect(comments.contains { $0.contains("negativeHeight") && $0.contains("height") })
    #expect(comments.contains { $0.contains("positiveInfinityWidth") && $0.contains("width") })
    #expect(comments.contains { $0.contains("negativeInfinityWidth") && $0.contains("width") })
    #expect(comments.contains { $0.contains("negativeInfinityHeight") && $0.contains("height") })
    #expect(comments.contains { $0.contains("notANumberWidth") && $0.contains("width") })
    #expect(comments.contains { $0.contains("notANumberHeight") && $0.contains("height") })

    #expect(designSystem.size(for: .negativeWidth).width == -2)
    #expect(designSystem.size(for: .negativeHeight).height == -2)
    #expect(designSystem.size(for: .positiveInfinityWidth).width == .infinity)
    #expect(designSystem.size(for: .negativeInfinityWidth).width == -.infinity)
    #expect(designSystem.size(for: .negativeInfinityHeight).height == -.infinity)
    #expect(designSystem.size(for: .notANumberWidth).width.isNaN)
    #expect(designSystem.size(for: .notANumberHeight).height.isNaN)
}

private let expectedCornerRadiusIssueTokens = [
    CornerRadiusFixtureToken.negativeFinite,
    .positiveInfinity,
    .negativeInfinity,
    .notANumber,
].map { String(describing: $0) }

private let expectedCornerRadiusIssueMessages = [
    "Corner-radius token negativeFinite resolved to a negative value.",
    "Corner-radius token positiveInfinity resolved to a non-finite value.",
    "Corner-radius token negativeInfinity resolved to a non-finite value.",
    "Corner-radius token notANumber resolved to a non-finite value.",
]

private let capturedCornerRadiusIssues = Mutex<[String]>([])

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard expectedCornerRadiusIssueTokens.contains(where: { comment.contains($0) }) else {
        return true
    }

    capturedCornerRadiusIssues.withLock { $0.append(comment) }
    return false
})
func cornerRadiusValidatorReportsEveryInvalidTokenAndContinues() {
    capturedCornerRadiusIssues.withLock { $0.removeAll() }

    let designSystem = CornerRadiusValidationFixture()
    validateCornerRadii(in: designSystem)

    let expectedVocabulary = CornerRadiusFixtureToken.allCases
        .map { String(describing: $0) }
        .sorted()
    #expect(designSystem.resolutionHistory.sorted() == expectedVocabulary)
    #expect(capturedCornerRadiusIssues.withLock { $0 }.sorted() == expectedCornerRadiusIssueMessages.sorted())
    #expect(designSystem.cornerRadius(for: .negativeFinite) == -4)
    #expect(designSystem.cornerRadius(for: .positiveInfinity) == .infinity)
    #expect(designSystem.cornerRadius(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.cornerRadius(for: .notANumber).isNaN)
}

private let expectedStrokeWidthIssueTokens = [
    StrokeWidthFixtureToken.negativeFinite,
    .positiveInfinity,
    .negativeInfinity,
    .notANumber,
].map { String(describing: $0) }

private let expectedStrokeWidthIssueMessages = [
    "Stroke-width token negativeFinite resolved to a negative value.",
    "Stroke-width token positiveInfinity resolved to a non-finite value.",
    "Stroke-width token negativeInfinity resolved to a non-finite value.",
    "Stroke-width token notANumber resolved to a non-finite value.",
]

private let capturedStrokeWidthIssues = Mutex<[String]>([])

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard expectedStrokeWidthIssueTokens.contains(where: { comment.contains($0) }) else {
        return true
    }

    capturedStrokeWidthIssues.withLock { $0.append(comment) }
    return false
})
func strokeWidthValidatorReportsEveryInvalidTokenAndContinues() {
    capturedStrokeWidthIssues.withLock { $0.removeAll() }

    let designSystem = StrokeWidthValidationFixture()
    validateStrokeWidths(in: designSystem)

    let expectedVocabulary = StrokeWidthFixtureToken.allCases
        .map { String(describing: $0) }
        .sorted()
    #expect(designSystem.resolutionHistory.sorted() == expectedVocabulary)
    #expect(capturedStrokeWidthIssues.withLock { $0 }.sorted() == expectedStrokeWidthIssueMessages.sorted())
    #expect(designSystem.strokeWidth(for: .negativeFinite) == -2)
    #expect(designSystem.strokeWidth(for: .positiveInfinity) == .infinity)
    #expect(designSystem.strokeWidth(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.strokeWidth(for: .notANumber).isNaN)
}

private let expectedOpacityIssueTokens = [
    OpacityFixtureToken.negativeFinite,
    .finiteAboveOne,
    .positiveInfinity,
    .negativeInfinity,
    .notANumber,
].map { String(describing: $0) }

private let expectedOpacityIssueMessages = [
    "Opacity token negativeFinite resolved outside the inclusive 0...1 range.",
    "Opacity token finiteAboveOne resolved outside the inclusive 0...1 range.",
    "Opacity token positiveInfinity resolved to a non-finite value.",
    "Opacity token negativeInfinity resolved to a non-finite value.",
    "Opacity token notANumber resolved to a non-finite value.",
]

private let capturedOpacityIssues = Mutex<[String]>([])

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard expectedOpacityIssueTokens.contains(where: { comment.contains($0) }) else {
        return true
    }

    capturedOpacityIssues.withLock { $0.append(comment) }
    return false
})
func opacityValidatorReportsBothRangeSidesAndNonFiniteValues() {
    capturedOpacityIssues.withLock { $0.removeAll() }

    let designSystem = OpacityValidationFixture()
    validateOpacities(in: designSystem)

    let expectedVocabulary = OpacityFixtureToken.allCases
        .map { String(describing: $0) }
        .sorted()
    #expect(designSystem.resolutionHistory.sorted() == expectedVocabulary)
    #expect(capturedOpacityIssues.withLock { $0 }.sorted() == expectedOpacityIssueMessages.sorted())
    #expect(designSystem.opacity(for: .zero) == 0)
    #expect(designSystem.opacity(for: .one) == 1)
    #expect(designSystem.opacity(for: .negativeFinite) == -0.25)
    #expect(designSystem.opacity(for: .finiteAboveOne) == 1.25)
    #expect(designSystem.opacity(for: .positiveInfinity) == .infinity)
    #expect(designSystem.opacity(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.opacity(for: .notANumber).isNaN)
}

@Test
func scalarResolversReturnAppAuthoredValuesUnchanged() {
    let dimension = DimensionFixture()
    #expect(dimension.dimension(for: .finiteBefore) == 3)
    #expect(dimension.dimension(for: .negativeFinite) == -4)
    #expect(dimension.dimension(for: .positiveInfinity) == .infinity)
    #expect(dimension.dimension(for: .negativeInfinity) == -.infinity)
    #expect(dimension.dimension(for: .notANumber).isNaN)

    let size = SizeFixture()
    #expect(size.size(for: .finiteBefore) == CGSize(width: 0, height: 12))
    #expect(size.size(for: .negativeWidth).width == -2)
    #expect(size.size(for: .negativeHeight).height == -2)
    #expect(size.size(for: .positiveInfinityWidth).width == .infinity)
    #expect(size.size(for: .negativeInfinityHeight).height == -.infinity)
    #expect(size.size(for: .notANumberWidth).width.isNaN)
    #expect(size.size(for: .notANumberHeight).height.isNaN)

    let cornerRadius = CornerRadiusFixture()
    #expect(cornerRadius.cornerRadius(for: .finiteBefore) == 0)
    #expect(cornerRadius.cornerRadius(for: .negativeFinite) == -4)
    #expect(cornerRadius.cornerRadius(for: .positiveInfinity) == .infinity)
    #expect(cornerRadius.cornerRadius(for: .negativeInfinity) == -.infinity)
    #expect(cornerRadius.cornerRadius(for: .notANumber).isNaN)

    let strokeWidth = StrokeWidthFixture()
    #expect(strokeWidth.strokeWidth(for: .finiteBefore) == 0)
    #expect(strokeWidth.strokeWidth(for: .negativeFinite) == -2)
    #expect(strokeWidth.strokeWidth(for: .positiveInfinity) == .infinity)
    #expect(strokeWidth.strokeWidth(for: .negativeInfinity) == -.infinity)
    #expect(strokeWidth.strokeWidth(for: .notANumber).isNaN)

    let opacity = OpacityFixture()
    #expect(opacity.opacity(for: .zero) == 0)
    #expect(opacity.opacity(for: .one) == 1)
    #expect(opacity.opacity(for: .finiteInterior) == 0.5)
    #expect(opacity.opacity(for: .negativeFinite) == -0.25)
    #expect(opacity.opacity(for: .finiteAboveOne) == 1.25)
    #expect(opacity.opacity(for: .positiveInfinity) == .infinity)
    #expect(opacity.opacity(for: .negativeInfinity) == -.infinity)
    #expect(opacity.opacity(for: .notANumber).isNaN)
}

@Test
func scalarValidatorsAcceptFiniteNonnegativeValuesAndOpacityBoundaries() {
    let designSystem = ValidScalarDesignSystem()
    validateDimensions(in: designSystem)
    validateSizes(in: designSystem)
    validateCornerRadii(in: designSystem)
    validateStrokeWidths(in: designSystem)
    validateOpacities(in: designSystem)
}
