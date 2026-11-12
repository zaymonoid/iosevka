import Foundation

/// An invitation to a duel: a match of rounds between two players, each on
/// their own phone, playing the same board at the same time. The host's phone
/// makes the invite and shows it as a QR code; the guest scans it, which opens
/// the app with `url`.
///
/// The invite carries only a seed. Each phone generates round n's board from
/// the seed and n, so Rematch moves both phones to the next board without
/// scanning again. That relies on both phones running the same build.
struct DuelInvite: Equatable {
  static let scheme = "iosevka"
  static let host = "duel"

  let seed: UInt64

  /// e.g. `iosevka://duel?s=8F3A21C07E5D9B10`
  var url: URL {
    var components = URLComponents()
    components.scheme = Self.scheme
    components.host = Self.host
    components.queryItems = [URLQueryItem(name: "s", value: String(seed, radix: 16, uppercase: true))]
    return components.url!
  }

  /// The board for a round of the match, counting from 1.
  func board(round: Int) -> GameBoard {
    // Mix the round in so neighbouring rounds don't share a generator stream.
    var generator = SeededGenerator(seed: seed ^ (UInt64(round) &* 0xD1B5_4A32_D192_ED03))
    return mkGameBoard(size: boardSize, using: &generator).0
  }
}

extension DuelInvite {
  /// A new match with a random seed.
  static func random() -> DuelInvite { DuelInvite(seed: .random(in: .min ... .max)) }

  /// Reads an invite back from its URL. Returns nil for anything that isn't an
  /// invite with a hexadecimal seed.
  init?(url: URL) {
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == Self.scheme, components.host == Self.host,
      let items = components.queryItems,
      let hex = items.first(where: { $0.name == "s" })?.value,
      let seed = UInt64(hex, radix: 16)
    else { return nil }

    self.seed = seed
  }
}

/// One round of a duel match. Rematch moves both phones to the next round.
struct DuelRound: Equatable {
  let invite: DuelInvite
  /// Counts from 1.
  let number: Int

  /// The first round of a new match, from the invite the host showed.
  init(firstOf invite: DuelInvite) { self.init(invite: invite, number: 1) }

  private init(invite: DuelInvite, number: Int) {
    self.invite = invite
    self.number = number
  }

  var next: DuelRound { DuelRound(invite: invite, number: number + 1) }
  var board: GameBoard { invite.board(round: number) }
}
