import SwiftUI

struct MainInterfaceView: View {
    @Bindable var viewModel: TheRaceViewModel
    let onReadyToggle: () -> Void

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: viewModel.backgroundImageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()

            HStack(spacing: 28) {
                AvatarRailView(
                    avatars: viewModel.avatars,
                    onAddAvatar: viewModel.addAvatar
                )

                HStack(spacing: 0) {
                    ParameterSidebarView(viewModel: viewModel)
                    ParameterDetailView(
                        viewModel: viewModel,
                        onReadyToggle: onReadyToggle
                    )
                }
                .frame(width: 1280, height: 720)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 46, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 46, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

typealias MainParameterView = MainInterfaceView
