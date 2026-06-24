import Foundation

enum L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedFormat(for: key)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    private static func localizedFormat(for key: String) -> String {
        for bundle in localizationBundles {
            for localizedBundle in preferredBundles(for: bundle) {
                let value = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
                if value != key {
                    return value
                }
            }
        }
        return key
    }

    private static func preferredBundles(for bundle: Bundle) -> [Bundle] {
        let preferredLocalizations = Bundle.preferredLocalizations(
            from: bundle.localizations,
            forPreferences: Locale.preferredLanguages
        )
        let localizedBundles = preferredLocalizations.compactMap { localization in
            lprojBundle(for: localization, in: bundle)
        }

        return localizedBundles + [bundle]
    }

    private static func lprojBundle(for localization: String, in bundle: Bundle) -> Bundle? {
        if let path = bundle.path(forResource: localization, ofType: "lproj") {
            return Bundle(path: path)
        }

        guard let resourceURL = bundle.resourceURL,
              let lprojURL = try? FileManager.default.contentsOfDirectory(
                at: resourceURL,
                includingPropertiesForKeys: nil
              ).first(where: {
                $0.pathExtension == "lproj"
                    && $0.deletingPathExtension().lastPathComponent.caseInsensitiveCompare(localization) == .orderedSame
              })
        else {
            return nil
        }

        return Bundle(url: lprojURL)
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
