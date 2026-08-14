import AppKit
import SwiftUI

@main
struct GestureDeckApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        Window("GestureDeck", id: "settings") {
            RootView(controller: controller)
        }
        .defaultSize(width: 900, height: 620)

        MenuBarExtra {
            MenuBarView(
                store: controller.store,
                gestureService: controller.gestureService,
                launcher: controller.launcher
            )
        } label: {
            Image(systemName: controller.store.isEnabled ? "hand.draw.fill" : "hand.draw")
                .accessibilityLabel(controller.store.isEnabled ? "GestureDeck enabled" : "GestureDeck paused")
        }
        .menuBarExtraStyle(.window)
    }
}
