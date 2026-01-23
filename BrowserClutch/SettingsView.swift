import ServiceManagement
import SwiftUI

// MARK: - Window Accessor for Centered Title

struct WindowAccessor: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.title = title
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.styleMask.insert(.titled)
            window.toolbar = nil
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var defaultBrowser: String = ""
    @State private var rules: [RuleItem] = []
    @State private var statusMessage: String = ""
    @State private var isError: Bool = false
    @State private var installedBrowsers: [BrowserInfo] = []
    @State private var installedApps: [AppInfo] = []
    @State private var isDefaultBrowser: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var hideMenuBarIcon: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Warning banner if not default browser
            if !isDefaultBrowser {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Browser Clutch is not set as your default browser")
                        .font(.callout)
                    Spacer()
                    Button("Set as Default...") {
                        openDefaultBrowserSettings()
                    }
                    .buttonStyle(.link)
                    Button(action: checkDefaultBrowser) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // General options at top
                    HStack(spacing: 24) {
                        Toggle("Open at Login", isOn: $launchAtLogin)
                            .toggleStyle(.checkbox)
                            .onChange(of: launchAtLogin) { _, newValue in
                                setLaunchAtLogin(newValue)
                            }

                        Toggle("Hide Menu Bar Icon", isOn: $hideMenuBarIcon)
                            .toggleStyle(.checkbox)
                            .onChange(of: hideMenuBarIcon) { _, newValue in
                                setHideMenuBarIcon(newValue)
                            }

                        Spacer()
                    }

                    Divider()

                    // Default Browser Section
                    SettingsSection(title: "DEFAULT BROWSER") {
                        HStack(spacing: 12) {
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

                            Text("URLs that don't match any rule")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                    }

                    Divider()

                    // Rules Section
                    SettingsSection(title: "RULES", subtitle: "First match wins · evaluated top to bottom") {
                        if rules.isEmpty {
                            HStack {
                                Text("No rules configured")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(rules.enumerated()), id: \.element.id) { index, _ in
                                    RuleRow(
                                        rule: $rules[index],
                                        index: index,
                                        isLast: index == rules.count - 1,
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
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                        }

                        Button {
                            addRule()
                        } label: {
                            Label("Add Rule", systemImage: "plus")
                        }
                        .buttonStyle(.link)
                        .padding(.top, 8)
                    }

                    Divider()

                    // Config File Section
                    SettingsSection(title: "CONFIG") {
                        HStack(spacing: 12) {
                            Button {
                                NSWorkspace.shared.open(ConfigManager.shared.configDirectoryURL)
                            } label: {
                                Label("Open Config Folder", systemImage: "folder")
                            }

                            Spacer()

                            if !statusMessage.isEmpty {
                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundColor(isError ? .red : (statusMessage == "Saved" ? .green : .secondary))
                                    .lineLimit(1)
                            }

                            Button("Reload") {
                                loadConfig()
                            }

                            Button("Save") {
                                saveConfig()
                            }
                            .keyboardShortcut("s", modifiers: .command)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            Divider()

            // Quit Section
            HStack {
                Spacer()
                Button("Quit Browser Clutch") {
                    NSApp.terminate(nil)
                }
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(WindowAccessor(title: "Browser Clutch ®"))
        .frame(width: 540, height: 480)
        .onAppear {
            installedBrowsers = BrowserDetector.detectInstalledBrowsers()
            installedApps = AppDetector.detectAllApps()
            loadConfig()
            checkDefaultBrowser()
            loadLaunchAtLogin()
            loadHideMenuBarIcon()
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

        let path = ConfigManager.shared.configFileURL.path
            .replacingOccurrences(of: NSHomeDirectory(), with: "~")
        statusMessage = path
        isError = false
    }

    private func saveConfig() {
        // Validate
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

        // Check duplicates
        for i in 0..<rules.count {
            for j in (i + 1)..<rules.count {
                if rules[i].appName == rules[j].appName &&
                   rules[i].urlPattern == rules[j].urlPattern &&
                   rules[i].browser == rules[j].browser {
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

    private func checkDefaultBrowser() {
        guard let testURL = URL(string: "https://example.com"),
              let defaultBrowserURL = NSWorkspace.shared.urlForApplication(toOpen: testURL),
              let bundle = Bundle(url: defaultBrowserURL),
              let bundleId = bundle.bundleIdentifier else {
            isDefaultBrowser = false
            return
        }
        isDefaultBrowser = bundleId == Bundle.main.bundleIdentifier
    }

    private func openDefaultBrowserSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func loadLaunchAtLogin() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert the toggle if it failed
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func loadHideMenuBarIcon() {
        hideMenuBarIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
    }

    private func setHideMenuBarIcon(_ hidden: Bool) {
        UserDefaults.standard.set(hidden, forKey: "hideMenuBarIcon")
        NotificationCenter.default.post(name: .menuBarIconVisibilityChanged, object: nil)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            content()
        }
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
    let isLast: Bool
    let installedApps: [AppInfo]
    let installedBrowsers: [BrowserInfo]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Move buttons
                VStack(spacing: 0) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 16, height: 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(canMoveUp ? .secondary : .clear)
                    .disabled(!canMoveUp)

                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 16, height: 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(canMoveDown ? .secondary : .clear)
                    .disabled(!canMoveDown)
                }

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
                .frame(width: 130)

                // Domain
                TextField("any domain", text: Binding(
                    get: { rule.urlPattern ?? "" },
                    set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))

                // Browser
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
                .frame(width: 100)

                Spacer()

                // Delete
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            if !isLast {
                Divider()
                    .padding(.leading, 34)
            }
        }
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
    private static var cachedApps: [AppInfo]?
    private static var cacheTime: Date?
    private static let cacheDuration: TimeInterval = 60 // Cache for 60 seconds

    static func detectAllApps() -> [AppInfo] {
        // Return cached results if available and fresh
        if let cached = cachedApps,
           let time = cacheTime,
           Date().timeIntervalSince(time) < cacheDuration {
            return cached
        }

        var apps: [AppInfo] = []
        let fileManager = FileManager.default
        let workspace = NSWorkspace.shared

        let appDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]

        let browserIds: Set<String> = [
            "com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
            "com.brave.Browser", "com.microsoft.edgemac", "company.thebrowser.Browser",
            "com.operasoftware.Opera", "com.vivaldi.Vivaldi"
        ]

        for directory in appDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let appPath = (directory as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(url: URL(fileURLWithPath: appPath)),
                      let bundleId = bundle.bundleIdentifier else { continue }

                // Skip browsers
                if browserIds.contains(bundleId) { continue }

                let name = bundle.infoDictionary?["CFBundleName"] as? String ??
                           bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                           (item as NSString).deletingPathExtension

                if bundleId.hasPrefix("com.apple.") && name.hasPrefix("com.apple.") { continue }

                let icon = workspace.icon(forFile: appPath)
                icon.size = NSSize(width: 16, height: 16)
                apps.append(AppInfo(id: bundleId, name: name, bundleId: bundleId, icon: icon))
            }
        }

        var seen = Set<String>()
        let result = apps
            .filter { seen.insert($0.bundleId).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Cache the results
        cachedApps = result
        cacheTime = Date()

        return result
    }
}

// MARK: - Notification

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
    static let menuBarIconVisibilityChanged = Notification.Name("menuBarIconVisibilityChanged")
}
