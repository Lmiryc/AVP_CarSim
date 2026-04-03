import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class TheRaceViewModel {
    var hasEnteredMainInterface = false
    var isReady = false

    let backgroundImageURL = "https://www.figma.com/api/mcp/asset/19c08829-3d9e-4154-bf80-990125ced4ad"
    let loadingBackgroundImageURL = "https://www.figma.com/api/mcp/asset/2d858c9a-01dc-42d8-980a-9bf0abed8144"

    var readyButtonTitle: String {
        isReady ? "Cancel" : "Ready"
    }

    var pages: [ParameterPage] = ParameterPage.all
    var selectedPageID: String = "yawInertia"
    var sliderValues: [String: Double] = [:]

    var absEnabled = false

    var avatars: [Avatar] = [
        .init(name: "P1"),
        .init(name: "P2"),
        .init(name: "P3")
    ]
    
    init() {
        for page in pages where page.type == .slider {
            sliderValues[page.id] = page.defaultSliderValue ?? page.minValue ?? 0
        }
    }

    var selectedPage: ParameterPage {
        pages.first(where: { $0.id == selectedPageID }) ?? pages[0]
    }

    var primaryPages: [ParameterPage] {
        pages.filter { $0.section == .primary }
    }

    var advancedPages: [ParameterPage] {
        pages.filter { $0.section == .advanced }
    }

    var baseVehicleMassText: String {
        "1240 kg"
    }

    var currentPageIndex: Int {
        pages.firstIndex(where: { $0.id == selectedPageID }) ?? 0
    }

    var pageCounterText: String {
        "\(currentPageIndex + 1) / \(pages.count)"
    }

    var canGoToPreviousPage: Bool {
        currentPageIndex > 0
    }

    var canGoToNextPage: Bool {
        currentPageIndex < (pages.count - 1)
    }

    func selectPage(_ pageID: String) {
        selectedPageID = pageID
    }

    func goToNextPage() {
        guard canGoToNextPage else { return }
        selectedPageID = pages[currentPageIndex + 1].id
    }

    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        selectedPageID = pages[currentPageIndex - 1].id
    }

    func sliderValue(for pageID: String) -> Double {
        sliderValues[pageID, default: 0]
    }

    func setSliderValue(_ value: Double, for pageID: String) {
        sliderValues[pageID] = value
    }

    func sliderValue(for pageID: String, fallback: Double) -> Double {
        sliderValues[pageID, default: fallback]
    }

    func sliderBinding(for pageID: String) -> Binding<Double> {
        Binding<Double>(
            get: { self.sliderValues[pageID, default: 0] },
            set: { self.sliderValues[pageID] = $0 }
        )
    }

    func formattedValue(for page: ParameterPage) -> String {
        if page.type == .toggle {
            return absEnabled ? "ON" : "OFF"
        }

        let rawValue = sliderValue(for: page.id)
        let step = page.step ?? 1

        let decimalPlaces: Int
        if step >= 1 {
            decimalPlaces = 0
        } else if step >= 0.1 {
            decimalPlaces = 1
        } else if step >= 0.01 {
            decimalPlaces = 2
        } else {
            decimalPlaces = 3
        }

        let valueText = String(format: "%.\(decimalPlaces)f", rawValue)
        return page.unit.isEmpty ? valueText : "\(valueText) \(page.unit)"
    }

    func toggleReady() {
        setReady(!isReady)
    }

    func setReady(_ ready: Bool) {
        isReady = ready
        for index in avatars.indices {
            avatars[index].isActive = isReady
        }
    }

    func addAvatar() {
        let nextIndex = avatars.count + 1
        avatars.append(.init(name: "P\(nextIndex)", isActive: isReady))
    }

    var appliedParameterRows: [(String, String)] {
        [
            ("Vehicle Mass", formattedValueByID("vehicleMass", unitFallback: "kg", fallback: 1240)),
            ("Yaw Inertia", formattedValueByID("yawInertia", unitFallback: "kg·m²", fallback: 3350)),
            ("Rolling Radius", formattedValueByID("rollingRadius", unitFallback: "m", fallback: 0.30)),
            ("Tire Grip", formattedValueByID("tireGrip", unitFallback: "", fallback: 0.85)),
            ("Rolling Resistance", formattedValueByID("rollingResistance", unitFallback: "", fallback: 0.015)),
            ("Brake Bias", formattedValueByID("brakeBias", unitFallback: "", fallback: 0.60)),
            ("Brake Response Time", formattedValueByID("brakeResponseTime", unitFallback: "s", fallback: 0.25)),
            ("ABS", absEnabled ? "ON" : "OFF")
        ]
    }

    private func formattedValueByID(_ id: String, unitFallback: String, fallback: Double) -> String {
        let page = pages.first(where: { $0.id == id })
        let step = page?.step ?? 0.01
        let unit = page?.unit ?? unitFallback
        let value = sliderValue(for: id, fallback: fallback)
        let decimalPlaces = step >= 1 ? 0 : (step >= 0.1 ? 1 : (step >= 0.01 ? 2 : 3))
        let valueText = String(format: "%.\(decimalPlaces)f", value)
        return unit.isEmpty ? valueText : "\(valueText) \(unit)"
    }
}
