import Carbon.HIToolbox
import Foundation
import GestureDeckCore

@MainActor
final class HotkeyService: ObservableObject {
    @Published private(set) var registrationError: String?

    var onShortcut: ((UUID) -> Void)?

    private nonisolated static let signature: OSType = 0x4744_454B // "GDEK"
    private var handlerRef: EventHandlerRef?
    private var registrations: [UUID: EventHotKeyRef] = [:]
    private var ids: [UInt32: UUID] = [:]
    private var nextID: UInt32 = 1

    init() {
        installEventHandler()
    }

    func refresh(bindings: [ShortcutBinding], enabled: Bool) {
        unregisterAll()
        registrationError = nil

        guard enabled else { return }

        for binding in bindings where binding.isEnabled {
            guard let shortcut = binding.shortcut else { continue }
            register(shortcut, bindingID: binding.id)
        }
    }

    func stop() {
        unregisterAll()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotkeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return service.handle(event)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )

        if status != noErr {
            registrationError = "The macOS hot-key event handler could not start (status \(status))."
        }
    }

    private func register(_ shortcut: HotkeyShortcut, bindingID: UUID) {
        let numericID = nextID
        nextID &+= 1
        let hotkeyID = EventHotKeyID(signature: Self.signature, id: numericID)
        var reference: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference else {
            registrationError = "One or more shortcuts conflict with a macOS or application shortcut (status \(status))."
            return
        }

        registrations[bindingID] = reference
        ids[numericID] = bindingID
    }

    private func unregisterAll() {
        registrations.values.forEach { UnregisterEventHotKey($0) }
        registrations.removeAll()
        ids.removeAll()
    }

    private nonisolated func handle(_ event: EventRef) -> OSStatus {
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr, hotkeyID.signature == Self.signature else {
            return OSStatus(eventNotHandledErr)
        }

        let numericID = hotkeyID.id
        Task { @MainActor [weak self] in
            guard let bindingID = self?.ids[numericID] else { return }
            self?.onShortcut?(bindingID)
        }
        return noErr
    }
}
