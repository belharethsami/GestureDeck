import AppKit
import Combine
import Foundation
import GestureDeckCore
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var state: LaunchAtLoginState
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?

    private let service: SMAppService
    private var activationObserver: AnyCancellable?

    init(service: SMAppService = .mainApp) {
        self.service = service
        state = Self.state(for: service.status)

        activationObserver = NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    var isRequested: Bool {
        state.isRequested
    }

    func setRequested(_ requested: Bool) {
        guard !isUpdating else { return }

        isUpdating = true
        errorMessage = nil

        defer {
            refresh()
            isUpdating = false
        }

        do {
            switch state.action(toSetRequested: requested) {
            case .register:
                try service.register()
            case .unregister:
                try service.unregister()
            case .none:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() {
        state = Self.state(for: service.status)
    }

    func openLoginItemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    var statusDescription: String {
        switch state {
        case .disabled:
            "GestureDeck will remain closed after you sign in."
        case .enabled:
            "GestureDeck will start automatically after you sign in."
        case .requiresApproval:
            "GestureDeck is registered, but macOS requires approval in Login Items."
        case .unavailable:
            "GestureDeck is not registered yet. Turn this on to register it with macOS."
        }
    }

    private static func state(for status: SMAppService.Status) -> LaunchAtLoginState {
        switch status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }
}
