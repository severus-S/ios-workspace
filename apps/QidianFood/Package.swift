// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QidianCatalog",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "QidianCatalog",
            path: "Sources",
            exclude: ["App.swift", "ContentView.swift"],
            sources: ["CatalogAPI.swift", "CatalogModel.swift"]
        ),
        .testTarget(name: "QidianCatalogTests", dependencies: ["QidianCatalog"], path: "Tests")
    ]
)
