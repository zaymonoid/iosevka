import Foundation

let letterFrequencies = [
  ("E", 12.70),
  ("T", 9.06),
  ("A", 8.17),
  ("O", 7.51),
  ("I", 6.97),
  ("N", 6.75),
  ("S", 6.33),
  ("H", 6.09),
  ("R", 5.99),
  ("D", 4.25),
  ("L", 4.03),
  ("C", 2.78),
  ("U", 2.76),
  ("M", 2.41),
  ("W", 2.36),
  ("F", 2.23),
  ("G", 2.02),
  ("Y", 1.97),
  ("P", 1.93),
  ("B", 1.49),
  ("V", 0.98),
  ("K", 0.77),
  ("J", 0.15),
  ("X", 0.15),
  ("Q", 0.10),
  ("Z", 0.07)
].map { ($0.0, $0.1 / 100) } // Transform percentages into proportions

var cumulativeProbability: Double = 0

let cumulativeFrequencies = letterFrequencies.map { letter, probability -> (String, Double) in
  cumulativeProbability += probability
  return (letter, cumulativeProbability)
}

func randomLetter() -> Character {
  var generator = SystemRandomNumberGenerator()
  return randomLetter(using: &generator)
}

func randomLetter(using generator: inout some RandomNumberGenerator) -> Character {
  // 53 random bits make a Double in 0..<1. Done by hand rather than with
  // Double.random(in:using:) so a seeded generator gives the same letters on
  // every Swift version.
  let randomNumber = Double(generator.next() >> 11) * 0x1p-53
  for (letter, cumProb) in cumulativeFrequencies {
    if randomNumber < cumProb {
      return Character(letter)
    }
  }

  return "#" // This line should never be reached, but is included for safety
}

struct BoardCoordinate: Equatable, Hashable { var row: Int; var col: Int }

extension BoardCoordinate {
  func withRotation(of angle: RotationAngle, inMatrixOfSize n: Int) -> BoardCoordinate {
    let coordinate = self

    switch angle {
    case .degrees0: return coordinate
    case .degrees90: return BoardCoordinate(row: n - 1 - coordinate.col, col: coordinate.row)
    case .degrees180: return BoardCoordinate(row: n - 1 - coordinate.row, col: n - 1 - coordinate.col)
    case .degrees270: return BoardCoordinate(row: coordinate.col, col: n - 1 - coordinate.row)
    }
  }
}

struct GameBoard {
  let size: Int
  public private(set) var letters: [[Character]]

  init(size: Int) {
    var generator = SystemRandomNumberGenerator()
    self.init(size: size, using: &generator)
  }

  init(size: Int, using generator: inout some RandomNumberGenerator) {
    self.size = size
    self.letters = (0..<size).map { _ in
      (0..<size).map { _ in randomLetter(using: &generator) }
    }
  }

  init(letters: [[Character]]) {
    let size = letters.count

    guard letters.allSatisfy({ row in row.count == size }) else {
      fatalError("Letters array must be square")
    }

    self.size = size
    self.letters = letters
  }

  subscript(position: BoardCoordinate) -> Character? {
    guard position.row >= 0, position.row < size else { return nil }
    guard position.col >= 0, position.col < size else { return nil }

    return letters[position.row][position.col]
  }
}

extension GameBoard {
  func neighbors(of position: BoardCoordinate) -> [BoardCoordinate] {
    let dx = [-1, -1, -1, 0, 1, 1, 1, 0]
    let dy = [-1, 0, 1, 1, 1, 0, -1, -1]

    var neighbors: [BoardCoordinate] = []

    for i in 0..<dx.count {
      let newX = position.row + dx[i]
      let newY = position.col + dy[i]

      if newX >= 0, newX < size, newY >= 0, newY < size {
        neighbors.append(BoardCoordinate(row: newX, col: newY))
      }
    }

    return neighbors
  }
}

extension GameBoard: Equatable {
  static func == (lhs: GameBoard, rhs: GameBoard) -> Bool {
    return lhs.letters == rhs.letters
  }
}

extension GameBoard {
  func rotatedBoardCoordinates(of rotation: Int) -> [[BoardCoordinate]] {
    var coordinates: [[BoardCoordinate]] = Array(repeating: [], count: size)

    for i in 0..<size {
      for j in 0..<size {
        var row = i
        var column = j

        switch rotation {
        case 90:
          (row, column) = (column, size - 1 - row)
        case 180:
          (row, column) = (size - 1 - row, size - 1 - column)
        case 270:
          (row, column) = (size - 1 - column, row)
        default:
          break
        }

        coordinates[row].append(BoardCoordinate(row: i, col: j))
      }
    }

    return coordinates
  }
}

func cardinalAngle(_ a: BoardCoordinate, _ b: BoardCoordinate) -> Double {
  let dx = Double(a.col - b.col)
  let dy = Double(a.row - b.row)

  return atan2(dy, dx)
}
