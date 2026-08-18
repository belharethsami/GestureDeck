import SwiftUI

struct AboutView: View {
    @ObservedObject var store: BindingStore
    @ObservedObject var launcher: ApplicationLauncher
    @ObservedObject var hotkeyService: HotkeyService
    @ObservedObject var launchAtLoginController: LaunchAtLoginController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.blue.gradient)
                            .frame(width: 76, height: 76)
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("GestureDeck")
                            .font(.largeTitle.weight(.bold))
                        Text("Focused gesture and shortcut automation for macOS")
                            .foregroundStyle(.secondary)
                        Text("Version 0.2.1 · MIT licensed")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                GroupBox("Status") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(
                            "GestureDeck is enabled",
                            isOn: Binding(
                                get: { store.isEnabled },
                                set: { enabled in store.setEnabled(enabled) }
                            )
                        )

                        LabeledContent("Last action", value: launcher.lastAction)

                        if let error = launcher.lastError
                            ?? hotkeyService.registrationError
                            ?? store.persistenceError {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Startup") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(
                            "Start GestureDeck at Login",
                            isOn: Binding(
                                get: { launchAtLoginController.isRequested },
                                set: { requested in
                                    launchAtLoginController.setRequested(requested)
                                }
                            )
                        )
                        .disabled(launchAtLoginController.isUpdating)
                        .accessibilityIdentifier("startAtLoginToggle")

                        Text(launchAtLoginController.statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if launchAtLoginController.state == .requiresApproval {
                            Button("Open Login Items Settings…") {
                                launchAtLoginController.openLoginItemSettings()
                            }
                            .controlSize(.small)
                        }

                        if let error = launchAtLoginController.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Privacy and platform notes") {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No network client, analytics, account, or cloud sync", systemImage: "network.slash")
                        Label("Application paths and mappings stay in local UserDefaults", systemImage: "internaldrive")
                        Label("Keyboard shortcuts use registered macOS hot keys—not a key logger", systemImage: "keyboard.badge.ellipsis")
                        Label("Raw global trackpad contacts use Apple's private MultitouchSupport framework", systemImage: "exclamationmark.shield")

                        Text("Because the multitouch API is private, GestureDeck is not suitable for the Mac App Store and may require maintenance after macOS updates. The trackpad implementation is isolated from configuration and action launching so it can be replaced independently.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)
                }

                HStack {
                    Link(
                        "OpenMultitouchSupport",
                        destination: URL(string: "https://github.com/Kyome22/OpenMultitouchSupport")!
                    )
                    Spacer()
                }
                .font(.caption)
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }
}
