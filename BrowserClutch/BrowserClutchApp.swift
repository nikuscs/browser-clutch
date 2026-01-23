import SwiftUI

@main
struct BrowserClutchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserClutch", systemImage: "arrow.triangle.branch") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            ConfigEditorView()
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

struct ConfigEditorView: View {
    @State private var configText: String = ""
    @State private var statusMessage: String = ""
    @State private var isError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Config")
                    .font(.headline)
                Spacer()
                Button {
                    NSWorkspace.shared.open(ConfigManager.shared.configDirectoryURL)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open config folder")
            }

            TextEditor(text: $configText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 500, minHeight: 350)

            HStack {
                Text(statusMessage)
                    .foregroundColor(isError ? .red : .green)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()

                Button("Reload") {
                    loadConfig()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Save") {
                    saveConfig()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .padding()
        .frame(width: 600, height: 450)
        .onAppear {
            loadConfig()
        }
    }

    private func loadConfig() {
        let configURL = ConfigManager.shared.configFileURL

        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                configText = try String(contentsOf: configURL, encoding: .utf8)
                statusMessage = "Loaded from: \(configURL.path)"
                isError = false
            } catch {
                configText = defaultConfigTemplate()
                statusMessage = "Error loading: \(error.localizedDescription)"
                isError = true
            }
        } else {
            configText = defaultConfigTemplate()
            statusMessage = "No config file yet - showing template"
            isError = false
        }
    }

    private func saveConfig() {
        guard let data = configText.data(using: .utf8) else {
            statusMessage = "Error: Invalid text encoding"
            isError = true
            return
        }

        // Validate JSON
        do {
            _ = try JSONDecoder().decode(RoutingConfig.self, from: data)
        } catch {
            statusMessage = "Invalid JSON: \(error.localizedDescription)"
            isError = true
            return
        }

        // Save
        do {
            ConfigManager.shared.ensureConfigDirectoryExists()
            try configText.write(to: ConfigManager.shared.configFileURL, atomically: true, encoding: .utf8)
            statusMessage = "Saved!"
            isError = false
        } catch {
            statusMessage = "Error saving: \(error.localizedDescription)"
            isError = true
        }
    }

    private func defaultConfigTemplate() -> String {
        """
        {
          "defaultBrowser": "com.apple.Safari",
          "rules": [
            {
              "id": "example-rule",
              "priority": 100,
              "source": {
                "name": "Slack"
              },
              "browser": "com.google.Chrome"
            }
          ]
        }
        """
    }
}
