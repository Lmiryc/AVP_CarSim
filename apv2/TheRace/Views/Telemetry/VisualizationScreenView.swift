import SwiftUI
import Charts

struct VisualizationScreenView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let appModel: AppModel
    let parameterRows: [(String, String)]
    let onReturn: () -> Void

    @State private var allSamples: [TelemetrySample] = TelemetryLoader.loadRaceSamples()
    @State private var visibleSamples: [TelemetrySample] = []
    @State private var playbackTask: Task<Void, Never>?

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                VisualizationHeaderView(onReturn: onReturn)
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                ScrollView(.vertical) {
                    VStack(spacing: 16) {
                        VisualizationTopGrid(
                            samples: visibleSamples,
                            appModel: appModel,
                            parameterRows: parameterRows
                        )

                        VisualizationBottomRow(samples: visibleSamples)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: 1328, height: 920, alignment: .topLeading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Ensure old floating HUD is hidden while telemetry screen is active.
            dismissWindow(id: "VXDisplay")
            startTelemetryPlayback()
        }
        .onDisappear {
            playbackTask?.cancel()
            playbackTask = nil
            dismissWindow(id: "VXDisplay")
        }
    }

    private func startTelemetryPlayback() {
        playbackTask?.cancel()
        visibleSamples = []

        guard !allSamples.isEmpty else { return }
        visibleSamples = [allSamples[0]]

        playbackTask = Task { @MainActor in
            for index in 1..<allSamples.count {
                if Task.isCancelled { return }

                let previousTime = allSamples[index - 1].time
                let currentTime = allSamples[index].time
                let dt = max(0.005, currentTime - previousTime)
                let waitNs = UInt64(dt * 1_000_000_000)

                try? await Task.sleep(nanoseconds: waitNs)
                if Task.isCancelled { return }

                visibleSamples.append(allSamples[index])
            }
        }
    }
}

struct VisualizationHeaderView: View {
    let onReturn: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Simulation Telemetry")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TelemetryTheme.textPrimary)
                Text("Modular cards for dynamics, input and replay state")
                    .font(.footnote)
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }
            Spacer()
            Button("Back to Parameters", action: onReturn)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
        }
        .frame(height: 80, alignment: .top)
    }
}

struct VisualizationTopGrid: View {
    let samples: [TelemetrySample]
    let appModel: AppModel
    let parameterRows: [(String, String)]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            SpeedChartCard(samples: samples)
                .frame(minHeight: 220)
            DriverInputChartCard(samples: samples)
                .frame(minHeight: 220)
            VehicleDynamicsChartCard(samples: samples)
                .frame(minHeight: 220)
            TraceStatusCard(appModel: appModel, parameterRows: parameterRows)
                .frame(minHeight: 220)
        }
    }
}

struct VisualizationBottomRow: View {
    let samples: [TelemetrySample]

    var body: some View {
        HStack(spacing: 16) {
            TireSlipCard(samples: samples)
                .frame(maxWidth: .infinity, minHeight: 180)
            TireForceCard(samples: samples)
                .frame(maxWidth: .infinity, minHeight: 180)
            BrakeDistributionCard(samples: samples)
                .frame(maxWidth: .infinity, minHeight: 180)
        }
    }
}

struct TelemetryCardView<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TelemetryTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            shape
                .fill(.regularMaterial)
                .overlay { shape.fill(TelemetryTheme.cardBackground) }
        )
        .overlay(shape.stroke(TelemetryTheme.cardBorder, lineWidth: 1))
        .clipShape(shape)
    }
}

private struct SpeedChartCard: View {
    let samples: [TelemetrySample]
    private var latestSpeed: Double { samples.last?.vx ?? 0 }
    private var peakSpeed: Double { samples.map(\.vx).max() ?? 0 }

    var body: some View {
        TelemetryCardView(title: "Speed", subtitle: "Vx (km/h)") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart(samples) { sample in
                        LineMark(x: .value("Time", sample.time), y: .value("Speed", sample.vx))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 2.2))
                            .foregroundStyle(TelemetryTheme.speed)
                    }
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Current", String(format: "%.2f", latestSpeed), "km/h", TelemetryTheme.speed),
                    ("Peak", String(format: "%.2f", peakSpeed), "km/h", .white)
                ])
            }
        }
    }
}

private struct DriverInputChartCard: View {
    struct DriverPoint: Identifiable {
        let id = UUID()
        let t: Double
        let v: Double
        let category: String
    }

    let samples: [TelemetrySample]
    private var latestThrottle: Double { samples.last?.throttle ?? 0 }
    private var latestBrake: Double { samples.last?.brakeCommand ?? 0 }
    private var latestSteer: Double { samples.last?.steering ?? 0 }

    var points: [DriverPoint] {
        samples.flatMap { s in
            [
                DriverPoint(t: s.time, v: s.throttle, category: "Throttle"),
                DriverPoint(t: s.time, v: s.brakeCommand, category: "Brake"),
                DriverPoint(t: s.time, v: s.steering, category: "Steer")
            ]
        }
    }

    var body: some View {
        TelemetryCardView(title: "Driver Input", subtitle: "Throttle / Pbk_Con / Steer_SW") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart(points) { p in
                        LineMark(x: .value("Time", p.t), y: .value("Value", p.v))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.9))
                            .foregroundStyle(by: .value("Input", p.category))
                    }
                    .chartForegroundStyleScale([
                        "Throttle": TelemetryTheme.throttle,
                        "Brake": TelemetryTheme.brake,
                        "Steer": TelemetryTheme.steering
                    ])
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Throttle", String(format: "%.2f", latestThrottle), "", TelemetryTheme.throttle),
                    ("Brake", String(format: "%.2f", latestBrake), "", TelemetryTheme.brake),
                    ("Steer", String(format: "%.2f", latestSteer), "deg", TelemetryTheme.steering)
                ])
            }
        }
    }
}

private struct VehicleDynamicsChartCard: View {
    struct DynPoint: Identifiable {
        let id = UUID()
        let t: Double
        let v: Double
        let category: String
    }

    let samples: [TelemetrySample]
    private var latestAx: Double { samples.last?.ax ?? 0 }
    private var latestAy: Double { samples.last?.ay ?? 0 }
    private var latestAvz: Double { samples.last?.avz ?? 0 }

    var points: [DynPoint] {
        samples.flatMap { s in
            [
                DynPoint(t: s.time, v: s.ax, category: "Ax"),
                DynPoint(t: s.time, v: s.ay, category: "Ay"),
                DynPoint(t: s.time, v: s.avz, category: "AVz")
            ]
        }
    }

    var body: some View {
        TelemetryCardView(title: "Vehicle Dynamics", subtitle: "Ax / Ay / AVz") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart(points) { p in
                        LineMark(x: .value("Time", p.t), y: .value("Value", p.v))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.9))
                            .foregroundStyle(by: .value("Channel", p.category))
                    }
                    .chartForegroundStyleScale([
                        "Ax": TelemetryTheme.ax,
                        "Ay": TelemetryTheme.ay,
                        "AVz": TelemetryTheme.avz
                    ])
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Ax", String(format: "%.3f", latestAx), "", TelemetryTheme.ax),
                    ("Ay", String(format: "%.3f", latestAy), "", TelemetryTheme.ay),
                    ("AVz", String(format: "%.3f", latestAvz), "", TelemetryTheme.avz)
                ])
            }
        }
    }
}

private struct TraceStatusCard: View {
    let appModel: AppModel
    let parameterRows: [(String, String)]

    var body: some View {
        TelemetryCardView(title: "Trace / Replay Status", subtitle: "Current simulation state and applied setup") {
            VStack(alignment: .leading, spacing: 10) {
                statusRow("Simulation", appModel.isAnimating ? "Running" : "Idle")
                statusRow("Trigger Flag", appModel.shouldStartAnimation ? "Queued" : "None")
                statusRow("Current Vx", String(format: "%.2f km/h", appModel.currentVX))

                Divider().overlay(.white.opacity(0.14))

                Text("Applied Parameters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TelemetryTheme.textPrimary)

                ScrollView(.vertical) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(parameterRows, id: \.0) { row in
                            compactStatusRow(row.0, row.1)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(TelemetryTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(TelemetryTheme.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.caption)
    }

    private func compactStatusRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(TelemetryTheme.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TelemetryTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TireSlipCard: View {
    let samples: [TelemetrySample]
    private var latestAlpha: Double { samples.last?.alphaFrontAvg ?? 0 }
    private var latestKappa: Double { samples.last?.kappaFrontAvg ?? 0 }

    var body: some View {
        TelemetryCardView(title: "Tire Slip", subtitle: "Alpha_* / Kappa_* (front avg)") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart(samples) { s in
                        LineMark(x: .value("Time", s.time), y: .value("Alpha", s.alphaFrontAvg))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.8))
                            .foregroundStyle(.mint)
                        LineMark(x: .value("Time", s.time), y: .value("Kappa", s.kappaFrontAvg))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.8))
                            .foregroundStyle(.cyan)
                    }
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Alpha", String(format: "%.3f", latestAlpha), "", .mint),
                    ("Kappa", String(format: "%.3f", latestKappa), "", .cyan)
                ])
            }
        }
    }
}

private struct TireForceCard: View {
    let samples: [TelemetrySample]
    private var latestFx: Double { samples.last?.fxTotal ?? 0 }
    private var latestFy: Double { samples.last?.fyTotal ?? 0 }
    private var latestFz: Double { samples.last?.fzTotal ?? 0 }

    var body: some View {
        TelemetryCardView(title: "Tire Forces", subtitle: "Fx_* / Fy_* / Fz_* (avg)") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart(samples) { s in
                        LineMark(x: .value("Time", s.time), y: .value("Fx", s.fxTotal))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.8))
                            .foregroundStyle(.yellow)
                        LineMark(x: .value("Time", s.time), y: .value("Fy", s.fyTotal))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.8))
                            .foregroundStyle(.green)
                        LineMark(x: .value("Time", s.time), y: .value("Fz", s.fzTotal))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(.init(lineWidth: 1.8))
                            .foregroundStyle(.purple)
                    }
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Fx", String(format: "%.0f", latestFx), "", .yellow),
                    ("Fy", String(format: "%.0f", latestFy), "", .green),
                    ("Fz", String(format: "%.0f", latestFz), "", .purple)
                ])
            }
        }
    }
}

private struct BrakeDistributionCard: View {
    let samples: [TelemetrySample]
    private var front: Double { samples.last?.brakeFrontAvg ?? 0 }
    private var rear: Double { samples.last?.brakeRearAvg ?? 0 }
    private var upperBound: Double { max(1, max(front, rear)) }

    var body: some View {
        TelemetryCardView(title: "Brake Distribution", subtitle: "PbkCh_* front vs rear") {
            VStack(spacing: 10) {
                ChartSurface {
                    Chart {
                        BarMark(x: .value("Group", "Front"), y: .value("Pressure", front))
                            .foregroundStyle(TelemetryTheme.brake)
                        BarMark(x: .value("Group", "Rear"), y: .value("Pressure", rear))
                            .foregroundStyle(TelemetryTheme.avz)
                    }
                    .chartYScale(domain: 0...upperBound)
                    .telemetryChartStyle()
                }
                MetricSummaryRow(metrics: [
                    ("Front", String(format: "%.1f", front), "", TelemetryTheme.brake),
                    ("Rear", String(format: "%.1f", rear), "", TelemetryTheme.avz)
                ])
            }
        }
    }
}

private struct ChartSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(height: 112)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct MetricSummaryRow: View {
    let metrics: [(title: String, value: String, unit: String, color: Color)]

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    HStack(spacing: 3) {
                        Text(metric.value)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(metric.color)
                        if !metric.unit.isEmpty {
                            Text(metric.unit)
                                .font(.caption2)
                                .foregroundStyle(TelemetryTheme.textSecondary)
                        }
                    }
                }
                if index < metrics.count - 1 {
                    Divider().overlay(.white.opacity(0.10))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func telemetryChartStyle() -> some View {
        self
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: .init(lineWidth: 0.6))
                        .foregroundStyle(.white.opacity(0.12))
                    AxisTick(stroke: .init(lineWidth: 0.6))
                        .foregroundStyle(.white.opacity(0.26))
                    AxisValueLabel()
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: .init(lineWidth: 0.6))
                        .foregroundStyle(.white.opacity(0.12))
                    AxisTick(stroke: .init(lineWidth: 0.6))
                        .foregroundStyle(.white.opacity(0.26))
                    AxisValueLabel()
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
            }
            .chartLegend(.hidden)
    }
}
