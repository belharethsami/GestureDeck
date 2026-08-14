import AppKit
import Carbon.HIToolbox
import Combine
import Foundation
import GestureDeckCore

@MainActor
final class AppController: ObservableObject {
    let store: BindingStore
    let launcher: ApplicationLauncher
    let gestureService: GestureService
    let hotkeyService: HotkeyService
    private var cancellables: Set<AnyCancellable> = []
    private var diagnosticsStarted = false

    init() {
        store = BindingStore()
        launcher = ApplicationLauncher()
        gestureService = GestureService()
        hotkeyService = HotkeyService()

        store.onChange = { [weak self] configuration in
            self?.apply(configuration)
        }

        gestureService.onSwipe = { [weak self] swipe in
            self?.handle(swipe)
        }

        hotkeyService.onShortcut = { [weak self] id in
            self?.handleShortcut(id: id)
        }

        store.objectWillChange
            .merge(with: launcher.objectWillChange, gestureService.objectWillChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        hotkeyService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        apply(store.configuration)

        Task { @MainActor [weak self] in
            await self?.runStartupDiagnosticsIfRequested()
        }
    }

    func testLaunch(_ target: ApplicationTarget, source: String = "Test") {
        launcher.launch(target, source: source)
    }

    func runStartupDiagnosticsIfRequested() async {
        guard !diagnosticsStarted else { return }
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--diagnostics") else { return }

        diagnosticsStarted = true
        let duration: TimeInterval
        if arguments.indices.contains(flagIndex + 1),
           let parsed = TimeInterval(arguments[flagIndex + 1]) {
            duration = max(0.2, parsed)
        } else {
            duration = 1
        }

        if arguments.contains("--register-test-hotkey") {
            let diagnosticShortcut = ShortcutBinding(
                shortcut: HotkeyShortcut(
                    keyCode: UInt32(kVK_F12),
                    carbonModifiers: UInt32(cmdKey | optionKey | controlKey | shiftKey),
                    displayKey: "F12"
                )
            )
            hotkeyService.refresh(bindings: [diagnosticShortcut], enabled: true)
        }

        if let launchIndex = arguments.firstIndex(of: "--launch-test"),
           arguments.indices.contains(launchIndex + 1) {
            let path = arguments[launchIndex + 1]
            let url = URL(fileURLWithPath: path)
            let bundle = Bundle(url: url)
            let target = ApplicationTarget(
                name: bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? url.deletingPathExtension().lastPathComponent,
                path: path,
                bundleIdentifier: bundle?.bundleIdentifier
            )
            launcher.launch(target, source: "Launch diagnostic")
        }

        try? await Task.sleep(for: .seconds(duration))

        let report: [String: Any] = [
            "activeFingerCount": gestureService.activeFingerCount,
            "enabled": store.isEnabled,
            "hotkeyHandlerReady": hotkeyService.registrationError == nil,
            "lastAction": launcher.lastAction,
            "launchError": launcher.lastError ?? NSNull(),
            "multitouchListening": gestureService.isListening,
            "multitouchStatus": gestureService.status
        ]

        if let data = try? JSONSerialization.data(
            withJSONObject: report,
            options: [.sortedKeys]
        ) {
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        }

        NSApplication.shared.terminate(nil)
    }

    private func apply(_ configuration: GestureDeckConfiguration) {
        hotkeyService.refresh(
            bindings: configuration.shortcuts,
            enabled: configuration.isEnabled
        )

        if configuration.isEnabled {
            gestureService.start()
        } else {
            gestureService.stop()
        }
    }

    private func handle(_ swipe: RecognizedSwipe) {
        guard store.isEnabled else { return }

        guard let binding = store.gestures.first(where: {
            $0.isEnabled
                && $0.fingerCount == swipe.fingerCount
                && $0.direction == swipe.direction
                && $0.application != nil
        }), let target = binding.application else {
            return
        }

        launcher.launch(
            target,
            source: "\(swipe.fingerCount)-finger \(swipe.direction.title.lowercased()) swipe"
        )
    }

    private func handleShortcut(id: UUID) {
        guard
            store.isEnabled,
            let binding = store.shortcuts.first(where: { $0.id == id }),
            binding.isEnabled,
            let target = binding.application
        else {
            return
        }

        launcher.launch(target, source: "Keyboard shortcut")
    }
}
