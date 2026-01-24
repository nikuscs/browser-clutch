import ServiceManagement
import SwiftUI

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

struct SettingsView: View {
    @State private var defaultBrowser = ""
    @State private var rules: [RuleItem] = []
    @State private var status = ""
    @State private var hasError = false
    @State private var browsers: [BrowserInfo] = []
    @State private var apps: [AppInfo] = []
    @State private var isDefault = true
    @State private var launchAtLogin = false
    @State private var hideIcon = false
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            warningBanner
            scrollContent
            Divider()
            quitSection
        }
        .background(WindowAccessor(title: "Browser Clutch"))
        .frame(width: 540, height: 520)
        .onAppear(perform: load)
        .onChange(of: defaultBrowser) { _, _ in autosave() }
        .onChange(of: rules) { _, _ in autosave() }
    }

    @ViewBuilder
    private var warningBanner: some View {
        if !isDefault {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Browser Clutch is not set as your default browser")
                    .font(.callout)
                Spacer()
                Button("Set as Default...") {
                    DefaultBrowser.openSettings()
                }
                .buttonStyle(.link)
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
        }
    }

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                optionsRow
                Divider()
                defaultBrowserSection
                Divider()
                rulesSection
                Divider()
                configSection
                Divider()
                statusSection
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private var optionsRow: some View {
        HStack(spacing: 24) {
            Toggle("Open at Login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .onChange(of: launchAtLogin) { _, value in
                    setLaunchAtLogin(value)
                }

            Toggle("Hide Menu Bar Icon", isOn: $hideIcon)
                .toggleStyle(.checkbox)
                .onChange(of: hideIcon) { _, value in
                    setHideIcon(value)
                }

            Spacer()
        }
    }

    private var defaultBrowserSection: some View {
        Section(title: "DEFAULT BROWSER") {
            HStack(spacing: 12) {
                Picker("", selection: $defaultBrowser) {
                    ForEach(browsers) { browser in
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
    }

    private var rulesSection: some View {
        Section(title: "RULES", subtitle: "First match wins") {
            if rules.isEmpty {
                emptyRulesPlaceholder
            } else {
                rulesList
            }

            Button {
                rules.append(RuleItem(appName: nil, urlPattern: nil, browser: defaultBrowser))
            } label: {
                Label("Add Rule", systemImage: "plus.circle.fill")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .padding(.top, 4)
        }
    }

    private var emptyRulesPlaceholder: some View {
        HStack {
            Text("No rules configured")
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }

    private var rulesList: some View {
        VStack(spacing: 6) {
            ForEach(Array(rules.enumerated()), id: \.element.id) { index, _ in
                RuleRow(
                    rule: $rules[index],
                    apps: apps,
                    browsers: browsers,
                    canMoveUp: index > 0,
                    canMoveDown: index < rules.count - 1,
                    onMoveUp: { move(index, by: -1) },
                    onMoveDown: { move(index, by: 1) },
                    onDelete: { rules.remove(at: index) }
                )
            }
        }
    }

    private var configSection: some View {
        Section(title: "CONFIG") {
            HStack(spacing: 12) {
                Button {
                    NSWorkspace.shared.open(ConfigManager.shared.configDirectoryURL)
                } label: {
                    Label("Open Config Folder", systemImage: "folder")
                }

                Spacer()

                if !status.isEmpty {
                    HStack(spacing: 4) {
                        if status == "Saved" {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                        Text(status)
                            .font(.caption)
                            .foregroundColor(hasError ? .red : (status == "Saved" ? .green : .secondary))
                            .lineLimit(1)
                    }
                }

                Button("Reload", action: reload)
            }
        }
    }

    private var statusSection: some View {
        Section(title: "STATUS") {
            HStack(spacing: 8) {
                if isDefault {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Browser Clutch is your default browser")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Not set as default browser")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open Settings...") {
                        DefaultBrowser.openSettings()
                    }
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var quitSection: some View {
        HStack {
            Spacer()
            Button("Quit Browser Clutch") {
                NSApp.terminate(nil)
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private func load() {
        browsers = BrowserDetector.detect()
        apps = AppDetector.detect()
        reload()
        refresh()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        hideIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isLoading = false
        }
    }

    private func reload() {
        let config = ConfigManager.shared.load()
        defaultBrowser = config.defaultBrowser

        rules = config.rules.map { rule in
            RuleItem(
                appName: rule.source?.name,
                urlPattern: rule.domain?.pattern ?? rule.domain?.contains,
                browser: rule.browser,
                isPrivate: rule.private ?? false,
                newWindow: rule.newWindow ?? false
            )
        }

        status = ""
        hasError = false
    }

    private func autosave() {
        guard !isLoading else { return }
        save()
    }

    private func save() {
        for (i, rule) in rules.enumerated() {
            if rule.appName == nil && (rule.urlPattern ?? "").isEmpty {
                status = "Rule \(i + 1): needs app or domain"
                hasError = true
                return
            }
            if rule.browser.isEmpty {
                status = "Rule \(i + 1): needs browser"
                hasError = true
                return
            }
        }

        for i in 0..<rules.count {
            for j in (i + 1)..<rules.count {
                if rules[i].appName == rules[j].appName &&
                   rules[i].urlPattern == rules[j].urlPattern &&
                   rules[i].browser == rules[j].browser {
                    status = "Rules \(i + 1) & \(j + 1) are duplicates"
                    hasError = true
                    return
                }
            }
        }

        let configRules: [Rule] = rules.enumerated().map { i, rule in
            Rule(
                id: "rule-\(i + 1)",
                priority: rules.count - i,
                source: rule.appName.map { SourceMatch(name: $0) },
                domain: (rule.urlPattern?.isEmpty == false) ? DomainMatch(pattern: rule.urlPattern) : nil,
                browser: rule.browser,
                private: rule.isPrivate ? true : nil,
                newWindow: rule.newWindow ? true : nil
            )
        }

        let config = RoutingConfig(defaultBrowser: defaultBrowser, rules: configRules)

        do {
            try ConfigManager.shared.save(config)
            status = "Saved"
            hasError = false
            NotificationCenter.default.post(name: .configDidChange, object: nil)
        } catch {
            status = "Error: \(error.localizedDescription)"
            hasError = true
        }
    }

    private func move(_ index: Int, by offset: Int) {
        let newIndex = index + offset
        guard newIndex >= 0 && newIndex < rules.count else { return }
        rules.swapAt(index, newIndex)
    }

    private func refresh() {
        isDefault = DefaultBrowser.isSet
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setHideIcon(_ hidden: Bool) {
        UserDefaults.standard.set(hidden, forKey: "hideMenuBarIcon")
        NotificationCenter.default.post(name: .menuBarIconDidChange, object: nil)
    }
}

private struct Section<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            content()
        }
    }
}

struct RuleItem: Identifiable, Equatable {
    let id = UUID()
    var appName: String?
    var urlPattern: String?
    var browser: String
    var isPrivate: Bool = false
    var newWindow: Bool = false

    static func == (lhs: RuleItem, rhs: RuleItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.appName == rhs.appName &&
        lhs.urlPattern == rhs.urlPattern &&
        lhs.browser == rhs.browser &&
        lhs.isPrivate == rhs.isPrivate &&
        lhs.newWindow == rhs.newWindow
    }
}

struct RuleRow: View {
    @Binding var rule: RuleItem
    let apps: [AppInfo]
    let browsers: [BrowserInfo]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            reorderButtons
            appPicker
            patternField
            arrow
            browserPicker
            optionButtons
            Spacer()
            deleteButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var optionButtons: some View {
        HStack(spacing: 4) {
            Button {
                rule.isPrivate.toggle()
            } label: {
                Image(systemName: rule.isPrivate ? "eye.slash.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(rule.isPrivate ? .purple : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Private/Incognito mode")

            Button {
                rule.newWindow.toggle()
            } label: {
                Image(systemName: rule.newWindow ? "macwindow.badge.plus" : "macwindow")
                    .font(.system(size: 11))
                    .foregroundColor(rule.newWindow ? .blue : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Open in new window")
        }
    }

    private var reorderButtons: some View {
        VStack(spacing: 2) {
            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveUp ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveDown ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveDown)
        }
    }

    private var appPicker: some View {
        Picker("", selection: Binding(
            get: { rule.appName ?? "__any__" },
            set: { rule.appName = $0 == "__any__" ? nil : $0 }
        )) {
            Text("Any app").tag("__any__")
            Divider()
            ForEach(apps) { app in
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
        .frame(width: 110)
    }

    private var patternField: some View {
        TextField("*", text: Binding(
            get: { rule.urlPattern ?? "" },
            set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(.roundedBorder)
        .frame(width: 100)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary.opacity(0.4))
    }

    private var browserPicker: some View {
        Picker("", selection: $rule.browser) {
            ForEach(browsers) { browser in
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
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(0.5)
    }
}
