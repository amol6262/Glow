import SwiftUI
import ServiceManagement

@Observable
@MainActor
final class AppModel {
    // Current brightness (0.0 – 1.0)
    var brightness: Double = 0
    var isAvailable: Bool = false

    // Increase hotkey
    var increaseKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(increaseKeyCode), forKey: "increaseKeyCode")
            registerHotkeys()
        }
    }
    var increaseModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(increaseModifiers), forKey: "increaseModifiers")
            registerHotkeys()
        }
    }

    // Decrease hotkey
    var decreaseKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(decreaseKeyCode), forKey: "decreaseKeyCode")
            registerHotkeys()
        }
    }
    var decreaseModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(decreaseModifiers), forKey: "decreaseModifiers")
            registerHotkeys()
        }
    }

    // Step size (fraction of 1.0)
    var stepSize: Double {
        didSet {
            UserDefaults.standard.set(stepSize, forKey: "stepSize")
        }
    }

    // Launch at login
    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    init() {
        let defaults = UserDefaults.standard

        // Register default values for first launch
        defaults.register(defaults: [
            "increaseKeyCode": 0x18,     // kVK_ANSI_Equal (=)
            "increaseModifiers": 0x1800, // controlKey | optionKey
            "decreaseKeyCode": 0x1B,     // kVK_ANSI_Minus (-)
            "decreaseModifiers": 0x1800, // controlKey | optionKey
            "stepSize": 0.1,
            "launchAtLogin": false,
        ])

        self.increaseKeyCode = UInt32(defaults.integer(forKey: "increaseKeyCode"))
        self.increaseModifiers = UInt32(defaults.integer(forKey: "increaseModifiers"))
        self.decreaseKeyCode = UInt32(defaults.integer(forKey: "decreaseKeyCode"))
        self.decreaseModifiers = UInt32(defaults.integer(forKey: "decreaseModifiers"))
        self.stepSize = defaults.double(forKey: "stepSize")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        refreshBrightness()

        HotkeyManager.shared.setup(
            onIncrease: { [weak self] in self?.increase() },
            onDecrease: { [weak self] in self?.decrease() }
        )
        registerHotkeys()
    }

    // MARK: - Brightness

    func refreshBrightness() {
        let result = KeyboardBrightness.get()
        isAvailable = result.available
        if result.available {
            brightness = Double(result.value)
        }
    }

    func setBrightness(_ value: Double) {
        brightness = max(0, min(1, value))
        KeyboardBrightness.set(Float(brightness))
    }

    func increase() {
        setBrightness(brightness + stepSize)
    }

    func decrease() {
        setBrightness(brightness - stepSize)
    }

    // MARK: - Hotkeys

    func registerHotkeys() {
        HotkeyManager.shared.registerIncrease(
            keyCode: increaseKeyCode, modifiers: increaseModifiers)
        HotkeyManager.shared.registerDecrease(
            keyCode: decreaseKeyCode, modifiers: decreaseModifiers)
    }

    // MARK: - Login item

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Login item error: \(error)")
        }
    }
}
