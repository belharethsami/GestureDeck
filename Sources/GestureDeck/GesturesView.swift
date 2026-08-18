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
                    swipeDistanceCard
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

    private var swipeDistanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Swipe Distance", systemImage: "arrow.left.and.right")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(swipeDistancePercentage)% travel")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Text("Short")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(store.swipeMinimumDistance) },
                        set: { store.setSwipeMinimumDistance(Float($0)) }
                    ),
                    in: swipeDistanceRange,
                    step: 0.01
                )
                .accessibilityLabel("Required swipe distance")
                .accessibilityValue("\(swipeDistancePercentage) percent")

                Text("Long")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("The 8% default is tuned for a shorter, macOS-like multi-finger swipe. Reduce it for lighter movement or increase it to avoid accidental triggers.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private var swipeDistanceRange: ClosedRange<Double> {
        let lowerBound = Double(SwipeRecognitionSettings.minimumAllowedDistance)
        let upperBound = Double(SwipeRecognitionSettings.maximumAllowedDistance)
        return lowerBound...upperBound
    }

    private var swipeDistancePercentage: Int {
        Int((store.swipeMinimumDistance * 100).rounded())
    }
}
