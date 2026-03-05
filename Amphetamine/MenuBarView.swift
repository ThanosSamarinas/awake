import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var sessionTimer: SessionTimer
    @AppStorage("showCountdownInMenuBar") private var showCountdown = false
    @AppStorage("menuBarIcon") private var menuBarIconRaw = "pill"

    var body: some View {
        if sessionTimer.powerManager.assertionFailed {
            failureSection
            Divider()
        }

        if sessionTimer.isRunning {
            statusSection
            Divider()
        }

        durationSection
        Divider()
        settingsSection
        Divider()

        Button("Quit Amphetamine") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    // MARK: - Sections

    @ViewBuilder
    private var failureSection: some View {
        Text("⚠️ Could not prevent sleep")
        Text("macOS denied the power assertion.")
    }

    @ViewBuilder
    private var statusSection: some View {
        if sessionTimer.selectedDuration == .indefinite {
            Text("Active — Indefinitely")
        } else {
            Text("Active — \(sessionTimer.coarseTimeRemaining)")
        }

        Button("End Session") {
            sessionTimer.stop()
        }
        .keyboardShortcut("e")
    }

    @ViewBuilder
    private var durationSection: some View {
        ForEach(SessionDuration.allCases) { duration in
            Button(duration.label) {
                sessionTimer.start(duration: duration)
            }
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        Toggle("Keep Display Awake", isOn: $sessionTimer.keepDisplayAwake)
        Toggle("Keep Slack Active (Mouse Jiggler)", isOn: $sessionTimer.isMouseJigglerEnabled)

        Picker(selection: $menuBarIconRaw) {
            ForEach(MenuBarIcon.allCases) { icon in
                Label(icon.displayName, systemImage: icon.rawValue)
                    .tag(icon.rawValue)
            }
        } label: {
            Text("Menu Bar Icon")
        }

        Toggle("Show Time in Menu Bar", isOn: $showCountdown)

        Toggle("Launch at Login", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to update launch at login: \(error)")
                }
            }
        ))
    }
}
