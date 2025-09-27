// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "BottleKeep",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BottleKeepLib",
            targets: ["BottleKeep"]
        )
    ],
    dependencies: [
        // 外部依存関係はここに追加
    ],
    targets: [
        .target(
            name: "BottleKeep",
            dependencies: [],
            path: "BottleKeep",
            exclude: [
                "Info.plist",
                "BottleKeep.xcdatamodeld",
                "Preview Content"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)