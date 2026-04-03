import SwiftUI

struct ParameterControlAreaView: View {
    @Bindable var viewModel: TheRaceViewModel

    var body: some View {
        let page = viewModel.selectedPage

        VStack(alignment: .leading, spacing: 12) {
            if page.type == .slider,
               let min = page.minValue,
               let max = page.maxValue,
               let step = page.step {
                let binding = viewModel.sliderBinding(for: page.id)
                let range = min...max
                let currentValueText = viewModel.formattedValue(for: page)

                HStack {
                    Text("Current: \(currentValueText)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.bottom, 2)

                HStack {
                    Text(formatValue(range.lowerBound, unit: page.unit, step: step))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Slider(value: binding, in: range, step: step)
                        .tint(.white.opacity(0.85))
                    Spacer()
                    Text(formatValue(range.upperBound, unit: page.unit, step: step))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                }
                .frame(height: 20)

                Text(page.sliderHint)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                    Spacer()
                    Toggle("", isOn: $viewModel.absEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Text(viewModel.absEnabled ? "ABS is ON" : "ABS is OFF")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func formatValue(_ value: Double, unit: String, step: Double) -> String {
        let text: String
        if step >= 1 {
            text = String(format: "%.0f", value)
        } else if step >= 0.01 {
            text = String(format: "%.2f", value)
        } else {
            text = String(format: "%.3f", value)
        }
        return unit.isEmpty ? text : "\(text) \(unit)"
    }
}
