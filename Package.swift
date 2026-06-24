// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Blobby",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Blobby",
            path: "Blobby",
            exclude: ["Info.plist", "Blobby.entitlements"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
