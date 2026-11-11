// swift-tools-version: 6.0
// Builds the game logic in iosevka/ and the unit tests in iosevkaTests/ as a
// macOS package, so `swift test` runs them in about a second without booting a
// simulator. The folders are symlinked; the module is named `iosevka` so
// `@testable import iosevka` resolves the same as in the Xcode test target.
//
// Only the files listed in `sources` are built. Keep them free of SwiftUI and
// UIKit; add new logic files there and new app-only files to `exclude`.
import PackageDescription

let package = Package(
  name: "AppLogic",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/subconsciousnetwork/ObservableStore", exact: "0.4.0"),
  ],
  targets: [
    .target(
      name: "iosevka",
      dependencies: ["ObservableStore"],
      exclude: [
        "Assets.xcassets", "ContentView.swift", "FadeIn.swift", "GameBoardView.swift",
        "GameView.swift", "MenuView.swift", "Preview Content", "ReadOnlyBoardView.swift",
        "SwipeState.swift", "Theme.swift", "dictionary.txt", "iosevkaApp.swift",
      ],
      sources: [
        "BoardGeneration.swift",
        "GameBoard.swift",
        "GameState.swift",
        "Math.swift",
        "Rotation.swift",
        "Solver.swift",
        "Trie.swift",
      ]
    ),
    .testTarget(name: "iosevkaTests", dependencies: ["iosevka"]),
  ],
  swiftLanguageModes: [.v5]
)
