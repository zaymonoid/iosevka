import Foundation
import SwiftUI

struct MenuView: View {
  @ObservedObject var dailyHistory: DailyHistoryStore
  var dispatch: (AppAction) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var titleShown = false
  @State private var showingRules = false

  private let title = Array("IOSEVKA")
  private let tilts: [Double] = [-4, 3, -2, 4, -3, 2, -4]

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      HStack(spacing: 6) {
        ForEach(title.indices, id: \.self) { index in
          TileFace(letter: title[index])
            .frame(width: 42, height: 42)
            .rotationEffect(.degrees(titleShown ? tilts[index] : 0))
            .offset(y: titleShown ? 0 : 12)
            .opacity(titleShown ? 1 : 0)
            .animation(
              reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.4).delay(Double(index) * 0.05),
              value: titleShown
            )
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Iosevka")
      .accessibilityAddTraits(.isHeader)

      Text("Find words. Beat the clock.")
        .font(.system(.title3, design: .rounded).weight(.medium))
        .foregroundStyle(Theme.secondaryInk)
        .padding(.top, 20)

      Spacer()

      // Re-render each minute so the countdown ticks and the board turns over
      // at midnight.
      TimelineView(.everyMinute) { context in
        let today = DailyDay(containing: context.date)
        DailyCard(
          today: today,
          now: context.date,
          result: dailyHistory.history.result(for: today),
          streak: dailyHistory.history.streak(today: today),
          play: { dispatch(.playDaily(today)) }
        )
      }

      Button("Single Player") { dispatch(.newGame) }
        .buttonStyle(SecondaryButtonStyle())
        .padding(.top, 12)

      Button("How to play") { showingRules = true }
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .foregroundStyle(Theme.accent)
        .padding(.top, 14)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 8)
    .frame(maxWidth: 520)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background.ignoresSafeArea())
    .onAppear { titleShown = true }
    .sheet(isPresented: $showingRules) {
      RulesSheet()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
  }
}

// -- Daily card --------------------------------------------------------------

private struct DailyCard: View {
  let today: DailyDay
  let now: Date
  let result: DailyResult?
  let streak: Int
  let play: () -> Void

  /// Today's letters, shown once it's been played. Made off the main thread:
  /// generating a board runs the solver.
  @State private var board: GameBoard?

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .firstTextBaseline) {
        Text("DAILY #\(today.number)")
          .font(Theme.statLabel)
          .tracking(1.2)
          .foregroundStyle(Theme.accent)
        Spacer()
        if streak > 0 {
          Label("\(streak) day\(streak == 1 ? "" : "s")", systemImage: "flame.fill")
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.warning)
            .accessibilityLabel("Streak")
            .accessibilityValue("\(streak) day\(streak == 1 ? "" : "s")")
        }
      }

      HStack(spacing: 16) {
        MiniBoard(board: result == nil ? nil : board, coverage: result?.coverage)
          .frame(width: 76, height: 76)

        VStack(alignment: .leading, spacing: 4) {
          if let result {
            Text("\(result.score) of \(result.possibleScore) points")
              .font(.system(.headline, design: .rounded))
              .foregroundStyle(Theme.ink)
            Text("\(result.wordsFound) of \(result.totalWords) words")
              .font(.system(.subheadline, design: .rounded))
              .foregroundStyle(Theme.secondaryInk)
          } else {
            Text("Today's board")
              .font(.system(.headline, design: .rounded))
              .foregroundStyle(Theme.ink)
            Text("The same letters for everyone. One go.")
              .font(.system(.subheadline, design: .rounded))
              .foregroundStyle(Theme.secondaryInk)
              .fixedSize(horizontal: false, vertical: true)
          }
          Text("\(result == nil ? "Ends" : "Next board") in \(countdown)")
            .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
            .foregroundStyle(Theme.secondaryInk)
            .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
        Spacer(minLength: 0)
      }

      if let result {
        ShareLink(item: result.shareText) {
          Label("Share Result", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(PrimaryButtonStyle())
      } else {
        Button("Play Today's Board", action: play)
          .buttonStyle(PrimaryButtonStyle())
      }
    }
    .padding(16)
    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(Theme.hairline, lineWidth: 1)
    )
    .task(id: today) {
      board = nil
      let day = today
      board = await Task.detached(priority: .userInitiated) { Daily.board(for: day) }.value
    }
  }

  private var countdown: String {
    let minutes = max(1, Int(today.end().timeIntervalSince(now) / 60))
    return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
  }
}

/// A small board: face down before playing, then the letters with the tiles
/// your words used picked out.
private struct MiniBoard: View {
  let board: GameBoard?
  let coverage: [Bool]?

  var body: some View {
    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
      ForEach(0..<boardSize, id: \.self) { row in
        GridRow {
          ForEach(0..<boardSize, id: \.self) { col in
            let used = coverage?[row * boardSize + col] ?? false
            TileFace(
              letter: board?.letters[row][col] ?? (coverage == nil ? "?" : " "),
              fill: used ? Theme.accent : Theme.tile,
              foreground: used ? Theme.onAccent : (board == nil ? Theme.secondaryInk : Theme.ink),
              lifted: false,
              rounding: 0.18
            )
          }
        }
      }
    }
    .padding(4)
    .background(Theme.tray, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    .animation(.default, value: board)
    .accessibilityHidden(true)
  }
}

// -- Rules -------------------------------------------------------------------

private struct RulesSheet: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("How to play")
        .font(.system(.title2, design: .rounded).weight(.bold))
        .foregroundStyle(Theme.ink)
        .accessibilityAddTraits(.isHeader)
      RuleRow(symbol: "hand.draw", text: "Swipe across neighbouring letters to spell a word.")
      RuleRow(symbol: "textformat.size", text: "Words need three or more letters. Longer words score far more.")
      RuleRow(symbol: "timer", text: "You have \(timeLimit / 60) minutes per round.")
      RuleRow(symbol: "calendar", text: "The daily board is the same for everyone and changes at midnight. Single player boards are new every game.")
      Spacer(minLength: 0)
    }
    .padding(24)
    .padding(.top, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Theme.background.ignoresSafeArea())
  }
}

private struct RuleRow: View {
  let symbol: String
  let text: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Image(systemName: symbol)
        .foregroundStyle(Theme.accent)
        .frame(width: 24)
      Text(text)
        .foregroundStyle(Theme.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.system(.body, design: .rounded))
    .accessibilityElement(children: .combine)
  }
}

struct MenuView_Previews: PreviewProvider {
  static var previews: some View {
    MenuView(dailyHistory: DailyHistoryStore(), dispatch: { action in print("Dispatching \(action)") })
  }
}
