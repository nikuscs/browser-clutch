import XCTest
@testable import BrowserClutch

final class SourceMatchTests: XCTestCase {

    // MARK: - Name Matching

    func testMatchesExactName() {
        let match = SourceMatch(name: "Slack")
        XCTAssertTrue(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
    }

    func testDoesNotMatchDifferentName() {
        let match = SourceMatch(name: "Slack")
        XCTAssertFalse(match.matches(appName: "Discord", bundleId: "com.discord"))
    }

    // MARK: - Bundle ID Matching

    func testMatchesExactBundleId() {
        let match = SourceMatch(bundleId: "com.tinyspeck.slackmacgap")
        XCTAssertTrue(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
    }

    func testDoesNotMatchDifferentBundleId() {
        let match = SourceMatch(bundleId: "com.tinyspeck.slackmacgap")
        XCTAssertFalse(match.matches(appName: "Discord", bundleId: "com.discord"))
    }

    // MARK: - Pattern Matching

    func testMatchesRegexPattern() {
        let match = SourceMatch(pattern: "^Slack.*")
        XCTAssertTrue(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
        XCTAssertTrue(match.matches(appName: "SlackBeta", bundleId: "com.tinyspeck.slackmacgap.beta"))
    }

    func testDoesNotMatchRegexPattern() {
        let match = SourceMatch(pattern: "^Slack.*")
        XCTAssertFalse(match.matches(appName: "Discord", bundleId: "com.discord"))
    }

    func testMatchesPartialPattern() {
        let match = SourceMatch(pattern: "(?i).*mail.*")
        XCTAssertTrue(match.matches(appName: "Apple Mail", bundleId: "com.apple.mail"))
        XCTAssertTrue(match.matches(appName: "Airmail", bundleId: "it.bloop.airmail2"))
    }

    func testCaseSensitivePattern() {
        let match = SourceMatch(pattern: ".*Mail.*")
        XCTAssertTrue(match.matches(appName: "Apple Mail", bundleId: "com.apple.mail"))
        XCTAssertFalse(match.matches(appName: "Airmail", bundleId: "it.bloop.airmail2"))
    }

    // MARK: - Edge Cases

    func testNoMatchersReturnsFalse() {
        let match = SourceMatch()
        XCTAssertFalse(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
    }

    func testInvalidRegexReturnsFalse() {
        let match = SourceMatch(pattern: "[invalid")
        XCTAssertFalse(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
    }

    func testNameTakesPrecedenceOverBundleId() {
        let match = SourceMatch(name: "Slack", bundleId: "com.different.app")
        XCTAssertTrue(match.matches(appName: "Slack", bundleId: "com.tinyspeck.slackmacgap"))
    }
}
