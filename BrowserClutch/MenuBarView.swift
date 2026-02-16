import SwiftUI

struct MenuBarView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @Environment(\.openSettings) private var openSettings
    @State private var currentDefault = ConfigManager.shared.load().defaultBrowser

    var body: some View {
        if !DefaultBrowser.isSet {
            Button("Set as Default Browser...") {
                DefaultBrowser.openSettings()
            }
            Divider()
        }

        Text("Default Browser")
            .font(.caption)
            .foregroundColor(.secondary)

        ForEach(BrowserDetector.detect()) { browser in
            let selected = browser.bundleId == currentDefault
            if let icon = browser.icon {
                Button(
                    action: { select(browser.bundleId) },
                    label: {
                        Image(nsImage: icon)
                        Text(browser.name + (selected ? "  ✓" : ""))
                    }
                )
            } else {
                Button(browser.name + (selected ? "  ✓" : "")) {
                    select(browser.bundleId)
                }
            }
        }

        Divider()

        Button("Settings...") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Check for Updates...") {
            updaterViewModel.checkForUpdates()
        }
        .disabled(!updaterViewModel.canCheckForUpdates)

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func select(_ bundleId: String) {
        let config = ConfigManager.shared.load()
        let updated = RoutingConfig(defaultBrowser: bundleId, rules: config.rules)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(updated) else { return }
        try? data.write(to: ConfigManager.shared.configFileURL)
        currentDefault = bundleId
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
}
