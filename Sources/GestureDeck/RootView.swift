import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case gestures
    case shortcuts
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .gestures: "Trackpad Swipes"
        case .shortcuts: "Keyboard Shortcuts"
        case .about: "General & About"
        }
    }

    var symbolName: String {
        switch self {
        case .gestures: "hand.draw"
        case .shortcuts: "keyboard"
        case .about: "gearshape"
        }
    }
}

struct RootView: View {
    @ObservedObject var controller: AppController
    @State private var selection: SettingsSection? = .gestures

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.symbolName)
                    .tag(section)
            }
            .navigationTitle("GestureDeck")
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
        } detail: {
            switch selection ?? .gestures {
            case .gestures:
                GesturesView(
                    store: controller.store,
                    gestureService: controller.gestureService,
                    launcher: controller.launcher,
                    testLaunch: { target, source in
                        controller.testLaunch(target, source: source)
                    }
                )
            case .shortcuts:
                ShortcutsView(
                    store: controller.store,
                    testLaunch: { target, source in
                        controller.testLaunch(target, source: source)
                    }
                )
            case .about:
                AboutView(
                    store: controller.store,
                    launcher: controller.launcher,
                    hotkeyService: controller.hotkeyService,
                    launchAtLoginController: controller.launchAtLoginController
                )
            }
        }
        .frame(minWidth: 760, minHeight: 540)
    }
}
