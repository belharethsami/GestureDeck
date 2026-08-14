import GestureDeckCore
import SwiftUI

struct GestureBindingRow: View {
    let binding: GestureBinding
    let hasConflict: Bool
    let update: (GestureBinding) -> Void
    let delete: () -> Void
    let testLaunch: (ApplicationTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Toggle(
                    "",
                    isOn: updating(\.isEnabled)
                )
                .labelsHidden()

                Picker("Fingers", selection: updating(\.fingerCount)) {
                    Text("3 fingers").tag(3)
                    Text("4 fingers").tag(4)
                    Text("5 fingers").tag(5)
                }
                .frame(width: 130)

                Picker("Direction", selection: updating(\.direction)) {
                    ForEach(SwipeDirection.allCases) { direction in
                        Label(direction.title, systemImage: direction.symbolName)
                            .tag(direction)
                    }
                }
                .frame(width: 150)

                Spacer()

                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete gesture")
            }

            if hasConflict {
                Label(
                    "Another enabled binding uses this same gesture. Only the first match runs.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
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
                .stroke(hasConflict ? Color.orange.opacity(0.6) : Color.secondary.opacity(0.18))
        }
        .opacity(binding.isEnabled ? 1 : 0.62)
    }

    private func updating<Value>(_ keyPath: WritableKeyPath<GestureBinding, Value>) -> Binding<Value> {
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
