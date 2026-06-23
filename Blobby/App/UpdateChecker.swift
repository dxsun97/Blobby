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

struct UpdateChecker {
    static let repoOwner = "dxsun97"
    static let repoName = "Blobby"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static func check() async -> UpdateResult {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            return .error("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Invalid response")
            }

            if httpResponse.statusCode == 404 {
                return .error("No releases found")
            }

            guard httpResponse.statusCode == 200 else {
                return .error("GitHub API error (\(httpResponse.statusCode))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String,
                  let releaseURL = URL(string: htmlURL)
            else {
                return .error("Failed to parse response")
            }

            let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

            guard isNewer(latestVersion, than: currentVersion) else {
                return .upToDate(currentVersion: currentVersion)
            }

            let dmgURL = findDMGAsset(json: json)
                ?? URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/download/\(tagName)/Blobby-\(latestVersion)-universal.dmg")!

            return .available(latestVersion: latestVersion, releaseURL: releaseURL, dmgURL: dmgURL)
        } catch {
            return .error(error.localizedDescription)
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
