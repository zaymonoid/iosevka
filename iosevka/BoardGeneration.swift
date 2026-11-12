//
//  BoardGeneration.swift
//  iosevka
//
//  Created by Zaymon Foulds-Cook on 19/10/2023.
//

import Foundation

func coordinateSquare(size: Int) -> Set<BoardCoordinate> {
  Set((0..<size).flatMap { row in
    (0..<size).map { col in
      BoardCoordinate(row: row, col: col)
    }
  })
}

func mkGameBoard(size: Int) -> (GameBoard, [BoardWord]) {
  var generator = SystemRandomNumberGenerator()
  return mkGameBoard(size: size, using: &generator)
}

/// Makes a board, then swaps out up to five letters that no word passes
/// through. The same seeded generator gives the same board.
func mkGameBoard(size: Int, using generator: inout some RandomNumberGenerator) -> (GameBoard, [BoardWord]) {
  let coordinates = coordinateSquare(size: size)

  var board = GameBoard(size: size, using: &generator)
  var boardWords = Solver.shared.findAllWords(board: board)
  var usedPositions = Set(boardWords.flatMap { x in x.path })
  var unusedPositions = coordinates.subtracting(usedPositions)

  var attempts = 0

  while unusedPositions.count != 0, attempts < 5 {
    // The first in reading order, not Set.first, whose order changes per run.
    let pos = unusedPositions.min { ($0.row, $0.col) < ($1.row, $1.col) }!

    let newLetter = randomLetter(using: &generator)

    var letters = board.letters
    letters[pos.row][pos.col] = newLetter

    board = GameBoard(letters: letters)
    boardWords = Solver.shared.findAllWords(board: board)
    usedPositions = Set(boardWords.flatMap { x in x.path })
    unusedPositions = coordinates.subtracting(usedPositions)

    attempts += 1
  }

  return (board, boardWords)
}
