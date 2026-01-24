import AppKit

enum BrowserLauncher {
    private static let log = Logger.shared

    private static let browserArgs: [String: (private: String?, newWindow: String?)] = [
        "com.google.Chrome": ("--incognito", "--new-window"),
        "com.google.Chrome.canary": ("--incognito", "--new-window"),
        "com.brave.Browser": ("--incognito", "--new-window"),
        "com.microsoft.edgemac": ("--inprivate", "--new-window"),
        "org.mozilla.firefox": ("-private-window", "-new-window"),
        "org.mozilla.firefoxdeveloperedition": ("-private-window", "-new-window"),
        "company.thebrowser.Browser": ("--incognito", "--new-window"),
        "com.vivaldi.Vivaldi": ("--incognito", "--new-window"),
        "com.operasoftware.Opera": ("--private", "--new-window")
    ]

    static func launch(url: URL, options: LaunchOptions) {
        let workspace = NSWorkspace.shared

        guard let appURL = workspace.urlForApplication(withBundleIdentifier: options.browser) else {
            log.warn("Browser '\(options.browser)' not found, using system default")
            workspace.open(url)
            return
        }

        if options.browser == "com.apple.Safari" && options.private {
            launchSafariPrivate(url: url)
            return
        }

        var args: [String] = []
        if let browserConfig = browserArgs[options.browser] {
            if options.private, let privateArg = browserConfig.private {
                args.append(privateArg)
            }
            if options.newWindow, let newWindowArg = browserConfig.newWindow {
                args.append(newWindowArg)
            }
        }
        args.append(url.absoluteString)

        if args.count > 1 {
            launchWithArgs(appURL: appURL, args: args)
        } else {
            let config = NSWorkspace.OpenConfiguration()
            workspace.open([url], withApplicationAt: appURL, configuration: config) { _, error in
                if let error = error {
                    log.error("Launch failed: \(error.localizedDescription)")
                    workspace.open(url)
                }
            }
        }
    }

    private static func launchWithArgs(appURL: URL, args: [String]) {
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = args

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if let error = error {
                log.error("Launch with args failed: \(error.localizedDescription)")
            }
        }
    }

    private static func launchSafariPrivate(url: URL) {
        let script = """
            tell application "Safari"
                activate
                tell application "System Events"
                    keystroke "n" using {command down, shift down}
                end tell
                delay 0.5
                set URL of front document to "\(url.absoluteString)"
            end tell
            """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                log.error("Safari private mode failed: \(error)")
                NSWorkspace.shared.open(url)
            }
        }
    }
}
