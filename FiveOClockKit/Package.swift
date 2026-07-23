// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FiveOClockKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FiveOClockKit", targets: ["FiveOClockKit"])
    ],
    targets: [
        .target(
            name: "FiveOClockKit",
            resources: [.copy("Resources/cities")]
        ),
        .testTarget(
            name: "FiveOClockKitTests",
            dependencies: ["FiveOClockKit"]
        )
    ]
)
