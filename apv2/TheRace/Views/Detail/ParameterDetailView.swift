import SwiftUI

struct ParameterDetailView: View {
    @Bindable var viewModel: TheRaceViewModel
    let onReadyToggle: () -> Void
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let contentHorizontalPadding: CGFloat = 24
        let contentSpacing: CGFloat = 12
        let descriptionWidth = min(260, max(220, width * 0.27))
        let imageWidth = max(360, width - contentHorizontalPadding * 2 - descriptionWidth - contentSpacing)

        VStack(spacing: 0) {
            HStack {
                Text(viewModel.selectedPage.title)
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(.white.opacity(0.96))
                Spacer()
                ReadyToggleButton(
                    title: viewModel.readyButtonTitle,
                    isReady: viewModel.isReady,
                    action: onReadyToggle
                )
            }
            .padding(.horizontal, 24)
            .frame(height: 92)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ParameterIllustrationView(
                        page: viewModel.selectedPage,
                        width: imageWidth
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What is \(viewModel.selectedPage.title)?")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white.opacity(0.96))
                        Text(viewModel.selectedPage.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(width: descriptionWidth, alignment: .topLeading)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .frame(height: 400)

                Spacer(minLength: 0)

                ParameterControlAreaView(viewModel: viewModel)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: width, height: height)
    }
}

private struct ParameterIllustrationView: View {
    let page: ParameterPage
    let width: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        ZStack {
            shape.fill(.black.opacity(0.25))

            if let imageURL = page.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: page.imageName)
                        .font(.system(size: 42))
                        .foregroundStyle(.white.opacity(0.45))
                }
            } else {
                Image(systemName: page.imageName)
                    .font(.system(size: 42))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(width: width, height: 400)
        .clipShape(shape)
        .overlay(shape.stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
