import Foundation

enum SpringMode: String, CaseIterable, Codable, Identifiable {
    case normal
    case slow
    case bouncy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: L10n.text("spring.normal")
        case .slow: L10n.text("spring.slow")
        case .bouncy: L10n.text("spring.bouncy")
        }
    }

    struct Constants {
        let acceleration: Double
        let friction: Double
    }

    var constants: Constants {
        switch self {
        case .normal:
            Constants(acceleration: 0.1, friction: 1.0 - 0.35)
        case .slow:
            Constants(acceleration: 0.06, friction: 1.0 - 0.35)
        case .bouncy:
            Constants(acceleration: 0.1, friction: 1.0 - 0.28)
        }
    }
}
