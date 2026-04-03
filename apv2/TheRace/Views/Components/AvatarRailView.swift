import SwiftUI

struct AvatarRailView: View {
    let avatars: [Avatar]
    let onAddAvatar: () -> Void

    var body: some View {
        GlassPanel(padding: 12, cornerRadius: 34) {
            VStack(spacing: 12) {
                ForEach(Array(avatars.enumerated()), id: \.element.id) { index, avatar in
                    ZStack {
                        Circle()
                            .fill(avatar.isActive ? Color.white.opacity(0.92) : Color.black.opacity(0.45))
                            .overlay {
                                Circle()
                                    .stroke(avatar.isActive ? Color.blue.opacity(0.7) : Color.white.opacity(0.15), lineWidth: 1)
                            }
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(avatar.isActive ? .blue : .white.opacity(0.7))
                    }
                    .frame(width: 44, height: 44)
                    .opacity(avatar.isActive ? 1 : 0.6)
                }

                Button(action: onAddAvatar) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 68)
        .animation(.snappy, value: avatars)
    }
}
