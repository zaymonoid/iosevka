@testable import iosevka
import XCTest

final class iosevkaTests: XCTestCase {
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
  }

  func testTickFromAnEarlierGameIsIgnored() {
    var state = GameState()
    state.gameId = UUID()
    state.gameBoard = GameBoard(size: boardSize)
    state.timeRemaining = 100

    let stale = GameState.update(state: state, action: .tickTimer(10, gameId: UUID()), environment: AppEnvironment())
    XCTAssertEqual(stale.state.timeRemaining, 100)

    let current = GameState.update(state: state, action: .tickTimer(10, gameId: state.gameId), environment: AppEnvironment())
    XCTAssertEqual(current.state.timeRemaining, 10)
  }

  func testTickAfterGameOverIsIgnored() {
    var state = GameState()
    state.gameId = UUID()
    state.gameBoard = GameBoard(size: boardSize)
    state.stateOfTheGame = .summary
    state.timeRemaining = 0

    let next = GameState.update(state: state, action: .tickTimer(5, gameId: state.gameId), environment: AppEnvironment())
    XCTAssertEqual(next.state.timeRemaining, 0)
    XCTAssertEqual(next.state.stateOfTheGame, .summary)
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
}
