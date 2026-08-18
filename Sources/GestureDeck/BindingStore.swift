import Combine
import Foundation
import GestureDeckCore

@MainActor
final class BindingStore: ObservableObject {
    @Published private(set) var configuration: GestureDeckConfiguration
    @Published private(set) var persistenceError: String?

    var onChange: ((GestureDeckConfiguration) -> Void)?

    private let defaults: UserDefaults
    private let storageKey = "gestureDeck.configuration.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: storageKey) {
            do {
                configuration = try JSONDecoder().decode(
                    GestureDeckConfiguration.self,
                    from: data
                )
            } catch {
                configuration = GestureDeckConfiguration()
                persistenceError = "Saved settings could not be read. A fresh configuration was loaded."
            }
        } else {
            configuration = GestureDeckConfiguration()
        }
    }

    var gestures: [GestureBinding] { configuration.gestures }
    var shortcuts: [ShortcutBinding] { configuration.shortcuts }
    var isEnabled: Bool { configuration.isEnabled }
    var swipeMinimumDistance: Float { configuration.swipeMinimumDistance }

    func setEnabled(_ enabled: Bool) {
        mutate { $0.isEnabled = enabled }
    }

    func setSwipeMinimumDistance(_ distance: Float) {
        mutate {
            $0.swipeMinimumDistance = SwipeRecognitionSettings.clamped(distance)
        }
    }

    @discardableResult
    func addGesture() -> UUID {
        let occupied = Set(configuration.gestures.map {
            "\($0.fingerCount)-\($0.direction.rawValue)"
        })

        let nextCombination = (3...5).lazy.flatMap { fingerCount in
            SwipeDirection.allCases.map { (fingerCount, $0) }
        }.first { fingerCount, direction in
            !occupied.contains("\(fingerCount)-\(direction.rawValue)")
        } ?? (3, .right)

        let binding = GestureBinding(
            fingerCount: nextCombination.0,
            direction: nextCombination.1
        )
        mutate { $0.gestures.append(binding) }
        return binding.id
    }

    func updateGesture(_ binding: GestureBinding) {
        mutate { configuration in
            guard let index = configuration.gestures.firstIndex(where: { $0.id == binding.id }) else {
                return
            }
            configuration.gestures[index] = binding
        }
    }

    func removeGesture(id: UUID) {
        mutate { configuration in
            configuration.gestures.removeAll { $0.id == id }
        }
    }

    @discardableResult
    func addShortcut() -> UUID {
        let binding = ShortcutBinding()
        mutate { $0.shortcuts.append(binding) }
        return binding.id
    }

    func updateShortcut(_ binding: ShortcutBinding) {
        mutate { configuration in
            guard let index = configuration.shortcuts.firstIndex(where: { $0.id == binding.id }) else {
                return
            }
            configuration.shortcuts[index] = binding
        }
    }

    func removeShortcut(id: UUID) {
        mutate { configuration in
            configuration.shortcuts.removeAll { $0.id == id }
        }
    }

    func gestureHasConflict(_ binding: GestureBinding) -> Bool {
        configuration.gestures.contains { other in
            other.id != binding.id
                && other.isEnabled
                && binding.isEnabled
                && other.fingerCount == binding.fingerCount
                && other.direction == binding.direction
        }
    }

    private func mutate(_ change: (inout GestureDeckConfiguration) -> Void) {
        var updated = configuration
        change(&updated)
        configuration = updated
        persist()
        onChange?(updated)
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            defaults.set(try encoder.encode(configuration), forKey: storageKey)
            persistenceError = nil
        } catch {
            persistenceError = "Settings could not be saved: \(error.localizedDescription)"
        }
    }
}
