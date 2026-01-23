import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lastSourceApp: (name: String, bundleId: String)?
    private var appObserver: NSObjectProtocol?
    private var cachedConfig: RoutingConfig?
    private var ruleEngine: RuleEngine?

    private let log = Logger.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("BrowserClutch launched")

        ConfigManager.shared.ensureConfigDirectoryExists()
        reloadConfig()
        startTrackingActiveApp()
        registerURLHandler()
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
