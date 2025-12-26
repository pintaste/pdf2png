// swift-tools-version:5.9
// PDF2PNG - PDF to PNG Converter for macOS

import PackageDescription

let package = Package(
    name: "PDF2PNG",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PDF2PNG",
            targets: ["PDF2PNG"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PDF2PNG",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PDF2PNGTests",
            dependencies: ["PDF2PNG"],
            path: "Tests"
        )
    ]
)
