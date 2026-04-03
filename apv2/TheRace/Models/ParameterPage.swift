import Foundation

struct ParameterPage: Identifiable, Hashable {
    enum Section: Hashable {
        case primary
        case advanced
    }

    enum PageType: Hashable {
        case slider
        case toggle
    }

    let id: String
    let sidebarTitle: String
    let title: String
    let description: String
    let sliderHint: String
    let imageName: String
    let imageURL: String?
    let minValue: Double?
    let maxValue: Double?
    let step: Double?
    let unit: String
    let type: PageType
    let defaultSliderValue: Double?
    let section: Section
}

extension ParameterPage {
    static let all: [ParameterPage] = [
        .init(
            id: "yawInertia",
            sidebarTitle: "Handling",
            title: "Yaw Inertia",
            description: "Yaw inertia describes how resistant a vehicle is to rotating around its vertical axis (turning). A higher value makes the vehicle more stable and harder to rotate, while a lower value makes it more responsive and easier to turn, but less stable. It is influenced by the vehicle’s total mass and how that mass is distributed around its center.",
            sliderHint: "Yaw inertia can be understood as how difficult it is for a car to turn. Higher values improve stability but reduce responsiveness.",
            imageName: "car.rear.waves.up",
            imageURL: "https://www.figma.com/api/mcp/asset/033c418f-b379-455e-b110-e1064ea90140",
            minValue: 1500,
            maxValue: 4000,
            step: 100,
            unit: "kg·m²",
            type: .slider,
            defaultSliderValue: 3350,
            section: .primary
        ),
        .init(
            id: "vehicleMass",
            sidebarTitle: "Vehicle Mass",
            title: "Vehicle Mass",
            description: "Adjust total vehicle mass to see how inertia affects acceleration and braking response.",
            sliderHint: "Higher mass increases inertia and can reduce responsiveness in acceleration and direction changes.",
            imageName: "car.side",
            imageURL: nil,
            minValue: 1000,
            maxValue: 2000,
            step: 10,
            unit: "kg",
            type: .slider,
            defaultSliderValue: 1240,
            section: .primary
        ),
        .init(
            id: "rollingRadius",
            sidebarTitle: "Rolling Radius",
            title: "Rolling Radius",
            description: "Rolling radius influences effective wheel speed and longitudinal force conversion at the tire.",
            sliderHint: "Changing rolling radius impacts gearing behavior and acceleration feel.",
            imageName: "circle",
            imageURL: nil,
            minValue: 0.28,
            maxValue: 0.36,
            step: 0.005,
            unit: "m",
            type: .slider,
            defaultSliderValue: 0.30,
            section: .advanced
        ),
        .init(
            id: "tireGrip",
            sidebarTitle: "Tire Grip Level",
            title: "Tire Grip",
            description: "Tire grip defines the maximum friction force available between the tire and road surface.",
            sliderHint: "Higher grip usually increases cornering performance but may alter balance.",
            imageName: "gauge.with.dots.needle.67percent",
            imageURL: nil,
            minValue: 0.6,
            maxValue: 1.4,
            step: 0.05,
            unit: "",
            type: .slider,
            defaultSliderValue: 0.85,
            section: .advanced
        ),
        .init(
            id: "rollingResistance",
            sidebarTitle: "Rolling Resistance",
            title: "Rolling Resistance",
            description: "Rolling resistance models losses caused by tire deformation and contact friction.",
            sliderHint: "Lower values generally improve efficiency; higher values increase resistance.",
            imageName: "arrow.left.and.right.righttriangle.left.righttriangle.right",
            imageURL: nil,
            minValue: 0.008,
            maxValue: 0.02,
            step: 0.001,
            unit: "",
            type: .slider,
            defaultSliderValue: 0.015,
            section: .advanced
        ),
        .init(
            id: "brakeBias",
            sidebarTitle: "Brake Bias",
            title: "Brake Bias",
            description: "Brake bias sets front-rear braking force distribution and influences turn-in stability.",
            sliderHint: "More front bias improves stability; more rear bias can increase rotation response.",
            imageName: "dial.medium",
            imageURL: nil,
            minValue: 0.5,
            maxValue: 0.8,
            step: 0.01,
            unit: "",
            type: .slider,
            defaultSliderValue: 0.6,
            section: .advanced
        ),
        .init(
            id: "brakeResponseTime",
            sidebarTitle: "Brake Response Time",
            title: "Brake Response Time",
            description: "Brake response time indicates delay from pedal input to effective braking force generation.",
            sliderHint: "Smaller response time means faster brake system reaction.",
            imageName: "timer",
            imageURL: nil,
            minValue: 0.05,
            maxValue: 0.3,
            step: 0.01,
            unit: "s",
            type: .slider,
            defaultSliderValue: 0.25,
            section: .advanced
        ),
        .init(
            id: "abs",
            sidebarTitle: "ABS",
            title: "ABS",
            description: "Enable ABS to prevent wheel lock-up during heavy braking input.",
            sliderHint: "ABS modulates braking force to help maintain steerability while braking.",
            imageName: "switch.2",
            imageURL: nil,
            minValue: nil,
            maxValue: nil,
            step: nil,
            unit: "",
            type: .toggle,
            defaultSliderValue: nil,
            section: .advanced
        )
    ]
}
