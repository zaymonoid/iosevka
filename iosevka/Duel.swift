import Foundation

/// An invitation to a duel: two players on their own phones play the same
/// board at the same time. The host's phone makes the invite and shows it as
/// a QR code; the guest scans it, which opens the app with `url`.
///
/// The invite carries the board's letters, not a seed, so both phones see the
/// same board whatever their random number generators or app versions do.
struct DuelInvite: Equatable {
  static let scheme = "iosevka"
  static let host = "duel"
  static let version = 1

  let board: GameBoard

  /// e.g. `iosevka://duel?v=1&b=TESNARLOIDHCUMWF`, the rows read left to right.
  var url: URL {
    var components = URLComponents()
    components.scheme = Self.scheme
    components.host = Self.host
    components.queryItems = [
      URLQueryItem(name: "v", value: String(Self.version)),
      URLQueryItem(name: "b", value: String(board.letters.joined())),
    ]
    return components.url!
  }
}

extension DuelInvite {
  /// Reads an invite back from its URL. Returns nil for anything that isn't a
  /// version 1 invite holding a `boardSize` × `boardSize` board of A–Z.
  init?(url: URL) {
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == Self.scheme, components.host == Self.host,
      let items = components.queryItems,
      items.first(where: { $0.name == "v" })?.value == String(Self.version),
      let letters = items.first(where: { $0.name == "b" })?.value?.uppercased(),
      letters.count == boardSize * boardSize,
      letters.allSatisfy({ ("A"..."Z").contains($0) })
    else { return nil }

    let characters = Array(letters)
    let rows = stride(from: 0, to: characters.count, by: boardSize).map {
      Array(characters[$0..<$0 + boardSize])
    }
    self.board = GameBoard(letters: rows)
  }
}
