import Combine
import Foundation
import ObservableStore
import SwiftUI

/// The board on the summary screen. Shows the path of the selected word: tiles
/// fade from the first letter to the last and carry their order number.
struct ReadOnlyBoardView: View {
  let gameBoard: GameBoard
  let selected: [BoardCoordinate]

  var body: some View {
    GeometryReader { geometry in
      let cellSize = geometry.size.width / CGFloat(gameBoard.size)

      VStack(spacing: 0) {
        ForEach(gameBoard.letters.indices, id: \.self) { row in
          HStack(spacing: 0) {
            ForEach(gameBoard.letters[row].indices, id: \.self) { col in
              let coordinate = BoardCoordinate(row: row, col: col)
              let order = selected.firstIndex(of: coordinate)

              TileFace(
                letter: gameBoard.letters[row][col],
                fill: order == nil ? Theme.tile : Theme.accent.opacity(opacity(for: order!)),
                foreground: order == nil ? Theme.ink : Theme.onAccent,
                lifted: false,
                rounding: 0.06
              )
              .background(Theme.tile, in: RoundedRectangle(cornerRadius: cellSize * 0.06, style: .continuous))
              .overlay(alignment: .topLeading) {
                if let order {
                  Text("\(order + 1)")
                    .font(.system(size: cellSize * 0.18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.onAccent.opacity(0.85))
                    .padding(cellSize * 0.07)
                }
              }
              .padding(1)
              .frame(width: cellSize, height: cellSize)
            }
          }
        }
      }
      .background {
        TilePath(cells: selected, gridSize: gameBoard.size)
          .trail(Theme.accent, cellSize: cellSize)
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.default.speed(2), value: selected)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Letter board")
    .accessibilityValue(gameBoard.letters.map { String($0) }.joined(separator: ", "))
  }

  private func opacity(for index: Int) -> Double {
    guard selected.count > 1 else { return 1 }
    return 1 - interpolate(
      value: Double(index),
      from: 0...Double(selected.count - 1),
      to: 0...0.35
    )
  }
}

struct ReadOnlyBoard_Previews: PreviewProvider {
  static var previews: some View {
    ReadOnlyBoardView(
      gameBoard: GameBoard(size: 4),
      selected: []
    )
  }
}
