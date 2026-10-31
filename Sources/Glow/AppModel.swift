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

    init() {
        let defaults = UserDefaults.standard

        // Defaults:
        // Decrease: Option + O (kVK_ANSI_O = 31, optionKey = 0x0800)
        // Increase: Option + P (kVK_ANSI_P = 35, optionKey = 0x0800)
        defaults.register(defaults: [
            "increaseKeyCode": 35,          // 'P'
            "increaseModifiers": 0x0800,    // Option (⌥)
            "decreaseKeyCode": 31,          // 'O'
            "decreaseModifiers": 0x0800,    // Option (⌥)
            "stepSize": 0.10,               // 10% step
            "launchAtLogin": false,
            "showOSD": true
        ])

        self.increaseKeyCode = UInt32(defaults.integer(forKey: "increaseKeyCode"))
        self.increaseModifiers = UInt32(defaults.integer(forKey: "increaseModifiers"))
        self.decreaseKeyCode = UInt32(defaults.integer(forKey: "decreaseKeyCode"))
        self.decreaseModifiers = UInt32(defaults.integer(forKey: "decreaseModifiers"))
        self.stepSize = defaults.double(forKey: "stepSize")
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showOSD = defaults.bool(forKey: "showOSD")

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
    }

    // MARK: - Brightness Control

    func refreshBrightness() {
        let kb = KeyboardBrightness.shared
        self.isAvailable = kb.isAvailable
        if kb.isAvailable {
            self.brightness = Double(kb.get())
        }
    }

    func setBrightness(_ value: Double, triggerOSD: Bool = false) {
        let clamped = max(0.0, min(1.0, value))
        self.brightness = clamped
        KeyboardBrightness.shared.set(Float(clamped))

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
