// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "BottleKeep",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BottleKeep",
            targets: ["BottleKeep"]
        )
    ],
    dependencies: [
        // Core Data用の依存関係
    ],
    targets: [
        .target(
            name: "BottleKeep",
            dependencies: [],
            path: "BottleKeep",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BottleKeepTests",
            dependencies: ["BottleKeep"],
            path: "BottleKeepTests"
        )
    ]
)