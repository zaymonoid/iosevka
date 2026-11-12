import Foundation
import ObservableStore
import SwiftUI

// -- Playing -----------------------------------------------------------------

struct ScoreView: View {
  var gameState: GameState

  private var timeTint: Color {
    if gameState.timeRemaining <= 10 { return Theme.invalid }
    if gameState.timeRemaining <= 30 { return Theme.warning }
    return Theme.ink
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 0) {
        StatView(label: "Words",
                 value: "\(gameState.foundWords.count)",
                 detail: "/ \(gameState.wordLookup.count)")
        Divider().frame(height: 32).overlay(Theme.hairline)
        StatView(label: "Points",
                 value: "\(gameState.score)",
                 detail: "/ \(gameState.possibleScore)")
        Divider().frame(height: 32).overlay(Theme.hairline)
        StatView(label: "Time", value: formatTime(gameState.timeRemaining), tint: timeTint)
      }

      TimeBar(fraction: Double(gameState.timeRemaining) / Double(timeLimit), tint: timeTint)
    }
    .padding(.horizontal, 12)
    .padding(.top, 14)
    .padding(.bottom, 14)
    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(Theme.hairline, lineWidth: 1)
    )
    .animation(.default, value: gameState.score)
    .animation(.default, value: gameState.foundWords.count)
  }
}

private struct TimeBar: View {
  let fraction: Double
  let tint: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(Theme.hairline.opacity(0.6))
        Capsule()
          .fill(tint == Theme.ink ? Theme.accent : tint)
          .frame(width: max(geometry.size.height, geometry.size.width * fraction))
      }
    }
    .frame(height: 4)
    .padding(.horizontal, 8)
    .animation(.linear(duration: 1), value: fraction)
    .accessibilityHidden(true)
  }
}

/// The word being swiped, or the result of the last one.
struct SelectionView: View {
  var selection: [Character]
  var lastSubmission: Submission?

  var body: some View {
    ZStack {
      if !selection.isEmpty {
        Text(String(selection))
          .font(.system(size: 34, weight: .heavy, design: .rounded))
          .tracking(2)
          .foregroundStyle(Theme.accent)
          .transition(.opacity)
      } else if let last = lastSubmission, !last.word.isEmpty {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Text(last.word)
            .font(.system(size: 26, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(last.result == .valid ? Theme.ink : Theme.ink.opacity(0.35))
            .strikethrough(last.result == .invalid, color: Theme.invalid.opacity(0.6))
          Text(resultText(last))
            .font(.system(.callout, design: .rounded).weight(.bold))
            .foregroundStyle(submissionResultToColor(last.result))
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
      }
    }
    .lineLimit(1)
    .minimumScaleFactor(0.5)
    .frame(maxWidth: .infinity, minHeight: 48)
    .animation(.default.speed(3), value: selection.isEmpty)
  }

  private func resultText(_ submission: Submission) -> String {
    switch submission.result {
    case .valid: return "+\(scoreWord(submission.word))"
    case .duplicate: return "Already found"
    case .invalid: return submission.word.count < 3 ? "Too short" : "Not a word"
    }
  }
}

/// Wraps children onto new lines when a row is full.
struct FlowLayout: Layout {
  var spacing: CGFloat = 6

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = arrange(subviews: subviews, width: proposal.width ?? .infinity)
    let height = rows.last.map { $0.y + $0.height } ?? 0
    let width = rows.map(\.width).max() ?? 0
    return CGSize(width: proposal.width ?? width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let rows = arrange(subviews: subviews, width: bounds.width)
    for row in rows {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
    }
  }

  private struct Row { var indices: [Int] = []; var y: CGFloat = 0; var width: CGFloat = 0; var height: CGFloat = 0 }

  private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
    var rows: [Row] = [Row()]
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      if !rows[rows.count - 1].indices.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
        let last = rows[rows.count - 1]
        rows.append(Row(y: last.y + last.height + spacing))
      }
      rows[rows.count - 1].width += (rows[rows.count - 1].indices.isEmpty ? 0 : spacing) + size.width
      rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
      rows[rows.count - 1].indices.append(index)
    }
    return rows
  }
}

struct WordChip: View {
  let word: String

  var body: some View {
    HStack(spacing: 5) {
      Text(word)
        .font(.system(.subheadline, design: .rounded).weight(.bold))
        .tracking(0.6)
        .foregroundStyle(Theme.ink)
      Text("\(scoreWord(word))")
        .font(.system(.caption2, design: .rounded).weight(.bold).monospacedDigit())
        .foregroundStyle(Theme.accent)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Theme.surface, in: Capsule())
    .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(word)
    .accessibilityValue("\(scoreWord(word)) points")
  }
}

/// Words found so far, newest first.
struct FoundWordsView: View {
  let words: [String]

  var body: some View {
    ScrollView {
      FlowLayout(spacing: 6) {
        ForEach(words.reversed(), id: \.self) { word in
          WordChip(word: word)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
      }
      .padding(.vertical, 12)
      .animation(.spring(duration: 0.35, bounce: 0.3), value: words)
    }
    .scrollIndicators(.hidden)
    .mask(
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0),
          .init(color: .black, location: 0.06),
          .init(color: .black, location: 0.85),
          .init(color: .clear, location: 1),
        ],
        startPoint: .top, endPoint: .bottom
      )
    )
    .overlay {
      if words.isEmpty {
        Text("Words you find will collect here")
          .font(.system(.callout, design: .rounded))
          .foregroundStyle(Theme.secondaryInk.opacity(0.7))
      }
    }
  }
}

struct PlayingView: View {
  @ObservedObject var store: Store<GameState>

  var body: some View {
    VStack(spacing: 8) {
      Group {
        ScoreView(gameState: store.state)

        FoundWordsView(words: store.state.foundWords)
          .frame(minHeight: 60, maxHeight: .infinity)

        SelectionView(selection: store.state.selection, lastSubmission: store.state.lastSubmission)
      }
      .padding(.horizontal, 12)

      if let gameBoard = store.state.gameBoard {
        // Edge to edge: the board is the game, so it gets the full width.
        GameBoardView(
          gameBoard: gameBoard,
          selected: store.state.selectedCells,
          flashingLetters: store.state.flashingLetters,
          flashType: store.state.flashType,
          dispatch: store.send,
          rotation: store.state.rotation
        )
        .padding(1)
        .background(Theme.tray)
        .layoutPriority(1)
        .gameHaptics(selectedCount: store.state.selectedCells.count,
                     lastSubmission: store.state.lastSubmission)

        Button(action: { store.send(.rotateBoard) }) {
          Image(systemName: "rotate.right")
            .font(.system(size: 20, weight: .semibold))
            .symbolEffect(.bounce.down.byLayer, options: .speed(5), value: store.state.rotation)
            .foregroundStyle(Theme.ink)
            .frame(width: 52, height: 52)
            .background(Theme.surface, in: Circle())
            .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
        }
        .accessibilityLabel("Rotate board")
        .padding(.top, 6)
      }
    }
    .padding(.bottom, 4)
    .frame(maxWidth: 600)
  }
}

// -- Summary -----------------------------------------------------------------

struct WordRow: View {
  let word: String
  let selected: Bool
  let onTapped: (String) -> Void

  var body: some View {
    Button { onTapped(word) } label: {
      HStack {
        Text(word)
          .font(.system(.body, design: .rounded).weight(.semibold))
          .tracking(0.8)
        Spacer()
        Text("+\(scoreWord(word))")
          .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
          .foregroundStyle(selected ? Theme.onAccent : Theme.accent)
      }
      .foregroundStyle(selected ? Theme.onAccent : Theme.ink)
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(
        selected ? Theme.accent : Color.clear,
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(word)
    .accessibilityValue("\(scoreWord(word)) points")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

struct WordList: View {
  var words: [String]
  var selectedWord: String?
  var selectWord: (String) -> Void

  var body: some View {
    LazyVStack(spacing: 2) {
      ForEach(words, id: \.self) { word in
        WordRow(word: word, selected: word == selectedWord, onTapped: selectWord)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

struct WordList_Previews: PreviewProvider {
  static var previews: some View {
    WordList(words: ["ABC", "DEF", "GHI", "JKL"], selectedWord: "DEF", selectWord: { _ in })
  }
}

private func byScoreThenAlphabet(_ words: some Collection<String>) -> [String] {
  words.sorted { x, y in
    scoreWord(x) != scoreWord(y) ? scoreWord(x) > scoreWord(y) : x < y
  }
}

struct SummaryView: View {
  enum Tab: Hashable { case found, missed }

  @ObservedObject var store: Store<GameState>
  var dispatch: (AppAction) -> Void

  let foundWords: [String]
  let remainingWords: [String]
  @State var selectedWord: String?
  @State var selected: [BoardCoordinate] = []
  @State var tab: Tab

  init(store: Store<GameState>, dispatch: @escaping (AppAction) -> Void) {
    self.store = store
    self.dispatch = dispatch
    self.foundWords = byScoreThenAlphabet(store.state.foundWords)
    self.remainingWords = byScoreThenAlphabet(store.state.wordLookup.subtracting(store.state.foundWords))
    self._tab = State(initialValue: store.state.foundWords.isEmpty ? .missed : .found)
  }

  func select(word: String) {
    selectedWord = word
    selected =
      store.state.boardWords
        .filter { boardWord in word == boardWord.word }
        .randomElement()?
        .path ?? []
  }

  private var headline: String {
    guard store.state.possibleScore > 0 else { return "Time's up" }
    let ratio = Double(store.state.score) / Double(store.state.possibleScore)
    switch ratio {
    case 0: return "Time's up"
    case ..<0.15: return "Nice start"
    case ..<0.35: return "Well played"
    case ..<0.6: return "Impressive"
    default: return "Word wizard"
    }
  }

  var body: some View {
    VStack(spacing: 14) {
      VStack(spacing: 4) {
        Text(headline.uppercased())
          .font(Theme.statLabel)
          .tracking(1.5)
          .foregroundStyle(Theme.secondaryInk)
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text("\(store.state.score)")
            .font(.system(size: 56, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(Theme.ink)
          Text("of \(store.state.possibleScore) points")
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.secondaryInk)
        }
        Text("\(store.state.foundWords.count) of \(store.state.wordLookup.count) words found")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(Theme.secondaryInk)
      }
      .accessibilityElement(children: .combine)
      .padding(.top, 8)

      VStack(spacing: 8) {
        ReadOnlyBoardView(gameBoard: store.state.gameBoard!, selected: selected)
          .padding(1)
          .background(Theme.tray)
          .frame(width: 220, height: 220)

        Group {
          if let selectedWord {
            Text(selectedWord).foregroundStyle(Theme.accent)
          } else {
            Text("Tap a word to trace it").foregroundStyle(Theme.secondaryInk)
          }
        }
        .font(.system(.subheadline, design: .rounded).weight(.bold))
        .tracking(1)
        .frame(height: 20)
      }

      VStack(spacing: 8) {
        Picker("Words", selection: $tab) {
          Text("Found \(foundWords.count)").tag(Tab.found)
          Text("Missed \(remainingWords.count)").tag(Tab.missed)
        }
        .pickerStyle(.segmented)

        ScrollView {
          let words = tab == .found ? foundWords : remainingWords
          if words.isEmpty {
            Text(tab == .found ? "No words this round" : "You found every word!")
              .font(.system(.callout, design: .rounded))
              .foregroundStyle(Theme.secondaryInk)
              .padding(.top, 24)
          } else {
            WordList(words: words, selectedWord: selectedWord, selectWord: select)
              .padding(4)
          }
        }
        .scrollIndicators(.hidden)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Theme.hairline, lineWidth: 1)
        )
      }

      HStack(spacing: 12) {
        Button("Menu") { dispatch(.mainMenu) }
          .buttonStyle(SecondaryButtonStyle())
        Button("Play Again") { store.send(GameAction.appear) }
          .buttonStyle(PrimaryButtonStyle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 4)
    .frame(maxWidth: 560)
    .onAppear {
      if let best = foundWords.first ?? remainingWords.first { select(word: best) }
    }
  }
}

struct GameView: View {
  @StateObject var store = Store(
    state: GameState(),
    environment: AppEnvironment()
  )

  /// The board to start on, e.g. a duel's; nil makes a new one.
  var board: GameBoard?
  var dispatch: (AppAction) -> Void
  /// Called with the final state each time a game ends.
  var onGameOver: (GameState) -> Void = { _ in }

  var body: some View {
    Group {
      switch store.state.stateOfTheGame {
      case .playing:
        PlayingView(store: store).fadeIn()
      case .summary:
        SummaryView(store: store, dispatch: dispatch).fadeIn()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background.ignoresSafeArea())
    // Start the first game once; Play Again starts the next ones.
    .onAppear {
      guard store.state.gameBoard == nil else { return }
      store.send(board.map(GameAction.play) ?? .appear)
    }
    .onChange(of: store.state.stateOfTheGame) { _, stage in
      if stage == .summary { onGameOver(store.state) }
    }
  }
}

struct GameView_Previews: PreviewProvider {
  static var previews: some View {
    GameView(dispatch: { action in print("Dispatching \(action)") })
  }
}
