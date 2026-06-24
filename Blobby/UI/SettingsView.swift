import AppKit
import SwiftUI

// MARK: - Grouped card section (mimics System Settings style)

private enum SettingsLayout {
    static let labelWidth: CGFloat = 96
    static let controlWidth: CGFloat = 156
    static let rowHeight: CGFloat = 34
    static let segmentedControlHeight: CGFloat = 24
}

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
            HStack(alignment: .center, spacing: 12) {
                Text(label.localized)
                    .font(.body)
                    .lineLimit(1)
                    .frame(width: SettingsLayout.labelWidth, alignment: .leading)
                control()
                    .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .frame(height: SettingsLayout.rowHeight)

            if showDivider {
                Divider().padding(.leading, 12)
            }
        }
    }
}

struct SliderValueControl<Value: BinaryFloatingPoint>: View where Value.Stride: BinaryFloatingPoint {
    @Binding var value: Value
    let range: ClosedRange<Value>
    let step: Value.Stride
    let format: (Value) -> String

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Slider(value: $value, in: range, step: step)
                .frame(width: 110)
            Text(format(value))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
    }
}

struct SpringModeControl: View {
    @Binding var mode: SpringMode

    var body: some View {
        NativeSpringModeSegmentedControl(mode: $mode)
        .frame(width: SettingsLayout.controlWidth, height: SettingsLayout.segmentedControlHeight)
    }
}

struct NativeSpringModeSegmentedControl: NSViewRepresentable {
    @Binding var mode: SpringMode

    func makeCoordinator() -> Coordinator {
        Coordinator(mode: $mode)
    }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(
            labels: SpringMode.allCases.map(\.displayName),
            trackingMode: .selectOne,
            target: context.coordinator,
            action: #selector(Coordinator.selectMode(_:))
        )
        control.segmentStyle = .rounded
        control.controlSize = .small
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .vertical)
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.mode = $mode

        let modes = SpringMode.allCases
        if control.segmentCount != modes.count {
            control.segmentCount = modes.count
        }

        for (index, springMode) in modes.enumerated() {
            control.setLabel(springMode.displayName, forSegment: index)
            control.setWidth(SettingsLayout.controlWidth / CGFloat(modes.count), forSegment: index)
        }

        control.selectedSegment = modes.firstIndex(of: mode) ?? 0
    }

    final class Coordinator: NSObject {
        var mode: Binding<SpringMode>

        init(mode: Binding<SpringMode>) {
            self.mode = mode
        }

        @objc func selectMode(_ sender: NSSegmentedControl) {
            guard sender.selectedSegment >= 0 else { return }
            mode.wrappedValue = SpringMode.allCases[sender.selectedSegment]
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
                SliderValueControl(value: $settings.blobSize, range: 20...100, step: 2) {
                    "\(Int($0))"
                }
            }
            CardRow("settings.opacity", showDivider: false) {
                SliderValueControl(value: $settings.opacity, range: 0.2...1.0, step: 0.05) {
                    "\(Int($0 * 100))%"
                }
            }
        }
    }

    // MARK: - Behavior Card

    private var behaviorCard: some View {
        CardSection {
            CardRow("settings.spring") {
                SpringModeControl(mode: $settings.springMode)
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
                    SliderValueControl(value: $settings.dotSize, range: 2...16, step: 1) {
                        "\(Int($0))"
                    }
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
