import SwiftUI

struct ReadyToggleButton: View {
    let title: String
    let isReady: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.96))
                .frame(width: 104, height: 44)
                .background(
                    Capsule()
                        .fill(isReady ? .red : Color(red: 0.0, green: 0.57, blue: 1.0))
                )
        }
        .buttonStyle(.plain)
    }
}
