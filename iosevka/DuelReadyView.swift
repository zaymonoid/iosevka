import CoreImage.CIFilterBuiltins
import SwiftUI

// A duel starts in two steps. The host shows the invite as a QR code, and the
// guest scans it. Then both players wait on the ready screen with the board
// face down, and tap Start together. Each Rematch returns both players to the
// ready screen for the next round, with no scanning.

/// The host's invite as a QR code. Ready moves on once the guest has scanned it.
struct DuelInviteView: View {
  let invite: DuelInvite
  var dispatch: (AppAction) -> Void
  @State private var scanning = false

  var body: some View {
    DuelScreen(
      title: "Scan to join",
      hint: "Your friend scans this with their iPhone camera. Tap Ready once they have it.",
      action: "Ready",
      perform: { dispatch(.getReady(DuelRound(firstOf: invite))) },
      dispatch: dispatch
    ) {
      InviteCode(url: invite.url)
    } extra: {
      Button("Scan a friend's code instead") { scanning = true }
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .foregroundStyle(Theme.accent)
        .padding(.top, 14)
    }
    .sheet(isPresented: $scanning) {
      InviteScannerView { invite in
        scanning = false
        dispatch(.getReady(DuelRound(firstOf: invite)))
      }
    }
  }
}

/// Both players have the round's board; it stays face down until they tap
/// Start together.
struct DuelReadyView: View {
  let round: DuelRound
  var dispatch: (AppAction) -> Void

  var body: some View {
    DuelScreen(
      eyebrow: "HEAD TO HEAD · ROUND \(round.number)",
      title: "Get ready",
      hint: "Count down together and tap Start at the same time.",
      action: "Start",
      perform: { dispatch(.startDuel(round)) },
      dispatch: dispatch
    ) {
      HiddenBoard(size: boardSize)
    } extra: {
      EmptyView()
    }
  }
}

/// The layout both duel screens share: a heading, a square centrepiece, a
/// hint, and Cancel beside the screen's one action.
private struct DuelScreen<Centrepiece: View, Extra: View>: View {
  var eyebrow = "HEAD TO HEAD"
  let title: String
  let hint: String
  let action: String
  let perform: () -> Void
  var dispatch: (AppAction) -> Void
  @ViewBuilder var centrepiece: Centrepiece
  @ViewBuilder var extra: Extra

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 6) {
        Text(eyebrow)
          .font(Theme.statLabel)
          .tracking(1.5)
          .foregroundStyle(Theme.secondaryInk)
        Text(title)
          .font(.system(.largeTitle, design: .rounded).weight(.heavy))
          .foregroundStyle(Theme.ink)
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)

      centrepiece
        .frame(width: 240, height: 240)
        .padding(.top, 32)

      Text(hint)
        .font(.system(.callout, design: .rounded))
        .foregroundStyle(Theme.secondaryInk)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 24)

      extra

      Spacer()

      HStack(spacing: 12) {
        Button("Cancel") { dispatch(.mainMenu) }
          .buttonStyle(SecondaryButtonStyle())
        Button(action, action: perform)
          .buttonStyle(PrimaryButtonStyle())
      }
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 16)
    .frame(maxWidth: 520)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background.ignoresSafeArea())
  }
}

/// The invite as a QR code, always dark on white so cameras can read it in dark mode.
private struct InviteCode: View {
  let url: URL

  var body: some View {
    Group {
      if let image = Self.render(url.absoluteString) {
        Image(uiImage: image)
          .interpolation(.none)
          .resizable()
          .scaledToFit()
      } else {
        Text(url.absoluteString).font(.caption.monospaced())
      }
    }
    .padding(16)
    .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Invite code")
    .accessibilityValue(url.absoluteString)
  }

  private static func render(_ message: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(message.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage,
          let cgImage = CIContext().createCGImage(output, from: output.extent)
    else { return nil }
    return UIImage(cgImage: cgImage)
  }
}

/// A face-down board: the right number of tiles, none of the letters.
private struct HiddenBoard: View {
  let size: Int

  var body: some View {
    Grid(horizontalSpacing: 6, verticalSpacing: 6) {
      ForEach(0..<size, id: \.self) { _ in
        GridRow {
          ForEach(0..<size, id: \.self) { _ in
            TileFace(letter: "?", foreground: Theme.secondaryInk)
          }
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Hidden board")
  }
}

struct DuelReadyView_Previews: PreviewProvider {
  static var previews: some View {
    let invite = DuelInvite.random()
    DuelInviteView(invite: invite, dispatch: { print($0) })
    DuelReadyView(round: DuelRound(firstOf: invite).next, dispatch: { print($0) })
  }
}
