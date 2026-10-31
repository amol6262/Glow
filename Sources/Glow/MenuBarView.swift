import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header: Title, Power Toggle & Percentage
            HStack(spacing: 8) {
                Button(action: {
                    model.togglePower()
                }) {
                    Image(systemName: model.brightness > 0.02 ? "keyboard.fill" : "keyboard")
                        .font(.system(size: 15))
                        .foregroundStyle(model.brightness > 0.02 ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(model.brightness > 0.02 ? "Click to turn off backlight" : "Click to restore previous brightness")

                Text("Keyboard Brightness")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Button(action: {
                    model.togglePower()
                }) {
                    Text(model.brightness > 0.02 ? "\(Int(round(model.brightness * 100)))%" : "Off")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(model.brightness > 0.02 ? Color.primary : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            // Apple Control Center Style Interactive Slider
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 34
                let fillWidth = max(0, min(width, width * CGFloat(model.brightness)))

                ZStack(alignment: .leading) {
                    // Slider Background Track
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    // Interactive Fill Bar
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color.white.opacity(0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth)

                    // Icon & Level inside the slider
                    HStack {
                        Image(systemName: model.brightness > 0.05 ? "keyboard.fill" : "keyboard")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(model.brightness > 0.35 ? Color.black.opacity(0.75) : Color.primary)
                            .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(model.brightness > 0.85 ? Color.black.opacity(0.6) : Color.secondary)
                            .padding(.trailing, 12)
                    }
                }
                .frame(height: height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let percent = Double(max(0, min(1, value.location.x / width)))
                            model.setBrightness(percent, triggerOSD: false)
                        }
                )
            }
            .frame(height: 34)

            // Preset Buttons (Off, 25%, 50%, 75%, Max)
            HStack(spacing: 5) {
                presetButton(title: "Off", value: 0.0)
                presetButton(title: "25%", value: 0.25)
                presetButton(title: "50%", value: 0.50)
                presetButton(title: "75%", value: 0.75)
                presetButton(title: "Max", value: 1.0)
            }

            // Schedule Time Feature Card
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: model.scheduleEnabled
                          ? (model.isCurrentlyDay ? "sun.max.fill" : "moon.stars.fill")
                          : "clock.arrow.circlepath")
                        .font(.system(size: 13))
                        .foregroundStyle(model.scheduleEnabled
                                         ? (model.isCurrentlyDay ? Color.orange : Color.indigo)
                                         : Color.secondary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Schedule Time")
                            .font(.system(size: 12, weight: .medium))

                        if model.scheduleEnabled {
                            if model.isCurrentlyDay {
                                Text("☀️ Off (Day) • Restores at \(model.nightTimeString)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("🌙 Restored (\(Int(round(model.savedBrightness * 100)))%) • Off at \(model.dayTimeString)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Off during day • Restored at night")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $model.scheduleEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if !model.isAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Keyboard backlight not detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Active Shortcuts Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Decrease Brightness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    keyBadge(KeyCombo.displayString(keyCode: model.decreaseKeyCode, modifiers: model.decreaseModifiers))
                }
                HStack {
                    Text("Increase Brightness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    keyBadge(KeyCombo.displayString(keyCode: model.increaseKeyCode, modifiers: model.increaseModifiers))
                }
            }

            Divider()

            // Footer
            HStack {
                Button(action: onOpenSettings) {
                    Label("Settings…", systemImage: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Spacer()

                Button(action: onQuit) {
                    Text("Quit Glow")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    private func presetButton(title: String, value: Double) -> some View {
        let isSelected = abs(model.brightness - value) < 0.05
        return Button(action: {
            if value == 0.0 {
                // If user clicks Off, save current level so they can restore it
                if model.brightness > 0.05 {
                    model.savedBrightness = model.brightness
                }
                model.setBrightness(0.0, triggerOSD: false)
            } else {
                model.setBrightness(value, triggerOSD: false)
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    isSelected
                        ? Color(nsColor: .selectedControlColor).opacity(0.35)
                        : Color.secondary.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func keyBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
