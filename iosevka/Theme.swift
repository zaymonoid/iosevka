import SwiftUI
import UIKit

// -- Palette -----------------------------------------------------------------
// Warm paper and ink in light mode, soft charcoal in dark. One accent (ink
// blue) for selection and actions; green / amber / red only for submission
// feedback.

private extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(uiColor: UIColor { traits in
      let hex = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
      )
    })
  }
}

enum Theme {
  static let background = Color(light: 0xF3EFE6, dark: 0x121214)
  static let surface = Color(light: 0xFFFDF8, dark: 0x1D1D21)
  static let tray = Color(light: 0xE6E0D3, dark: 0x0B0B0D)
  static let tile = Color(light: 0xFFFDF8, dark: 0x2A2A30)
  static let ink = Color(light: 0x1F1D1A, dark: 0xF2EFE8)
  static let secondaryInk = Color(light: 0x6E685E, dark: 0x9B978F)
  static let hairline = Color(light: 0xD9D2C4, dark: 0x34343B)

  static let accent = Color(light: 0x3552D1, dark: 0x8399FF)
  static let onAccent = Color(light: 0xFFFFFF, dark: 0x0E1230)

  static let valid = Color(light: 0x2E9E5B, dark: 0x3FBF73)
  static let duplicate = Color(light: 0xE0A21B, dark: 0xF0B43A)
  static let invalid = Color(light: 0xD8483B, dark: 0xF06656)

  static let warning = Color(light: 0xD9822B, dark: 0xF29B45)

  // -- Type ------------------------------------------------------------------
  static func tileLetter(size: CGFloat) -> Font {
    .system(size: size, weight: .bold, design: .rounded)
  }

  static let statValue = Font.system(.title2, design: .rounded).weight(.bold).monospacedDigit()
  static let statLabel = Font.system(.caption2, design: .rounded).weight(.semibold)
}

func submissionResultToColor(_ result: SubmissionResult) -> Color {
  switch result {
  case .invalid: return Theme.invalid
  case .duplicate: return Theme.duplicate
  case .valid: return Theme.valid
  }
}

// -- Shared pieces -----------------------------------------------------------

/// A rounded letter tile, shared by the live board, the summary board and the
/// menu title.
struct TileFace: View {
  let letter: Character
  var fill: Color = Theme.tile
  var foreground: Color = Theme.ink
  var lifted = true
  /// Corner radius as a fraction of the tile's side.
  var rounding: CGFloat = 0.22

  var body: some View {
    GeometryReader { geometry in
      let side = min(geometry.size.width, geometry.size.height)
      RoundedRectangle(cornerRadius: side * rounding, style: .continuous)
        .fill(fill)
        .shadow(color: .black.opacity(lifted ? 0.12 : 0), radius: 0, x: 0, y: side * 0.04)
        .overlay {
          Text(String(letter))
            .font(Theme.tileLetter(size: side * 0.5))
            .foregroundStyle(foreground)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}

/// A line through the centres of `cells`, in order, on a square grid of
/// `gridSize` cells a side. The boards draw it behind the tiles, so it only
/// shows in the gaps, linking the tiles of a word in order.
struct TilePath: Shape {
  let cells: [BoardCoordinate]
  let gridSize: Int

  func path(in rect: CGRect) -> Path {
    let cell = rect.width / CGFloat(gridSize)
    var path = Path()
    path.addLines(cells.map { coordinate in
      CGPoint(x: rect.minX + (CGFloat(coordinate.col) + 0.5) * cell,
              y: rect.minY + (CGFloat(coordinate.row) + 0.5) * cell)
    })
    return path
  }
}

extension TilePath {
  /// The path a shade darker than `color`, the fill of the tiles it links, so
  /// it stands apart from them where it shows between tiles.
  func trail(_ color: Color, cellSize: CGFloat) -> some View {
    let style = StrokeStyle(lineWidth: cellSize * 0.12, lineCap: .round, lineJoin: .round)
    return ZStack {
      stroke(color, style: style)
      stroke(Color.black.opacity(0.2), style: style)
    }
  }
}

/// Small uppercase label above a large rounded number.
struct StatView: View {
  let label: String
  let value: String
  var detail: String?
  var tint: Color = Theme.ink

  var body: some View {
    VStack(spacing: 2) {
      Text(label.uppercased())
        .font(Theme.statLabel)
        .tracking(1.2)
        .foregroundStyle(Theme.secondaryInk)
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text(value)
          .font(Theme.statValue)
          .foregroundStyle(tint)
          .contentTransition(.numericText())
        if let detail {
          Text(detail)
            .font(.system(.footnote, design: .rounded).weight(.semibold).monospacedDigit())
            .foregroundStyle(Theme.secondaryInk)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(detail.map { "\(value) \($0)" } ?? value)
  }
}

struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(.headline, design: .rounded))
      .foregroundStyle(Theme.onAccent)
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(Theme.accent, in: Capsule())
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .opacity(configuration.isPressed ? 0.9 : 1)
      .animation(.default.speed(3), value: configuration.isPressed)
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(.headline, design: .rounded))
      .foregroundStyle(Theme.ink)
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(Theme.surface, in: Capsule())
      .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.default.speed(3), value: configuration.isPressed)
  }
}

func formatTime(_ seconds: Int) -> String {
  String(format: "%d:%02d", seconds / 60, seconds % 60)
}
