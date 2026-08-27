// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftHTTPServer",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.9.0")
    ],
    targets: [
        .target(
            name: "SwiftHTTPServer",
            dependencies: ["Kitura"]),
        .testTarget(
            name: "SwiftHTTPServerTests",
            dependencies: ["SwiftHTTPServer"]),
    ]
)