import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header: Title + Current Percentage
            HStack(spacing: 8) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text("Keyboard Brightness")
                    .font(.headline)
                Spacer()
                Text("\(Int(round(model.brightness * 100)))%")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
            }

            // Slider
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { model.brightness },
                        set: { model.setBrightness($0, triggerOSD: false) }
                    ),
                    in: 0.0...1.0
                )
                .controlSize(.small)
                Image(systemName: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Preset Buttons
            HStack(spacing: 6) {
                presetButton(title: "Off", value: 0.0)
                presetButton(title: "25%", value: 0.25)
                presetButton(title: "50%", value: 0.50)
                presetButton(title: "75%", value: 0.75)
                presetButton(title: "100%", value: 1.0)
            }

            if !model.isAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Keyboard backlight not detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }

            Divider()

            // Active Shortcuts Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Decrease Brightness:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(KeyCombo.displayString(keyCode: model.decreaseKeyCode, modifiers: model.decreaseModifiers))
                        .font(.caption.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("Increase Brightness:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(KeyCombo.displayString(keyCode: model.increaseKeyCode, modifiers: model.increaseModifiers))
                        .font(.caption.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Divider()

            // Footer
            HStack {
                Button(action: onOpenSettings) {
                    Label("Settings…", systemImage: "gearshape")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Spacer()

                Button(action: onQuit) {
                    Text("Quit Glow")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func presetButton(title: String, value: Double) -> some View {
        Button(action: {
            model.setBrightness(value, triggerOSD: false)
        }) {
            Text(title)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    abs(model.brightness - value) < 0.03
                        ? Color.accentColor.opacity(0.25)
                        : Color.secondary.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}
