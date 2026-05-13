// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BudgetTrackerMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BudgetTrackerMac", targets: ["BudgetTrackerMac"])
    ],
    targets: [
        .executableTarget(
            name: "BudgetTrackerMac",
            path: "Sources/BudgetTrackerMac",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
