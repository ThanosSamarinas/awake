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
    @Published var customSeconds: Int?
    @Published var isScheduleSession = false
    @Published var isMouseJigglerEnabled: Bool = UserDefaults.standard.bool(forKey: "mouseJigglerEnabled") {
        didSet {
            UserDefaults.standard.set(isMouseJigglerEnabled, forKey: "mouseJigglerEnabled")
            updateMouseJiggler()
        }
    }
    @Published var keepDisplayAwake: Bool = UserDefaults.standard.object(forKey: "keepDisplayAwake") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(keepDisplayAwake, forKey: "keepDisplayAwake")
            if isRunning {
                powerManager.restartKeepingAwake(keepDisplayAwake: keepDisplayAwake)
            }
        }
    }
    @Published var batteryStopThreshold: Int = UserDefaults.standard.object(forKey: "batteryStopThreshold") as? Int ?? 0 {
        didSet {
            UserDefaults.standard.set(batteryStopThreshold, forKey: "batteryStopThreshold")
        }
    }

    let powerManager = PowerManager()
    private let mouseJiggler = MouseJiggler()
    private var timer: AnyCancellable?
    private var lastSessionLabel: String = ""

    func start(duration: SessionDuration) {
        stop()
        selectedDuration = duration
        customSeconds = nil
        powerManager.startKeepingAwake(keepDisplayAwake: keepDisplayAwake)
        isRunning = powerManager.isActive
        guard isRunning else { return }
        updateMouseJiggler()
        lastSessionLabel = duration.label

        guard duration != .indefinite else { return }
        startCountdown(seconds: duration.rawValue)
    }

    func startCustom(seconds: Int) {
        stop()
        selectedDuration = .indefinite
        customSeconds = seconds
        powerManager.startKeepingAwake(keepDisplayAwake: keepDisplayAwake)
        isRunning = powerManager.isActive
        guard isRunning else { return }
        updateMouseJiggler()
        lastSessionLabel = formattedDuration(seconds)
        startCountdown(seconds: seconds)
    }

    func restartLastSession() {
        if let custom = customSeconds {
            startCustom(seconds: custom)
        } else {
            start(duration: selectedDuration)
        }
    }

    private func startCountdown(seconds: Int) {
        remainingSeconds = seconds
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    let label = self.lastSessionLabel
                    self.stop()
                    NotificationManager.shared.postSessionEnded(durationLabel: label)
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        mouseJiggler.stop()
        powerManager.stopKeepingAwake()
        isRunning = false
        isScheduleSession = false
        remainingSeconds = 0
    }

    func toggle() {
        if isRunning {
            stop()
        } else if let custom = customSeconds {
            startCustom(seconds: custom)
        } else {
            start(duration: selectedDuration)
        }
    }

    private func updateMouseJiggler() {
        if isRunning && isMouseJigglerEnabled {
            mouseJiggler.start()
        } else {
            mouseJiggler.stop()
        }
    }

    private var isTimed: Bool { remainingSeconds > 0 }

    var formattedTimeRemaining: String {
        guard isTimed else { return "∞" }
        let totalMinutes = Int(ceil(Double(remainingSeconds) / 60.0))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h\(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(max(minutes, 1))m"
    }

    var coarseTimeRemaining: String {
        guard isTimed else { return "indefinitely" }
        let totalMinutes = Int(ceil(Double(remainingSeconds) / 60.0))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if hours > 0 {
            return "\(hours)h remaining"
        } else {
            return "\(max(minutes, 1))m remaining"
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
