import SwiftUI

@main
struct BrowserClutchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hideMenuBarIcon") private var hideMenuBarIcon = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("BrowserClutch", image: "MenuBarIcon", isInserted: Binding(
            get: { !hideMenuBarIcon },
            set: { hideMenuBarIcon = !$0 }
        )) {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Browser Clutch") {
                    openWindow(id: "about")
                }
            }
        }

        Window("About Browser Clutch", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
