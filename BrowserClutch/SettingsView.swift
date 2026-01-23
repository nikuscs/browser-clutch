import SwiftUI

struct SettingsView: View {
    @State private var defaultBrowser: String = ""
    @State private var rules: [RuleItem] = []
    @State private var statusMessage: String = ""
    @State private var isError: Bool = false
    @State private var installedBrowsers: [BrowserInfo] = []
    @State private var installedApps: [AppInfo] = []

    private let contentWidth: CGFloat = 450

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Default Browser
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Browser")
                    .font(.headline)

                Picker("", selection: $defaultBrowser) {
                    ForEach(installedBrowsers) { browser in
                        HStack(spacing: 8) {
                            if let icon = browser.icon {
                                Image(nsImage: icon)
                            }
                            Text(browser.name)
                        }
                        .tag(browser.bundleId)
                    }
                }
                .labelsHidden()
                .fixedSize()

                Text("URLs that don't match any rule open here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Rules
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rules")
                        .font(.headline)
                    Spacer()
                    Text("First match wins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if rules.isEmpty {
                    Text("No rules yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 1) {
                        ForEach(Array(rules.enumerated()), id: \.element.id) { index, _ in
                            RuleRow(
                                rule: $rules[index],
                                index: index,
                                installedApps: installedApps,
                                installedBrowsers: installedBrowsers,
                                canMoveUp: index > 0,
                                canMoveDown: index < rules.count - 1,
                                onMoveUp: { moveRule(from: index, direction: -1) },
                                onMoveDown: { moveRule(from: index, direction: 1) },
                                onDelete: { deleteRule(at: index) }
                            )
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
                }

                Button {
                    addRule()
                } label: {
                    Label("Add Rule", systemImage: "plus")
                        .font(.body)
                }
                .buttonStyle(.link)
            }

            Spacer()

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button {
                    NSWorkspace.shared.open(ConfigManager.shared.configDirectoryURL)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open config folder")

                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(isError ? .red : (statusMessage == "Saved" ? .green : .secondary))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("Reload") {
                    loadConfig()
                }

                Button("Save") {
                    saveConfig()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .padding(20)
        .frame(width: 500, height: 450)
        .onAppear {
            installedBrowsers = BrowserDetector.detectInstalledBrowsers()
            installedApps = AppDetector.detectAllApps()
            loadConfig()
        }
    }

    private func loadConfig() {
        let config = ConfigManager.shared.loadConfig()
        defaultBrowser = config.defaultBrowser

        rules = config.rules.map { rule in
            RuleItem(
                appName: rule.source?.name,
                urlPattern: rule.domain?.pattern ?? rule.domain?.contains,
                browser: rule.browser
            )
        }

        let configPath = ConfigManager.shared.configFileURL.path
            .replacingOccurrences(of: NSHomeDirectory(), with: "~")
        statusMessage = configPath
        isError = false
    }

    private func saveConfig() {
        // Validate rules
        for (index, rule) in rules.enumerated() {
            if rule.appName == nil && (rule.urlPattern ?? "").isEmpty {
                statusMessage = "Rule \(index + 1): needs app or domain"
                isError = true
                return
            }
            if rule.browser.isEmpty {
                statusMessage = "Rule \(index + 1): needs browser"
                isError = true
                return
            }
        }

        // Check for duplicates
        for i in 0..<rules.count {
            for j in (i + 1)..<rules.count {
                let r1 = rules[i]
                let r2 = rules[j]
                if r1.appName == r2.appName &&
                   r1.urlPattern == r2.urlPattern &&
                   r1.browser == r2.browser {
                    statusMessage = "Rules \(i + 1) & \(j + 1) are duplicates"
                    isError = true
                    return
                }
            }
        }

        let configRules: [Rule] = rules.enumerated().map { index, rule in
            Rule(
                id: "rule-\(index + 1)",
                priority: rules.count - index,
                source: rule.appName.map { SourceMatch(name: $0) },
                domain: (rule.urlPattern?.isEmpty == false) ? DomainMatch(pattern: rule.urlPattern) : nil,
                browser: rule.browser
            )
        }

        let config = RoutingConfig(defaultBrowser: defaultBrowser, rules: configRules)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            ConfigManager.shared.ensureConfigDirectoryExists()
            try data.write(to: ConfigManager.shared.configFileURL)
            statusMessage = "Saved"
            isError = false
            NotificationCenter.default.post(name: .configDidChange, object: nil)
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            isError = true
        }
    }

    private func addRule() {
        rules.append(RuleItem(appName: nil, urlPattern: nil, browser: defaultBrowser))
    }

    private func deleteRule(at index: Int) {
        rules.remove(at: index)
    }

    private func moveRule(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < rules.count else { return }
        rules.swapAt(index, newIndex)
    }
}

// MARK: - Rule Item Model

struct RuleItem: Identifiable {
    let id = UUID()
    var appName: String?
    var urlPattern: String?
    var browser: String
}

// MARK: - Rule Row

struct RuleRow: View {
    @Binding var rule: RuleItem
    let index: Int
    let installedApps: [AppInfo]
    let installedBrowsers: [BrowserInfo]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Move buttons
            VStack(spacing: 2) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(canMoveUp ? .secondary : .clear)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveUp)

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(canMoveDown ? .secondary : .clear)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveDown)
            }
            .frame(width: 16)

            // App picker
            Picker("", selection: Binding(
                get: { rule.appName ?? "__any__" },
                set: { rule.appName = $0 == "__any__" ? nil : $0 }
            )) {
                Text("Any app").tag("__any__")
                Divider()
                ForEach(installedApps) { app in
                    HStack(spacing: 6) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                        }
                        Text(app.name)
                    }
                    .tag(app.name)
                }
            }
            .labelsHidden()
            .frame(width: 140)

            // Domain field
            TextField("domain", text: Binding(
                get: { rule.urlPattern ?? "" },
                set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 120)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)

            // Browser picker
            Picker("", selection: $rule.browser) {
                ForEach(installedBrowsers) { browser in
                    HStack(spacing: 6) {
                        if let icon = browser.icon {
                            Image(nsImage: icon)
                        }
                        Text(browser.name)
                    }
                    .tag(browser.bundleId)
                }
            }
            .labelsHidden()
            .frame(width: 110)

            // Delete
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete rule")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(index % 2 == 0 ? Color.clear : Color(nsColor: .separatorColor).opacity(0.1))
    }
}

// MARK: - App Detection

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let bundleId: String
    let icon: NSImage?
}

enum AppDetector {
    static func detectAllApps() -> [AppInfo] {
        var apps: [AppInfo] = []
        let fileManager = FileManager.default
        let workspace = NSWorkspace.shared

        let appDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]

        for directory in appDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else {
                continue
            }

            for item in contents where item.hasSuffix(".app") {
                let appPath = (directory as NSString).appendingPathComponent(item)
                let appURL = URL(fileURLWithPath: appPath)

                guard let bundle = Bundle(url: appURL),
                      let bundleId = bundle.bundleIdentifier else {
                    continue
                }

                let name = bundle.infoDictionary?["CFBundleName"] as? String ??
                           bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                           (item as NSString).deletingPathExtension

                // Skip browsers
                let browserIds = ["com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
                                  "com.brave.Browser", "com.microsoft.edgemac", "company.thebrowser.Browser",
                                  "com.operasoftware.Opera", "com.vivaldi.Vivaldi"]
                if browserIds.contains(bundleId) { continue }

                // Skip system daemons
                if bundleId.hasPrefix("com.apple.") && name.hasPrefix("com.apple.") { continue }

                let icon = workspace.icon(forFile: appPath)
                icon.size = NSSize(width: 16, height: 16)
                apps.append(AppInfo(id: bundleId, name: name, bundleId: bundleId, icon: icon))
            }
        }

        var seen = Set<String>()
        return apps
            .filter { seen.insert($0.bundleId).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
}
