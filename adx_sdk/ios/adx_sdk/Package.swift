// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adx_sdk",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "adx-sdk", targets: ["adx_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/adxcorp/AdxLibrary_iOS_Release.git", exact: "2.9.1"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "adx_sdk",
            dependencies: [
                .product(name: "ADXLibrary", package: "AdxLibrary_iOS_Release"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            publicHeadersPath: "."
        )
    ]
)
