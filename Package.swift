// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TRPCoreKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TRPCoreKit",
            targets: ["TRPCoreKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
        .package(url: "https://github.com/WenchaoD/FSCalendar.git", from: "2.8.3"),
        .package(url: "https://github.com/mapbox/mapbox-directions-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/rechsteiner/Parchment", from: "3.1.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.19.7"),
//        .package(url: "https://github.com/mapbox/mapbox-events-ios.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TRPCoreKit",
            dependencies: [
                .product(name: "MapboxDirections", package: "mapbox-directions-swift"),
//                .product(name: "MapboxMobileEvents", package: "mapbox-events-ios"),
                "Parchment",
                "SDWebImage",
                "FSCalendar",
                "Alamofire",
                "Mapbox",
                "MapboxMobileEvents",
            ],
            path: "TRPCoreKit",
            resources: [
                .process("Resources/Fonts")   
            ]
        ),
        .binaryTarget(
            name: "Mapbox",
            path: "./Mapbox.xcframework"
        ),
        .binaryTarget(
            name: "MapboxMobileEvents",
            path: "./MapboxMobileEvents.xcframework"
        ),
        .testTarget(
            name: "TRPCoreKitTests",
            dependencies: ["TRPCoreKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
