// swift-tools-version: 6.4
// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import PackageDescription

let package = Package(
  name: "PrankMindScriptingCore",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(name: "ScriptingCoreArgumentParser", targets: [ "ScriptingCoreArgumentParser" ]),
    .library(name: "ScriptingCoreAsyncSequence", targets: [ "ScriptingCoreAsyncSequence" ]),
    .library(name: "ScriptingCoreConsole", targets: [ "ScriptingCoreConsole" ]),
    .library(name: "ScriptingCoreGeneral", targets: [ "ScriptingCoreGeneral" ]),
    .library(name: "ScriptingCoreInterpolation", targets: [ "ScriptingCoreInterpolation" ]),
    .library(name: "ScriptingCoreLogging", targets: [ "ScriptingCoreLogging" ]),
    .library(name: "ScriptingCoreNetworking", targets: [ "ScriptingCoreNetworking" ]),
    .library(name: "ScriptingCoreShell", targets: [ "ScriptingCoreShell" ]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.0"),
    .package(url: "https://github.com/apple/swift-log", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "ScriptingCoreArgumentParser",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
        "ScriptingCoreGeneral",
      ]
    ),
    .target(name: "ScriptingCoreAsyncSequence"),
    .target(name: "ScriptingCoreConsole"),
    .target(name: "ScriptingCoreGeneral", dependencies: [ "ScriptingCoreInterpolation" ]),
    .target(name: "ScriptingCoreInterpolation"),
    .target(name: "ScriptingCoreLogging", dependencies: [
      .product(name: "Logging", package: "swift-log"),
    ]),
    .target(
      name: "ScriptingCoreNetworking",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        "ScriptingCoreGeneral", "ScriptingCoreInterpolation",
      ],
    ),
    .target(
      name: "ScriptingCoreShell",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
      ],
    ),

    .testTarget(name: "AsyncSequenceTests", dependencies: [ "ScriptingCoreAsyncSequence" ]),
    .testTarget(name: "GeneralTests", dependencies: [ "ScriptingCoreGeneral" ]),
    .testTarget(name: "InterpolationTests", dependencies: [ "ScriptingCoreGeneral", "ScriptingCoreInterpolation" ]),
    .testTarget(name: "LoggingTests", dependencies: [ "ScriptingCoreLogging" ]),
    .testTarget(name: "NetworkingTests", dependencies: [ "ScriptingCoreNetworking" ]),
    .testTarget(
      name: "ShellTests",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        "ScriptingCoreShell",
      ],
    ),
  ]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
  target.swiftSettings = (target.swiftSettings ?? []) + [
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
  ]
}
