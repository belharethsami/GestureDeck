import AppKit
import Carbon.HIToolbox
import GestureDeckCore
import SwiftUI

struct HotkeyRecorder: NSViewRepresentable {
    @Binding var shortcut: HotkeyShortcut?

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.onChange = { shortcut = $0 }
        return button
    }

    func updateNSView(_ button: RecorderButton, context: Context) {
        button.shortcut = shortcut
        button.updateTitle()
    }
}

final class RecorderButton: NSButton {
    var shortcut: HotkeyShortcut?
    var onChange: ((HotkeyShortcut?) -> Void)?

    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        setButtonType(.momentaryPushIn)
        updateTitle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        title = "Type shortcut…"
        window?.makeFirstResponder(self)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        updateTitle()
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == UInt16(kVK_Escape) {
            window?.makeFirstResponder(nil)
            return
        }

        if event.keyCode == UInt16(kVK_Delete) || event.keyCode == UInt16(kVK_ForwardDelete) {
            shortcut = nil
            onChange?(nil)
            window?.makeFirstResponder(nil)
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let carbonModifiers = Self.carbonModifiers(from: modifiers)

        guard carbonModifiers != 0 else {
            NSSound.beep()
            title = "Add a modifier"
            return
        }

        let recorded = HotkeyShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonModifiers,
            displayKey: Self.displayKey(for: event)
        )
        shortcut = recorded
        onChange?(recorded)
        window?.makeFirstResponder(nil)
    }

    func updateTitle() {
        guard !isRecording else { return }
        title = shortcut.map(Self.displayString) ?? "Record Shortcut"
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }

    private static func displayString(_ shortcut: HotkeyShortcut) -> String {
        var result = ""
        if shortcut.carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if shortcut.carbonModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if shortcut.carbonModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if shortcut.carbonModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + shortcut.displayKey
    }

    private static func displayKey(for event: NSEvent) -> String {
        let specialKeys: [UInt16: String] = [
            UInt16(kVK_Return): "↩",
            UInt16(kVK_Tab): "⇥",
            UInt16(kVK_Space): "Space",
            UInt16(kVK_Delete): "⌫",
            UInt16(kVK_ForwardDelete): "⌦",
            UInt16(kVK_LeftArrow): "←",
            UInt16(kVK_RightArrow): "→",
            UInt16(kVK_UpArrow): "↑",
            UInt16(kVK_DownArrow): "↓",
            UInt16(kVK_Home): "↖",
            UInt16(kVK_End): "↘",
            UInt16(kVK_PageUp): "⇞",
            UInt16(kVK_PageDown): "⇟",
            UInt16(kVK_F1): "F1",
            UInt16(kVK_F2): "F2",
            UInt16(kVK_F3): "F3",
            UInt16(kVK_F4): "F4",
            UInt16(kVK_F5): "F5",
            UInt16(kVK_F6): "F6",
            UInt16(kVK_F7): "F7",
            UInt16(kVK_F8): "F8",
            UInt16(kVK_F9): "F9",
            UInt16(kVK_F10): "F10",
            UInt16(kVK_F11): "F11",
            UInt16(kVK_F12): "F12"
        ]

        return specialKeys[event.keyCode]
            ?? event.charactersIgnoringModifiers?.uppercased()
            ?? "Key \(event.keyCode)"
    }
}
