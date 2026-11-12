@testable import iosevka
import XCTest

final class DailyTests: XCTestCase {
  func testSameDayGivesSameBoard() {
    let day = DailyDay(year: 2026, month: 11, day: 11)
    XCTAssertEqual(Daily.board(for: day), Daily.board(for: day))
  }

  func testDifferentDaysGiveDifferentBoards() {
    let day = DailyDay(year: 2026, month: 11, day: 11)
    XCTAssertNotEqual(Daily.board(for: day), Daily.board(for: day.previous))
  }

  /// Pins the generator. If this fails, every player's daily boards changed.
  func testSeededGeneratorIsStable() {
    var generator = SeededGenerator(seed: 42)
    XCTAssertEqual(generator.next(), 0xBDD7_3226_2FEB_6E95)
  }

  func testPuzzleNumbersCountFromTheFirstDay() {
    XCTAssertEqual(DailyDay.first.number, 1)
    XCTAssertEqual(DailyDay(year: 2026, month: 11, day: 11).number, 11)
  }

  func testDayFollowsTheLocalCalendar() {
    var sydney = Calendar(identifier: .gregorian)
    sydney.timeZone = TimeZone(identifier: "Australia/Sydney")!
    // 20:00 UTC on the 10th is already the 11th in Sydney.
    let date = ISO8601DateFormatter().date(from: "2026-11-10T20:00:00Z")!
    XCTAssertEqual(DailyDay(containing: date, calendar: sydney), DailyDay(year: 2026, month: 11, day: 11))
    XCTAssertEqual(
      DailyDay(year: 2026, month: 11, day: 11).end(calendar: sydney),
      ISO8601DateFormatter().date(from: "2026-11-11T13:00:00Z")!
    )
  }

  private func result(_ day: DailyDay, score: Int = 10) -> DailyResult {
    DailyResult(day: day, score: score, possibleScore: 100, wordsFound: 3, totalWords: 30,
                coverage: [true, false, false, true] + Array(repeating: false, count: 12))
  }

  func testStreakCountsConsecutiveDays() {
    let today = DailyDay(year: 2026, month: 11, day: 11)
    var history = DailyHistory()
    XCTAssertEqual(history.streak(today: today), 0)

    history.record(result(today.previous))
    history.record(result(today.previous.previous))
    // Not played today yet: yesterday's streak still stands.
    XCTAssertEqual(history.streak(today: today), 2)

    history.record(result(today))
    XCTAssertEqual(history.streak(today: today), 3)

    // A gap breaks it.
    XCTAssertEqual(history.streak(today: DailyDay(index: today.index + 2)), 0)
  }

  func testFirstResultForADayStands() {
    let today = DailyDay(year: 2026, month: 11, day: 11)
    var history = DailyHistory()
    history.record(result(today, score: 10))
    history.record(result(today, score: 99))
    XCTAssertEqual(history.result(for: today)?.score, 10)
  }

  func testShareTextShowsScoreAndCoverage() {
    let text = result(DailyDay(year: 2026, month: 11, day: 11)).shareText
    XCTAssertEqual(text, """
    Iosevka Daily #11
    10/100 points · 3/30 words
    🟦⬜️⬜️🟦
    ⬜️⬜️⬜️⬜️
    ⬜️⬜️⬜️⬜️
    ⬜️⬜️⬜️⬜️
    """)
  }

  func testHistorySurvivesAReload() {
    let defaults = UserDefaults(suiteName: "DailyTests")!
    defaults.removePersistentDomain(forName: "DailyTests")
    let day = DailyDay(year: 2026, month: 11, day: 11)

    DailyHistoryStore(defaults: defaults).record(result(day))
    XCTAssertEqual(DailyHistoryStore(defaults: defaults).history.result(for: day), result(day))
  }
}
