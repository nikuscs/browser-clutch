import Foundation

final class RuleEngine {
    private let config: RoutingConfig
    private let sortedRules: [Rule]
    private let log = Logger.shared

    init(config: RoutingConfig) {
        self.config = config
        self.sortedRules = config.rules.sorted { $0.priority > $1.priority }
    }

    func findBrowser(forURL url: URL, sourceApp: (name: String, bundleId: String)?) -> String {
        for rule in sortedRules {
            if matches(rule: rule, url: url, sourceApp: sourceApp) {
                log.debug("Rule '\(rule.id)' matched")
                return rule.browser
            }
        }
        return config.defaultBrowser
    }

    private func matches(rule: Rule, url: URL, sourceApp: (name: String, bundleId: String)?) -> Bool {
        // Rule must have at least one condition
        guard rule.source != nil || rule.domain != nil else {
            return false
        }

        // If rule requires source match but no source app detected, skip
        if rule.source != nil && sourceApp == nil {
            return false
        }

        // Check source match if specified
        if let sourceMatch = rule.source, let sourceApp = sourceApp {
            if !sourceMatch.matches(appName: sourceApp.name, bundleId: sourceApp.bundleId) {
                return false
            }
        }

        // Check domain match if specified
        if let domainMatch = rule.domain {
            if !domainMatch.matches(url: url) {
                return false
            }
        }

        return true
    }
}
