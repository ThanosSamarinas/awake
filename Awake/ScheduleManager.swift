import Foundation
import Combine

final class ScheduleManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "scheduleEnabled") }
    }
    @Published var startHour: Int {
        didSet { UserDefaults.standard.set(startHour, forKey: "scheduleStartHour") }
    }
    @Published var startMinute: Int {
        didSet { UserDefaults.standard.set(startMinute, forKey: "scheduleStartMinute") }
    }
    @Published var endHour: Int {
        didSet { UserDefaults.standard.set(endHour, forKey: "scheduleEndHour") }
    }
    @Published var endMinute: Int {
        didSet { UserDefaults.standard.set(endMinute, forKey: "scheduleEndMinute") }
    }

    var onShouldStart: (() -> Void)?
    var onShouldStop: (() -> Void)?

    private var timer: Timer?
    private var wasInSchedule = false

    init() {
        let d = UserDefaults.standard
        isEnabled = d.bool(forKey: "scheduleEnabled")
        startHour = d.object(forKey: "scheduleStartHour") as? Int ?? 9
        startMinute = d.object(forKey: "scheduleStartMinute") as? Int ?? 0
        endHour = d.object(forKey: "scheduleEndHour") as? Int ?? 17
        endMinute = d.object(forKey: "scheduleEndMinute") as? Int ?? 0
    }

    var isInSchedule: Bool {
        guard isEnabled else { return false }
        let cal = Calendar.current
        let now = Date()
        let current = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute

        if start <= end {
            return current >= start && current < end
        }
        return current >= start || current < end
    }

    var scheduleDescription: String {
        "\(formatTime(hour: startHour, minute: startMinute)) – \(formatTime(hour: endHour, minute: endMinute))"
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        if minute == 0 { return "\(h) \(period)" }
        let m = String(format: "%02d", minute)
        return "\(h):\(m) \(period)"
    }

    func startMonitoring() {
        wasInSchedule = isInSchedule
        if wasInSchedule { onShouldStart?() }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func evaluate() {
        guard isEnabled else {
            if wasInSchedule {
                wasInSchedule = false
                onShouldStop?()
            }
            return
        }

        let inSchedule = isInSchedule
        if inSchedule && !wasInSchedule {
            wasInSchedule = true
            onShouldStart?()
        } else if !inSchedule && wasInSchedule {
            wasInSchedule = false
            onShouldStop?()
        }
    }

    deinit { stopMonitoring() }
}
