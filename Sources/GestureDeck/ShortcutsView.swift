import GestureDeckCore
import SwiftUI

struct ShortcutsView: View {
    @ObservedObject var store: BindingStore
    let testLaunch: (ApplicationTarget, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    infoCard

                    if store.shortcuts.isEmpty {
                        ContentUnavailableView {
                            Label("No keyboard shortcuts", systemImage: "keyboard")
                        } description: {
                            Text("Record a global shortcut and choose the app it launches.")
                        } actions: {
                            Button("Add Shortcut") {
                                store.addShortcut()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 260)
                    } else {
                        ForEach(store.shortcuts) { binding in
                            ShortcutBindingRow(
                                binding: binding,
                                update: store.updateShortcut,
                                delete: { store.removeShortcut(id: binding.id) },
                                testLaunch: { target in
                                    testLaunch(target, "Test: keyboard shortcut")
                                }
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Keyboard Shortcuts")
                    .font(.title2.weight(.semibold))
                Text("Launch applications from anywhere")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.addShortcut()
            } label: {
                Label("Add Shortcut", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }

    private var infoCard: some View {
        Label(
            "Click the recorder, press your desired key combination, then choose an application. Global shortcuts use the macOS hot-key service and do not record typed text.",
            systemImage: "lock.shield"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
