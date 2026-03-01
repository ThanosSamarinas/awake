import SwiftUI

@main
struct AmphetamineApp: App {
    @StateObject private var sessionTimer = SessionTimer()
    @AppStorage("showCountdownInMenuBar") private var showCountdown = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(sessionTimer: sessionTimer)
        } label: {
            if showCountdown && sessionTimer.isRunning && sessionTimer.selectedDuration != .indefinite {
                Label(sessionTimer.formattedTimeRemaining, systemImage: "pill.fill")
            } else {
                Image(systemName: sessionTimer.isRunning ? "pill.fill" : "pill")
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
