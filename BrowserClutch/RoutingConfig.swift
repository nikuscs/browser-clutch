import Foundation

struct RoutingConfig: Codable {
    static let currentVersion = 1

    let version: Int
    let defaultBrowser: String
    let rules: [Rule]

    init(defaultBrowser: String, rules: [Rule]) {
        self.version = Self.currentVersion
        self.defaultBrowser = defaultBrowser
        self.rules = rules
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Default to version 1 for configs without version field
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.defaultBrowser = try container.decode(String.self, forKey: .defaultBrowser)
        self.rules = try container.decode([Rule].self, forKey: .rules)
    }
}

struct Rule: Codable {
    let id: String
    let priority: Int
    let source: SourceMatch?
    let domain: DomainMatch?
    let browser: String
    let `private`: Bool?
    let newWindow: Bool?

    enum CodingKeys: String, CodingKey {
        case id, priority, source, domain, browser
        case `private`
        case newWindow = "new_window"
    }

    init(
        id: String,
        priority: Int,
        source: SourceMatch?,
        domain: DomainMatch?,
        browser: String,
        `private`: Bool? = nil,
        newWindow: Bool? = nil
    ) {
        self.id = id
        self.priority = priority
        self.source = source
        self.domain = domain
        self.browser = browser
        self.private = `private`
        self.newWindow = newWindow
    }
}

struct LaunchOptions {
    let browser: String
    let `private`: Bool
    let newWindow: Bool

    static func from(rule: Rule) -> LaunchOptions {
        LaunchOptions(
            browser: rule.browser,
            private: rule.private ?? false,
            newWindow: rule.newWindow ?? false
        )
    }

    static func `default`(browser: String) -> LaunchOptions {
        LaunchOptions(browser: browser, private: false, newWindow: false)
    }
}

struct SourceMatch: Codable {
    let name: String?
    let bundleId: String?
    let pattern: String?

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
        guard let host = url.host?.lowercased() else { return false }

        if let exact = exact {
            return exact.lowercased() == host
        }

        if let pattern = pattern {
            return matchesWildcard(pattern.lowercased(), against: host)
        }

        if let contains = contains {
            return host.contains(contains.lowercased())
        }

        return false
    }

    private func matchesWildcard(_ pattern: String, against host: String) -> Bool {
        let regexPattern: String
        if pattern.hasPrefix("^") {
            regexPattern = pattern
        } else {
            regexPattern = "^" + pattern
                .replacingOccurrences(of: ".", with: "\\.")
                .replacingOccurrences(of: "*", with: ".*") + "$"
        }

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }
        let range = NSRange(host.startIndex..<host.endIndex, in: host)
        return regex.firstMatch(in: host, options: [], range: range) != nil
    }
}
