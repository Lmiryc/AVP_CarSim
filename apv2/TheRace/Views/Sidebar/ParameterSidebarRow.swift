import SwiftUI

struct ParameterSidebarRow: View {
    let page: ParameterPage
    let valueText: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(page.sidebarTitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.96))
                Spacer()
                Text(valueText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
