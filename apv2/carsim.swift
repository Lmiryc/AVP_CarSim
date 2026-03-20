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
    @State private var frames: [CarFrame] = []
    @State private var isPlaying = false

    // 比例尺：0.01 = 真实1米 → 虚拟1厘米。调大让车更大（比如0.02 = 放大2倍）
    let scaleFactor: Float = 0.1

    // 观看偏移：把整条轨迹移到用户面前
    // x=0(正中), y=-0.5(略低于视线), z=-3(前方3米)
    let viewingOffset: SIMD3<Float> = [0, -0.5, -3]
    
    // 汽车颜色：这里可直接改成你想要的颜色
    let carColor: UIColor = .systemYellow

    var body: some View {
        // ImmersiveSpace 里只放 RealityView，没有 2D 面板遮挡
        RealityView { content in
            content.add(trajectoryAnchor)

            if let model = try? await Entity(named: "carframe") {
                applyColor(to: model, color: carColor)
                model.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                model.scale = [scaleFactor, scaleFactor, scaleFactor]
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
            guard let url = Bundle.main.url(forResource: "LastRun", withExtension: "csv") else {
                print("❌ 失败：找不到 LastRun.csv！请确保它拖进左侧目录时勾选了右侧面板的 Target Membership。")
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
            
            // 🚨 最容易报错的地方在这里！
            guard let timeIdx = headers.firstIndex(of: "Time"),
                  let xIdx = headers.firstIndex(of: "Xo"), // 你是不是没改这里的名字？
                  let yIdx = headers.firstIndex(of: "Yo"),
                  let zIdx = headers.firstIndex(of: "Zo"),
                  let yawIdx = headers.firstIndex(of: "Yaw"),
                  let pitchIdx = headers.firstIndex(of: "Pitch"),
                  let rollIdx = headers.firstIndex(of: "Roll") else {
                print("❌ 失败：表头匹配失败！找不到 Xo, Yo, Zo, Yaw, Pitch 或 Roll 中的某一个。")
                print("👇 请仔细查看下面的真实表头，找出代表位置和角度的列名，然后去代码里替换掉：")
                print(headers) // 打印所有真实的表头给你看
                return
            }
            
            print("✅ 2. 表头匹配成功！开始解析每一行数据...")
            var parsedFrames: [CarFrame] = []
            
            for i in 1..<lines.count {
                let line = lines[i]
                if line.isEmpty { continue }
                
                let columns = line.components(separatedBy: ",")
                if columns.count <= max(timeIdx, xIdx, yIdx, zIdx, yawIdx, pitchIdx, rollIdx) { continue }
                
                // 注意：如果你的 CSV 里有的数据为空格或者不是数字，这里也会跳过
                guard let time = Double(columns[timeIdx]),
                      let carX = Float(columns[xIdx]),
                      let carY = Float(columns[yIdx]),
                      let carZ = Float(columns[zIdx]),
                      let yawDeg = Float(columns[yawIdx]),
                      let pitchDeg = Float(columns[pitchIdx]),
                      let rollDeg = Float(columns[rollIdx]) else { continue }
                
                let realityX = -carY * scaleFactor
                let realityY = carZ * scaleFactor
                let realityZ = -carX * scaleFactor
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
            
            // 以第一帧为原点，避免轨迹跑到很远的绝对坐标
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
