// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Toast",
    platforms:
    [
       .iOS(.v16),
       .tvOS(.v16),
       .macCatalyst(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Toast",
            targets: ["Toast"]),
    ],
    dependencies: [
        .package(url: "https://github.com/voyager-software/NVActivityIndicatorView", from: "6.1.0")
    ],
    targets: [
        .target(
            name: "Toast",
            dependencies: [
                "NVActivityIndicatorView"
            ]),
        .testTarget(
            name: "ToastTests",
            dependencies: ["Toast"]),
    ]
)
