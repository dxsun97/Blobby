import SwiftUI

@main
struct BlobbyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(appDelegate: appDelegate)
        } label: {
            Image(nsImage: appDelegate.menuBarIcon)
        }
    }
}

struct MenuBarMenu: View {
    let appDelegate: AppDelegate

    var body: some View {
        Button(toggleTitle) {
            if appDelegate.settings.isEnabled {
                appDelegate.settings.isEnabled = false
                appDelegate.deactivate()
            } else {
                appDelegate.settings.isEnabled = true
                appDelegate.activate()
            }
        }
        .keyboardShortcut("b", modifiers: [.command, .shift])

        Divider()

        Button("menu.settings") {
            appDelegate.showSettingsPopup()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("menu.checkUpdates") {
            appDelegate.checkForUpdates()
        }

        Divider()

        Button("menu.quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var toggleTitle: LocalizedStringKey {
        appDelegate.settings.isEnabled ? "menu.disable" : "menu.enable"
    }
}
