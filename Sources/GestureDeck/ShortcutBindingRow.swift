import GestureDeckCore
import SwiftUI

struct ShortcutBindingRow: View {
    let binding: ShortcutBinding
    let update: (ShortcutBinding) -> Void
    let delete: () -> Void
    let testLaunch: (ApplicationTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Toggle("", isOn: updating(\.isEnabled))
                    .labelsHidden()

                Text("Keyboard shortcut")
                    .font(.headline)

                Spacer()

                HotkeyRecorder(
                    shortcut: updating(\.shortcut)
                )
                .frame(width: 150)

                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete shortcut")
            }

            ApplicationTargetView(
                target: binding.application,
                choose: chooseApplication,
                test: binding.application.map { target in
                    { testLaunch(target) }
                }
            )
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.18))
        }
        .opacity(binding.isEnabled ? 1 : 0.62)
    }

    private func updating<Value>(_ keyPath: WritableKeyPath<ShortcutBinding, Value>) -> Binding<Value> {
        Binding(
            get: { binding[keyPath: keyPath] },
            set: { value in
                var updated = binding
                updated[keyPath: keyPath] = value
                update(updated)
            }
        )
    }

    private func chooseApplication() {
        guard let target = ApplicationPicker.chooseApplication() else { return }
        var updated = binding
        updated.application = target
        update(updated)
    }
}
