import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    // Current brightness (0.0 to 1.0)
    @Published var brightness: Double = 0.5
    @Published var isAvailable: Bool = false

    // Hotkey settings
    @Published var increaseKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(increaseKeyCode), forKey: "increaseKeyCode")
            registerHotkeys()
        }
    }
    @Published var increaseModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(increaseModifiers), forKey: "increaseModifiers")
            registerHotkeys()
        }
    }

    @Published var decreaseKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(decreaseKeyCode), forKey: "decreaseKeyCode")
            registerHotkeys()
        }
    }
    @Published var decreaseModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(decreaseModifiers), forKey: "decreaseModifiers")
            registerHotkeys()
        }
    }

    // Step size
    @Published var stepSize: Double {
        didSet {
            UserDefaults.standard.set(stepSize, forKey: "stepSize")
        }
    }

    // Launch at login
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    // Show OSD HUD
    @Published var showOSD: Bool {
        didSet {
            UserDefaults.standard.set(showOSD, forKey: "showOSD")
        }
    }

    // MARK: - Schedule Time Settings

    @Published var scheduleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(scheduleEnabled, forKey: "scheduleEnabled")
            if scheduleEnabled {
                evaluateSchedule(applyImmediately: true)
            } else if brightness < 0.02 {
                // If turning off schedule while brightness is 0, restore previous brightness
                let restoreVal = savedBrightness > 0.05 ? savedBrightness : 0.50
                setBrightness(restoreVal, triggerOSD: true)
            }
        }
    }

    @Published var dayHour: Int {
        didSet {
            UserDefaults.standard.set(dayHour, forKey: "dayHour")
            if scheduleEnabled { evaluateSchedule(applyImmediately: true) }
        }
    }

    @Published var dayMinute: Int {
        didSet {
            UserDefaults.standard.set(dayMinute, forKey: "dayMinute")
            if scheduleEnabled { evaluateSchedule(applyImmediately: true) }
        }
    }

    @Published var nightHour: Int {
        didSet {
            UserDefaults.standard.set(nightHour, forKey: "nightHour")
            if scheduleEnabled { evaluateSchedule(applyImmediately: true) }
        }
    }

    @Published var nightMinute: Int {
        didSet {
            UserDefaults.standard.set(nightMinute, forKey: "nightMinute")
            if scheduleEnabled { evaluateSchedule(applyImmediately: true) }
        }
    }

    // Saved brightness to restore (defaults to 50%)
    @Published var savedBrightness: Double {
        didSet {
            UserDefaults.standard.set(savedBrightness, forKey: "savedBrightness")
        }
    }

    @Published var isCurrentlyDay: Bool = false

    private var scheduleTimer: Timer?

    init() {
        let defaults = UserDefaults.standard

        // Register default values
        defaults.register(defaults: [
            "increaseKeyCode": 35,          // 'P'
            "increaseModifiers": 0x0800,    // Option (⌥)
            "decreaseKeyCode": 31,          // 'O'
            "decreaseModifiers": 0x0800,    // Option (⌥)
            "stepSize": 0.10,               // 10% step
            "launchAtLogin": false,
            "showOSD": true,
            "scheduleEnabled": false,
            "dayHour": 7,                   // 7:00 AM
            "dayMinute": 0,
            "nightHour": 19,                // 7:00 PM (19:00)
            "nightMinute": 0,
            "savedBrightness": 0.50
        ])

        self.increaseKeyCode = UInt32(defaults.integer(forKey: "increaseKeyCode"))
        self.increaseModifiers = UInt32(defaults.integer(forKey: "increaseModifiers"))
        self.decreaseKeyCode = UInt32(defaults.integer(forKey: "decreaseKeyCode"))
        self.decreaseModifiers = UInt32(defaults.integer(forKey: "decreaseModifiers"))
        self.stepSize = defaults.double(forKey: "stepSize")
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showOSD = defaults.bool(forKey: "showOSD")

        self.scheduleEnabled = defaults.bool(forKey: "scheduleEnabled")
        self.dayHour = defaults.integer(forKey: "dayHour")
        self.dayMinute = defaults.integer(forKey: "dayMinute")
        self.nightHour = defaults.integer(forKey: "nightHour")
        self.nightMinute = defaults.integer(forKey: "nightMinute")
        let saved = defaults.double(forKey: "savedBrightness")
        self.savedBrightness = saved > 0.05 ? saved : 0.50

        refreshBrightness()

        HotkeyManager.shared.setup(
            onIncrease: { [weak self] in
                self?.increase(triggerOSD: true)
            },
            onDecrease: { [weak self] in
                self?.decrease(triggerOSD: true)
            }
        )
        registerHotkeys()

        startScheduleTimer()
        evaluateSchedule(applyImmediately: false)
    }

    // MARK: - Brightness Control

    func refreshBrightness() {
        let kb = KeyboardBrightness.shared
        self.isAvailable = kb.isAvailable
        if kb.isAvailable {
            let current = Double(kb.get())
            self.brightness = current
            if current > 0.05 {
                self.savedBrightness = current
            }
        }
    }

    func setBrightness(_ value: Double, triggerOSD: Bool = false) {
        let clamped = max(0.0, min(1.0, value))
        self.brightness = clamped
        KeyboardBrightness.shared.set(Float(clamped))

        // Save preferred non-zero brightness level for restoring
        if clamped > 0.05 {
            self.savedBrightness = clamped
        }

        if triggerOSD && showOSD {
            OSDController.shared.show(brightness: clamped)
        }
    }

    func increase(triggerOSD: Bool = true) {
        setBrightness(brightness + stepSize, triggerOSD: triggerOSD)
    }

    func decrease(triggerOSD: Bool = true) {
        setBrightness(brightness - stepSize, triggerOSD: triggerOSD)
    }

    /// Toggles between fully OFF (0%) and restoring the previous brightness.
    func togglePower() {
        if brightness > 0.02 {
            // Save current level and turn off completely
            savedBrightness = brightness
            setBrightness(0.0, triggerOSD: true)
        } else {
            // Restore previous level
            let target = savedBrightness > 0.05 ? savedBrightness : 0.50
            setBrightness(target, triggerOSD: true)
        }
    }

    // MARK: - Schedule Time Logic

    var dayDate: Date {
        get {
            var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comp.hour = dayHour
            comp.minute = dayMinute
            return Calendar.current.date(from: comp) ?? Date()
        }
        set {
            let comp = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dayHour = comp.hour ?? 7
            dayMinute = comp.minute ?? 0
        }
    }

    var nightDate: Date {
        get {
            var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comp.hour = nightHour
            comp.minute = nightMinute
            return Calendar.current.date(from: comp) ?? Date()
        }
        set {
            let comp = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            nightHour = comp.hour ?? 19
            nightMinute = comp.minute ?? 0
        }
    }

    var dayTimeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: dayDate)
    }

    var nightTimeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: nightDate)
    }

    func isDaytimeNow() -> Bool {
        let cal = Calendar.current
        let now = Date()
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let cur = h * 60 + m
        let day = dayHour * 60 + dayMinute
        let night = nightHour * 60 + nightMinute

        if day < night {
            return cur >= day && cur < night
        } else {
            return cur >= day || cur < night
        }
    }

    func evaluateSchedule(applyImmediately: Bool) {
        let isDay = isDaytimeNow()
        self.isCurrentlyDay = isDay

        guard scheduleEnabled else { return }

        if isDay {
            // Day mode: Turn backlight off completely (0%)
            if brightness > 0.01 {
                savedBrightness = brightness
                setBrightness(0.0, triggerOSD: applyImmediately)
            }
        } else {
            // Night mode: Restore previous brightness
            if brightness < 0.01 {
                let toRestore = savedBrightness > 0.05 ? savedBrightness : 0.50
                setBrightness(toRestore, triggerOSD: applyImmediately)
            }
        }
    }

    private func startScheduleTimer() {
        scheduleTimer?.invalidate()
        // Checks every 30 seconds with 0% CPU footprint
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateSchedule(applyImmediately: true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.scheduleTimer = timer

        // Listen for system clock adjustments
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemClockDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateSchedule(applyImmediately: true)
            }
        }

        // Listen for system wake from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateSchedule(applyImmediately: true)
            }
        }
    }

    // MARK: - Hotkey Management

    func registerHotkeys() {
        HotkeyManager.shared.registerIncrease(
            keyCode: increaseKeyCode,
            modifiers: increaseModifiers
        )
        HotkeyManager.shared.registerDecrease(
            keyCode: decreaseKeyCode,
            modifiers: decreaseModifiers
        )
    }

    func resetToDefaults() {
        increaseKeyCode = 35       // 'P'
        increaseModifiers = 0x0800 // Option
        decreaseKeyCode = 31       // 'O'
        decreaseModifiers = 0x0800 // Option
        stepSize = 0.10
        showOSD = true
        scheduleEnabled = false
        dayHour = 7
        dayMinute = 0
        nightHour = 19
        nightMinute = 0
    }

    // MARK: - Launch At Login

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Glow: Login item update error: \(error)")
        }
    }
}
