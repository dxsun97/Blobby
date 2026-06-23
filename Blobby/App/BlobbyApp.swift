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
        Button(appDelegate.settings.isEnabled ? "Disable Blobby" : "Enable Blobby") {
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

        Button("Settings...") {
            appDelegate.showSettingsPopup()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Check for Updates...") {
            appDelegate.checkForUpdates()
        }

        Divider()

        Button("Quit Blobby") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
