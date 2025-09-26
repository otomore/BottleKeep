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
        // Core Data用の依存関係
    ],
    targets: [
        .executableTarget(
            name: "BottleKeep",
            dependencies: [],
            path: "BottleKeep",
            exclude: [
                "Resources/Info.plist",
                "Resources/BottleKeep.xcdatamodeld"
            ]
        ),
        .testTarget(
            name: "BottleKeepTests",
            dependencies: ["BottleKeep"],
            path: "BottleKeepTests"
        )
    ]
)