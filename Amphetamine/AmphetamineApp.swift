import SwiftUI

@main
struct AmphetamineApp: App {
    @StateObject private var sessionTimer = SessionTimer()
    @AppStorage("showCountdownInMenuBar") private var showCountdown = false
    @AppStorage("menuBarIcon") private var menuBarIconRaw = "pill"

    private var menuBarIcon: MenuBarIcon {
        MenuBarIcon(rawValue: menuBarIconRaw) ?? .pill
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(sessionTimer: sessionTimer)
        } label: {
            if showCountdown && sessionTimer.isRunning && sessionTimer.remainingSeconds > 0 {
                Label(sessionTimer.formattedTimeRemaining, systemImage: menuBarIcon.filledSymbol)
            } else {
                Image(systemName: sessionTimer.isRunning ? menuBarIcon.filledSymbol : menuBarIcon.rawValue)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
