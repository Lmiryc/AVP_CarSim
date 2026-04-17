import SwiftUI

struct ParameterSidebarView: View {
    @Bindable var viewModel: TheRaceViewModel
    let width: CGFloat
    let height: CGFloat
    @State private var showAdvanced = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Parameters")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .frame(height: 92, alignment: .bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ParameterSidebarStaticRow(title: "The Vehicle", valueText: viewModel.baseVehicleMassText)

                    ForEach(viewModel.primaryPages) { page in
                        ParameterSidebarRow(
                            page: page,
                            valueText: viewModel.formattedValue(for: page),
                            isSelected: viewModel.selectedPageID == page.id,
                            onSelect: { viewModel.selectPage(page.id) }
                        )
                    }

                    DisclosureGroup(isExpanded: $showAdvanced) {
                        VStack(spacing: 4) {
                            ForEach(viewModel.advancedPages) { page in
                                ParameterSidebarRow(
                                    page: page,
                                    valueText: viewModel.formattedValue(for: page),
                                    isSelected: viewModel.selectedPageID == page.id,
                                    onSelect: { viewModel.selectPage(page.id) }
                                )
                            }
                        }
                    } label: {
                        HStack {
                            Text("Advanced Parameters")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.96))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
        }
        .frame(width: width, height: height)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.16))
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1)
        }
    }
}
