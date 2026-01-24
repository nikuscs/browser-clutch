import XCTest
@testable import BrowserClutch

final class DomainMatchTests: XCTestCase {

    // MARK: - Exact Matching

    func testMatchesExactDomain() {
        let match = DomainMatch(exact: "github.com")
        let url = URL(string: "https://github.com/user/repo")!
        XCTAssertTrue(match.matches(url: url))
    }

    func testDoesNotMatchSubdomain() {
        let match = DomainMatch(exact: "github.com")
        let url = URL(string: "https://gist.github.com/user/123")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testDoesNotMatchDifferentDomain() {
        let match = DomainMatch(exact: "github.com")
        let url = URL(string: "https://gitlab.com/user/repo")!
        XCTAssertFalse(match.matches(url: url))
    }

    // MARK: - Wildcard Matching

    func testMatchesWildcardSubdomain() {
        let match = DomainMatch(pattern: "*.github.com")
        let url = URL(string: "https://gist.github.com/user/123")!
        XCTAssertTrue(match.matches(url: url))
    }

    func testMatchesWildcardMultipleSubdomains() {
        let match = DomainMatch(pattern: "*.github.com")
        let url = URL(string: "https://raw.githubusercontent.github.com/file")!
        XCTAssertTrue(match.matches(url: url))
    }

    func testWildcardDoesNotMatchRootDomain() {
        let match = DomainMatch(pattern: "*.github.com")
        let url = URL(string: "https://github.com/user/repo")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testMatchesContainsWildcard() {
        let match = DomainMatch(pattern: "*google*")
        XCTAssertTrue(match.matches(url: URL(string: "https://google.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://mail.google.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://google.co.uk")!))
    }

    // MARK: - Contains Matching

    func testMatchesContains() {
        let match = DomainMatch(contains: "google")
        XCTAssertTrue(match.matches(url: URL(string: "https://google.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://mail.google.com")!))
    }

    func testDoesNotMatchContains() {
        let match = DomainMatch(contains: "google")
        XCTAssertFalse(match.matches(url: URL(string: "https://bing.com")!))
    }

    // MARK: - Regex Patterns

    func testMatchesNegationRegex() {
        let match = DomainMatch(pattern: "^(?!.*mail).*google.*")
        XCTAssertTrue(match.matches(url: URL(string: "https://google.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://docs.google.com")!))
        XCTAssertFalse(match.matches(url: URL(string: "https://mail.google.com")!))
    }

    func testMatchesTLDRegex() {
        let match = DomainMatch(pattern: "^.*\\.(dev|io)$")
        XCTAssertTrue(match.matches(url: URL(string: "https://example.dev")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://app.io")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://sub.domain.dev")!))
        XCTAssertFalse(match.matches(url: URL(string: "https://example.com")!))
    }

    func testMatchesComplexRegex() {
        let match = DomainMatch(pattern: "^(www\\.)?github\\.com$")
        XCTAssertTrue(match.matches(url: URL(string: "https://github.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://www.github.com")!))
        XCTAssertFalse(match.matches(url: URL(string: "https://gist.github.com")!))
    }

    // MARK: - Case Insensitivity

    func testMatchesCaseInsensitiveExact() {
        let match = DomainMatch(exact: "GitHub.COM")
        XCTAssertTrue(match.matches(url: URL(string: "https://github.com/user/repo")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://GITHUB.COM/user/repo")!))
    }

    func testMatchesCaseInsensitivePattern() {
        let match = DomainMatch(pattern: "*.GITHUB.com")
        XCTAssertTrue(match.matches(url: URL(string: "https://gist.github.com/user/123")!))
    }

    func testMatchesCaseInsensitiveContains() {
        let match = DomainMatch(contains: "GOOGLE")
        XCTAssertTrue(match.matches(url: URL(string: "https://google.com")!))
        XCTAssertTrue(match.matches(url: URL(string: "https://mail.google.com")!))
    }

    // MARK: - Edge Cases

    func testNoMatchersReturnsFalse() {
        let match = DomainMatch()
        let url = URL(string: "https://github.com")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testURLWithoutHostReturnsFalse() {
        let match = DomainMatch(exact: "github.com")
        let url = URL(string: "file:///path/to/file")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testInvalidWildcardPatternReturnsFalse() {
        let match = DomainMatch(pattern: "[invalid")
        let url = URL(string: "https://github.com")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testExactTakesPrecedenceOverPattern() {
        let match = DomainMatch(exact: "github.com", pattern: "*.gitlab.com")
        let url = URL(string: "https://github.com/user/repo")!
        XCTAssertTrue(match.matches(url: url))
    }

    func testEmptyStringExactDoesNotMatch() {
        let match = DomainMatch(exact: "")
        let url = URL(string: "https://github.com")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testEmptyStringPatternDoesNotMatch() {
        let match = DomainMatch(pattern: "")
        let url = URL(string: "https://github.com")!
        XCTAssertFalse(match.matches(url: url))
    }

    func testMatchesIPAddress() {
        let match = DomainMatch(exact: "192.168.1.1")
        XCTAssertTrue(match.matches(url: URL(string: "http://192.168.1.1:8080/path")!))
    }

    func testMatchesLocalhost() {
        let match = DomainMatch(exact: "localhost")
        XCTAssertTrue(match.matches(url: URL(string: "http://localhost:3000")!))
    }

    func testWildcardMatchesLocalhost() {
        let match = DomainMatch(pattern: "local*")
        XCTAssertTrue(match.matches(url: URL(string: "http://localhost:3000")!))
    }

    func testPortDoesNotAffectMatching() {
        let match = DomainMatch(exact: "github.com")
        XCTAssertTrue(match.matches(url: URL(string: "https://github.com:443/user/repo")!))
    }

    func testPathDoesNotAffectMatching() {
        let match = DomainMatch(exact: "github.com")
        XCTAssertTrue(match.matches(url: URL(string: "https://github.com/very/long/path/to/file.html?query=1")!))
    }
}
