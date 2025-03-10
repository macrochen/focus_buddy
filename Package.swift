// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "focus_buddy",
    platforms: [
        .iOS(.v15),
        // .macOS(.v12)
    ],
    products: [
        .library(
            name: "FocusBuddy",
            targets: ["FocusBuddy"]),
    ],
    targets: [
        .target(
            name: "FocusBuddy",
            path: "Shared",
            exclude: []
        )
    ]
)