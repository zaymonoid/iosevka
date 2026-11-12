import Foundation

let minimumWordLength = 3

struct BoardWord: Equatable {
  let word: String
  let path: [BoardCoordinate]
}

class Solver {
  public static var shared = Solver()
  let trie: Trie
    
  init() {
    #if SWIFT_PACKAGE
    // AppLogic's tests run outside the app, so the dictionary is a package resource.
    let bundle = Bundle.module
    #else
    let bundle = Bundle.main
    #endif

    guard let dictionaryURL = bundle.url(forResource: "dictionary", withExtension: "txt") else {
      fatalError("Couldn't find dictionary.txt in the bundle")
    }
    
    let dictionary = try! String(contentsOf: dictionaryURL)
    trie = Trie()
    
    let words = dictionary
      .split(separator: "\n")
      .filter { $0.count >= minimumWordLength }
    
    for word in words { trie.insert(word: String(word)) }
  }
    
  func findAllWords(board: GameBoard) -> [BoardWord] {
    var validWords: [BoardWord] = []
    
    for x in 0..<board.size {
      for y in 0..<board.size {
        search(board: board, x: x, y: y, validWords: &validWords, path: [])
      }
    }
    
    return validWords.sorted(by: { a, b in a.word < b.word })
  }
    
  private func search(board: GameBoard, x: Int, y: Int, validWords: inout [BoardWord], path: [BoardCoordinate]) {
    var visited = Array(repeating: Array(repeating: false, count: board.size), count: board.size)
    var currentWord = ""
    
    func dfs(x: Int, y: Int, path: [BoardCoordinate]) {
      guard x >= 0, x < board.size, y >= 0, y < board.size else { return }
      guard !visited[x][y] else { return }
      
      let coordinate = BoardCoordinate(row: x, col: y)
      
      if let letter = board[coordinate] {
        let newWord = currentWord + String(letter)
        
        if trie.contains(word: newWord) {
          validWords.append(BoardWord(word: newWord, path: path + [coordinate]))
        }
        
        if !trie.isPrefix(word: newWord) {
          return
        }
        
        visited[x][y] = true
        let previousWord = currentWord
        currentWord = newWord
                
        let adjacentPositions = board.neighbors(of: coordinate)
        
        for pos in adjacentPositions {
          dfs(x: pos.row, y: pos.col, path: path + [coordinate])
        }
                
        visited[x][y] = false
        currentWord = previousWord
      }
    }
    
    dfs(x: x, y: y, path: path)
  }
}

extension Solver: Equatable {
  static func == (lhs: Solver, rhs: Solver) -> Bool {
    return lhs.trie.size == rhs.trie.size
  }
}
