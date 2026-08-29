// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "nesd_audio",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "nesd-audio", targets: ["nesd_audio"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "nesd_audio",
      dependencies: []
    )
  ],
  cxxLanguageStandard: .gnucxx17
)
