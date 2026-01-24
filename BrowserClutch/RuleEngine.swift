import Foundation

final class RuleEngine {
    private let config: RoutingConfig
    private let rules: [Rule]
    private let log = Logger.shared

    init(config: RoutingConfig) {
        self.config = config
        self.rules = config.rules.sorted { $0.priority > $1.priority }
    }

    func find(forURL url: URL, sourceApp: (name: String, bundleId: String)?) -> LaunchOptions {
        for rule in rules where matches(rule: rule, url: url, sourceApp: sourceApp) {
            log.debug("Rule '\(rule.id)' matched")
            return LaunchOptions.from(rule: rule)
        }
        return LaunchOptions.default(browser: config.defaultBrowser)
    }

    private func matches(rule: Rule, url: URL, sourceApp: (name: String, bundleId: String)?) -> Bool {
        guard rule.source != nil || rule.domain != nil else { return false }
        if rule.source != nil && sourceApp == nil { return false }

        if let sourceMatch = rule.source, let sourceApp = sourceApp {
            if !sourceMatch.matches(appName: sourceApp.name, bundleId: sourceApp.bundleId) {
                return false
            }
        }

        if let domainMatch = rule.domain {
            if !domainMatch.matches(url: url) {
                return false
            }
        }

        return true
    }
}
