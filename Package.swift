// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "oracle-kit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "OracleKit",
            targets: ["OracleKit"]),
    ],
    dependencies: [
         .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
         .package(url: "https://github.com/lovetodream/sql-kit.git", branch: "main"), // use vapor version once PR#
         .package(url: "https://github.com/vapor/async-kit.git", from: "1.14.0"),
    ],
    targets: [
        .target(name: "OracleKit", dependencies: [
            .product(name: "OracleNIO", package: "oracle-nio"),
            .product(name: "AsyncKit", package: "async-kit"),
            .product(name: "SQLKit", package: "sql-kit"),
        ]),
        .testTarget(name: "OracleKitTests", dependencies: [
            .product(name: "SQLKitBenchmark", package: "sql-kit"),
            .target(name: "OracleKit"),
        ]),
    ]
)
