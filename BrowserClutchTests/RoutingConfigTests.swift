import XCTest
@testable import BrowserClutch

final class RoutingConfigTests: XCTestCase {

    // MARK: - JSON Encoding

    func testEncodesConfigToJSON() throws {
        let rule = Rule(
            id: "test-rule",
            priority: 100,
            source: SourceMatch(name: "Slack"),
            domain: DomainMatch(exact: "github.com"),
            browser: "com.google.Chrome",
            private: true,
            newWindow: false
        )
        let config = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"defaultBrowser\""))
        XCTAssertTrue(json.contains("com.apple.Safari"))
        XCTAssertTrue(json.contains("\"rules\""))
        XCTAssertTrue(json.contains("test-rule"))
    }

    func testDecodesConfigFromJSON() throws {
        let json = """
        {
            "version": 1,
            "defaultBrowser": "com.apple.Safari",
            "rules": [
                {
                    "id": "test-rule",
                    "priority": 100,
                    "source": { "name": "Slack" },
                    "domain": { "exact": "github.com" },
                    "browser": "com.google.Chrome",
                    "private": true,
                    "new_window": false
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(RoutingConfig.self, from: data)

        XCTAssertEqual(config.version, 1)
        XCTAssertEqual(config.defaultBrowser, "com.apple.Safari")
        XCTAssertEqual(config.rules.count, 1)
        XCTAssertEqual(config.rules[0].id, "test-rule")
        XCTAssertEqual(config.rules[0].priority, 100)
        XCTAssertEqual(config.rules[0].source?.name, "Slack")
        XCTAssertEqual(config.rules[0].domain?.exact, "github.com")
        XCTAssertEqual(config.rules[0].browser, "com.google.Chrome")
        XCTAssertEqual(config.rules[0].private, true)
        XCTAssertEqual(config.rules[0].newWindow, false)
    }

    func testDecodesConfigWithoutVersion() throws {
        let json = """
        {
            "defaultBrowser": "com.apple.Safari",
            "rules": []
        }
        """

        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(RoutingConfig.self, from: data)

        XCTAssertEqual(config.version, 1)
    }

    func testDecodesMinimalRule() throws {
        let json = """
        {
            "version": 1,
            "defaultBrowser": "com.apple.Safari",
            "rules": [
                {
                    "id": "minimal",
                    "priority": 50,
                    "browser": "com.google.Chrome"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(RoutingConfig.self, from: data)

        XCTAssertNil(config.rules[0].source)
        XCTAssertNil(config.rules[0].domain)
        XCTAssertNil(config.rules[0].private)
        XCTAssertNil(config.rules[0].newWindow)
    }

    // MARK: - Round Trip

    func testRoundTripEncoding() throws {
        let rule = Rule(
            id: "roundtrip-rule",
            priority: 75,
            source: SourceMatch(bundleId: "com.tinyspeck.slackmacgap"),
            domain: DomainMatch(pattern: "*.github.com"),
            browser: "org.mozilla.firefox",
            private: false,
            newWindow: true
        )
        let original = RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [rule])

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(RoutingConfig.self, from: data)

        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.defaultBrowser, original.defaultBrowser)
        XCTAssertEqual(decoded.rules.count, original.rules.count)
        XCTAssertEqual(decoded.rules[0].id, original.rules[0].id)
        XCTAssertEqual(decoded.rules[0].source?.bundleId, original.rules[0].source?.bundleId)
        XCTAssertEqual(decoded.rules[0].domain?.pattern, original.rules[0].domain?.pattern)
    }

    // MARK: - LaunchOptions

    func testLaunchOptionsFromRule() {
        let rule = Rule(
            id: "test",
            priority: 100,
            source: nil,
            domain: nil,
            browser: "com.google.Chrome",
            private: true,
            newWindow: true
        )

        let options = LaunchOptions.from(rule: rule)

        XCTAssertEqual(options.browser, "com.google.Chrome")
        XCTAssertTrue(options.private)
        XCTAssertTrue(options.newWindow)
    }

    func testLaunchOptionsDefaultsNilToFalse() {
        let rule = Rule(
            id: "test",
            priority: 100,
            source: nil,
            domain: nil,
            browser: "com.google.Chrome"
        )

        let options = LaunchOptions.from(rule: rule)

        XCTAssertFalse(options.private)
        XCTAssertFalse(options.newWindow)
    }

    func testLaunchOptionsDefault() {
        let options = LaunchOptions.default(browser: "com.apple.Safari")

        XCTAssertEqual(options.browser, "com.apple.Safari")
        XCTAssertFalse(options.private)
        XCTAssertFalse(options.newWindow)
    }
}
