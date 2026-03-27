//
//  carsim.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/25.
//

import SwiftUI
import RealityKit
import simd

struct CarFrame {
    var time: Double
    var position: SIMD3<Float>
    var rotation: simd_quatf
}

struct CarSimulationView: View {
    @Environment(AppModel.self) private var appModel

    @State private var trajectoryAnchor = Entity()
    @State private var mapAnchor = Entity()
    @State private var frames: [CarFrame] = []
    @State private var isPlaying = false

    // 比例尺：0.01 = 真实1米 → 虚拟1厘米。调大让车更大（比如0.02 = 放大2倍）
    //let scaleFactor: Float = 0.1
    // 1. 赛道与轨迹的比例（比如你想缩小赛道，就调小这个值，确保道路和路线匹配）
    let trackScale: Float = 0.357 
    
    // 2. 汽车模型的比例（独立控制车的大小，不管赛道怎么变，车都是这么大）
    let carScale: Float = 0.1     

    // 观看偏移... (保留原样)
  
    let viewingOffset: SIMD3<Float> = [0, -0.5, -3]
    
    // 汽车颜色：这里可直接改成你想要的颜色
    let carColor: UIColor = .systemYellow

    var body: some View {
        // ImmersiveSpace 里只放 RealityView，没有 2D 面板遮挡
        RealityView { content in
            content.add(trajectoryAnchor)
            content.add(mapAnchor)

            if let road = try? await Entity(named: "road") {
                road.position = viewingOffset
                // 1. 先定义好两个旋转
                let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
                let rotationY = simd_quatf(angle: -.pi/2, axis: [0, 1, 0])
                let rotationsth = simd_quatf(angle: .pi, axis: [0, 0, 1]) // 额外旋转，让道路斜着放更有沉浸感

                // 2. 将它们相乘来叠加效果，然后赋值
                road.transform.rotation = rotationY * rotationX * rotationsth
                //let roadScale: Float = 0.357
                let mapScale: Float = 0.357
                road.scale = [mapScale*trackScale, mapScale*trackScale, mapScale*trackScale]
                mapAnchor.addChild(road)
            }

            if let model = try? await Entity(named: "carframe") {
                applyColor(to: model, color: carColor)
                let flatRotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                let headingRotation = simd_quatf(angle: .pi , axis: [0, 0, 1])
                model.transform.rotation = flatRotation * headingRotation
                model.scale = [carScale, carScale, carScale]
                trajectoryAnchor.addChild(model)
                loadCSVData()
            }
        }
        // 监听来自 ControlPanelView 的开始信号
        .onChange(of: appModel.shouldStartAnimation) { _, newValue in
            if newValue {
                appModel.shouldStartAnimation = false
                if !frames.isEmpty && !isPlaying {
                    startAnimation()
                }
            }
        }
    }
    
    private func applyColor(to entity: Entity, color: UIColor) {
        if let modelEntity = entity as? ModelEntity,
           var modelComponent = modelEntity.components[ModelComponent.self] {
            let material = SimpleMaterial(color: color, isMetallic: true)
            modelComponent.materials = Array(repeating: material, count: modelComponent.materials.count)
            modelEntity.components.set(modelComponent)
        }
        
        for child in entity.children {
            applyColor(to: child, color: color)
        }
    }
    
    private func loadCSVData() {
        print("🔍 1. 开始尝试读取 CSV 文件...")
        guard let url = Bundle.main.url(forResource: "race", withExtension: "csv") else {
            print("❌ 失败：找不到 race.csv！请确保它拖进左侧目录时勾选了右侧面板的 Target Membership。")
            return
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ 失败：文件找到了，但无法以 UTF-8 格式读取内容。")
            return
        }

        let lines = content.components(separatedBy: .newlines)
        if lines.count < 2 {
            print("❌ 失败：CSV 文件内容为空或行数不够。")
            return
        }

        let headers = lines[0].components(separatedBy: ",")
        print("✅ 成功读取表头，总共有 \(headers.count) 列数据。")

        func findHeaderIndex(_ names: [String]) -> Int? {
            for (index, header) in headers.enumerated() {
                let normalizedHeader = header
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if names.contains(normalizedHeader) {
                    return index
                }
            }
            return nil
        }

        guard let timeIdx = findHeaderIndex(["time"]) else {
            print("❌ 失败：表头匹配失败！找不到 Time。")
            return
        }

        let xIdx = findHeaderIndex(["xo", "x", "xcg_tm", "xcg_sm"])
        let yIdx = findHeaderIndex(["yo", "y", "ycg_tm", "ycg_sm"])
        let zIdx = findHeaderIndex(["zo", "z", "zcg_tm", "zcg_sm"])
        let yawIdx = findHeaderIndex(["yaw"])
        let pitchIdx = findHeaderIndex(["pitch"])
        let rollIdx = findHeaderIndex(["roll"])
        let vxIdx = findHeaderIndex(["vx"])

        let hasDirectPosition = xIdx != nil && yIdx != nil && zIdx != nil
        if !hasDirectPosition && (vxIdx == nil || yawIdx == nil) {
            print("❌ 失败：当前文件没有 Xo/Yo/Zo，且也缺少 Vx 或 Yaw，无法推算轨迹。")
            print(headers)
            return
        }

        print("✅ 2. 表头匹配成功！开始解析每一行数据...")
        var parsedFrames: [CarFrame] = []
        var inferredCarX: Float = 0
        var inferredCarY: Float = 0
        var inferredCarZ: Float = 0
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

            let carX: Float
            let carY: Float
            let carZ: Float

            if hasDirectPosition,
               let xIdx,
               let yIdx,
               let zIdx,
               columns.count > max(xIdx, yIdx, zIdx),
               let parsedX = Float(columns[xIdx]),
               let parsedY = Float(columns[yIdx]),
               let parsedZ = Float(columns[zIdx]) {
                carX = parsedX
                carY = parsedY
                carZ = parsedZ
            } else if let vxIdx,
                      columns.count > vxIdx,
                      let vx = Float(columns[vxIdx]) {
                if let previousTime = lastTime {
                    let dt = max(0, Float(time - previousTime))
                    let yawRadForPath = yawDeg * .pi / 180.0
                    let speedMS = vx / 3.6 // 如果你的 vx 原本就是 m/s，请忽略除以 3.6
                    let stepDistance = speedMS * trackScale * dt
                    inferredCarX += stepDistance * cos(yawRadForPath)
                    inferredCarY += stepDistance * sin(yawRadForPath)
                }
                carX = inferredCarX
                carY = inferredCarY
                carZ = inferredCarZ
            } else {
                continue
            }
            lastTime = time

            let realityX = -carY * trackScale
            let realityY = carZ * trackScale
            let realityZ = -carX * trackScale
            let position = SIMD3<Float>(realityX, realityY, realityZ)

            let yawRad = yawDeg * .pi / 180.0
            let pitchRad = pitchDeg * .pi / 180.0
            let rollRad = rollDeg * .pi / 180.0

            let qYaw = simd_quatf(angle: yawRad, axis: [0, 1, 0])
            let qPitch = simd_quatf(angle: pitchRad, axis: [1, 0, 0])
            let qRoll = simd_quatf(angle: rollRad, axis: [0, 0, 1])
            let rotation = qYaw * qPitch * qRoll

            parsedFrames.append(CarFrame(time: time, position: position, rotation: rotation))
        }

        if let first = parsedFrames.first {
            let originOffset = first.position
            self.frames = parsedFrames.map { frame in
                CarFrame(
                    time: frame.time,
                    position: (frame.position - originOffset) + viewingOffset,
                    rotation: frame.rotation
                )
            }
        } else {
            self.frames = parsedFrames
        }

        print("🎉 大功告成！成功加载了 \(parsedFrames.count) 帧有效数据！")
    }
    
    private func startAnimation() {
        guard !frames.isEmpty else { return }
        isPlaying = true
        appModel.isAnimating = true
        
        Task {
            let startTime = Date()
            let firstFrameTime = frames.first!.time
            var frameIndex = 0
            
            while frameIndex < frames.count {
                let targetFrame = frames[frameIndex]
                let elapsedRealTime = Date().timeIntervalSince(startTime)
                let elapsedSimTime = targetFrame.time - firstFrameTime
                
                if elapsedRealTime < elapsedSimTime {
                    let waitTime = elapsedSimTime - elapsedRealTime
                    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
                
                trajectoryAnchor.transform.translation = targetFrame.position
                trajectoryAnchor.transform.rotation = targetFrame.rotation
                
                frameIndex += 1
            }
            isPlaying = false
            appModel.isAnimating = false
        }
    }
}
