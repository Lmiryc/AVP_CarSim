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
    struct SimulationParameterSet {
        var vehicleMass: Double = 1240
        var yawInertia: Double = 3350
        var rollingRadius: Double = 0.30
        var tireGrip: Double = 0.85
        var rollingResistance: Double = 0.015
        var brakeBias: Double = 0.60
        var brakeResponseTime: Double = 0.25
        var absEnabled: Bool = false
    }

    let immersiveSpaceID = "CarSimSpace"
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

    // 前端参数页写入的仿真参数快照
    var simulationParameters = SimulationParameterSet()
}
