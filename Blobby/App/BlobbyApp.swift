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
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        Button {
            if appDelegate.settings.isEnabled {
                appDelegate.settings.isEnabled = false
                appDelegate.deactivate()
            } else {
                appDelegate.settings.isEnabled = true
                appDelegate.activate()
            }
        } label: {
            Text(toggleTitle)
        }
        .keyboardShortcut("b", modifiers: [.command, .shift])

        Divider()

        Button {
            appDelegate.showSettingsPopup()
        } label: {
            Text("menu.settings".localized)
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            appDelegate.checkForUpdates()
        } label: {
            Text("menu.checkUpdates".localized)
        }
        .disabled(appDelegate.isCheckingForUpdates)

        Button {
            appDelegate.showAccessibilityRepairHelp()
        } label: {
            Text("menu.fixAccessibility".localized)
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("menu.quit".localized)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var toggleTitle: String {
        appDelegate.settings.isEnabled ? "menu.disable".localized : "menu.enable".localized
    }
}
