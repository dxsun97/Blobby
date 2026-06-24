import Foundation

enum L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedFormat(for: key)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    private static func localizedFormat(for key: String) -> String {
        for bundle in localizationBundles {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key {
                return value
            }
        }
        return key
    }

    private static let localizationBundles: [Bundle] = {
        var bundles: [Bundle] = []
        for bundle in [Bundle.main, Bundle.module] {
            if !bundles.contains(where: { $0.bundleURL == bundle.bundleURL }) {
                bundles.append(bundle)
            }
        }
        return bundles
    }()
}

extension String {
    var localized: String {
        L10n.text(self)
    }
}
