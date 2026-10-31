import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: brightnessIcon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Keyboard Brightness")
                    .font(.headline)
                Spacer()
                Text("\(Int(model.brightness * 100))%")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            // Slider
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Slider(
                    value: brightnessBinding,
                    in: 0...1,
                    step: model.stepSize
                )
                .controlSize(.small)
                Image(systemName: "sun.max")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if !model.isAvailable {
                Label("Keyboard backlight not detected", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            // Hotkey hints
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    hotkeyHint(
                        label: "Increase",
                        keyCode: model.increaseKeyCode,
                        modifiers: model.increaseModifiers
                    )
                    hotkeyHint(
                        label: "Decrease",
                        keyCode: model.decreaseKeyCode,
                        modifiers: model.decreaseModifiers
                    )
                }
                Spacer()
            }

            Divider()

            // Footer
            HStack {
                SettingsLink {
                    Label("Settings…", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit Glow")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(16)
        .frame(width: 260)
        .onAppear {
            model.refreshBrightness()
        }
    }

    // MARK: - Helpers

    private var brightnessBinding: Binding<Double> {
        Binding(
            get: { model.brightness },
            set: { model.setBrightness($0) }
        )
    }

    private var brightnessIcon: String {
        if model.brightness > 0.66 { return "light.max" }
        if model.brightness > 0.33 { return "light.min" }
        return "light.min"
    }

    private func hotkeyHint(label: String, keyCode: UInt32, modifiers: UInt32) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(KeyCombo.displayString(keyCode: keyCode, modifiers: modifiers))
                .font(.caption.monospaced())
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}
