import Foundation
import GestureDeckCore
import OpenMultitouchSupport

@MainActor
final class GestureService: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var activeFingerCount = 0
    @Published private(set) var status = "Trackpad listener is stopped"
    @Published private(set) var lastRecognizedGesture: String?

    var onSwipe: ((RecognizedSwipe) -> Void)?

    private let manager = OMSManager.shared
    private var streamTask: Task<Void, Never>?
    private var recognizer = SwipeRecognizer()

    func setMinimumDistance(_ distance: Float) {
        recognizer.minimumDistance = SwipeRecognitionSettings.clamped(distance)
    }

    func start() {
        guard streamTask == nil else { return }

        streamTask = Task { @MainActor [weak self, manager] in
            for await frame in manager.touchDataStream {
                guard !Task.isCancelled else { return }
                self?.consume(frame)
            }
        }

        isListening = manager.startListening()
        status = isListening
            ? "Listening for 3–5 finger swipes"
            : "No compatible Apple trackpad was found"

        if !isListening {
            streamTask?.cancel()
            streamTask = nil
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        _ = manager.stopListening()
        recognizer.reset()
        activeFingerCount = 0
        isListening = false
        status = "Trackpad listener is stopped"
    }

    private func consume(_ frame: [OMSTouchData]) {
        let active = frame.filter { touch in
            switch touch.state {
            case .making, .touching, .breaking:
                true
            case .notTouching, .starting, .hovering, .lingering, .leaving:
                false
            }
        }

        activeFingerCount = active.count
        let points = active.map {
            TouchPoint(id: $0.id, x: $0.position.x, y: $0.position.y)
        }

        if let swipe = recognizer.consume(
            touches: points,
            timestamp: ProcessInfo.processInfo.systemUptime
        ) {
            lastRecognizedGesture = "\(swipe.fingerCount)-finger \(swipe.direction.title.lowercased())"
            onSwipe?(swipe)
        }
    }
}
