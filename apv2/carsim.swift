//
//  carsim.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/25.
//

import SwiftUI
import RealityKit
import simd
import ARKit

struct CarFrame {
    var time: Double
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var vx: Float  // 速度值
    var steering: WheelSteering
    
    // 👇 新增：车辆 Z 轴相关动态数据
    var yaw: Float  // 横摆角 (度)
    var az: Float   // Z轴加速度 (m/s²)
    var avz: Float  // Z轴角速度/横摆角速度 (rad/s 或 deg/s)
    var aaz: Float  // Z轴角加速度
}

struct WheelSteering {
    var l1: Float
    var l2: Float
    var r1: Float
    var r2: Float
}

enum WheelPosition: CaseIterable {
    case l1
    case l2
    case r1
    case r2
}

struct CarSimulationView: View {
    @Environment(AppModel.self) private var appModel
    @State private var trajectoryAnchor = Entity()
    @State private var mapAnchor = Entity()
    @State private var planeAnchor: AnchorEntity?
    @State private var frames: [CarFrame] = []
    
    // 动画与暂停状态
    @State private var isPlaying = false
    @State private var isPaused = false
    
    // 用于 Debug 染色的原始节点引用
    @State private var tireEntities: [WheelPosition: Entity] = [:]
    @State private var hubEntities: [WheelPosition: Entity] = [:]
    
    // 动态生成的虚拟车轴 (解决 Gimbal Lock 和 Flat Hierarchy)
    @State private var steerPivots: [WheelPosition: Entity] = [:]
    @State private var spinPivots: [WheelPosition: Entity] = [:]
    
    @State private var wheelSpinAngle: Float = 0

    // ===== 全局缩放系数 =====
    let globalScale: Float = 0.35  // 调整这个值来缩放所有内容（车、轨道、速度等）
    
    // 1. 赛道与轨迹的比例
    let trackScale: Float = 0.357
    
    // 2. 汽车模型的比例
    let carScale: Float = 0.1
    
    // 3. Road 的轴向缩放系数
    let roadScaleX: Float = 0.045
    let roadScaleY: Float = 0.045
    let roadScaleZ: Float = 0.079
    
    // 计算实际使用的缩放值
    var effectiveTrackScale: Float { return trackScale * globalScale }
    var effectiveCarScale: Float { return carScale * globalScale }
    var effectiveRoadScaleX: Float { return roadScaleX * globalScale }
    var effectiveRoadScaleY: Float { return roadScaleY * globalScale }
    var effectiveRoadScaleZ: Float { return roadScaleZ * globalScale }

    // 观看偏移
    let viewingOffset: SIMD3<Float> = [0, -0.5, -3]

    // 轮胎运动调试参数
    let wheelRadiusMeters: Float = 0.34
    let steeringVisualScale: Float = 2.5
    let steeringValueIsDegrees: Bool = false
    let frontSteeringSign: Float = -1.0
    let rearSteeringSign: Float = 1.0

    var body: some View {
        ZStack { // 使用 ZStack 防止隐藏按钮占据空间导致画面偏移
            RealityView { content in
                let planeAnchor = AnchorEntity(plane: .horizontal)
                self.planeAnchor = planeAnchor
                content.add(planeAnchor)
                
                planeAnchor.addChild(trajectoryAnchor)
                planeAnchor.addChild(mapAnchor)

                if let road = try? await Entity(named: "road") {
                    road.position = viewingOffset
                    let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
                    let rotationY = simd_quatf(angle: -.pi/2, axis: [0, 1, 0])
                    let rotationsth = simd_quatf(angle: .pi, axis: [0, 0, 1])
                    road.transform.rotation = rotationY * rotationX * rotationsth
                    road.scale = [effectiveRoadScaleX, effectiveRoadScaleY, effectiveRoadScaleZ]
                    mapAnchor.addChild(road)
                }

                if let model = try? await Entity(named: "GT3RS") {
                    let flatRotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                    let headingRotation = simd_quatf(angle: .pi , axis: [0, 0, 1])
                    model.transform.rotation = flatRotation * headingRotation
                    model.scale = [effectiveCarScale, effectiveCarScale, effectiveCarScale]
                    trajectoryAnchor.addChild(model)
                    model.position.y = 0.01
                    // 处理车轮层级
                    cacheWheelEntities(in: model)
                    debugTintAllTires()
                    loadCSVData()
                }
            }
            .onChange(of: appModel.shouldStartAnimation) { _, newValue in
                if newValue {
                    appModel.shouldStartAnimation = false
                    if !frames.isEmpty && !isPlaying {
                        startAnimation()
                    }
                }
            }
            // 键盘按键监听 (Space 键暂停)
            Button(action: {
                if isPlaying {
                    isPaused.toggle()
                    print(isPaused ? "⏸️ 动画已暂停" : "▶️ 动画已继续")
                }
            }) {
                EmptyView()
            }
            .keyboardShortcut(.space, modifiers: []) 
            .opacity(0) 
        }
    }

    private func cacheWheelEntities(in root: Entity) {
            let allNodes = allEntities(from: root)
            
            // 1. 映射字典
            let wheelMapping: [String: WheelPosition] = [
                "twixer_992_gt3rs_style_1_chrome_wheels_20x9": .l1,
                "object_4_003": .l1,
                
                "twixer_992_gt3rs_style_1_chrome_wheels_20x9_001": .l2,
                "object_4_001": .l2,
                
                "twixer_992_gt3rs_style_1_chrome_wheels_20x9_002": .r1,
                "object_4_002": .r1,
                
                "twixer_992_gt3rs_style_1_chrome_wheels_20x9_003": .r2,
                "object_4_004": .r2
            ]
            
            // 🎨 2. 定义好四个轮子的专属颜色
            let wheelColors: [WheelPosition: UIColor] = [
                .l1: .red,    // 左前轮：红
                .r1: .green,  // 右前轮：绿
                .l2: .blue,   // 左后轮：蓝
                .r2: .yellow  // 右后轮：黄
            ]
            
            var wheelGroups: [WheelPosition: [Entity]] = [.l1: [], .l2: [], .r1: [], .r2: []]
            
                // 🌟 修复关键：将字典按 Key 的字符串长度从长到短排序
                // 这样会优先匹配 "_001", "_002", "_003"，最后才匹配没有后缀的基础名
                let sortedMappings = wheelMapping.sorted { $0.key.count > $1.key.count }
                
                // 3. 遍历并直接染色
                for node in allNodes {
                    let nodeName = node.name.lowercased()
                    
                    // 使用排序后的数组进行遍历
                    for (mappingName, position) in sortedMappings {
                        if nodeName.contains(mappingName.lowercased()) {
                            wheelGroups[position]?.append(node)
                            
                            if nodeName.contains("twixer") {
                                DispatchQueue.main.async { self.hubEntities[position] = node }
                            } else if nodeName.contains("object_4") {
                                DispatchQueue.main.async { self.tireEntities[position] = node }
                                
                                if let color = wheelColors[position] {
                                    applyColor(color, to: node)
                                    print("✅ 已直接将 \(position) 轮胎染成 \(color)")
                                }
                            }
                            break // 匹配成功就跳出，不会再被较短的字符串误捕获
                        }
                    }
                }
            
            // 4. 构建 Pivot 结构
            for (pos, nodes) in wheelGroups {
                guard !nodes.isEmpty else { continue }
                
                let center = nodes[0].visualBounds(relativeTo: root).center
                
                let steerPivot = Entity()
                steerPivot.name = "SteerPivot_\(pos)"
                steerPivot.position = center
                root.addChild(steerPivot)
                
                let spinPivot = Entity()
                spinPivot.name = "SpinPivot_\(pos)"
                steerPivot.addChild(spinPivot)
                
                for node in nodes {
                    node.setParent(spinPivot, preservingWorldTransform: true)
                }
                
                DispatchQueue.main.async {
                    self.steerPivots[pos] = steerPivot
                    self.spinPivots[pos] = spinPivot
                }
            }
        }

    private func allEntities(from root: Entity) -> [Entity] {
        var result: [Entity] = [root]
        for child in root.children {
            result.append(contentsOf: allEntities(from: child))
        }
        return result
    }

    private func applyWheelSteering(_ steering: WheelSteering, speedKPH: Float, deltaTime: Float) {
            let speedMS = speedKPH / 3.6
            wheelSpinAngle += (speedMS / wheelRadiusMeters) * deltaTime

            let steerMap: [WheelPosition: Float] = [
                .l1: steering.l1, .r1: steering.r1,
                .l2: steering.l2, .r2: steering.r2
            ]

            // 🛠️ 1. 单独定义每个轮子的【转向轴】(控制左右打方向)
            // 正常通常是 Y 轴 [0, 1, 0]。如果前轮打方向变成了上下翻滚，可以改成 [1, 0, 0] 或 [0, 0, 1] 试试。
            let steerAxis: [WheelPosition: SIMD3<Float>] = [
                .l1: [1, 0, 0], // 左前
                .r1: [1, 0, 0], // 右前
                .l2: [1, 0, 0], // 左后
                .r2: [0, 1, 0]  // 右后
            ]

            // 🛠️ 2. 单独定义每个轮子的【自转轴】(控制车轮往前滚动)
            // 正常通常是 X 轴 [1, 0, 0]。如果前轮像陀螺一样平着转，大概率是 Z 轴，请改成 [0, 0, 1]。
            // 如果方向转反了（比如倒车），就加个负号，比如 [-1, 0, 0] 或 [0, 0, -1]。
                let spinAxis: [WheelPosition: SIMD3<Float>] = [
                    .l1: [1, 0, 0], // 👈 左前轮如果滚动不对，优先把这里改成 [0, 0, 1]
                    .r1: [1, 0, 0], // 👈 右前轮如果滚动不对，优先把这里改成 [0, 0, 1]
                    .l2: [1, 0, 0], // 左后 (默认正确)
                    .r2: [1, 0, 0]  // 右后 (默认正确)
            ]

            for pos in WheelPosition.allCases {
                // 改变转向
                if let sPivot = steerPivots[pos], let angle = steerMap[pos], let sAxis = steerAxis[pos] {
                    sPivot.transform.rotation = simd_quatf(angle: angle * steeringVisualScale, axis: sAxis)
                }
                
                // 改变转速 (滚动)
                if let rPivot = spinPivots[pos], let rAxis = spinAxis[pos] {
                    rPivot.transform.rotation = simd_quatf(angle: wheelSpinAngle, axis: rAxis)
                }
            }
        }
        private func debugTintAllTires() {
            // 定义四个轮子的专属颜色，方便区分
            let wheelColors: [WheelPosition: UIColor] = [
                .l1: .red,    // 左前轮：红色
                .r1: .green,  // 右前轮：绿色
                .l2: .blue,   // 左后轮：蓝色
                .r2: .yellow  // 右后轮：黄色
            ]
            
            for (pos, color) in wheelColors {
                // 给轮胎染色
                if let tire = tireEntities[pos] {
                    applyColor(color, to: tire)
                }
                
                // 💡 备选：如果你想连轮毂一起染色，可以把下面这段取消注释
                // if let hub = hubEntities[pos] {
                //     applyColor(color, to: hub)
                // }
            }
            
            print("🎨 四轮调试染色已完成：左前=红，右前=绿，左后=蓝，右后=黄")
        }

        /// 递归遍历 Entity 及其子节点，替换所有材质为指定颜色
    /// 递归遍历 Entity 及其子节点，强制替换所有材质为无光照的纯色
        private func applyColor(_ color: UIColor, to entity: Entity) {
            // 如果当前节点有网格，替换它的材质
            if var modelComp = entity.components[ModelComponent.self] as? ModelComponent {
                let debugMaterial = UnlitMaterial(color: color) // 使用 Unlit 保证无视光照绝对显色
                modelComp.materials = modelComp.materials.map { _ in debugMaterial }
                entity.components.set(modelComp)
            }
            
            // 递归处理子节点
            for child in entity.children {
                applyColor(color, to: child)
            }
        }
    
    private func loadCSVData() {
        print("🔍 1. 开始尝试读取 CSV 文件...")
        guard let url = Bundle.main.url(forResource: "race", withExtension: "csv") else { return }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let lines = content.components(separatedBy: .newlines)
        if lines.count < 2 { return }

        let headers = lines[0].components(separatedBy: ",")
        func findHeaderIndex(_ names: [String]) -> Int? {
            for (index, header) in headers.enumerated() {
                let normalizedHeader = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if names.contains(normalizedHeader) { return index }
            }
            return nil
        }

        guard let timeIdx = findHeaderIndex(["time"]) else { return }

        let xIdx = findHeaderIndex(["xo", "x", "xcg_tm", "xcg_sm"])
        let yIdx = findHeaderIndex(["yo", "y", "ycg_tm", "ycg_sm"])
        let zIdx = findHeaderIndex(["zo", "z", "zcg_tm", "zcg_sm"])
        let yawIdx = findHeaderIndex(["yaw"])
        let pitchIdx = findHeaderIndex(["pitch"])
        let rollIdx = findHeaderIndex(["roll"])
        let vxIdx = findHeaderIndex(["vx"])
        let azIdx = findHeaderIndex(["az"])
        let avzIdx = findHeaderIndex(["avz"])
        let aazIdx = findHeaderIndex(["aaz"])
        let steerL1Idx = findHeaderIndex(["steer_l1"])
        let steerL2Idx = findHeaderIndex(["steer_l2"])
        let steerR1Idx = findHeaderIndex(["steer_r1"])
        let steerR2Idx = findHeaderIndex(["steer_r2"])
        let cmpSL1Idx = findHeaderIndex(["cmps_l1"])
        let cmpSL2Idx = findHeaderIndex(["cmps_l2"])
        let cmpSR1Idx = findHeaderIndex(["cmps_r1"])
        let cmpSR2Idx = findHeaderIndex(["cmps_r2"])

        let hasDirectPosition = xIdx != nil && yIdx != nil && zIdx != nil
        if !hasDirectPosition && (vxIdx == nil || yawIdx == nil) { return }

        var parsedFrames: [CarFrame] = []
        var inferredCarX: Float = 0
        var inferredCarY: Float = 0
        var inferredCarZ: Float = 0
        var inferredVerticalVelocity: Float = 0
        var lastTime: Double?

        for i in 1..<lines.count {
            let line = lines[i]
            if line.isEmpty { continue }

            let columns = line.components(separatedBy: ",")
            if columns.count <= timeIdx { continue }

            guard let time = Double(columns[timeIdx]) else { continue }

            let yawDeg = (yawIdx != nil && columns.count > yawIdx!) ? (Float(columns[yawIdx!]) ?? 0) : 0
            let pitchDeg = (pitchIdx != nil && columns.count > pitchIdx!) ? (Float(columns[pitchIdx!]) ?? 0) : 0
            let rollDeg = (rollIdx != nil && columns.count > rollIdx!) ? (Float(columns[rollIdx!]) ?? 0) : 0
            let vxValue = (vxIdx != nil && columns.count > vxIdx!) ? (Float(columns[vxIdx!]) ?? 0) : 0
            
            //  新增：读取 Z 轴的具体数值
            let azValue = (azIdx != nil && columns.count > azIdx!) ? (Float(columns[azIdx!]) ?? 0) : 0
            let avzValue = (avzIdx != nil && columns.count > avzIdx!) ? (Float(columns[avzIdx!]) ?? 0) : 0
            let aazValue = (aazIdx != nil && columns.count > aazIdx!) ? (Float(columns[aazIdx!]) ?? 0) : 0
            
            let steerL1 = (steerL1Idx != nil && columns.count > steerL1Idx!) ? (Float(columns[steerL1Idx!]) ?? 0) : 0
            let steerL2 = (steerL2Idx != nil && columns.count > steerL2Idx!) ? (Float(columns[steerL2Idx!]) ?? 0) : 0
            let steerR1 = (steerR1Idx != nil && columns.count > steerR1Idx!) ? (Float(columns[steerR1Idx!]) ?? 0) : 0
            let steerR2 = (steerR2Idx != nil && columns.count > steerR2Idx!) ? (Float(columns[steerR2Idx!]) ?? 0) : 0

            let carX: Float
            let carY: Float
            let carZ: Float

            if hasDirectPosition,
               let xIdx, let yIdx, let zIdx,
               columns.count > max(xIdx, yIdx, zIdx),
               let parsedX = Float(columns[xIdx]),
               let parsedY = Float(columns[yIdx]),
               let parsedZ = Float(columns[zIdx]) {
                carX = parsedX
                carY = parsedY
                carZ = parsedZ
            } else if let vxIdx, columns.count > vxIdx, let vx = Float(columns[vxIdx]) {
                if let previousTime = lastTime {
                    let dt = max(0, Float(time - previousTime))
                    let yawRadForPath = yawDeg * .pi / 180.0
                    let speedMS = vx / 3.6
                    let stepDistance = speedMS * effectiveTrackScale * dt
                    inferredCarX += stepDistance * cos(yawRadForPath)
                    inferredCarY += stepDistance * sin(yawRadForPath)

                    if let cmpSL1Idx, let cmpSL2Idx, let cmpSR1Idx, let cmpSR2Idx,
                       columns.count > max(cmpSL1Idx, cmpSL2Idx, cmpSR1Idx, cmpSR2Idx),
                       let cmpL1 = Float(columns[cmpSL1Idx]),
                       let cmpL2 = Float(columns[cmpSL2Idx]),
                       let cmpR1 = Float(columns[cmpSR1Idx]),
                       let cmpR2 = Float(columns[cmpSR2Idx]) {
                        let avgCompression = (cmpL1 + cmpL2 + cmpR1 + cmpR2) * 0.25
                        inferredCarZ = -(avgCompression * 0.001)
                    } else if let azIdx, columns.count > azIdx, let az = Float(columns[azIdx]) {
                        inferredVerticalVelocity += az * dt
                        inferredCarZ += inferredVerticalVelocity * dt * 0.5
                        inferredVerticalVelocity *= 0.98
                        inferredCarZ = min(max(inferredCarZ, -2.0), 2.0)
                    }
                }
                carX = inferredCarX
                carY = inferredCarY
                carZ = inferredCarZ
            } else {
                continue
            }
            lastTime = time

            let realityX = -carY * effectiveTrackScale
            let realityY = carZ * effectiveTrackScale
            let realityZ = -carX * effectiveTrackScale
            let position = SIMD3<Float>(realityX, realityY, realityZ)

            let yawRad = yawDeg * .pi / 180.0
            let pitchRad = pitchDeg * .pi / 180.0
            let rollRad = rollDeg * .pi / 180.0

            let qYaw = simd_quatf(angle: yawRad, axis: [0, 1, 0])
            let qPitch = simd_quatf(angle: pitchRad, axis: [1, 0, 0])
            let qRoll = simd_quatf(angle: rollRad, axis: [0, 0, 1])
            let rotation = qYaw * qPitch * qRoll

            // 第一次 append
            parsedFrames.append(
                CarFrame(
                    time: time,
                    position: position,
                    rotation: rotation,
                    vx: vxValue,
                    steering: WheelSteering(l1: steerL1, l2: steerL2, r1: steerR1, r2: steerR2),
                    // 👇 新增装载
                    yaw: yawDeg,
                    az: azValue,
                    avz: avzValue,
                    aaz: aazValue
                )
            )
        }

        if let first = parsedFrames.first {
            let originOffset = first.position
            self.frames = parsedFrames.map { frame in
                CarFrame(
                    time: frame.time,
                    position: (frame.position - originOffset) + viewingOffset,
                    rotation: frame.rotation,
                    vx: frame.vx,
                    steering: frame.steering,
                    // 👇 新增传递
                    yaw: frame.yaw,
                    az: frame.az,
                    avz: frame.avz,
                    aaz: frame.aaz
                )
            }}
        else {
            self.frames = parsedFrames
        }
        

        print("🎉 大功告成！成功加载了 \(parsedFrames.count) 帧有效数据！")
    }
    
    private func startAnimation() {
        guard !frames.isEmpty else { return }
        isPlaying = true
        isPaused = false
        appModel.isAnimating = true
        
        Task {
            let startTime = Date()
            let firstFrameTime = frames.first!.time
            var frameIndex = 0
            var previousFrameTime = firstFrameTime
            
            var totalPausedDuration: TimeInterval = 0
            var pauseStartTime: Date? = nil
            
            while frameIndex < frames.count && isPlaying {
                if isPaused {
                    if pauseStartTime == nil {
                        pauseStartTime = Date()
                    }
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    continue
                } else {
                    if let pStart = pauseStartTime {
                        totalPausedDuration += Date().timeIntervalSince(pStart)
                        pauseStartTime = nil
                    }
                }
                
                let targetFrame = frames[frameIndex]
                let elapsedRealTime = Date().timeIntervalSince(startTime) - totalPausedDuration
                let elapsedSimTime = targetFrame.time - firstFrameTime
                
                if elapsedRealTime < elapsedSimTime {
                    let waitTime = elapsedSimTime - elapsedRealTime
                    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
                
                trajectoryAnchor.transform.translation = targetFrame.position
                trajectoryAnchor.transform.rotation = targetFrame.rotation
                appModel.currentVX = targetFrame.vx
                appModel.currentCarPosition = targetFrame.position
                appModel.currentCarRotation = targetFrame.rotation
                
                let dt = Float(max(0, targetFrame.time - previousFrameTime))
                let wheelRadius: Float = 0.35 // 假设 GT3RS 轮胎半径是 0.35米，你可以微调
                // 滚动角速度 = 速度 / 半径。转角增量 = 角速度 * dt
                appModel.currentWheelRoll -= (targetFrame.vx * dt) / wheelRadius

                applyWheelSteering(targetFrame.steering, speedKPH: targetFrame.vx, deltaTime: dt)
                previousFrameTime = targetFrame.time

                frameIndex += 1
            }
            
            isPlaying = false
            isPaused = false
            appModel.isAnimating = false
        }
    }
}
