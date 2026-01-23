import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lastSourceApp: (name: String, bundleId: String)?
    private var appObserver: NSObjectProtocol?
    private var configObserver: NSObjectProtocol?
    private var menuBarObserver: NSObjectProtocol?
    private var cachedConfig: RoutingConfig?
    private var ruleEngine: RuleEngine?

    private let log = Logger.shared

    var hideMenuBarIcon: Bool {
        UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("BrowserClutch launched")

        ConfigManager.shared.ensureConfigDirectoryExists()
        reloadConfig()
        startTrackingActiveApp()
        registerURLHandler()
        observeConfigChanges()
        observeMenuBarIconVisibility()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When menu bar icon is hidden and user clicks app icon, open settings
        if hideMenuBarIcon {
            openSettings()
        }
        return true
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // Try multiple selectors for opening settings (varies by macOS version)
        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) { return }
        if NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) { return }
        // Last resort: try to find and click the menu item
        if let appMenu = NSApp.mainMenu?.items.first?.submenu {
            for item in appMenu.items {
                if item.title.contains("Settings") || item.title.contains("Preferences") {
                    _ = item.target?.perform(item.action, with: item)
                    return
                }
            }
        }
    }

    private func observeConfigChanges() {
        configObserver = NotificationCenter.default.addObserver(
            forName: .configDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log.info("Config changed, reloading...")
            self?.reloadConfig()
        }
    }

    private func observeMenuBarIconVisibility() {
        menuBarObserver = NotificationCenter.default.addObserver(
            forName: .menuBarIconVisibilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log.info("Menu bar icon visibility changed")
            // The SwiftUI MenuBarExtra will handle this via @AppStorage
        }
    }

    // MARK: - Config

    private func reloadConfig() {
        cachedConfig = ConfigManager.shared.loadConfig()
        ruleEngine = RuleEngine(config: cachedConfig!)
        log.debug("Config loaded: \(cachedConfig!.rules.count) rules")
    }

    // MARK: - App Tracking

    private func startTrackingActiveApp() {
        // Initialize with current frontmost app
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let name = frontApp.localizedName,
           let bundleId = frontApp.bundleIdentifier,
           bundleId != Bundle.main.bundleIdentifier {
            lastSourceApp = (name, bundleId)
        }

        // Track app activations
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              bundleId != Bundle.main.bundleIdentifier,
              let name = app.localizedName else {
            return
        }
        lastSourceApp = (name, bundleId)
        log.debug("Active app: \(name)")
    }

    // MARK: - URL Handling

    private func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            log.error("Failed to parse URL from event")
            return
        }
        routeURL(url)
    }

    private func routeURL(_ url: URL) {
        guard let engine = ruleEngine else {
            log.error("RuleEngine not initialized")
            return
        }

        let browserBundleId = engine.findBrowser(forURL: url, sourceApp: lastSourceApp)

        if let source = lastSourceApp {
            log.info("[\(source.name)] \(url) → \(browserBundleId)")
        } else {
            log.info("[unknown] \(url) → \(browserBundleId)")
        }

        BrowserLauncher.launch(url: url, withBrowser: browserBundleId)
    }

    // MARK: - App Lifecycle

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
