import ObservableStore
import SwiftUI

enum AppAction {
  /// A single player game on a random board.
  case newGame
  case playDaily(DailyDay)
  case mainMenu
  /// Start a match and show its invite for a friend to scan.
  case hostDuel
  /// Go to the ready screen for a round: the guest scanned the host's code,
  /// the host tapped Ready once the guest had it, or a player tapped Rematch.
  case getReady(DuelRound)
  case startDuel(DuelRound)
}

enum AppState {
  case mainMenu
  case game
  case daily(DailyDay, GameBoard)
  /// The host shows the invite as a QR code for the guest to scan.
  case duelInvite(DuelInvite)
  /// Both players have the round's board, hidden until they tap Start together.
  case duelReady(DuelRound)
  case duel(DuelRound, GameBoard)
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
    case .hostDuel: appState = .duelInvite(.random())
    // A scanned invite abandons whatever was on screen, even a game in progress.
    case let .getReady(round): appState = .duelReady(round)
    case let .startDuel(round): appState = .duel(round, round.board)
    }
  }

  var body: some View {
    Group {
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
      case let .duelInvite(invite):
        DuelInviteView(invite: invite, dispatch: dispatch).fadeIn()
      case let .duelReady(round):
        DuelReadyView(round: round, dispatch: dispatch).fadeIn()
      case let .duel(round, board):
        GameView(board: board, rematch: { dispatch(.getReady(round.next)) }, dispatch: dispatch)
          .fadeIn()
      }
    }
    .onOpenURL { url in
      if let invite = DuelInvite(url: url) { dispatch(.getReady(DuelRound(firstOf: invite))) }
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView().fadeIn()
  }
}
