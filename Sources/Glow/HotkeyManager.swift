import Carbon.HIToolbox
import Foundation

/// Manages global system hotkeys using Carbon's RegisterEventHotKey with zero-latency synchronous dispatch.
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var onIncrease: (() -> Void)?
    private var onDecrease: (() -> Void)?
    private var increaseRef: EventHotKeyRef?
    private var decreaseRef: EventHotKeyRef?

    /// 'GLOW' as a four-char OSType signature.
    private let signature: OSType = 0x474C_4F57

    private init() {
        installCarbonHandler()
    }

    // MARK: - Configuration

    func setup(onIncrease: @escaping () -> Void, onDecrease: @escaping () -> Void) {
        self.onIncrease = onIncrease
        self.onDecrease = onDecrease
    }

    func registerIncrease(keyCode: UInt32, modifiers: UInt32) {
        if let ref = increaseRef {
            UnregisterEventHotKey(ref)
            increaseRef = nil
        }
        let id = EventHotKeyID(signature: signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            increaseRef = ref
        }
    }

    func registerDecrease(keyCode: UInt32, modifiers: UInt32) {
        if let ref = decreaseRef {
            UnregisterEventHotKey(ref)
            decreaseRef = nil
        }
        let id = EventHotKeyID(signature: signature, id: 2)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            decreaseRef = ref
        }
    }

    // MARK: - Event Dispatch

    func fire(_ id: UInt32) {
        switch id {
        case 1:
            onIncrease?()
        case 2:
            onDecrease?()
        default:
            break
        }
    }

    // MARK: - Private

    private func installCarbonHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hk = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hk
                )
                // Execute synchronously on the main thread for 0ms latency
                MainActor.assumeIsolated {
                    HotkeyManager.shared.fire(hk.id)
                }
                return noErr
            },
            1,
            &spec,
            nil,
            nil
        )
    }
}
