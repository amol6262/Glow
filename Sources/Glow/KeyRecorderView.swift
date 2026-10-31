import SwiftUI
import AppKit

/// A native button that records any single key or key combination when clicked.
struct KeyRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    var onChanged: (() -> Void)?

    func makeNSView(context: Context) -> KeyRecorderNSButton {
        let button = KeyRecorderNSButton()
        button.onKeyRecorded = { newCode, newMods in
            self.keyCode = newCode
            self.modifiers = newMods
            self.onChanged?()
        }
        button.updateDisplay(keyCode: keyCode, modifiers: modifiers)
        return button
    }

    func updateNSView(_ nsView: KeyRecorderNSButton, context: Context) {
        nsView.updateDisplay(keyCode: keyCode, modifiers: modifiers)
    }
}

final class KeyRecorderNSButton: NSButton {
    var onKeyRecorded: ((UInt32, UInt32) -> Void)?

    private var currentKeyCode: UInt32 = 0
    private var currentModifiers: UInt32 = 0
    private var isRecording = false
    private var monitor: Any?

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        target = self
        action = #selector(buttonClicked)
        font = .systemFont(ofSize: 12, weight: .medium)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDisplay(keyCode: UInt32, modifiers: UInt32) {
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers
        if !isRecording {
            let title = KeyCombo.displayString(keyCode: keyCode, modifiers: modifiers)
            self.title = title.isEmpty ? "Record Key" : title
        }
    }

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        title = "Type any key…"
        highlight(true)

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Escape key cancels without changing
            if event.keyCode == 53 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.stopRecording()
                return nil
            }

            let newCode = UInt32(event.keyCode)
            let newMods = KeyCombo.carbonModifiers(from: event.modifierFlags)

            self.stopRecording()
            self.onKeyRecorded?(newCode, newMods)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        highlight(false)
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        let title = KeyCombo.displayString(keyCode: currentKeyCode, modifiers: currentModifiers)
        self.title = title.isEmpty ? "Record Key" : title
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            stopRecording()
        }
    }
}
