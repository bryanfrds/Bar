// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Bar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Bar",
            path: "Sources/Bar",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
