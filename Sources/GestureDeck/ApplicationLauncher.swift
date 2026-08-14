import AppKit
import Foundation
import GestureDeckCore

@MainActor
final class ApplicationLauncher: ObservableObject {
    @Published private(set) var lastAction = "No action triggered yet"
    @Published private(set) var lastError: String?

    func launch(_ target: ApplicationTarget, source: String) {
        let applicationURL = URL(fileURLWithPath: target.path)

        guard FileManager.default.fileExists(atPath: applicationURL.path) else {
            lastError = "\(target.name) is no longer available at \(target.path)."
            lastAction = "Failed: \(source)"
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.promptsUserIfNeeded = true

        NSWorkspace.shared.openApplication(
            at: applicationURL,
            configuration: configuration
        ) { [weak self] _, error in
            Task { @MainActor [weak self] in
                if let error {
                    self?.lastError = "Could not launch \(target.name): \(error.localizedDescription)"
                    self?.lastAction = "Failed: \(source)"
                } else {
                    self?.lastError = nil
                    self?.lastAction = "\(source) → \(target.name)"
                }
            }
        }
    }
}
