import SwiftUI

struct TheRaceRootView: View {
    enum ScreenMode {
        case parameters
        case telemetry
    }

    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var viewModel = TheRaceViewModel()
    @State private var readyController = ReadyStateController()
    @State private var screenMode: ScreenMode = .parameters

    var body: some View {
        Group {
            if viewModel.hasEnteredMainInterface {
                if screenMode == .parameters {
                    MainParameterView(
                        viewModel: viewModel,
                        onReadyToggle: handleReadyToggle
                    )
                    .overlay(alignment: .top) {
                        if readyController.phase == .arming {
                            Text("Simulation armed. Transitioning in 5s...")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 22)
                        }
                    }
                } else {
                    VisualizationScreenView(
                        appModel: appModel,
                        parameterRows: viewModel.appliedParameterRows,
                        onReturn: {
                            withAnimation(.smooth) {
                                screenMode = .parameters
                            }
                            viewModel.setReady(false)
                            readyController.resetToIdle()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
            } else {
                LoadingView(
                    onStart: {
                        viewModel.hasEnteredMainInterface = true
                        screenMode = .parameters
                    },
                    onCancel: {}
                )
            }
        }
        .animation(.smooth, value: viewModel.hasEnteredMainInterface)
        .animation(.smooth, value: screenMode)
    }
}

private extension TheRaceRootView {
    func handleReadyToggle() {
        if viewModel.isReady {
            // Cancel path: revert UI and cancel delayed transition if pending.
            viewModel.setReady(false)
            readyController.resetToIdle()
            return
        }

        // Ready path: activate UI, push params to backend, start simulation signal.
        viewModel.setReady(true)
        applyCurrentParametersToBackend()

        Task { @MainActor in
            _ = await openImmersiveSpace(id: appModel.immersiveSpaceID)
            openWindow(id: "VXDisplay")
            appModel.shouldStartAnimation = true
        }

        readyController.armAndScheduleTransition(delaySeconds: 5) {
            dismissWindow(id: "VXDisplay")
            withAnimation(.easeInOut(duration: 0.45)) {
                screenMode = .telemetry
            }
        }
    }

    func applyCurrentParametersToBackend() {
        appModel.simulationParameters = .init(
            vehicleMass: viewModel.sliderValue(for: "vehicleMass", fallback: 1240),
            yawInertia: viewModel.sliderValue(for: "yawInertia", fallback: 3350),
            rollingRadius: viewModel.sliderValue(for: "rollingRadius", fallback: 0.30),
            tireGrip: viewModel.sliderValue(for: "tireGrip", fallback: 0.85),
            rollingResistance: viewModel.sliderValue(for: "rollingResistance", fallback: 0.015),
            brakeBias: viewModel.sliderValue(for: "brakeBias", fallback: 0.60),
            brakeResponseTime: viewModel.sliderValue(for: "brakeResponseTime", fallback: 0.25),
            absEnabled: viewModel.absEnabled
        )
    }
}

#Preview {
    TheRaceRootView()
        .environment(AppModel())
}
