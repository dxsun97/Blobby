import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var overlayWindows: [OverlayWindow] = []
    private var blobViews: [BlobOverlayView] = []
    private let cursorTracker = CursorTracker()
    private let springRef = SpringRef()
    let settings = BlobbySettings()
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

        if AXIsProcessTrusted() {
            onAccessibilityGranted()
        } else {
            checkAccessibility()
        }

        autoCheckForUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
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
                    alert.messageText = L10n.text("updates.available.title")
                    alert.informativeText = L10n.text("updates.available.message", version, UpdateChecker.currentVersion)
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: L10n.text("updates.install"))
                    alert.addButton(withTitle: L10n.text("updates.later"))
                    if alert.runModal() == .alertFirstButtonReturn {
                        performUpdate(dmgURL: dmgURL, version: version)
                    }
                case .upToDate(let version):
                    if !silent {
                        let alert = NSAlert()
                        alert.messageText = L10n.text("updates.upToDate.title")
                        alert.informativeText = L10n.text("updates.upToDate.message", version)
                        alert.alertStyle = .informational
                        alert.runModal()
                    }
                case .error(let message):
                    if !silent {
                        let alert = NSAlert()
                        alert.messageText = L10n.text("updates.checkFailed.title")
                        alert.informativeText = message
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            }
        }
    }

    private func performUpdate(dmgURL: URL, version: String) {
        let progressWindow = makeUpdateProgressWindow(version: version)
        let indicator = progressWindow.indicator
        let progressLabel = progressWindow.progressLabel
        let window = progressWindow.window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        Task {
            let result = await UpdateChecker.downloadAndInstall(dmgURL: dmgURL) { progress in
                DispatchQueue.main.async {
                    indicator.doubleValue = progress
                    progressLabel.stringValue = L10n.text("updates.downloading.progress", Int(progress * 100))
                }
            }

            await MainActor.run {
                window.close()

                switch result {
                case .success:
                    let done = NSAlert()
                    done.messageText = L10n.text("updates.installed.title")
                    done.informativeText = L10n.text("updates.installed.message", version)
                    done.alertStyle = .informational
                    done.addButton(withTitle: L10n.text("updates.restart"))
                    done.runModal()
                    deactivate()
                    UpdateChecker.relaunch()
                case .failure(let error):
                    let fail = NSAlert()
                    fail.messageText = L10n.text("updates.failed.title")
                    switch error {
                    case .failed(let msg): fail.informativeText = msg
                    }
                    fail.alertStyle = .critical
                    fail.runModal()
                }
            }
        }
    }

    private func makeUpdateProgressWindow(version: String) -> (window: NSPanel, indicator: NSProgressIndicator, progressLabel: NSTextField) {
        let indicator = NSProgressIndicator()
        indicator.style = .bar
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: L10n.text("updates.downloading.title"))
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = NSTextField(labelWithString: L10n.text("updates.downloading.message", version))
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let progressLabel = NSTextField(labelWithString: L10n.text("updates.downloading.progress", 0))
        progressLabel.textColor = .secondaryLabelColor
        progressLabel.alignment = .right
        progressLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(indicator)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),

            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            indicator.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            indicator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),

            progressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressLabel.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 8),
            progressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
        ])

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 132),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("updates.downloading.title")
        window.contentView = contentView
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()

        return (window, indicator, progressLabel)
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

    private func closeSettingsPopup() {
        settingsWindow?.close()
        settingsWindow = nil
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
        blobViews.forEach { $0.startRendering() }
        overlayWindows.forEach { $0.orderFrontRegardless() }
    }

    func deactivate() {
        blobViews.forEach { $0.stopRendering() }
        overlayWindows.forEach { $0.orderOut(nil) }
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

    func showAccessibilityRepairHelp() {
        closeSettingsPopup()

        let alert = NSAlert()
        alert.messageText = L10n.text("accessibility.repair.title")
        alert.informativeText = L10n.text("accessibility.repair.message")
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.text("accessibility.openSettings"))
        alert.addButton(withTitle: L10n.text("common.cancel"))

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        if !NSWorkspace.shared.open(settingsURL),
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
            NSWorkspace.shared.open(appURL)
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
        springRef.reset(to: cursorTracker.mousePosition)
        setupOverlays()
        if settings.isEnabled {
            activate()
        }
    }
}
