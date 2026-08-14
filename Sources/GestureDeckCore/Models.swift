import Foundation

public enum SwipeDirection: String, Codable, CaseIterable, Identifiable, Sendable {
    case up
    case down
    case left
    case right

    public var id: Self { self }

    public var title: String {
        rawValue.capitalized
    }

    public var symbolName: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        }
    }
}

public struct ApplicationTarget: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var bundleIdentifier: String?

    public init(name: String, path: String, bundleIdentifier: String? = nil) {
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier
    }
}

public struct GestureBinding: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var fingerCount: Int
    public var direction: SwipeDirection
    public var application: ApplicationTarget?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        fingerCount: Int = 3,
        direction: SwipeDirection = .right,
        application: ApplicationTarget? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.fingerCount = min(5, max(3, fingerCount))
        self.direction = direction
        self.application = application
        self.isEnabled = isEnabled
    }
}

public struct ShortcutBinding: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var shortcut: HotkeyShortcut?
    public var application: ApplicationTarget?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        shortcut: HotkeyShortcut? = nil,
        application: ApplicationTarget? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.shortcut = shortcut
        self.application = application
        self.isEnabled = isEnabled
    }
}

public struct HotkeyShortcut: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    public var displayKey: String

    public init(keyCode: UInt32, carbonModifiers: UInt32, displayKey: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayKey = displayKey
    }
}

public struct GestureDeckConfiguration: Codable, Equatable, Sendable {
    public var gestures: [GestureBinding]
    public var shortcuts: [ShortcutBinding]
    public var isEnabled: Bool

    public init(
        gestures: [GestureBinding] = [],
        shortcuts: [ShortcutBinding] = [],
        isEnabled: Bool = true
    ) {
        self.gestures = gestures
        self.shortcuts = shortcuts
        self.isEnabled = isEnabled
    }
}
