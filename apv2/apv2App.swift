//
//  apv2App.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/20.
//

import SwiftUI

@main
struct apv2App: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        // 主窗口：The Race 前端 UI
        WindowGroup {
            TheRaceRootView()
                .environment(appModel)
        }
        .defaultSize(width: 1500, height: 820)
        .windowStyle(.plain)

        // 保留原测试控制面板窗口，便于后端/仿真调试
        WindowGroup(id: "ControlPanel") {
            ControlPanelView()
                .environment(appModel)
        }
        .defaultSize(width: 400, height: 250)

        // VX 显示窗口：独立窗口
        WindowGroup(id: "VXDisplay") {
            VXDisplayView()
                .environment(appModel)
        }.defaultSize(width: 200, height: 180)

        // 沉浸空间：无边界，3D 汽车可以自由移动
        ImmersiveSpace(id: "CarSimSpace") {
            CarSimulationView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
