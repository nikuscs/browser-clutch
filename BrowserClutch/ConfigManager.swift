import Foundation

final class ConfigManager {
    static let shared = ConfigManager()

    private let appName = "BrowserClutch"
    private let configFileName = "config.json"
    private let log = Logger.shared

    private init() {}

    var configDirectoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(appName)
    }

    var configFileURL: URL {
        configDirectoryURL.appendingPathComponent(configFileName)
    }

    func ensureConfigDirectoryExists() {
        try? FileManager.default.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)
    }

    func loadConfig() -> RoutingConfig {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            log.debug("No config file, using defaults")
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

    private func defaultConfig() -> RoutingConfig {
        RoutingConfig(defaultBrowser: "com.apple.Safari", rules: [])
    }
}
