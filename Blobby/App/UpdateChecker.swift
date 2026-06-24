import Foundation
import AppKit

enum UpdateResult {
    case upToDate(currentVersion: String)
    case available(latestVersion: String, releaseURL: URL, dmgURL: URL)
    case error(String)
}

enum UpdateError: Error {
    case failed(String)
}

private struct GitHubRelease {
    let tagName: String
    let htmlURL: URL
    let dmgURL: URL?
}

private enum ReleaseLookupResult {
    case success(GitHubRelease)
    case failure(String)
}

struct UpdateChecker {
    static let repoOwner = "dxsun97"
    static let repoName = "Blobby"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static func check() async -> UpdateResult {
        let apiResult = await latestReleaseFromAPI()
        let release: GitHubRelease

        switch apiResult {
        case .success(let apiRelease):
            release = apiRelease
        case .failure(let apiMessage):
            switch await latestReleaseFromRedirect() {
            case .success(let redirectRelease):
                release = redirectRelease
            case .failure(let fallbackMessage):
                return .error("\(apiMessage)\n\nFallback failed: \(fallbackMessage)")
            }
        }

        let latestVersion = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName

        guard isNewer(latestVersion, than: currentVersion) else {
            return .upToDate(currentVersion: currentVersion)
        }

        let dmgURL = release.dmgURL
            ?? URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/download/\(release.tagName)/Blobby-\(latestVersion)-universal.dmg")!

        return .available(latestVersion: latestVersion, releaseURL: release.htmlURL, dmgURL: dmgURL)
    }

    private static func latestReleaseFromAPI() async -> ReleaseLookupResult {
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            return .failure("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("Blobby/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Invalid response")
            }

            if httpResponse.statusCode == 404 {
                return .failure("No releases found")
            }

            guard httpResponse.statusCode == 200 else {
                return .failure(gitHubAPIErrorMessage(statusCode: httpResponse.statusCode, data: data, response: httpResponse))
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let release = release(from: json)
            else {
                return .failure("Failed to parse response")
            }

            return .success(release)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private static func latestReleaseFromRedirect() async -> ReleaseLookupResult {
        guard let url = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest") else {
            return .failure("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("Blobby/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Invalid response")
            }

            guard (200..<400).contains(httpResponse.statusCode) else {
                return .failure("GitHub releases page error (\(httpResponse.statusCode))")
            }

            guard let finalURL = httpResponse.url,
                  let tagName = finalURL.pathComponents.last,
                  finalURL.pathComponents.contains("tag")
            else {
                return .failure("Could not resolve latest release")
            }

            guard let releaseURL = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/tag/\(tagName)") else {
                return .failure("Invalid release URL")
            }

            return .success(GitHubRelease(tagName: tagName, htmlURL: releaseURL, dmgURL: nil))
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    static func downloadAndInstall(dmgURL: URL, progressHandler: @escaping (Double) -> Void) async -> Result<Void, UpdateError> {
        do {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("BlobbyUpdate")
            try? FileManager.default.removeItem(at: tempDir)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let dmgPath = tempDir.appendingPathComponent("Blobby.dmg")

            let delegate = DownloadProgressDelegate(handler: progressHandler)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let (localURL, _) = try await session.download(from: dmgURL)
            session.invalidateAndCancel()
            try FileManager.default.moveItem(at: localURL, to: dmgPath)

            let mountOutput = try shell("hdiutil attach \"\(dmgPath.path)\" -nobrowse -noverify -noautoopen")
            guard let mountPoint = mountOutput.components(separatedBy: "\n")
                .last(where: { $0.contains("/Volumes/") })?
                .components(separatedBy: "\t")
                .last?.trimmingCharacters(in: .whitespaces)
            else {
                return .failure(.failed("Failed to mount DMG"))
            }

            let sourcePath = "\(mountPoint)/Blobby.app"
            guard FileManager.default.fileExists(atPath: sourcePath) else {
                detach(mountPoint)
                return .failure(.failed("Blobby.app not found in DMG"))
            }

            guard let appPath = Bundle.main.bundlePath as String? else {
                detach(mountPoint)
                return .failure(.failed("Cannot determine install location"))
            }

            let backupPath = appPath + ".backup"
            try? FileManager.default.removeItem(atPath: backupPath)
            try FileManager.default.moveItem(atPath: appPath, toPath: backupPath)

            do {
                try FileManager.default.copyItem(atPath: sourcePath, toPath: appPath)
            } catch {
                try? FileManager.default.moveItem(atPath: backupPath, toPath: appPath)
                detach(mountPoint)
                return .failure(.failed("Failed to install: \(error.localizedDescription)"))
            }

            try? FileManager.default.removeItem(atPath: backupPath)
            detach(mountPoint)
            try? FileManager.default.removeItem(at: tempDir)

            return .success(())
        } catch {
            return .failure(.failed(error.localizedDescription))
        }
    }

    static func relaunch() {
        guard let appPath = Bundle.main.bundlePath as String? else { return }
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1 && open \"\(appPath)\""]
        try? task.run()
        NSApp.terminate(nil)
    }

    private static func release(from json: [String: Any]) -> GitHubRelease? {
        guard let tagName = json["tag_name"] as? String,
              let htmlURLString = json["html_url"] as? String,
              let htmlURL = URL(string: htmlURLString)
        else {
            return nil
        }

        return GitHubRelease(tagName: tagName, htmlURL: htmlURL, dmgURL: findDMGAsset(json: json))
    }

    private static func findDMGAsset(json: [String: Any]) -> URL? {
        guard let assets = json["assets"] as? [[String: Any]] else { return nil }
        for asset in assets {
            if let name = asset["name"] as? String,
               name.hasSuffix(".dmg"),
               let urlString = asset["browser_download_url"] as? String,
               let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }

    private static func gitHubAPIErrorMessage(statusCode: Int, data: Data, response: HTTPURLResponse) -> String {
        var message = "GitHub API error (\(statusCode))"

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let apiMessage = json["message"] as? String {
            message += ": \(apiMessage)"
        }

        if statusCode == 403,
           let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           remaining == "0",
           let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let resetTime = TimeInterval(reset) {
            let resetDate = Date(timeIntervalSince1970: resetTime)
            message += "\nGitHub's unauthenticated API rate limit is exhausted. Try again after \(resetDate.formatted(date: .omitted, time: .shortened))."
        }

        return message
    }

    private static func isNewer(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }

    private static func detach(_ mountPoint: String) {
        _ = try? shell("hdiutil detach \"\(mountPoint)\"")
    }

    @discardableResult
    private static func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        try task.run()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}

final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let handler: (Double) -> Void
    init(handler: @escaping (Double) -> Void) { self.handler = handler }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        handler(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
}
