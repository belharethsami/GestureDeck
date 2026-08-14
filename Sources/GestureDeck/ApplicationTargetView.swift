import AppKit
import GestureDeckCore
import SwiftUI

struct ApplicationTargetView: View {
    let target: ApplicationTarget?
    let choose: () -> Void
    let test: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let target {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: target.path))
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(target?.name ?? "No application selected")
                    .lineLimit(1)
                Text(target?.path ?? "Choose the app to launch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if let test, target != nil {
                Button("Test", action: test)
                    .buttonStyle(.borderless)
            }

            Button(target == nil ? "Choose…" : "Change…", action: choose)
        }
        .padding(10)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }
}
