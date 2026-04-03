import Foundation
import Observation

@MainActor
@Observable
final class ReadyStateController {
    enum Phase {
        case idle
        case arming
        case telemetry
    }

    private(set) var phase: Phase = .idle
    private var transitionTask: Task<Void, Never>?

    func armAndScheduleTransition(
        delaySeconds: Double = 5,
        onElapsed: @escaping @MainActor () -> Void
    ) {
        cancelPendingTransition()
        phase = .arming

        transitionTask = Task { @MainActor in
            let delayNs = UInt64(delaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNs)
            guard !Task.isCancelled else { return }
            phase = .telemetry
            onElapsed()
        }
    }

    func cancelPendingTransition() {
        transitionTask?.cancel()
        transitionTask = nil
    }

    func resetToIdle() {
        cancelPendingTransition()
        phase = .idle
    }
}
