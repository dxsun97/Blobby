import SwiftUI

@Observable
final class BlobbySettings {
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }

    var blobColor: Color {
        didSet { saveColor(blobColor, key: "blobColor") }
    }

    var dotColor: Color {
        didSet { saveColor(dotColor, key: "dotColor") }
    }

    var blobSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(blobSize), forKey: "blobSize") }
    }

    var opacity: Double {
        didSet { UserDefaults.standard.set(opacity, forKey: "opacity") }
    }

    var springMode: SpringMode {
        didSet { UserDefaults.standard.set(springMode.rawValue, forKey: "springMode") }
    }

    var showDotCursor: Bool {
        didSet { UserDefaults.standard.set(showDotCursor, forKey: "showDotCursor") }
    }

    var dotSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(dotSize), forKey: "dotSize") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        self.blobSize = CGFloat(defaults.object(forKey: "blobSize") as? Double ?? 40.0)
        self.opacity = defaults.object(forKey: "opacity") as? Double ?? 0.5
        self.springMode = SpringMode(rawValue: defaults.string(forKey: "springMode") ?? "") ?? .normal
        self.showDotCursor = defaults.object(forKey: "showDotCursor") as? Bool ?? false
        self.dotSize = CGFloat(defaults.object(forKey: "dotSize") as? Double ?? 8.0)
        self.blobColor = Self.loadColor(key: "blobColor", fallback: NSColor(red: 0.706, green: 0.706, blue: 0.706, alpha: 1.0))
        self.dotColor = Self.loadColor(key: "dotColor", fallback: .white)
    }

    private func saveColor(_ color: Color, key: String) {
        let nsColor = NSColor(color)
        let data = try? NSKeyedArchiver.archivedData(
            withRootObject: nsColor, requiringSecureCoding: true
        )
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadColor(key: String, fallback: NSColor) -> Color {
        guard let data = UserDefaults.standard.data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: NSColor.self, from: data
              )
        else {
            return Color(nsColor: fallback)
        }
        return Color(nsColor: nsColor)
    }
}
