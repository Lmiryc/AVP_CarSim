import SwiftUI
import RealityKit

struct CarDetailView: View {
    @Environment(AppModel.self) private var appModel
    @State private var carEntity: Entity?
    
    // 👇 完全复刻 carsim.swift 中的虚拟轴架构
    @State private var steerPivots: [WheelPosition: Entity] = [:]
    @State private var spinPivots: [WheelPosition: Entity] = [:]

    var body: some View {
        // 强制监听 AppModel 属性，确保 SwiftUI 持续驱动 update 闭包
        let currentPos = appModel.currentCarPosition
        let currentRot = appModel.currentCarRotation
        let currentSteering = appModel.currentSteering
        let currentRoll = appModel.currentWheelRoll

        RealityView { content in
            if let car = try? await Entity(named: "GT3RS") {
                // 基础朝向与缩放
                let flatRotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                let headingRotation = simd_quatf(angle: .pi, axis: [0, 0, 1])
                car.transform.rotation = currentRot * (flatRotation * headingRotation)
                car.scale = [0.10, 0.10, 0.10] 
                car.position = [0, -0.1 + currentPos.y * 0.2, 0] // 跑步机模式：X和Z锁死在中央
                
                // ==========================================
                // 🛠️ 核心：提取节点并构建虚拟层级 (复刻 carsim.swift)
                // ==========================================
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
                
                var wheelGroups: [WheelPosition: [Entity]] = [.l1: [], .l2: [], .r1: [], .r2: []]
                let allNodes = allEntities(from: car)
                let sortedMappings = wheelMapping.sorted { $0.key.count > $1.key.count }
                
                // 1. 查找节点
                for node in allNodes {
                    let nodeName = node.name.lowercased()
                    for (mappingName, position) in sortedMappings {
                        if nodeName.contains(mappingName.lowercased()) {
                            wheelGroups[position]?.append(node)
                            break
                        }
                    }
                }
                
                // 2. 为每个轮胎构建 SteerPivot 和 SpinPivot 以解决层级扁平和死锁
                for (pos, nodes) in wheelGroups {
                    guard !nodes.isEmpty else { continue }
                    
                    let center = nodes[0].visualBounds(relativeTo: car).center
                    
                    let steerPivot = Entity()
                    steerPivot.name = "SteerPivot_\(pos)"
                    steerPivot.position = center
                    car.addChild(steerPivot)
                    
                    let spinPivot = Entity()
                    spinPivot.name = "SpinPivot_\(pos)"
                    steerPivot.addChild(spinPivot)
                    
                    for node in nodes {
                        // 重新绑定父级，保持世界坐标系不动
                        node.setParent(spinPivot, preservingWorldTransform: true)
                    }
                    
                    // 保存引用，供 update 闭包驱动
                    DispatchQueue.main.async {
                        self.steerPivots[pos] = steerPivot
                        self.spinPivots[pos] = spinPivot
                    }
                }
                
                content.add(car)
                self.carEntity = car
                
                // 补光代码保持不变
                let directionalLight = Entity()
                var lightComponent = DirectionalLightComponent()
                lightComponent.color = .white
                lightComponent.intensity = 3000
                directionalLight.components.set(lightComponent)
                directionalLight.position = [-1, 1, 1]
                directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
                content.add(directionalLight)
                
                let fillLight = Entity()
                var fillComponent = PointLightComponent()
                fillComponent.color = .white
                fillComponent.intensity = 1000
                fillComponent.attenuationRadius = 5
                fillLight.components.set(fillComponent)
                fillLight.position = [0, 1, 1]
                content.add(fillLight)
            }
        } update: { _ in
            guard let car = carEntity else { return }
            
            // 1. 更新车身姿态与高度颠簸
            let flatRotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            let headingRotation = simd_quatf(angle: .pi, axis: [0, 0, 1])
            car.transform.rotation = currentRot * (flatRotation * headingRotation)
            car.position = [0, -0.1 + currentPos.y * 0.2, 0] // 保持在窗口中心
            
            // ==========================================
            // 🏎️ 2. 应用你特调的轮胎旋转属性
            // ==========================================
            let steerMap: [WheelPosition: Float] = [
                .l1: currentSteering.l1, .r1: currentSteering.r1,
                .l2: currentSteering.l2, .r2: currentSteering.r2
            ]
            
            // 完全照搬 carsim.swift 中的轴设定
            let steerAxis: [WheelPosition: SIMD3<Float>] = [
                .l1: [1, 0, 0], .r1: [1, 0, 0],
                .l2: [1, 0, 0], .r2: [0, 1, 0] // 特殊的右后轮轴向
            ]
            
            let spinAxis: [WheelPosition: SIMD3<Float>] = [
                .l1: [1, 0, 0], .r1: [1, 0, 0],
                .l2: [1, 0, 0], .r2: [1, 0, 0]
            ]
            
            let steeringVisualScale: Float = 2.5 // 同步转向放大系数
            
            for pos in WheelPosition.allCases {
                // 更新转向 (左右打轮)
                if let sPivot = steerPivots[pos], let angle = steerMap[pos], let sAxis = steerAxis[pos] {
                    sPivot.transform.rotation = simd_quatf(angle: angle * steeringVisualScale, axis: sAxis)
                }
                
                // 更新滚动 (车轮自转)
                if let rPivot = spinPivots[pos], let rAxis = spinAxis[pos] {
                    rPivot.transform.rotation = simd_quatf(angle: currentRoll, axis: rAxis)
                }
            }
        }
    }
    
    // 递归获取所有子节点辅助函数 (与 carsim.swift 保持一致)
    private func allEntities(from root: Entity) -> [Entity] {
        var result: [Entity] = [root]
        for child in root.children {
            result.append(contentsOf: allEntities(from: child))
        }
        return result
    }
}