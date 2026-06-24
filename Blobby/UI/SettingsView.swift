import SwiftUI

// MARK: - Grouped card section (mimics System Settings style)

struct CardSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CardRow<Control: View>: View {
    let label: String
    let showDivider: Bool
    @ViewBuilder let control: () -> Control

    init(_ label: String, showDivider: Bool = true, @ViewBuilder control: @escaping () -> Control) {
        self.label = label
        self.showDivider = showDivider
        self.control = control
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label.localized)
                    .font(.body)
                Spacer(minLength: 12)
                control()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if showDivider {
                Divider().padding(.leading, 12)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var settings: BlobbySettings
    weak var appDelegate: AppDelegate?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(settings.blobColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Circle()
                        .fill(settings.blobColor)
                        .frame(width: 14, height: 14)
                }
                Text("Blobby")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .onChange(of: settings.isEnabled) { _, enabled in
                        if enabled { appDelegate?.activate() }
                        else { appDelegate?.deactivate() }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            // Cards
            VStack(spacing: 10) {
                appearanceCard
                behaviorCard
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // Footer
            HStack {
                Text("v\(UpdateChecker.currentVersion)")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .frame(width: 296)
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        CardSection {
            CardRow("settings.color") {
                ColorPicker("", selection: $settings.blobColor, supportsOpacity: false)
                    .labelsHidden()
                    .onAppear { configureColorPanel() }
                    .onChange(of: settings.blobColor) { _, _ in configureColorPanel() }
            }
            CardRow("settings.size") {
                Slider(value: $settings.blobSize, in: 20...100, step: 2)
                    .frame(width: 110)
                Text("\(Int(settings.blobSize))")
                    .font(.body)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            CardRow("settings.opacity", showDivider: false) {
                Slider(value: $settings.opacity, in: 0.2...1.0, step: 0.05)
                    .frame(width: 110)
                Text("\(Int(settings.opacity * 100))%")
                    .font(.body)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    // MARK: - Behavior Card

    private var behaviorCard: some View {
        CardSection {
            CardRow("settings.spring") {
                Picker("", selection: $settings.springMode) {
                    ForEach(SpringMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 156)
            }
            CardRow("settings.dotCursor", showDivider: settings.showDotCursor) {
                Toggle("", isOn: $settings.showDotCursor)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
            if settings.showDotCursor {
                CardRow("settings.dotColor") {
                    ColorPicker("", selection: $settings.dotColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: settings.dotColor) { _, _ in configureColorPanel() }
                }
                CardRow("settings.dotSize", showDivider: false) {
                    Slider(value: $settings.dotSize, in: 2...16, step: 1)
                        .frame(width: 110)
                    Text("\(Int(settings.dotSize))")
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    private func configureColorPanel() {
        DispatchQueue.main.async {
            let panel = NSColorPanel.shared
            panel.level = .floating
            panel.hidesOnDeactivate = false
        }
    }
}
