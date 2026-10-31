import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            scheduleTab
                .tabItem {
                    Label("Schedule Time", systemImage: "clock.arrow.circlepath")
                }
            hotkeysTab
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 320)
        .padding()
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                LabeledContent("Brightness Step:") {
                    Picker("", selection: $model.stepSize) {
                        Text("5%").tag(0.05)
                        Text("10%").tag(0.10)
                        Text("15%").tag(0.15)
                        Text("20%").tag(0.20)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                LabeledContent("Start on Startup:") {
                    Toggle("Launch Glow automatically at login", isOn: $model.launchAtLogin)
                        .toggleStyle(.checkbox)
                }

                LabeledContent("On-Screen Bezel:") {
                    Toggle("Show HUD overlay when adjusting via hotkeys", isOn: $model.showOSD)
                        .toggleStyle(.checkbox)
                }
            }
        }
        .padding(8)
    }

    // MARK: - Schedule Time Tab

    private var scheduleTab: some View {
        Form {
            Section {
                Toggle("Enable Schedule Time", isOn: $model.scheduleEnabled)
                    .font(.headline)

                Text("Automatically turns off keyboard backlight during the day to save battery, and restores your previous brightness level at night.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                Divider()

                LabeledContent("Turn Off at (Day):") {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { model.dayDate },
                            set: { model.dayDate = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .disabled(!model.scheduleEnabled)
                }

                LabeledContent("Restore at (Night):") {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { model.nightDate },
                            set: { model.nightDate = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .disabled(!model.scheduleEnabled)
                }

                LabeledContent("Restored Level:") {
                    HStack(spacing: 8) {
                        Text("\(Int(round(model.savedBrightness * 100)))%")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        Text("• Updates automatically when you adjust brightness")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Schedule Live Status Banner
                HStack(spacing: 8) {
                    if model.scheduleEnabled {
                        if model.isCurrentlyDay {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.orange)
                            Text("Daytime active: Backlight is turned off until \(model.nightTimeString)")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(.indigo)
                            Text("Nighttime active: Backlight restored to \(Int(round(model.savedBrightness * 100)))% until \(model.dayTimeString)")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Schedule Time is paused. Backlight remains manual.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(8)
    }

    // MARK: - Hotkeys Tab

    private var hotkeysTab: some View {
        Form {
            Section {
                LabeledContent("Decrease Brightness:") {
                    KeyRecorderView(
                        keyCode: $model.decreaseKeyCode,
                        modifiers: $model.decreaseModifiers
                    )
                    .frame(width: 140, height: 28)
                }

                LabeledContent("Increase Brightness:") {
                    KeyRecorderView(
                        keyCode: $model.increaseKeyCode,
                        modifiers: $model.increaseModifiers
                    )
                    .frame(width: 140, height: 28)
                }

                Text("Click a key field, then press any key or combination (e.g. O, P, ⌥O, ⌥P). Press Escape to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                HStack {
                    Spacer()
                    Button("Reset to Defaults (⌥O / ⌥P)") {
                        model.resetToDefaults()
                    }
                    .controlSize(.small)
                }
                .padding(.top, 8)
            }
        }
        .padding(8)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "keyboard.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("Glow")
                .font(.title2.bold())

            Text("Native macOS Keyboard Backlight Controller")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Engineered for ultra-low resource usage (<15 MB RAM, 0% CPU at idle).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
