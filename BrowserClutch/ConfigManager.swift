import Foundation

final class ConfigManager {
    static let shared = ConfigManager()

    private let configFileName = "config.json"
    private let log = Logger.shared

    private init() {}

    var configDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("browserclutch")
    }

    var configFileURL: URL {
        configDirectoryURL.appendingPathComponent(configFileName)
    }

    func ensureConfigDirectoryExists() {
        try? FileManager.default.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)
    }

    func load() -> RoutingConfig {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            log.debug("No config, using defaults")
            return defaultConfig()
        }

        do {
            let data = try Data(contentsOf: configFileURL)
            return try JSONDecoder().decode(RoutingConfig.self, from: data)
        } catch {
            log.error("Config load failed: \(error.localizedDescription)")
            return defaultConfig()
        }
    }

    func save(_ config: RoutingConfig) throws {
        ensureConfigDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configFileURL)
    }

    private func defaultConfig() -> RoutingConfig {
        let browser = BrowserDetector.detect().first?.bundleId ?? ""
        return RoutingConfig(defaultBrowser: browser, rules: [])
    }
}
