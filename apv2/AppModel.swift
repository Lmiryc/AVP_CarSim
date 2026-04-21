//
//  AppModel.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/20.
//

import SwiftUI
import simd

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    // 仿真控制：ControlPanelView 设为 true，CarSimulationView 消费后重置
    var shouldStartAnimation: Bool = false
    var isAnimating: Bool = false
    
    // 当前 VX 值（用于显示）
    var currentVX: Float = 0.0

    // 当前车辆姿态（供 CarDetailWindow 实时同步）
    var currentCarPosition: SIMD3<Float> = .zero
    var currentCarRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    // 新增：用于同步轮胎状态
    var currentSteering: WheelSteering = WheelSteering(l1: 0, l2: 0, r1: 0, r2: 0)
    var currentWheelRoll: Float = 0.0 // 记录轮胎往前滚动的累积弧度
}
