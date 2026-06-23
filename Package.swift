// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Blobby",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Blobby",
            path: "Blobby",
            exclude: ["Info.plist", "Blobby.entitlements"],
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
