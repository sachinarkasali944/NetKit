// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "NetKit", targets: ["NetKit"])
    ],
    targets: [
        .target(name: "NetKit", path: "Sources/NetKit"),
        .testTarget(name: "NetKitTests",
                    dependencies: ["NetKit"],
                    path: "Tests/NetKitTests")
    ]
)
