import ObservableStore
import SwiftUI

enum AppAction {
  /// A single player game on a random board.
  case newGame
  case playDaily(DailyDay)
  case mainMenu
}

enum AppState {
  case mainMenu
  case game
  case daily(DailyDay, GameBoard)
}

@main
struct iosevkaApp: App {
  var body: some Scene {
    WindowGroup {
      AppView()
        .tint(Theme.accent)
    }
  }
}

struct AppView: View {
  @State var appState = AppState.mainMenu
  @StateObject var dailyHistory = DailyHistoryStore()

  func dispatch(_ action: AppAction) {
    switch action {
    case .newGame: appState = AppState.game
    case .mainMenu: appState = AppState.mainMenu
    case let .playDaily(day): appState = .daily(day, Daily.board(for: day))
    }
  }

  var body: some View {
    switch appState {
    case .mainMenu: MenuView(dailyHistory: dailyHistory, dispatch: dispatch).fadeIn()
    case .game:
      GameView(dispatch: dispatch).fadeIn()
    case let .daily(day, board):
      GameView(board: board, dispatch: dispatch) { game in
        // Play Again moves on to random boards; only the daily one counts.
        guard game.gameBoard == board else { return }
        dailyHistory.record(DailyResult(day: day, game: game))
      }
      .fadeIn()
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView().fadeIn()
  }
}
