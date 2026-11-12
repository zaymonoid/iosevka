@testable import iosevka
import XCTest

final class DuelTests: XCTestCase {
  private let invite = DuelInvite(seed: 0x8F3A_21C0_7E5D_9B10)

  func testInviteURLCarriesTheSeedInHex() {
    XCTAssertEqual(invite.url.absoluteString, "iosevka://duel?s=8F3A21C07E5D9B10")
  }

  func testInviteSurvivesTheRoundTrip() {
    XCTAssertEqual(DuelInvite(url: invite.url), invite)
    let extremes = [DuelInvite(seed: 0), DuelInvite(seed: .max)]
    for invite in extremes { XCTAssertEqual(DuelInvite(url: invite.url), invite) }
  }

  func testLowercaseSeedsAreAccepted() {
    XCTAssertEqual(DuelInvite(url: URL(string: "iosevka://duel?s=8f3a21c07e5d9b10")!), invite)
  }

  func testMalformedInvitesAreRejected() {
    let rejected = [
      "https://duel?s=8F3A21C07E5D9B10", // wrong scheme
      "iosevka://game?s=8F3A21C07E5D9B10", // wrong host
      "iosevka://duel", // no seed
      "iosevka://duel?s=XYZ", // not hex
      "iosevka://duel?s=18F3A21C07E5D9B10", // more than 64 bits
    ]
    for string in rejected {
      XCTAssertNil(DuelInvite(url: URL(string: string)!), string)
    }
  }

  func testBothPhonesGetTheSameBoardForARound() {
    let guest = DuelInvite(url: invite.url)!
    for round in 1...3 {
      XCTAssertEqual(guest.board(round: round), invite.board(round: round), "round \(round)")
    }
  }

  func testEachRoundGetsANewBoard() {
    let boards = (1...5).map { invite.board(round: $0) }
    XCTAssertEqual(Set(boards.map { $0.letters.joined().map(String.init).joined() }).count, 5)
  }

  func testDifferentMatchesGetDifferentBoards() {
    XCTAssertNotEqual(invite.board(round: 1), DuelInvite(seed: invite.seed + 1).board(round: 1))
  }

  func testPlayStartsAGameOnTheGivenBoard() {
    let board = invite.board(round: 1)
    let next = GameState.update(state: GameState(), action: .play(board), environment: AppEnvironment())

    XCTAssertEqual(next.state.gameBoard, board)
    XCTAssertEqual(next.state.stateOfTheGame, .playing)
    XCTAssertEqual(next.state.timeRemaining, timeLimit)
    XCTAssertEqual(next.state.wordLookup, Set(Solver.shared.findAllWords(board: board).map(\.word)))
  }
}
