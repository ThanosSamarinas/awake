import Foundation
import IOKit.pwr_mgt

final class PowerManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var assertionFailed = false

    private var assertionID: IOPMAssertionID = 0

    func startKeepingAwake(keepDisplayAwake: Bool, reason: String = "Awake is keeping your Mac awake") {
        guard !isActive else { return }

        let assertionType = keepDisplayAwake
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep

        let result = IOPMAssertionCreateWithName(
            assertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )

        if result == kIOReturnSuccess {
            isActive = true
            assertionFailed = false
        } else {
            isActive = false
            assertionFailed = true
        }
    }

    func restartKeepingAwake(keepDisplayAwake: Bool) {
        guard isActive else { return }
        stopKeepingAwake()
        startKeepingAwake(keepDisplayAwake: keepDisplayAwake)
    }

    func stopKeepingAwake() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        isActive = false
        assertionID = 0
    }

    deinit {
        stopKeepingAwake()
    }
}
