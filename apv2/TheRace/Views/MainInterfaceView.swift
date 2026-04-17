import SwiftUI

struct MainInterfaceView: View {
    @Bindable var viewModel: TheRaceViewModel
    let onReadyToggle: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let outerPaddingH: CGFloat = 24
            let outerPaddingV: CGFloat = 20
            let railWidth: CGFloat = 68
            let railGap: CGFloat = 28
            let minPanelWidth: CGFloat = 980
            let maxPanelWidth: CGFloat = 1280
            let panelHeight: CGFloat = min(720, proxy.size.height - outerPaddingV * 2)
            let availablePanelWidth = proxy.size.width - outerPaddingH * 2 - railWidth - railGap
            let panelWidth = min(maxPanelWidth, max(minPanelWidth, availablePanelWidth))
            let sidebarWidth = min(320, max(280, panelWidth * 0.25))
            let detailWidth = panelWidth - sidebarWidth
            let panelShape = RoundedRectangle(cornerRadius: 46, style: .continuous)

            ZStack {
                AsyncImage(url: URL(string: viewModel.backgroundImageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .ignoresSafeArea()

                HStack(spacing: 28) {
                    AvatarRailView(
                        avatars: viewModel.avatars,
                        onAddAvatar: viewModel.addAvatar
                    )

                    HStack(spacing: 0) {
                        ParameterSidebarView(
                            viewModel: viewModel,
                            width: sidebarWidth,
                            height: panelHeight
                        )
                        ParameterDetailView(
                            viewModel: viewModel,
                            onReadyToggle: onReadyToggle,
                            width: detailWidth,
                            height: panelHeight
                        )
                    }
                    .frame(width: panelWidth, height: panelHeight)
                    .background(.regularMaterial, in: panelShape)
                    .clipShape(panelShape)
                }
                .padding(.horizontal, outerPaddingH)
                .padding(.vertical, outerPaddingV)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

typealias MainParameterView = MainInterfaceView
