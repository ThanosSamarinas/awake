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
    @Published var isMouseJigglerEnabled: Bool = UserDefaults.standard.bool(forKey: "mouseJigglerEnabled") {
        didSet {
            UserDefaults.standard.set(isMouseJigglerEnabled, forKey: "mouseJigglerEnabled")
            updateMouseJiggler()
        }
    }
    @Published var keepDisplayAwake: Bool = UserDefaults.standard.object(forKey: "keepDisplayAwake") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(keepDisplayAwake, forKey: "keepDisplayAwake")
        }
    }

    let powerManager = PowerManager()
    private let mouseJiggler = MouseJiggler()
    private var timer: AnyCancellable?

    func start(duration: SessionDuration) {
        stop()
        selectedDuration = duration
        powerManager.startKeepingAwake(keepDisplayAwake: keepDisplayAwake)
        isRunning = powerManager.isActive
        guard isRunning else { return }
        updateMouseJiggler()

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
        mouseJiggler.stop()
        powerManager.stopKeepingAwake()
        isRunning = false
        remainingSeconds = 0
    }

    func toggle() {
        isRunning ? stop() : start(duration: selectedDuration)
    }

    private func updateMouseJiggler() {
        if isRunning && isMouseJigglerEnabled {
            mouseJiggler.start()
        } else {
            mouseJiggler.stop()
        }
    }

    /// Second-precision, used only in the menu bar icon label.
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

    /// Minute-precision, used inside the menu body to avoid per-second re-renders.
    var coarseTimeRemaining: String {
        guard selectedDuration != .indefinite else { return "indefinitely" }
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
}
