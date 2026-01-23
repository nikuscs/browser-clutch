import AppKit

enum BrowserLauncher {
    private static let log = Logger.shared

    static func launch(url: URL, withBrowser bundleId: String) {
        let workspace = NSWorkspace.shared

        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) else {
            log.warn("Browser '\(bundleId)' not found, using system default")
            workspace.open(url)
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        workspace.open([url], withApplicationAt: appURL, configuration: config) { _, error in
            if let error = error {
                log.error("Launch failed: \(error.localizedDescription)")
                workspace.open(url)
            }
        }
    }
}
