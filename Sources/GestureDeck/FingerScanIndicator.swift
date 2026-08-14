import SwiftUI

struct ListenerStatusCard: View {
    let status: String
    let isListening: Bool
    let fingerCount: Int
    let lastGesture: String?

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Label(
                    status,
                    systemImage: isListening ? "wave.3.right.circle.fill" : "wave.3.right.circle"
                )
                .foregroundStyle(isListening ? .green : .secondary)
                .lineLimit(1)

                Text(lastGesture.map { "Last recognized: \($0)" } ?? "No swipe recognized yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            FingerScanIndicator(fingerCount: fingerCount)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FingerScanIndicator: View {
    let fingerCount: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: fingerCount > 0 ? "hand.point.up.left.fill" : "hand.point.up.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(fingerCount > 0 ? Color.accentColor : Color.secondary)
                .frame(width: 18, height: 18)

            HStack(spacing: 4) {
                Text("\(fingerCount)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(width: 10, alignment: .trailing)
                Text(fingerCount == 1 ? "finger" : "fingers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 104, height: 30, alignment: .leading)
        .background(.quaternary.opacity(0.7), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trackpad scan")
        .accessibilityValue("\(fingerCount) fingers detected")
    }
}
