import SwiftUI

struct LoadingView: View {
    @State private var viewModel = TheRaceViewModel()
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: viewModel.loadingBackgroundImageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()

            Color.black.opacity(0.38)
                .ignoresSafeArea()

            GlassPanel(padding: 20, cornerRadius: 32) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 52, height: 52)
                        Image(systemName: "car.side.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.blue)
                    }

                    Text("The Race")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white.opacity(0.96))
                    Text("Immersive Vehicle Dynamic Design Tool")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.33, green: 0.33, blue: 0.33))
                        .padding(.bottom, 6)

                    Divider()
                        .overlay(.white.opacity(0.08))
                        .padding(.bottom, 4)

                    VStack(spacing: 2) {
                        Button("Start", action: onStart)
                            .buttonStyle(.plain)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.96))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        Button("Cancel", action: onCancel)
                            .buttonStyle(.plain)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color(red: 0.33, green: 0.33, blue: 0.33))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .frame(width: 280)
            }
            .frame(width: 320, height: 299)
        }
    }
}

typealias EntryPanelView = LoadingView
