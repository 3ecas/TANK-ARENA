// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Frontline",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Frontline",
            path: "Sources/Frontline"
        )
    ]
)
