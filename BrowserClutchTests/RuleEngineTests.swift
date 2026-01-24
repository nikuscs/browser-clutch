import XCTest
@testable import BrowserClutch

final class RuleEngineTests: XCTestCase {

    // MARK: - Basic Routing

    func testReturnsDefaultBrowserWhenNoRules() {
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
        XCTAssertFalse(options.private)
        XCTAssertFalse(options.newWindow)
    }

    func testReturnsDefaultBrowserWhenNoMatch() {
        let rule = Rule(
            id: "slack-rule",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: ("Discord", "com.discord"))

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    // MARK: - Source Matching

    func testMatchesSourceApp() {
        let rule = Rule(
            id: "slack-rule",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: ("Slack", "com.tinyspeck.slackmacgap"))

        XCTAssertEqual(options.browser, "com.google.Chrome")
    }

    func testSourceRuleRequiresSourceApp() {
        let rule = Rule(
            id: "slack-rule",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    // MARK: - Domain Matching

    func testMatchesDomain() {
        let rule = Rule(
            id: "github-rule",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "org.mozilla.firefox"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com/user/repo")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "org.mozilla.firefox")
    }

    // MARK: - Combined Matching

    func testMatchesSourceAndDomain() {
        let rule = Rule(
            id: "slack-github",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com/user/repo")!
        let options = engine.find(forURL: url, sourceApp: ("Slack", "com.tinyspeck.slackmacgap"))

        XCTAssertEqual(options.browser, "com.google.Chrome")
    }

    func testSourceAndDomainBothRequired() {
        let rule = Rule(
            id: "slack-github",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://gitlab.com/user/repo")!
        let options = engine.find(forURL: url, sourceApp: ("Slack", "com.tinyspeck.slackmacgap"))

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    // MARK: - Priority

    func testHigherPriorityWins() {
        let lowPriority = Rule(
            id: "low-priority",
            priority: 10,
            source: nil,
            domain: DomainMatch(contains: "github"),
            browser: "org.mozilla.firefox"
        )
        let highPriority = Rule(
            id: "high-priority",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [lowPriority, highPriority])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com/user/repo")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.google.Chrome")
    }

    func testPrioritySortingIndependentOfOrder() {
        let lowPriority = Rule(
            id: "low-priority",
            priority: 10,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "org.mozilla.firefox"
        )
        let highPriority = Rule(
            id: "high-priority",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [lowPriority, highPriority])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com/user/repo")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.google.Chrome")
    }

    // MARK: - Launch Options

    func testPrivateModeFromRule() {
        let rule = Rule(
            id: "private-rule",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "private.com"),
            browser: "com.google.Chrome",
            private: true
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://private.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertTrue(options.private)
    }

    func testNewWindowFromRule() {
        let rule = Rule(
            id: "new-window-rule",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "popup.com"),
            browser: "com.google.Chrome",
            newWindow: true
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://popup.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertTrue(options.newWindow)
    }

    // MARK: - Edge Cases

    func testRuleWithNoMatchersSkipped() {
        let rule = Rule(
            id: "empty-rule",
            priority: 100,
            source: nil,
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    // MARK: - Graceful Fallback (Never Block User)

    func testInvalidRegexFallsBackToDefault() {
        let rule = Rule(
            id: "invalid-regex",
            priority: 100,
            source: nil,
            domain: DomainMatch(pattern: "[invalid(regex"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    func testInvalidSourcePatternFallsBackToDefault() {
        let rule = Rule(
            id: "invalid-source",
            priority: 100,
            source: SourceMatch(pattern: "[invalid(regex"),
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: ("Slack", "com.slack"))

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    func testURLWithoutHostFallsBackToDefault() {
        let rule = Rule(
            id: "domain-rule",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "file:///path/to/file.html")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    func testEmptyDomainMatchFallsBackToDefault() {
        let rule = Rule(
            id: "empty-domain",
            priority: 100,
            source: nil,
            domain: DomainMatch(),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    func testEmptySourceMatchFallsBackToDefault() {
        let rule = Rule(
            id: "empty-source",
            priority: 100,
            source: SourceMatch(),
            domain: nil,
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: ("Slack", "com.slack"))

        XCTAssertEqual(options.browser, "com.apple.Safari")
    }

    func testValidRuleStillMatchesAfterInvalidRule() {
        let invalidRule = Rule(
            id: "invalid",
            priority: 200,
            source: nil,
            domain: DomainMatch(pattern: "[invalid"),
            browser: "org.mozilla.firefox"
        )
        let validRule = Rule(
            id: "valid",
            priority: 100,
            source: nil,
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome"
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [invalidRule, validRule])
        let engine = RuleEngine(config: config)

        let url = URL(string: "https://github.com")!
        let options = engine.find(forURL: url, sourceApp: nil)

        XCTAssertEqual(options.browser, "com.google.Chrome")
    }
}
