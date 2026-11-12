import Combine
import Foundation

// -- Daily board ---------------------------------------------------------------
// Everyone gets the same board each calendar day. The board is generated from a
// seed derived from the day, so it needs no server.

/// A calendar day, counted from 1970-01-01 in the player's own calendar, so
/// the daily board changes at their local midnight.
struct DailyDay: Codable, Hashable, Comparable {
  let index: Int

  /// The day of the first daily board, puzzle #1.
  static let first = DailyDay(year: 2026, month: 11, day: 1)

  init(index: Int) { self.index = index }

  init(year: Int, month: Int, day: Int) {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    let date = utc.date(from: DateComponents(year: year, month: month, day: day))!
    self.index = Int(date.timeIntervalSince1970 / 86400)
  }

  init(containing date: Date, calendar: Calendar = .current) {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    self.init(year: parts.year!, month: parts.month!, day: parts.day!)
  }

  /// The puzzle number shown to players, e.g. "Daily #11".
  var number: Int { index - Self.first.index + 1 }

  var previous: DailyDay { DailyDay(index: index - 1) }

  /// When this day ends, i.e. when the next board arrives, in `calendar`.
  func end(calendar: Calendar = .current) -> Date {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    let start = Date(timeIntervalSince1970: TimeInterval(index + 1) * 86400)
    let parts = utc.dateComponents([.year, .month, .day], from: start)
    return calendar.date(from: parts)!
  }

  static func < (lhs: DailyDay, rhs: DailyDay) -> Bool { lhs.index < rhs.index }
}

/// SplitMix64: a small, fast generator that gives the same sequence for the
/// same seed on every device and Swift version.
struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

enum Daily {
  /// Mixed into the seed so daily boards differ from a plain counter. Changing
  /// it changes every daily board, so leave it alone.
  private static let salt: UInt64 = 0x1053_7EAA_D417_0001

  static func board(for day: DailyDay) -> GameBoard {
    var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(day.index)) ^ salt)
    return mkGameBoard(size: boardSize, using: &generator).0
  }
}

// -- Results -----------------------------------------------------------------

/// How a player did on one daily board.
struct DailyResult: Codable, Equatable {
  let day: DailyDay
  let score: Int
  let possibleScore: Int
  let wordsFound: Int
  let totalWords: Int
  /// Row-major, one entry per tile: whether a found word passed through it.
  let coverage: [Bool]

  init(day: DailyDay, score: Int, possibleScore: Int, wordsFound: Int, totalWords: Int, coverage: [Bool]) {
    self.day = day
    self.score = score
    self.possibleScore = possibleScore
    self.wordsFound = wordsFound
    self.totalWords = totalWords
    self.coverage = coverage
  }

  /// The result of a finished game on `day`'s board.
  init(day: DailyDay, game: GameState) {
    let size = game.gameBoard?.size ?? boardSize
    var coverage = Array(repeating: false, count: size * size)
    for word in game.foundWords {
      guard let path = game.boardWords.first(where: { $0.word == word })?.path else { continue }
      for cell in path { coverage[cell.row * size + cell.col] = true }
    }
    self.init(
      day: day,
      score: game.score,
      possibleScore: game.possibleScore,
      wordsFound: game.foundWords.count,
      totalWords: game.wordLookup.count,
      coverage: coverage
    )
  }

  /// Spoiler-free text to share: the score and which tiles the player used.
  var shareText: String {
    let size = Int(Double(coverage.count).squareRoot())
    let grid = stride(from: 0, to: coverage.count, by: size).map { start in
      coverage[start..<start + size].map { $0 ? "🟦" : "⬜️" }.joined()
    }
    return ([
      "Iosevka Daily #\(day.number)",
      "\(score)/\(possibleScore) points · \(wordsFound)/\(totalWords) words",
    ] + grid).joined(separator: "\n")
  }
}

/// The daily results played on this device.
struct DailyHistory: Codable, Equatable {
  private(set) var results: [DailyDay: DailyResult] = [:]

  func result(for day: DailyDay) -> DailyResult? { results[day] }

  /// Keeps the first result for a day: the daily board counts once.
  mutating func record(_ result: DailyResult) {
    if results[result.day] == nil { results[result.day] = result }
  }

  /// Days in a row played, up to `today`. Not playing today yet doesn't break
  /// the streak until today is over.
  func streak(today: DailyDay) -> Int {
    var day = results[today] == nil ? today.previous : today
    var count = 0
    while results[day] != nil {
      count += 1
      day = day.previous
    }
    return count
  }
}

/// Keeps the daily history in UserDefaults.
final class DailyHistoryStore: ObservableObject {
  private static let key = "dailyHistory.v1"
  private let defaults: UserDefaults

  @Published private(set) var history: DailyHistory

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    history = defaults.data(forKey: Self.key)
      .flatMap { try? JSONDecoder().decode(DailyHistory.self, from: $0) }
      ?? DailyHistory()
  }

  func record(_ result: DailyResult) {
    history.record(result)
    if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Self.key) }
  }
}
