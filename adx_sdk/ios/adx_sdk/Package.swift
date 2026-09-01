// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adx_sdk",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "adx-sdk", targets: ["adx_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/adxcorp/AdxLibrary_iOS_Release.git", exact: "2.9.0")
    ],
    targets: [
        .target(
            name: "adx_sdk",
            dependencies: [
                .product(name: "ADXLibrary", package: "AdxLibrary_iOS_Release")
            ],
            publicHeadersPath: "."
        )
    ]
)
