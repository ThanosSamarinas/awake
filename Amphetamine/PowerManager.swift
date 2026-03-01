import Foundation
import IOKit.pwr_mgt

final class PowerManager {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    func startKeepingAwake(reason: String = "Amphetamine is keeping your Mac awake") {
        guard !isActive else { return }

        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        isActive = result == kIOReturnSuccess
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
