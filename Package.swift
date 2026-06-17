// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MinimalEditor",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "MinimalEditorCore"),
        .executableTarget(
            name: "MinimalEditor",
            dependencies: ["MinimalEditorCore"]
        ),
        .testTarget(
            name: "MinimalEditorCoreTests",
            dependencies: ["MinimalEditorCore"]
        ),
    ]
)
