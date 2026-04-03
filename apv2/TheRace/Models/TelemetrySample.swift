import Foundation

struct TelemetrySample: Identifiable {
    let id = UUID()
    let time: Double

    let vx: Double
    let throttle: Double
    let brakeCommand: Double
    let steering: Double

    let ax: Double
    let ay: Double
    let avz: Double

    let alphaFrontAvg: Double
    let kappaFrontAvg: Double

    let fxTotal: Double
    let fyTotal: Double
    let fzTotal: Double

    let brakeFrontAvg: Double
    let brakeRearAvg: Double
}

enum TelemetryLoader {
    static func loadRaceSamples() -> [TelemetrySample] {
        guard let url = Bundle.main.url(forResource: "race", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return fallbackSamples()
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return fallbackSamples() }

        let headers = lines[0].components(separatedBy: ",")
        let indexMap = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })

        func value(_ columns: [Substring], _ key: String) -> Double {
            guard let idx = indexMap[key], idx < columns.count else { return 0 }
            return Double(columns[idx]) ?? 0
        }

        var samples: [TelemetrySample] = []
        samples.reserveCapacity(lines.count / 8)

        for i in stride(from: 1, to: lines.count, by: 8) {
            let columns = lines[i].split(separator: ",", omittingEmptySubsequences: false)
            if columns.isEmpty { continue }

            let sample = TelemetrySample(
                time: value(columns, "Time"),
                vx: value(columns, "Vx"),
                throttle: value(columns, "Throttle"),
                brakeCommand: value(columns, "Pbk_Con"),
                steering: value(columns, "Steer_SW"),
                ax: value(columns, "Ax"),
                ay: value(columns, "Ay"),
                avz: value(columns, "AVz"),
                alphaFrontAvg: mean([
                    value(columns, "Alpha_L1"),
                    value(columns, "Alpha_L2"),
                    value(columns, "Alpha_R1"),
                    value(columns, "Alpha_R2")
                ]),
                kappaFrontAvg: mean([
                    value(columns, "Kappa_L1"),
                    value(columns, "Kappa_L2"),
                    value(columns, "Kappa_R1"),
                    value(columns, "Kappa_R2")
                ]),
                fxTotal: mean([
                    value(columns, "Fx_L1"),
                    value(columns, "Fx_L2"),
                    value(columns, "Fx_R1"),
                    value(columns, "Fx_R2")
                ]),
                fyTotal: mean([
                    value(columns, "Fy_L1"),
                    value(columns, "Fy_L2"),
                    value(columns, "Fy_R1"),
                    value(columns, "Fy_R2")
                ]),
                fzTotal: mean([
                    value(columns, "Fz_L1"),
                    value(columns, "Fz_L2"),
                    value(columns, "Fz_R1"),
                    value(columns, "Fz_R2")
                ]),
                brakeFrontAvg: mean([
                    value(columns, "PbkCh_L1"),
                    value(columns, "PbkCh_L2")
                ]),
                brakeRearAvg: mean([
                    value(columns, "PbkCh_R1"),
                    value(columns, "PbkCh_R2")
                ])
            )

            samples.append(sample)
        }

        return samples.isEmpty ? fallbackSamples() : samples
    }

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func fallbackSamples() -> [TelemetrySample] {
        stride(from: 0.0, through: 60.0, by: 0.5).map { t in
            TelemetrySample(
                time: t,
                vx: 90 + 18 * sin(t / 6),
                throttle: max(0, min(1, 0.55 + 0.35 * sin(t / 5))),
                brakeCommand: max(0, min(1, 0.25 + 0.2 * cos(t / 4))),
                steering: 12 * sin(t / 3.8),
                ax: 0.6 * sin(t / 7),
                ay: 0.9 * cos(t / 5.6),
                avz: 0.35 * sin(t / 4.2),
                alphaFrontAvg: 0.8 * sin(t / 8),
                kappaFrontAvg: 0.2 * cos(t / 9),
                fxTotal: 4200 + 500 * sin(t / 4),
                fyTotal: 2500 + 320 * cos(t / 6),
                fzTotal: 3900 + 420 * sin(t / 5),
                brakeFrontAvg: 420 * max(0, cos(t / 8)),
                brakeRearAvg: 360 * max(0, sin(t / 8))
            )
        }
    }
}
