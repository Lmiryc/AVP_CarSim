import SwiftUI

struct ParameterSidebarStaticRow: View {
    let title: String
    let valueText: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.96))
            Spacer()
            Text(valueText)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
    }
}
