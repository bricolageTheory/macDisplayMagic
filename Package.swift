// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macDisplayMagic",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "macDisplayMagic", targets: ["macDisplayMagic"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "macDisplayMagic",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "macDisplayMagicTests",
            dependencies: ["macDisplayMagic"],
            path: "Tests"
        )
    ]
)
