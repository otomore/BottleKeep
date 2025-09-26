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
        // 外部依存関係はここに追加
    ],
    targets: [
        .executableTarget(
            name: "BottleKeep",
            dependencies: [],
            path: "BottleKeep",
            resources: [
                .process("Resources")
            ]
        )
    ]
)