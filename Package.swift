// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CleanMyMac",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CleanMyMac",
            path: "Sources/CleanMyMac"
        )
    ]
)
