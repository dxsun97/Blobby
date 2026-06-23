import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var overlayWindows: [OverlayWindow] = []
    private var blobViews: [BlobOverlayView] = []
    private let cursorTracker = CursorTracker()
    let cursorHider = CursorHider()
    private let springRef = SpringRef()
    let settings = BlobbySettings()
    private var panelCheckTimer: Timer?
    private var settingsWindow: NSPanel?

    var menuBarIcon: NSImage {
        renderMenuBarIcon(isEnabled: settings.isEnabled)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.checkPanelState()
        }
        RunLoop.main.add(t, forMode: .common)
        panelCheckTimer = t

        if AXIsProcessTrusted() {
            onAccessibilityGranted()
        } else {
            checkAccessibility()
        }

        autoCheckForUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelCheckTimer?.invalidate()
        deactivate()
        cursorTracker.stop()
    }

    // MARK: - Check for Updates

    func checkForUpdates(silent: Bool = false) {
        Task {
            let result = await UpdateChecker.check()
            await MainActor.run {
                switch result {
                case .available(let version, _, let dmgURL):
                    let alert = NSAlert()
                    alert.messageText = "Update Available"
                    alert.informativeText = "Blobby v\(version) is available. You're currently on v\(UpdateChecker.currentVersion).\n\nInstall now? The app will restart automatically."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Install Update")
                    alert.addButton(withTitle: "Later")
                    if alert.runModal() == .alertFirstButtonReturn {
                        performUpdate(dmgURL: dmgURL, version: version)
                    }
                case .upToDate(let version):
                    if !silent {
                        let alert = NSAlert()
                        alert.messageText = "You're Up to Date"
                        alert.informativeText = "Blobby v\(version) is the latest version."
                        alert.alertStyle = .informational
                        alert.runModal()
                    }
                case .error(let message):
                    if !silent {
                        let alert = NSAlert()
                        alert.messageText = "Update Check Failed"
                        alert.informativeText = message
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            }
        }
    }

    private func performUpdate(dmgURL: URL, version: String) {
        let alert = NSAlert()
        alert.messageText = "Downloading Update..."
        alert.informativeText = "Downloading Blobby v\(version)..."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Cancel")
        let indicator = NSProgressIndicator()
        indicator.style = .bar
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.frame = NSRect(x: 0, y: 0, width: 250, height: 20)
        alert.accessoryView = indicator

        let window = alert.window
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
        }

        Task {
            let result = await UpdateChecker.downloadAndInstall(dmgURL: dmgURL) { progress in
                DispatchQueue.main.async {
                    indicator.doubleValue = progress
                    alert.informativeText = "Downloading... \(Int(progress * 100))%"
                }
            }

            await MainActor.run {
                window.close()

                switch result {
                case .success:
                    let done = NSAlert()
                    done.messageText = "Update Installed"
                    done.informativeText = "Blobby v\(version) has been installed. The app will restart now."
                    done.alertStyle = .informational
                    done.addButton(withTitle: "Restart")
                    done.runModal()
                    deactivate()
                    UpdateChecker.relaunch()
                case .failure(let error):
                    let fail = NSAlert()
                    fail.messageText = "Update Failed"
                    switch error {
                    case .failed(let msg): fail.informativeText = msg
                    }
                    fail.alertStyle = .critical
                    fail.runModal()
                }
            }
        }
    }

    private func autoCheckForUpdates() {
        let lastCheck = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        let now = Date().timeIntervalSince1970
        let oneDay: TimeInterval = 86400
        guard now - lastCheck > oneDay else { return }
        UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        checkForUpdates(silent: true)
    }

    // MARK: - Settings Popup

    func showSettingsPopup() {
        DispatchQueue.main.async { [self] in
            if let existing = settingsWindow, existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let contentView = SettingsView(settings: settings, appDelegate: self)
            let hosting = NSHostingController(rootView: contentView)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 440),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Blobby"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.contentViewController = hosting
            window.hasShadow = true
            window.isOpaque = false
            window.backgroundColor = .windowBackgroundColor
            window.animationBehavior = .default
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.center()

            settingsWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Menu Bar Icon

    private func renderMenuBarIcon(isEnabled: Bool) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let cx = rect.midX + 0.5
            let cy = rect.midY
            let r: CGFloat = 6.0
            let tailX: CGFloat = cx + r * 1.5
            let topY = cy + r * 0.85
            let bottomY = cy - r * 0.85

            let path = NSBezierPath()
            path.move(to: NSPoint(x: cx - r, y: cy))
            path.curve(to: NSPoint(x: cx, y: topY),
                       controlPoint1: NSPoint(x: cx - r, y: cy + r * 0.55),
                       controlPoint2: NSPoint(x: cx - r * 0.55, y: topY))
            path.curve(to: NSPoint(x: tailX, y: cy),
                       controlPoint1: NSPoint(x: cx + r * 0.5, y: topY),
                       controlPoint2: NSPoint(x: tailX, y: cy + r * 0.15))
            path.curve(to: NSPoint(x: cx, y: bottomY),
                       controlPoint1: NSPoint(x: tailX, y: cy - r * 0.15),
                       controlPoint2: NSPoint(x: cx + r * 0.5, y: bottomY))
            path.curve(to: NSPoint(x: cx - r, y: cy),
                       controlPoint1: NSPoint(x: cx - r * 0.55, y: bottomY),
                       controlPoint2: NSPoint(x: cx - r, y: cy - r * 0.55))
            path.close()

            (isEnabled ? NSColor.black : NSColor.black.withAlphaComponent(0.35)).setFill()
            path.fill()

            if isEnabled {
                let dotR: CGFloat = 1.5
                NSColor.white.setFill()
                NSBezierPath(ovalIn: NSRect(x: cx - r * 0.5 - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Blob Overlay

    func activate() {
        cursorHider.hide()
        blobViews.forEach { $0.startRendering() }
        overlayWindows.forEach { $0.orderFrontRegardless() }
    }

    func deactivate() {
        cursorHider.unhide()
        blobViews.forEach { $0.stopRendering() }
        overlayWindows.forEach { $0.orderOut(nil) }
    }

    private func checkPanelState() {
        guard settings.isEnabled else { return }
        let panelOpen = settingsWindow?.isVisible ?? false
        if panelOpen {
            cursorHider.pause()
        } else {
            cursorHider.resume()
        }
    }

    private func setupOverlays() {
        teardownOverlays()
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            let view = BlobOverlayView(
                tracker: cursorTracker,
                settings: settings,
                springRef: springRef,
                frame: NSRect(origin: .zero, size: screen.frame.size)
            )
            window.contentView = view
            overlayWindows.append(window)
            blobViews.append(view)
        }
    }

    private func teardownOverlays() {
        blobViews.forEach { $0.stopRendering() }
        overlayWindows.forEach { $0.close() }
        overlayWindows.removeAll()
        blobViews.removeAll()
    }

    @objc private func screensChanged() {
        let wasActive = settings.isEnabled
        if wasActive { deactivate() }
        setupOverlays()
        if wasActive { activate() }
    }

    private func checkAccessibility() {
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            waitForAccessibility()
        }
    }

    private func waitForAccessibility() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.onAccessibilityGranted()
            }
        }
        RunLoop.main.add(t, forMode: .common)
    }

    private func onAccessibilityGranted() {
        cursorTracker.start()
        setupOverlays()
        if settings.isEnabled {
            activate()
        }
    }
}
