public enum LaunchAtLoginState: String, Equatable, Sendable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    public var isRequested: Bool {
        switch self {
        case .enabled, .requiresApproval:
            true
        case .disabled, .unavailable:
            false
        }
    }

    public var isEffective: Bool {
        self == .enabled
    }

    public func action(toSetRequested requested: Bool) -> LaunchAtLoginAction {
        if self == .unavailable {
            return requested ? .register : .none
        }

        return switch (isRequested, requested) {
        case (false, true):
            .register
        case (true, false):
            .unregister
        case (false, false), (true, true):
            .none
        }
    }
}

public enum LaunchAtLoginAction: Equatable, Sendable {
    case register
    case unregister
    case none
}
