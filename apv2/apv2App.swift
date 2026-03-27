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
        // 控制面板：只有 UI 按钮，没有 3D 内容，不会裁剪汽车
        WindowGroup {
            ControlPanelView()
                .environment(appModel)
        }.defaultSize(width: 400, height: 250)

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
