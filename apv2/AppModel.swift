//
//  AppModel.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/20.
//

import SwiftUI

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
}
