import AppKit
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    let sessionTimer = SessionTimer()
    private let batteryMonitor = BatteryMonitor()
    private let scheduleManager = ScheduleManager()
    private var cancellables = Set<AnyCancellable>()
    private var isShowingMenu = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.requestAuthorization()
        NotificationManager.shared.onRestartRequested = { [weak self] in
            self?.sessionTimer.restartLastSession()
        }

        setupStatusItem()
        setupBindings()

        batteryMonitor.startMonitoring()
        scheduleManager.startMonitoring()

        scheduleManager.onShouldStart = { [weak self] in
            guard let self, !self.sessionTimer.isRunning else { return }
            self.sessionTimer.start(duration: .indefinite)
            self.sessionTimer.isScheduleSession = true
        }
        scheduleManager.onShouldStop = { [weak self] in
            guard let self, self.sessionTimer.isScheduleSession else { return }
            self.sessionTimer.stop()
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusItemAppearance()
    }

    private func setupBindings() {
        sessionTimer.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateStatusItemAppearance() }
        }.store(in: &cancellables)

        batteryMonitor.$batteryLevel
            .combineLatest(batteryMonitor.$isOnBattery)
            .sink { [weak self] level, onBattery in
                guard let self else { return }
                let threshold = self.sessionTimer.batteryStopThreshold
                guard threshold > 0, level <= threshold, onBattery, self.sessionTimer.isRunning else { return }
                self.sessionTimer.stop()
                NotificationManager.shared.postSessionEnded(durationLabel: "battery cutoff (\(threshold)%)")
            }
            .store(in: &cancellables)
    }

    @objc private func handleStatusItemClick() {
        guard !isShowingMenu else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp
            || event.modifierFlags.contains(.option)
            || event.modifierFlags.contains(.control)
        {
            showMenu()
        } else {
            sessionTimer.toggle()
        }
    }

    private func showMenu() {
        isShowingMenu = true
        statusItem.menu = buildMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
        isShowingMenu = false
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }
        let showCountdown = UserDefaults.standard.bool(forKey: "showCountdownInMenuBar")
        let symbolName = sessionTimer.isRunning ? "star.hexagon.fill" : "star.hexagon"
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Awake")

        if showCountdown && sessionTimer.isRunning && sessionTimer.remainingSeconds > 0 {
            button.title = " \(sessionTimer.formattedTimeRemaining)"
            button.imagePosition = .imageLeading
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }

        if sessionTimer.isRunning {
            if sessionTimer.remainingSeconds > 0 {
                button.toolTip = "Awake — \(sessionTimer.coarseTimeRemaining)"
            } else {
                button.toolTip = "Awake — Active indefinitely"
            }
        } else {
            let nextLabel = sessionTimer.selectedDuration.label.lowercased()
            button.toolTip = "Awake — Inactive\nClick to start (\(nextLabel)), right-click for menu"
        }
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        if sessionTimer.powerManager.assertionFailed {
            menu.addItem(disabled("⚠️ Could not prevent sleep"))
            menu.addItem(disabled("macOS denied the power assertion."))
            menu.addItem(.separator())
        }

        if sessionTimer.isRunning {
            let status = sessionTimer.remainingSeconds > 0
                ? "Active — \(sessionTimer.coarseTimeRemaining)"
                : "Active — Indefinitely"
            menu.addItem(disabled(status))
            menu.addItem(action("End Session", sel: #selector(endSession), key: "e"))
            menu.addItem(.separator())
        }

        for duration in SessionDuration.allCases {
            menu.addItem(action(duration.label, sel: #selector(startDuration(_:)), tag: duration.rawValue))
        }
        menu.addItem(submenuItem("Custom…", menu: buildCustomMenu()))
        menu.addItem(.separator())

        menu.addItem(toggle("Keep Display On", on: sessionTimer.keepDisplayAwake, sel: #selector(toggleDisplayAwake)))
        menu.addItem(toggle("Keep Status Active", on: sessionTimer.isMouseJigglerEnabled, sel: #selector(toggleMouseJiggler)))
        menu.addItem(toggle("Show Time Remaining", on: UserDefaults.standard.bool(forKey: "showCountdownInMenuBar"), sel: #selector(toggleCountdown)))
        menu.addItem(.separator())

        menu.addItem(submenuItem("Low Battery Cutoff", menu: buildBatteryMenu()))
        menu.addItem(toggle("Launch at Login",
                            on: SMAppService.mainApp.status == .enabled,
                            sel: #selector(toggleLaunchAtLogin)))
        menu.addItem(.separator())
        menu.addItem(action("Quit Awake", sel: #selector(quitApp), key: "q"))

        return menu
    }

    private func buildBatteryMenu() -> NSMenu {
        let m = NSMenu()
        let current = sessionTimer.batteryStopThreshold
        for (label, value) in [("Off", 0), ("10%", 10), ("20%", 20), ("30%", 30)] {
            let item = NSMenuItem(title: label, action: #selector(setBatteryCutoff(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            item.state = value == current ? .on : .off
            m.addItem(item)
        }
        return m
    }

    private func buildCustomMenu() -> NSMenu {
        let m = NSMenu()
        m.addItem(action("Set Duration…", sel: #selector(startCustom)))
        m.addItem(.separator())
        m.addItem(toggle("Schedule", on: scheduleManager.isEnabled, sel: #selector(toggleSchedule)))
        m.addItem(disabled(scheduleManager.scheduleDescription))
        m.addItem(action("Set Times…", sel: #selector(setScheduleTimes)))
        return m
    }

    // MARK: - Menu Helpers

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func action(_ title: String, sel: Selector, key: String = "", tag: Int = 0) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        item.target = self
        item.tag = tag
        return item
    }

    private func toggle(_ title: String, on: Bool, sel: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    private func submenuItem(_ title: String, menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    // MARK: - Actions

    @objc private func endSession() { sessionTimer.stop() }

    @objc private func startDuration(_ sender: NSMenuItem) {
        guard let duration = SessionDuration(rawValue: sender.tag) else { return }
        sessionTimer.isScheduleSession = false
        sessionTimer.start(duration: duration)
    }

    @objc private func startCustom() {
        guard let seconds = askForCustomDuration() else { return }
        sessionTimer.isScheduleSession = false
        sessionTimer.startCustom(seconds: seconds)
    }

    @objc private func toggleDisplayAwake() { sessionTimer.keepDisplayAwake.toggle() }
    @objc private func toggleMouseJiggler() { sessionTimer.isMouseJigglerEnabled.toggle() }

    @objc private func toggleCountdown() {
        let key = "showCountdownInMenuBar"
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: key), forKey: key)
        updateStatusItemAppearance()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }

    @objc private func setBatteryCutoff(_ sender: NSMenuItem) {
        sessionTimer.batteryStopThreshold = sender.tag
    }

    @objc private func toggleSchedule() {
        scheduleManager.isEnabled.toggle()
        scheduleManager.evaluate()
    }

    @objc private func setScheduleTimes() {
        guard let times = askForScheduleTimes(
            currentStart: (scheduleManager.startHour, scheduleManager.startMinute),
            currentEnd: (scheduleManager.endHour, scheduleManager.endMinute)
        ) else { return }
        scheduleManager.startHour = times.start.0
        scheduleManager.startMinute = times.start.1
        scheduleManager.endHour = times.end.0
        scheduleManager.endMinute = times.end.1
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }
}
