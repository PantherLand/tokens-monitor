// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenRouterMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "OpenRouterMonitor",
            targets: ["OpenRouterMonitor"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OpenRouterMonitor",
            dependencies: [],
            path: "OpenRouterMonitor/Sources"
        )
    ]
)
