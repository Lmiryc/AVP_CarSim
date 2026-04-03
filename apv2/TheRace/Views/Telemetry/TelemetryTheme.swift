import SwiftUI

enum TelemetryTheme {
    static let cardBackground = Color.black.opacity(0.28)
    static let cardBorder = Color.white.opacity(0.14)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.66)

    static let speed = Color(red: 1.0, green: 0.78, blue: 0.30)
    static let throttle = Color(red: 0.42, green: 0.88, blue: 0.44)
    static let brake = Color(red: 1.0, green: 0.44, blue: 0.28)
    static let steering = Color(red: 0.84, green: 0.47, blue: 1.0)
    static let ax = Color(red: 0.32, green: 0.92, blue: 1.0)
    static let ay = Color(red: 0.69, green: 0.96, blue: 0.42)
    static let avz = Color(red: 0.58, green: 0.53, blue: 1.0)
}

struct TelemetryCardContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TelemetryTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            shape
                .fill(.regularMaterial)
                .overlay {
                    shape
                        .fill(TelemetryTheme.cardBackground)
                }
        )
        .overlay(
            shape
                .stroke(TelemetryTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(shape)
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }
}
