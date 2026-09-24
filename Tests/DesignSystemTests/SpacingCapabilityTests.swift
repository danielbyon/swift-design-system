import CoreGraphics
import DesignSystem
import DesignSystemTestSupport
import Synchronization
import Testing

private enum SpacingFixtureToken: SpacingToken {
    case positiveFinite
    case negativeFinite
    case positiveInfinity
    case negativeInfinity
    case notANumber
}

private struct SpacingFixture: SpacingDesignSystem {
    typealias Spacing = SpacingFixtureToken

    func spacing(for token: Spacing) -> CGFloat {
        switch token {
        case .positiveFinite:
            12
        case .negativeFinite:
            -4
        case .positiveInfinity:
            .infinity
        case .negativeInfinity:
            -.infinity
        case .notANumber:
            .nan
        }
    }
}

private enum FiniteSpacingToken: SpacingToken {
    case negative
    case positive
}

private struct FiniteSpacingDesignSystem: SpacingDesignSystem {
    typealias Spacing = FiniteSpacingToken

    func spacing(for token: Spacing) -> CGFloat {
        switch token {
        case .negative:
            -3
        case .positive:
            9
        }
    }
}

private enum ValidationSpacingToken: SpacingToken {
    case finiteBefore
    case positiveInfinity
    case notANumber
    case negativeInfinity
    case finiteAfter
}

private final class ValidationSpacingDesignSystem: SpacingDesignSystem {
    typealias Spacing = ValidationSpacingToken

    private let resolvedTokenDescriptions = Mutex<[String]>([])

    var resolutionHistory: [String] {
        resolvedTokenDescriptions.withLock { $0 }
    }

    func spacing(for token: Spacing) -> CGFloat {
        resolvedTokenDescriptions.withLock { $0.append(String(describing: token)) }

        switch token {
        case .finiteBefore:
            -2
        case .positiveInfinity:
            .infinity
        case .notANumber:
            .nan
        case .negativeInfinity:
            -.infinity
        case .finiteAfter:
            7
        }
    }
}

private let expectedNonFiniteTokenDescriptions = [
    String(describing: ValidationSpacingToken.positiveInfinity),
    String(describing: ValidationSpacingToken.notANumber),
    String(describing: ValidationSpacingToken.negativeInfinity),
]

private let capturedNonFiniteSpacingIssues = Mutex<[String]>([])

@Test
func spacingResolverReturnsAppAuthoredValuesUnchanged() {
    let designSystem = SpacingFixture()

    #expect(designSystem.spacing(for: .positiveFinite) == 12)
    #expect(designSystem.spacing(for: .negativeFinite) == -4)
    #expect(designSystem.spacing(for: .positiveInfinity) == .infinity)
    #expect(designSystem.spacing(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.spacing(for: .notANumber).isNaN)
}

@Test(.filterIssues { issue in
    guard case .unconditional = issue.kind,
          issue.sourceLocation?.moduleName == "DesignSystemTestSupport"
    else {
        return true
    }

    let comment = issue.comments.map(\.rawValue).joined(separator: " ")
    guard let tokenDescription = expectedNonFiniteTokenDescriptions.first(where: {
        comment.contains($0)
    }) else {
        return true
    }

    capturedNonFiniteSpacingIssues.withLock { $0.append(tokenDescription) }
    return false
})
func spacingValidatorReportsEveryNonFiniteTokenAndContinues() {
    capturedNonFiniteSpacingIssues.withLock { $0.removeAll() }

    let designSystem = ValidationSpacingDesignSystem()
    validateSpacing(in: designSystem)

    let expectedVocabulary = ValidationSpacingToken.allCases
        .map { String(describing: $0) }
        .sorted()
    let resolvedVocabulary = designSystem.resolutionHistory.sorted()
    #expect(resolvedVocabulary == expectedVocabulary)

    let reportedTokens = capturedNonFiniteSpacingIssues.withLock { $0 }.sorted()
    #expect(reportedTokens == expectedNonFiniteTokenDescriptions.sorted())

    #expect(designSystem.spacing(for: .finiteBefore) == -2)
    #expect(designSystem.spacing(for: .positiveInfinity) == .infinity)
    #expect(designSystem.spacing(for: .notANumber).isNaN)
    #expect(designSystem.spacing(for: .negativeInfinity) == -.infinity)
    #expect(designSystem.spacing(for: .finiteAfter) == 7)
}

@Test
func spacingValidatorDoesNotReportFiniteVocabulary() {
    validateSpacing(in: FiniteSpacingDesignSystem())
}
