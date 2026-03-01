import Foundation
import Combine

enum SessionDuration: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400
    case eightHours = 28800
    case indefinite = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .twoHours: return "2 Hours"
        case .fourHours: return "4 Hours"
        case .eightHours: return "8 Hours"
        case .indefinite: return "Indefinitely"
        }
    }
}

final class SessionTimer: ObservableObject {
    @Published var isRunning = false
    @Published var remainingSeconds: Int = 0
    @Published var selectedDuration: SessionDuration = .indefinite

    private let powerManager = PowerManager()
    private var timer: AnyCancellable?

    func start(duration: SessionDuration) {
        stop()
        selectedDuration = duration
        powerManager.startKeepingAwake()
        isRunning = true

        guard duration != .indefinite else { return }

        remainingSeconds = duration.rawValue
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        powerManager.stopKeepingAwake()
        isRunning = false
        remainingSeconds = 0
    }

    func toggle() {
        isRunning ? stop() : start(duration: selectedDuration)
    }

    var formattedTimeRemaining: String {
        guard selectedDuration != .indefinite else { return "∞" }
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
