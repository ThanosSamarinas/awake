import Foundation
import IOKit.ps

final class BatteryMonitor: ObservableObject {
    @Published private(set) var batteryLevel: Int = 100
    @Published private(set) var isOnBattery: Bool = false

    private var timer: Timer?

    func startMonitoring() {
        updateBatteryInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBatteryInfo()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateBatteryInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else { return }

        let capacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
        let powerSource = desc[kIOPSPowerSourceStateKey] as? String ?? ""

        DispatchQueue.main.async {
            self.batteryLevel = capacity
            self.isOnBattery = (powerSource == kIOPSBatteryPowerValue)
        }
    }

    deinit { stopMonitoring() }
}
