// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GestureDeck",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "GestureDeck", targets: ["GestureDeck"]),
        .executable(name: "GestureDeckLogicTests", targets: ["GestureDeckLogicTests"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Kyome22/OpenMultitouchSupport.git",
            exact: "4.0.0"
        )
    ],
    targets: [
        .target(
            name: "GestureDeckCore",
            path: "Sources/GestureDeckCore"
        ),
        .executableTarget(
            name: "GestureDeck",
            dependencies: [
                "GestureDeckCore",
                .product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")
            ],
            path: "Sources/GestureDeck"
        ),
        .executableTarget(
            name: "GestureDeckLogicTests",
            dependencies: ["GestureDeckCore"],
            path: "Tests/GestureDeckLogicTests"
        )
    ]
)
