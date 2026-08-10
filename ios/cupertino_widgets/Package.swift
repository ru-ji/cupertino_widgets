// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cupertino_widgets",
    // Minimum required to use the package: every native view is built on
    // iOS 15+ SwiftUI/UIKit APIs.
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "cupertino-widgets", targets: ["cupertino_widgets"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "cupertino_widgets",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: []
        )
    ]
)
