// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "oracle-kit",
    products: [
        .library(
            name: "OracleKit",
            targets: ["OracleKit"]),
    ],
    dependencies: [
         .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "OracleKit",
            dependencies: [
                .product(name: "OracleNIO", package: "oracle-nio")
            ]),
        .testTarget(
            name: "OracleKitTests",
            dependencies: ["OracleKit"]),
    ]
)
