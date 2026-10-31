// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Glow",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Glow",
            path: "Sources/Glow"
        )
    ]
)
