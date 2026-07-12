// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cupertino_widgets",
    // Declared minimum matches Flutter's default app deployment target so the
    // package links into any Flutter app. The implementation itself is gated
    // with `@available(iOS 15.0, *)`: on iOS 13/14 the plugin registers
    // nothing and the native views are inert.
    platforms: [
        .iOS("13.0")
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
