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
        for bundle in [Bundle.main] + resourceBundles {
            if !bundles.contains(where: { $0.bundleURL == bundle.bundleURL }) {
                bundles.append(bundle)
            }
        }
        return bundles
    }()

    private static let resourceBundles: [Bundle] = {
        let bundleName = "Blobby_Blobby.bundle"
        let executableDirectory = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent(bundleName),
            Bundle.main.bundleURL.appendingPathComponent(bundleName),
            executableDirectory.appendingPathComponent(bundleName),
        ].compactMap { $0 }

        return candidates.compactMap { Bundle(url: $0) }
    }()
}

extension String {
    var localized: String {
        L10n.text(self)
    }
}
