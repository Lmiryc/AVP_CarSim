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
    static func loadDatasetSamples(fileName: String) -> [TelemetrySample] {
        let fileNameCandidates = [fileName, "LastRun", "race"]
        func urlFor(_ name: String) -> URL? {
            Bundle.main.url(forResource: name, withExtension: "csv", subdirectory: "racedataset") ??
            Bundle.main.url(forResource: name, withExtension: "csv") ??
            Bundle.main.bundleURL.appendingPathComponent("racedataset/\(name).csv")
        }
        guard let url = fileNameCandidates.compactMap(urlFor).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            return fallbackSamples()
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return fallbackSamples()
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return fallbackSamples() }

        let headers = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let indexMap = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })

        func value(_ columns: [Substring], keys: [String]) -> Double {
            for key in keys {
                if let idx = indexMap[key], idx < columns.count, let v = Double(columns[idx]) {
                    return v
                }
            }
            return 0
        }

        var samples: [TelemetrySample] = []
        samples.reserveCapacity(lines.count)

        for i in 1..<lines.count {
            let columns = lines[i].split(separator: ",", omittingEmptySubsequences: false)
            if columns.isEmpty { continue }

            let time = value(columns, keys: ["time"])
            if time == 0 && i > 1 { continue }

            let vx = value(columns, keys: ["vx", "v_x", "speed"])
            let throttle = value(columns, keys: ["throttle", "thr"])
            let brakeCommand = value(columns, keys: ["brake", "brakecommand", "pbk_con"])

            let steering = mean([
                value(columns, keys: ["steer_l1"]),
                value(columns, keys: ["steer_l2"]),
                value(columns, keys: ["steer_r1"]),
                value(columns, keys: ["steer_r2"]),
                value(columns, keys: ["steer_sw"])
            ])

            let ax = value(columns, keys: ["ax"])
            let ay = value(columns, keys: ["ay"])
            let avz = value(columns, keys: ["avz"])

            let alphaFrontAvg = mean([
                value(columns, keys: ["alpha_l1"]),
                value(columns, keys: ["alpha_l2"]),
                value(columns, keys: ["alpha_r1"]),
                value(columns, keys: ["alpha_r2"])
            ])

            let kappaFrontAvg = mean([
                value(columns, keys: ["kappa_l1"]),
                value(columns, keys: ["kappa_l2"]),
                value(columns, keys: ["kappa_r1"]),
                value(columns, keys: ["kappa_r2"])
            ])

            let fxTotal = mean([
                value(columns, keys: ["fx_l1"]),
                value(columns, keys: ["fx_l2"]),
                value(columns, keys: ["fx_r1"]),
                value(columns, keys: ["fx_r2"])
            ])
            let fyTotal = mean([
                value(columns, keys: ["fy_l1"]),
                value(columns, keys: ["fy_l2"]),
                value(columns, keys: ["fy_r1"]),
                value(columns, keys: ["fy_r2"])
            ])
            let fzTotal = mean([
                value(columns, keys: ["fz_l1"]),
                value(columns, keys: ["fz_l2"]),
                value(columns, keys: ["fz_r1"]),
                value(columns, keys: ["fz_r2"])
            ])

            let brakeFrontAvg = mean([
                value(columns, keys: ["pbkch_l1"]),
                value(columns, keys: ["pbkch_l2"])
            ])
            let brakeRearAvg = mean([
                value(columns, keys: ["pbkch_r1"]),
                value(columns, keys: ["pbkch_r2"])
            ])

            samples.append(
                TelemetrySample(
                    time: time,
                    vx: vx,
                    throttle: throttle,
                    brakeCommand: brakeCommand,
                    steering: steering,
                    ax: ax,
                    ay: ay,
                    avz: avz,
                    alphaFrontAvg: alphaFrontAvg,
                    kappaFrontAvg: kappaFrontAvg,
                    fxTotal: fxTotal,
                    fyTotal: fyTotal,
                    fzTotal: fzTotal,
                    brakeFrontAvg: brakeFrontAvg,
                    brakeRearAvg: brakeRearAvg
                )
            )
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
