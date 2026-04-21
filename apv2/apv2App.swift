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
        // 主窗口：你的 UI
        WindowGroup {
            TheRaceRootView()
                .environment(appModel)
        }
        .defaultSize(width: 1500, height: 1210)

        // 保留组员的控制面板窗口
        WindowGroup(id: "ControlPanel") {
            ControlPanelView()
                .environment(appModel)
        }
        .defaultSize(width: 400, height: 350)

        Window("Third Person View", id: "CarDetailWindow") {
            CarDetailView()
                .environment(appModel)
        }

        // 沉浸空间：无边界，3D 汽车可以自由移动
        ImmersiveSpace(id: "CarSimSpace") {
            CarSimulationView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
