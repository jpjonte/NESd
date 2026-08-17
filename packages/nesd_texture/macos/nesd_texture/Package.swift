// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "nesd_texture",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "nesd-texture", targets: ["nesd_texture"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "nesd_texture",
      dependencies: [],
      resources: [
        .process("Resources")
      ]
    )
  ]
)
