import AppKit
import GestureDeckCore
import UniformTypeIdentifiers

@MainActor
enum ApplicationPicker {
    static func chooseApplication() -> ApplicationTarget? {
        let panel = NSOpenPanel()
        panel.title = "Choose an application"
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        let bundle = Bundle(url: url)
        let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        return ApplicationTarget(
            name: displayName,
            path: url.path,
            bundleIdentifier: bundle?.bundleIdentifier
        )
    }
}
