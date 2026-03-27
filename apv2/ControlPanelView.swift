import SwiftUI

struct ControlPanelView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(AppModel.self) private var appModel
    @State private var isSpaceOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("CarSim Dynamics")
                .font(.title)

            // 第一步：打开无边界沉浸空间（汽车在里面，不会被裁剪）
            Button(isSpaceOpen ? "Close immersive space" : "Open sandbox") {
                Task {
                    if isSpaceOpen {
                        await dismissImmersiveSpace()
                        isSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: "CarSimSpace")
                        if result == .opened {
                            isSpaceOpen = true
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            // 第二步：启动仿真动画
            Button(appModel.isAnimating ? "Simulating..." : "Start Simulating") {
                appModel.shouldStartAnimation = true
            }
            .disabled(!isSpaceOpen || appModel.isAnimating)
            .buttonStyle(.borderedProminent)
            
            // 关闭应用
            Button(role: .destructive) {
                Task {
                    // 先关闭沉浸空间
                    if isSpaceOpen {
                        await dismissImmersiveSpace()
                        isSpaceOpen = false
                    }
                    // 稍微延迟后关闭窗口
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    // 关闭 VX Display 窗口
                    dismissWindow(id: "VXDisplay")
                    // 关闭主窗口
                    dismissWindow()
                }
            } label: {
                Label("Shutdown", systemImage: "power")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            openWindow(id: "VXDisplay")
        }
    }
}
