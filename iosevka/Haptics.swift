import SwiftUI

/// The game's haptic scheme, kept in one place so it can be dialled in by feel.
///
/// - A crisp click each time the swipe picks up a tile.
/// - A firmer bump when a word is accepted. Misses and duplicates stay silent.
enum Haptics {
  /// Feedback when a tile joins the selection, or nil to switch it off.
  /// Lighter weights barely register on device; rigid at full intensity reads as a crisp click.
  static let tileSelected: SensoryFeedback? = .impact(flexibility: .rigid, intensity: 1.0)

  /// Feedback when a submitted word is valid.
  static let wordAccepted: SensoryFeedback? = .success
}

extension View {
  func gameHaptics(selectedCount: Int, lastSubmission: Submission?) -> some View {
    self
      .sensoryFeedback(trigger: selectedCount) { old, new in
        new > old ? Haptics.tileSelected : nil
      }
      .sensoryFeedback(trigger: lastSubmission) { _, new in
        new?.result == .valid ? Haptics.wordAccepted : nil
      }
  }
}
