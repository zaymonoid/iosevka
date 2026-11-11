import Foundation
import SwiftUI

struct MenuView: View {
  var dispatch: (AppAction) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var titleShown = false

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

      VStack(alignment: .leading, spacing: 14) {
        RuleRow(symbol: "hand.draw", text: "Swipe across neighbouring letters to spell a word.")
        RuleRow(symbol: "textformat.size", text: "Words need three or more letters. Longer words score far more.")
        RuleRow(symbol: "timer", text: "You have \(timeLimit / 60) minutes per round.")
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(Theme.hairline, lineWidth: 1)
      )

      Button("New Game") { dispatch(.newGame) }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, 20)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 16)
    .frame(maxWidth: 520)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background.ignoresSafeArea())
    .onAppear { titleShown = true }
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
    .font(.system(.callout, design: .rounded))
    .accessibilityElement(children: .combine)
  }
}

struct MenuView_Previews: PreviewProvider {
  static var previews: some View {
    MenuView(dispatch: { action in print("Dispatching \(action)") })
  }
}
