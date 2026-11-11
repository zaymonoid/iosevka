import Combine
import Foundation
import ObservableStore

struct AppEnvironment {}

// -- Domain ------------------------------------------------------------------
private let wordPoints: [Int: Int] = [
  3: 1, 4: 1, 5: 2,
  6: 3, 7: 5, 8: 8,
  9: 13, 10: 21, 11: 34,
  12: 55, 13: 89, 14: 144,
  15: 233, 16: 377, 17: 610,
  18: 987, 19: 1597, 20: 2584,
  21: 4181, 22: 6765, 23: 10946,
  24: 17711, 25: 28657, 26: 46368
]

func scoreWord(_ word: String) -> Int { wordPoints[word.count, default: 0] }

let timeLimit: Int = 60 * 3

let boardSize = 4

func calculatePossibleScore(_ words: Set<String>) -> Int {
  words.reduce(0) { acc, word in acc + scoreWord(word) }
}

enum SubmissionResult {
  case invalid
  case duplicate
  case valid
}

struct Submission: Equatable {
  let word: String
  let result: SubmissionResult
}

enum GameAction: Equatable {
  case appear
  case selectLetter(position: BoardCoordinate)
  case submitWord
  case rotateBoard
  case tickTimer(_ remainingTime: Int, gameId: UUID?)
  case flashLetters(for: SubmissionResult, letters: [BoardCoordinate])
  case clearFlashedLetters
  case gameOver
}

enum StateOfTheGame {
  case playing
  case summary
}

struct GameState: ModelProtocol {
  var gameId: UUID?
  var gameBoard: GameBoard?
  var stateOfTheGame: StateOfTheGame = .playing
  var selectedCells: [BoardCoordinate] = []
  var selection: [Character] = []
  var foundWords: [String] = []

  var boardWords: [BoardWord] = []
  var wordLookup: Set<String> = []

  var timeRemaining: Int = timeLimit

  var possibleScore: Int = 0
  var score: Int = 0

  // View Concerns
  var rotation: RotationAngle = .degrees0

  var flashingLetters: [BoardCoordinate] = []
  var flashType = SubmissionResult.invalid
  var lastSubmission: Submission?

  static func update(
    state: GameState,
    action: GameAction,
    environment: AppEnvironment
  ) -> Update<GameState> {
    print(action)

    guard state.gameBoard != nil || (state.gameBoard == nil && (action == GameAction.appear)) else {
      print("BOARD NOT INITIALISED! Can't handle \(action)")
      return Update(state: state)
    }

    switch action {
    case .appear:
      var draft = state

      draft.gameId = UUID()

      let (board, boardWords) = mkGameBoard(size: boardSize)
      draft.gameBoard = board

      draft.stateOfTheGame = .playing

      draft.selectedCells = []
      draft.selection = []
      draft.foundWords = []

      draft.boardWords = boardWords
      draft.wordLookup = Set(boardWords.map { boardWord in boardWord.word })

      draft.possibleScore = calculatePossibleScore(draft.wordLookup)
      draft.score = 0
      draft.lastSubmission = nil
      draft.flashingLetters = []

      // Start the timer ticking
      return update(state: draft, action: .tickTimer(timeLimit, gameId: draft.gameId), environment: environment)

    case let .selectLetter(position):
      var draft = state

      let position = position.withRotation(of: draft.rotation, inMatrixOfSize: draft.gameBoard!.size)

      // Check that the new position is a neighbour of the last selection
      guard let lastPosition = draft.selectedCells.last else {
        draft.selectedCells.append(position)
        draft.selection.append(draft.gameBoard![position] ?? "?")
        return Update(state: draft)
      }

      let neighbours = draft.gameBoard!.neighbors(of: lastPosition)

      guard neighbours.contains(position) else { return Update(state: draft) }

      draft.selectedCells.append(position)
      draft.selection.append(draft.gameBoard![position] ?? "?")

      return Update(state: draft)

    case .submitWord:
      var draft = state
      var actions = [] as [GameAction]

      // Convert selected cells to a word and add to submittedWords
      let word = draft.selectedCells.reduce("") { word, position in
        word + String(draft.gameBoard![position]!)
      }

      let result: SubmissionResult
      if draft.foundWords.contains(word) {
        result = .duplicate
      } else if !draft.wordLookup.contains(word) {
        result = .invalid
      } else {
        result = .valid
        draft.foundWords.append(word)
        draft.score += wordPoints[word.count] ?? 0
      }
      actions.append(.flashLetters(for: result, letters: draft.selectedCells))
      draft.lastSubmission = Submission(word: word, result: result)

      draft.selectedCells = []
      draft.selection = []

      return update(state: draft, actions: actions, environment: environment).animation(.default.speed(5))

    case let .flashLetters(for: result, letters: letters):
      var draft = state

      draft.flashingLetters = letters
      draft.flashType = result

      let fx: Fx<GameAction> = Future.detached {
        try await Task.sleep(nanoseconds: 1000000000 / 9)
        return GameAction.clearFlashedLetters
      }.catch { _ in Empty() }.eraseToAnyPublisher()

      return Update(state: draft, fx: fx).animation(.default.speed(5))

    case .clearFlashedLetters:
      var draft = state
      draft.flashingLetters = []
      return Update(state: draft).animation(.default.speed(3))

    case .rotateBoard:
      var draft = state

      // Don't rotate in the middle of selecting a word or flashing
      guard draft.selectedCells.isEmpty && draft.flashingLetters.isEmpty
      else { return Update(state: state) }

      draft.rotation = nextRotation(of: draft.rotation)

      return Update(state: draft)

    case let .tickTimer(timeRemaining, gameId):
      // Each game runs its own tick chain; drop ticks from an earlier game.
      guard gameId == state.gameId, state.stateOfTheGame == .playing
      else { return Update(state: state) }

      var draft = state

      draft.timeRemaining = timeRemaining

      if draft.timeRemaining == 0 {
        return update(state: draft, action: .gameOver, environment: environment)

      } else {
        let fx: Fx<GameAction> = Future.detached {
          try await Task.sleep(nanoseconds: 1000000000)

          return .tickTimer(draft.timeRemaining - 1, gameId: draft.gameId)
        }.catch { _ in Empty() }.eraseToAnyPublisher()

        return Update(state: draft, fx: fx)
      }

    case .gameOver:
      var draft = state

      draft.stateOfTheGame = .summary

      return Update(state: draft)
    }
  }
}
