@testable import iosevka
import XCTest

final class DuelTests: XCTestCase {
  private let board = GameBoard(letters: [
    ["T", "E", "S", "N"],
    ["A", "R", "L", "O"],
    ["I", "D", "H", "C"],
    ["U", "M", "W", "F"],
  ])

  func testInviteURLListsTheRowsInOrder() {
    XCTAssertEqual(DuelInvite(board: board).url.absoluteString, "iosevka://duel?v=1&b=TESNARLOIDHCUMWF")
  }

  func testInviteSurvivesTheRoundTrip() {
    let invite = DuelInvite(board: board)
    XCTAssertEqual(DuelInvite(url: invite.url), invite)
  }

  func testLowercaseLettersAreAccepted() {
    let url = URL(string: "iosevka://duel?v=1&b=tesnarloidhcumwf")!
    XCTAssertEqual(DuelInvite(url: url)?.board, board)
  }

  func testMalformedInvitesAreRejected() {
    let rejected = [
      "https://duel?v=1&b=TESNARLOIDHCUMWF", // wrong scheme
      "iosevka://game?v=1&b=TESNARLOIDHCUMWF", // wrong host
      "iosevka://duel?v=2&b=TESNARLOIDHCUMWF", // unknown version
      "iosevka://duel?b=TESNARLOIDHCUMWF", // no version
      "iosevka://duel?v=1", // no board
      "iosevka://duel?v=1&b=TESNARLOIDHCUMW", // too short
      "iosevka://duel?v=1&b=TESNARLOIDHCUMWFX", // too long
      "iosevka://duel?v=1&b=TESNARLOIDHCUMW1", // not a letter
      "iosevka://duel?v=1&b=TESNARLOIDHCUMWÉ", // not A–Z
    ]
    for string in rejected {
      XCTAssertNil(DuelInvite(url: URL(string: string)!), string)
    }
  }

  /// Needs the app's dictionary, so it runs on the simulator, not in AppLogic.
  func testPlayStartsAGameOnTheGivenBoard() throws {
    try XCTSkipIf(Bundle.main.url(forResource: "dictionary", withExtension: "txt") == nil, "no dictionary")

    let next = GameState.update(state: GameState(), action: .play(board), environment: AppEnvironment())

    XCTAssertEqual(next.state.gameBoard, board)
    XCTAssertEqual(next.state.stateOfTheGame, .playing)
    XCTAssertEqual(next.state.timeRemaining, timeLimit)
    XCTAssertEqual(next.state.wordLookup, Set(Solver.shared.findAllWords(board: board).map(\.word)))
  }
}
