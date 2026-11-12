import AVFoundation
import SwiftUI
import VisionKit

/// A camera sheet that reads a friend's duel invite from their QR code.
/// Calls `onInvite` once, with the first valid invite it sees.
struct InviteScannerView: View {
  var onInvite: (DuelInvite) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var access: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

  var body: some View {
    NavigationStack {
      Group {
        if !DataScannerViewController.isSupported {
          unavailable("This device can't scan codes here. Use the Camera app to scan your friend's code instead.")
        } else if access == .authorized {
          InviteScanner(onInvite: onInvite)
            .ignoresSafeArea()
        } else if access == .notDetermined {
          ProgressView()
        } else {
          unavailable("iosevka needs the camera to scan codes. Turn it on in Settings, or use the Camera app instead.")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Theme.background.ignoresSafeArea())
      .navigationTitle("Scan a friend's code")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .task {
      guard access == .notDetermined else { return }
      _ = await AVCaptureDevice.requestAccess(for: .video)
      access = AVCaptureDevice.authorizationStatus(for: .video)
    }
  }

  private func unavailable(_ message: String) -> some View {
    Text(message)
      .font(.system(.callout, design: .rounded))
      .foregroundStyle(Theme.secondaryInk)
      .multilineTextAlignment(.center)
      .padding(32)
  }
}

private struct InviteScanner: UIViewControllerRepresentable {
  var onInvite: (DuelInvite) -> Void

  func makeUIViewController(context: Context) -> DataScannerViewController {
    let scanner = DataScannerViewController(
      recognizedDataTypes: [.barcode(symbologies: [.qr])],
      isHighlightingEnabled: true
    )
    scanner.delegate = context.coordinator
    return scanner
  }

  func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
    context.coordinator.onInvite = onInvite
    if !scanner.isScanning { try? scanner.startScanning() }
  }

  static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
    scanner.stopScanning()
  }

  func makeCoordinator() -> Coordinator { Coordinator(onInvite: onInvite) }

  final class Coordinator: NSObject, DataScannerViewControllerDelegate {
    var onInvite: (DuelInvite) -> Void
    private var found = false

    init(onInvite: @escaping (DuelInvite) -> Void) { self.onInvite = onInvite }

    func dataScanner(_ scanner: DataScannerViewController, didAdd added: [RecognizedItem], allItems: [RecognizedItem]) {
      guard !found else { return }
      for item in added {
        // Codes that aren't invites, e.g. a menu or a Wi-Fi code, are ignored.
        guard case let .barcode(code) = item,
              let payload = code.payloadStringValue,
              let url = URL(string: payload),
              let invite = DuelInvite(url: url)
        else { continue }
        found = true
        scanner.stopScanning()
        onInvite(invite)
        return
      }
    }
  }
}
