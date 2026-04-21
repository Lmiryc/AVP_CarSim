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

    // 当前车辆姿态（供 CarDetailWindow 实时同步）
    var currentCarPosition: SIMD3<Float> = .zero
    var currentCarRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    // 用于同步轮胎状态
    var currentSteering: WheelSteering = WheelSteering(l1: 0, l2: 0, r1: 0, r2: 0)
    var currentWheelRoll: Float = 0.0 // 记录轮胎往前滚动的累积弧度

    // 前端参数页写入的仿真参数快照
    var simulationParameters = SimulationParameterSet()

    var selectedDatasetFileName: String {
        // Dataset naming convention: LastRun{massIndex}_{yawIndex}.csv
        // massIndex maps mass 1000..2000 step 200  -> 0..5
        // yawIndex maps yawInertia 1500..4000 step 500 -> 0..5
        let massIndex = Int(((simulationParameters.vehicleMass - 1000) / 200).rounded(.toNearestOrAwayFromZero))
        let yawIndex = Int(((simulationParameters.yawInertia - 1500) / 500).rounded(.toNearestOrAwayFromZero))
        let clampedMassIndex = min(max(massIndex, 0), 5)
        let clampedYawIndex = min(max(yawIndex, 0), 5)
        return "LastRun\(clampedMassIndex)_\(clampedYawIndex)"
    }
}
