import Foundation

/// Controls the built-in keyboard backlight brightness via CoreBrightness framework.
@MainActor
final class KeyboardBrightness {
    static let shared = KeyboardBrightness()

    private var client: AnyObject?
    private var getBrightnessFunc: (@convention(c) (AnyObject, Selector, UInt64) -> Float)?
    private var setBrightnessFunc: (@convention(c) (AnyObject, Selector, Float, UInt64) -> Bool)?
    private var getSel: Selector?
    private var setSel: Selector?
    private(set) var keyboardID: UInt64?

    private init() {
        dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW)
        guard let cls = NSClassFromString("KeyboardBrightnessClient") as? NSObject.Type else {
            return
        }

        let clientInstance = cls.init()
        self.client = clientInstance

        let getSelector = NSSelectorFromString("brightnessForKeyboard:")
        let setSelector = NSSelectorFromString("setBrightness:forKeyboard:")
        self.getSel = getSelector
        self.setSel = setSelector

        let impGet = clientInstance.method(for: getSelector)
        self.getBrightnessFunc = unsafeBitCast(
            impGet,
            to: (@convention(c) (AnyObject, Selector, UInt64) -> Float).self
        )

        let impSet = clientInstance.method(for: setSelector)
        self.setBrightnessFunc = unsafeBitCast(
            impSet,
            to: (@convention(c) (AnyObject, Selector, Float, UInt64) -> Bool).self
        )

        if let ids = clientInstance.perform(NSSelectorFromString("copyKeyboardBacklightIDs"))?.takeRetainedValue() as? [NSNumber],
           let firstID = ids.first {
            self.keyboardID = firstID.uint64Value
        }
    }

    var isAvailable: Bool {
        client != nil && keyboardID != nil
    }

    func get() -> Float {
        guard let client = client,
              let getFunc = getBrightnessFunc,
              let sel = getSel,
              let id = keyboardID else {
            return 0
        }
        return getFunc(client, sel, id)
    }

    @discardableResult
    func set(_ value: Float) -> Bool {
        guard let client = client,
              let setFunc = setBrightnessFunc,
              let sel = setSel,
              let id = keyboardID else {
            return false
        }
        let clamped = max(0.0, min(1.0, value))
        return setFunc(client, sel, clamped, id)
    }
}
