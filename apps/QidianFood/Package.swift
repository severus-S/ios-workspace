// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QidianCatalog",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "QidianCatalog",
            path: "Sources",
            exclude: ["App.swift", "ContentView.swift", "MenuViews.swift", "AccountViews.swift", "AddressBookView.swift"],
            sources: ["CatalogAPI.swift", "CatalogModel.swift", "MenuModel.swift", "DemoAccount.swift"]
        ),
        .testTarget(name: "QidianCatalogTests", dependencies: ["QidianCatalog"], path: "Tests")
    ]
)
