import AppKit

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

struct AppInfo: Identifiable {
    let id: String
    let bundleId: String
    let name: String
    let icon: NSImage?
}

enum BrowserDetector {
    static let known: [(bundleId: String, name: String)] = [
        ("com.apple.Safari", "Safari"),
        ("com.google.Chrome", "Chrome"),
        ("org.mozilla.firefox", "Firefox"),
        ("com.brave.Browser", "Brave"),
        ("com.microsoft.edgemac", "Edge"),
        ("company.thebrowser.Browser", "Arc"),
        ("com.operasoftware.Opera", "Opera"),
        ("com.vivaldi.Vivaldi", "Vivaldi")
    ]

    private static var cache: (browsers: [BrowserInfo], time: Date)?
    private static let cacheTTL: TimeInterval = 30

    static func detect() -> [BrowserInfo] {
        if let cache, Date().timeIntervalSince(cache.time) < cacheTTL {
            return cache.browsers
        }

        let workspace = NSWorkspace.shared
        var browsers: [BrowserInfo] = []

        for (bundleId, name) in known {
            guard let url = workspace.urlForApplication(withBundleIdentifier: bundleId) else { continue }
            let icon = workspace.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            browsers.append(BrowserInfo(bundleId: bundleId, name: name, icon: icon))
        }

        cache = (browsers, Date())
        return browsers
    }

    static var bundleIds: Set<String> {
        Set(known.map(\.bundleId))
    }
}

enum AppDetector {
    private static var cache: (apps: [AppInfo], time: Date)?
    private static let cacheTTL: TimeInterval = 60

    private static let directories = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications"
    ]

    static func detect() -> [AppInfo] {
        if let cache, Date().timeIntervalSince(cache.time) < cacheTTL {
            return cache.apps
        }

        var apps: [AppInfo] = []
        let fileManager = FileManager.default
        let workspace = NSWorkspace.shared

        for directory in directories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let path = (directory as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(url: URL(fileURLWithPath: path)),
                      let bundleId = bundle.bundleIdentifier,
                      !BrowserDetector.bundleIds.contains(bundleId) else { continue }

                let name = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? (item as NSString).deletingPathExtension

                if bundleId.hasPrefix("com.apple.") && name.hasPrefix("com.apple.") { continue }

                let icon = workspace.icon(forFile: path)
                icon.size = NSSize(width: 16, height: 16)
                apps.append(AppInfo(id: bundleId, bundleId: bundleId, name: name, icon: icon))
            }
        }

        var seen = Set<String>()
        let result = apps
            .filter { seen.insert($0.bundleId).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        cache = (result, Date())
        return result
    }
}

enum DefaultBrowser {
    static var isSet: Bool {
        guard let testURL = URL(string: "https://example.com"),
              let browserURL = NSWorkspace.shared.urlForApplication(toOpen: testURL),
              let bundle = Bundle(url: browserURL),
              let bundleId = bundle.bundleIdentifier else {
            return false
        }
        return bundleId == Bundle.main.bundleIdentifier
    }

    static func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
