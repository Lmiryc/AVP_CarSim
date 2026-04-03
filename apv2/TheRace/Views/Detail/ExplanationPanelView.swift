import SwiftUI

struct ExplanationPanelView: View {
    let page: ParameterPage

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("What is \(page.title)?")
                    .font(.headline)
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(width: 260, height: 640, alignment: .topLeading)
        }
    }
}
