import GestureDeckCore
import SwiftUI

struct GesturesView: View {
    @ObservedObject var store: BindingStore
    @ObservedObject var gestureService: GestureService
    @ObservedObject var launcher: ApplicationLauncher
    let testLaunch: (ApplicationTarget, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    informationCard
                    ListenerStatusCard(
                        status: gestureService.status,
                        isListening: gestureService.isListening,
                        fingerCount: gestureService.activeFingerCount,
                        lastGesture: gestureService.lastRecognizedGesture
                    )

                    if store.gestures.isEmpty {
                        ContentUnavailableView {
                            Label("No swipe bindings", systemImage: "hand.draw")
                        } description: {
                            Text("Add a 3-, 4-, or 5-finger directional swipe and choose the app it launches.")
                        } actions: {
                            Button("Add Swipe") {
                                store.addGesture()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 260)
                    } else {
                        ForEach(store.gestures) { binding in
                            GestureBindingRow(
                                binding: binding,
                                hasConflict: store.gestureHasConflict(binding),
                                update: store.updateGesture,
                                delete: { store.removeGesture(id: binding.id) },
                                testLaunch: { target in
                                    testLaunch(
                                        target,
                                        "Test: \(binding.fingerCount)-finger \(binding.direction.title.lowercased()) swipe"
                                    )
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
                Text("Trackpad Swipes")
                    .font(.title2.weight(.semibold))
                Text("Map directional gestures to applications")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.addGesture()
            } label: {
                Label("Add Swipe", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }

    private var informationCard: some View {
        Label(
            "GestureDeck observes raw Apple trackpad contacts. macOS system gestures can still run at the same time; disable conflicting gestures in System Settings if needed.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}
