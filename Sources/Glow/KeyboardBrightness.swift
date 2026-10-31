import IOKit

/// Reads and writes the built-in keyboard backlight brightness via IOKit.
enum KeyboardBrightness {

    /// Returns the current keyboard brightness (0.0–1.0) and whether the backlight is available.
    static func get() -> (available: Bool, value: Float) {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleHIDKeyboardEventDriverV2"),
            &iterator
        )
        guard result == KERN_SUCCESS else { return (false, 0) }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != IO_OBJECT_NULL {
            if let prop = IORegistryEntryCreateCFProperty(
                service,
                "KeyboardBacklightBrightness" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? NSNumber {
                let value = prop.floatValue
                IOObjectRelease(service)
                return (true, value)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return (false, 0)
    }

    /// Sets the keyboard backlight brightness (clamped to 0.0–1.0).
    static func set(_ value: Float) {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleHIDKeyboardEventDriverV2"),
            &iterator
        )
        guard result == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        let clamped = max(0, min(1, value)) as NSNumber
        var service = IOIteratorNext(iterator)
        while service != IO_OBJECT_NULL {
            IORegistryEntrySetCFProperty(
                service,
                "KeyboardBacklightBrightness" as CFString,
                clamped
            )
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }
}
