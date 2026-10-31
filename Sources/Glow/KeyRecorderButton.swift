import SwiftUI
import AppKit

/// Sendable wrapper so an NSEvent monitor reference can live in @State.
private struct MonitorRef: @unchecked Sendable {
    let value: Any
}

/// A button that records a key combination when clicked.
/// Click once to start recording, then press any key combo. Press Escape to cancel.
struct KeyRecorderButton: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    var onChanged: (() -> Void)?

    @State private var isRecording = false
    @State private var monitor: MonitorRef?

    var body: some View {
        Button(action: { toggleRecording() }) {
            HStack(spacing: 4) {
                if isRecording {
                    Image(systemName: "record.circle")
                        .foregroundStyle(.red)
                        .font(.caption2)
                    Text("Press a key…")
                        .foregroundStyle(.secondary)
                } else {
                    Text(KeyCombo.displayString(keyCode: keyCode, modifiers: modifiers))
                }
            }
            .frame(minWidth: 100, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isRecording ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isRecording ? Color.accentColor : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onDisappear { stopRecording() }
    }

    // MARK: - Recording

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        let m = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                stopRecording()
            } else {
                keyCode = UInt32(event.keyCode)
                modifiers = KeyCombo.carbonModifiers(from: event.modifierFlags)
                stopRecording()
                onChanged?()
            }
            return nil // swallow the event
        }
        if let m { monitor = MonitorRef(value: m) }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m.value)
            monitor = nil
        }
    }
}
