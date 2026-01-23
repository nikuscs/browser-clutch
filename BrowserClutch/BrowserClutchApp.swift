import SwiftUI

@main
struct BrowserClutchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserClutch", image: "MenuBarIcon") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @State private var currentDefault: String = ConfigManager.shared.loadConfig().defaultBrowser

    private var isDefaultBrowser: Bool {
        guard let testURL = URL(string: "https://example.com"),
              let defaultBrowserURL = NSWorkspace.shared.urlForApplication(toOpen: testURL),
              let bundle = Bundle(url: defaultBrowserURL),
              let bundleId = bundle.bundleIdentifier else {
            return false
        }
        return bundleId == "com.browserclutch.app"
    }

    private var installedBrowsers: [BrowserInfo] {
        BrowserDetector.detectInstalledBrowsers()
    }

    var body: some View {
        if !isDefaultBrowser {
            Button("⚠️ Set as Default Browser...") {
                openDefaultBrowserSettings()
            }
            Divider()
        }

        // Default browser section
        Text("Default Browser")
            .font(.caption)
            .foregroundColor(.secondary)

        ForEach(installedBrowsers) { browser in
            let isSelected = browser.bundleId == currentDefault
            if let icon = browser.icon {
                Button(action: { setDefaultBrowser(browser.bundleId) }) {
                    Image(nsImage: icon)
                    Text(browser.name + (isSelected ? "  ✓" : ""))
                }
            } else {
                Button(browser.name + (isSelected ? "  ✓" : "")) {
                    setDefaultBrowser(browser.bundleId)
                }
            }
        }

        Divider()

        Button("Settings...") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func setDefaultBrowser(_ bundleId: String) {
        let config = ConfigManager.shared.loadConfig()
        let newConfig = RoutingConfig(defaultBrowser: bundleId, rules: config.rules)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(newConfig),
           let json = String(data: data, encoding: .utf8) {
            try? json.write(to: ConfigManager.shared.configFileURL, atomically: true, encoding: .utf8)
            currentDefault = bundleId
        }
    }

    private func openDefaultBrowserSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Browser Detection

struct BrowserInfo: Identifiable {
    let id: String
    let bundleId: String
    let name: String
    let icon: NSImage?

    init(bundleId: String, name: String, icon: NSImage? = nil) {
        self.id = bundleId
        self.bundleId = bundleId
        self.name = name
        self.icon = icon
    }
}

enum BrowserDetector {
    static let knownBrowsers: [(bundleId: String, name: String)] = [
        ("com.apple.Safari", "Safari"),
        ("com.google.Chrome", "Chrome"),
        ("org.mozilla.firefox", "Firefox"),
        ("com.brave.Browser", "Brave"),
        ("com.microsoft.edgemac", "Edge"),
        ("company.thebrowser.Browser", "Arc"),
        ("com.operasoftware.Opera", "Opera"),
        ("com.vivaldi.Vivaldi", "Vivaldi"),
    ]

    static func detectInstalledBrowsers() -> [BrowserInfo] {
        let workspace = NSWorkspace.shared
        var browsers: [BrowserInfo] = []

        for (bundleId, name) in knownBrowsers {
            if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) {
                let icon = workspace.icon(forFile: appURL.path)
                icon.size = NSSize(width: 16, height: 16)
                browsers.append(BrowserInfo(bundleId: bundleId, name: name, icon: icon))
            }
        }

        return browsers
    }
}

