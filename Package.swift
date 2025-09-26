// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "BottleKeep",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "BottleKeep",
            targets: ["BottleKeep"]
        )
    ],
    dependencies: [
        // 必要な依存関係をここに追加
    ],
    targets: [
        .executableTarget(
            name: "BottleKeep",
            dependencies: [],
            path: "BottleKeep"
        ),
        .testTarget(
            name: "BottleKeepTests",
            dependencies: ["BottleKeep"],
            path: "BottleKeepTests"
        )
    ]
)