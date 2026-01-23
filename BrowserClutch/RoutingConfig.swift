import Foundation

struct RoutingConfig: Codable {
    let defaultBrowser: String
    let rules: [Rule]

    init(defaultBrowser: String, rules: [Rule]) {
        self.defaultBrowser = defaultBrowser
        self.rules = rules
    }
}

struct Rule: Codable {
    let id: String
    let priority: Int
    let source: SourceMatch?
    let domain: DomainMatch?
    let browser: String

    init(id: String, priority: Int, source: SourceMatch?, domain: DomainMatch?, browser: String) {
        self.id = id
        self.priority = priority
        self.source = source
        self.domain = domain
        self.browser = browser
    }
}

struct SourceMatch: Codable {
    let name: String?
    let bundleId: String?
    let pattern: String?

    // Cached regex
    private var cachedRegex: NSRegularExpression?

    enum CodingKeys: String, CodingKey {
        case name
        case bundleId = "bundle_id"
        case pattern
    }

    init(name: String? = nil, bundleId: String? = nil, pattern: String? = nil) {
        self.name = name
        self.bundleId = bundleId
        self.pattern = pattern
    }

    func matches(appName: String, bundleId appBundleId: String) -> Bool {
        if let name = name, name == appName {
            return true
        }
        if let bundleId = bundleId, bundleId == appBundleId {
            return true
        }
        if let pattern = pattern {
            return matchesPattern(pattern, against: appName)
        }
        return false
    }

    private func matchesPattern(_ pattern: String, against text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

struct DomainMatch: Codable {
    let exact: String?
    let pattern: String?
    let contains: String?

    init(exact: String? = nil, pattern: String? = nil, contains: String? = nil) {
        self.exact = exact
        self.pattern = pattern
        self.contains = contains
    }

    func matches(url: URL) -> Bool {
        guard let host = url.host else { return false }

        if let exact = exact {
            return exact == host
        }

        if let pattern = pattern {
            return matchesWildcard(pattern, against: host)
        }

        if let contains = contains {
            return host.contains(contains)
        }

        return false
    }

    private func matchesWildcard(_ pattern: String, against host: String) -> Bool {
        // Convert wildcard to regex: "*.github.com" -> "^.*\.github\.com$"
        let regexPattern = "^" + pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*") + "$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }
        let range = NSRange(host.startIndex..<host.endIndex, in: host)
        return regex.firstMatch(in: host, options: [], range: range) != nil
    }
}
