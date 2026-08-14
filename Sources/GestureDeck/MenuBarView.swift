import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: BindingStore
    @ObservedObject var gestureService: GestureService
    @ObservedObject var launcher: ApplicationLauncher
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    store.isEnabled ? "GestureDeck is enabled" : "GestureDeck is paused",
                    systemImage: store.isEnabled ? "hand.draw.fill" : "pause.circle"
                )
                .font(.headline)

                Spacer()

                Toggle(
                    "",
                    isOn: Binding(
                        get: { store.isEnabled },
                        set: { enabled in store.setEnabled(enabled) }
                    )
                )
                .labelsHidden()
            }

            Divider()

            LabeledContent("Trackpad", value: gestureService.isListening ? "Listening" : "Unavailable")
                .font(.caption)

            Text(launcher.lastAction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let error = launcher.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Open GestureDeck…") {
                openSettings()
            }
            .keyboardShortcut(",")

            Button("Quit GestureDeck") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 290)
    }

    private func openSettings() {
        openWindow(id: "settings")
        NSApplication.shared.activate()
    }
}
