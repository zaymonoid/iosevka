import Combine
import Foundation
import ObservableStore
import SwiftUI

struct GameBoardView: View {
  let gameBoard: GameBoard
  let selected: [BoardCoordinate]
  let flashingLetters: [BoardCoordinate]
  let flashType: SubmissionResult
  let dispatch: GameDispatch
  let rotation: RotationAngle

  @State var swipeState: SwipeState
  @State var isDragging = false

  init(gameBoard: GameBoard,
       selected: [BoardCoordinate],
       flashingLetters: [BoardCoordinate],
       flashType: SubmissionResult,
       dispatch: @escaping GameDispatch,
       rotation: RotationAngle)
  {
    self.gameBoard = gameBoard
    self.selected = selected
    self.flashingLetters = flashingLetters
    self.flashType = flashType
    self.dispatch = dispatch
    self.swipeState = SwipeState(gameBoard: gameBoard, dispatch: dispatch)
    self.rotation = rotation
  }

  var body: some View {
    // The gesture maps touches to cells by dividing the grid evenly, so every
    // cell keeps an equal frame; the gap between tiles is drawn inside it.
    GeometryReader { geometry in
      let cellSize = geometry.size.width / CGFloat(gameBoard.size)

      VStack(spacing: 0) {
        ForEach(gameBoard.letters.indices, id: \.self) { row in
          HStack(spacing: 0) {
            ForEach(gameBoard.letters[row].indices, id: \.self) { col in
              let coord =
                BoardCoordinate(row: row, col: col)
                  .withRotation(of: rotation, inMatrixOfSize: gameBoard.size)

              CellView(letter: gameBoard.letters[coord.row][coord.col],
                       selected: selected.contains(coord),
                       flashing: flashingLetters.contains(coord),
                       flashType: flashType)
                .padding(1)
                .frame(width: cellSize, height: cellSize)
            }
          }
        }
      }
      .contentShape(Rectangle())
      .onAppear { swipeState.send(.appear(geometry.size)) }
      .gesture(
        DragGesture()
          .onChanged { value in
            if !isDragging {
              isDragging = true
              swipeState.send(.dragStart(value.startLocation))
            }
            swipeState.send(.positionUpdated(value.location))
          }
          .onEnded { value in
            swipeState.send(.dragStop(value.location))
            isDragging = false
          }
      )
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Letter board")
    .accessibilityValue(
      (0..<gameBoard.size).map { row in
        String((0..<gameBoard.size).map { col in
          let coord = BoardCoordinate(row: row, col: col)
            .withRotation(of: rotation, inMatrixOfSize: gameBoard.size)
          return gameBoard.letters[coord.row][coord.col]
        })
      }.joined(separator: ", ")
    )
  }
}

struct CellView: View {
  let letter: Character
  let selected: Bool
  let flashing: Bool
  let flashType: SubmissionResult

  var fill: Color {
    if flashing { return submissionResultToColor(flashType) }
    if selected { return Theme.accent }
    return Theme.tile
  }

  var body: some View {
    TileFace(
      letter: letter,
      fill: fill,
      foreground: flashing || selected ? Theme.onAccent : Theme.ink,
      lifted: false,
      rounding: 0.06
    )
  }
}
