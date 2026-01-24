import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lastSourceApp: (name: String, bundleId: String)?
    private var appObserver: NSObjectProtocol?
    private var configObserver: NSObjectProtocol?
    private var menuBarObserver: NSObjectProtocol?
    private var config: RoutingConfig?
    private var engine: RuleEngine?

    private let log = Logger.shared

    var hideMenuBarIcon: Bool {
        UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("BrowserClutch launched")

        ConfigManager.shared.ensureConfigDirectoryExists()
        reload()
        trackActiveApp()
        registerURLHandler()
        observeConfig()
        observeMenuBar()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if hideMenuBarIcon {
            UserDefaults.standard.set(false, forKey: "hideMenuBarIcon")
            NotificationCenter.default.post(name: .menuBarIconDidChange, object: nil)
        }
        return true
    }

    private func observeConfig() {
        configObserver = NotificationCenter.default.addObserver(
            forName: .configDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log.info("Config changed, reloading...")
            self?.reload()
        }
    }

    private func observeMenuBar() {
        menuBarObserver = NotificationCenter.default.addObserver(
            forName: .menuBarIconDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log.info("Menu bar icon changed")
        }
    }

    private func reload() {
        config = ConfigManager.shared.load()
        engine = RuleEngine(config: config!)
        log.debug("Config loaded: \(config!.rules.count) rules")
    }

    private func trackActiveApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let name = frontApp.localizedName,
           let bundleId = frontApp.bundleIdentifier,
           bundleId != Bundle.main.bundleIdentifier {
            lastSourceApp = (name, bundleId)
        }

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
        route(url)
    }

    private func route(_ url: URL) {
        guard let engine = engine else {
            log.error("RuleEngine not initialized")
            return
        }

        let options = engine.find(forURL: url, sourceApp: lastSourceApp)

        var flags: [String] = []
        if options.private { flags.append("private") }
        if options.newWindow { flags.append("new-window") }
        let flagsStr = flags.isEmpty ? "" : " [\(flags.joined(separator: ", "))]"

        if let source = lastSourceApp {
            log.info("[\(source.name)] \(url) → \(options.browser)\(flagsStr)")
        } else {
            log.info("[unknown] \(url) → \(options.browser)\(flagsStr)")
        }

        BrowserLauncher.launch(url: url, options: options)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
