// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SkeletonKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "SkeletonKit", targets: ["SkeletonKit"]),
    ],
    targets: [
        .target(name: "SkeletonKit"),
        .testTarget(name: "SkeletonKitTests", dependencies: ["SkeletonKit"]),
    ]
)
