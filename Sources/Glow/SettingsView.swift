import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        TabView {
            generalTab(model)
                .tabItem { Label("General", systemImage: "gear") }
            hotkeysTab(model)
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 240)
    }

    // MARK: - General

    @ViewBuilder
    private func generalTab(_ model: AppModel) -> some View {
        @Bindable var model = model

        Form {
            LabeledContent("Brightness Step") {
                Picker("", selection: $model.stepSize) {
                    Text("5%").tag(0.05)
                    Text("10%").tag(0.10)
                    Text("15%").tag(0.15)
                    Text("20%").tag(0.20)
                    Text("25%").tag(0.25)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 260)
            }

            LabeledContent("Launch at Login") {
                Toggle("", isOn: $model.launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if !model.isAvailable {
                LabeledContent("Status") {
                    Label("Keyboard backlight not detected", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Hotkeys

    @ViewBuilder
    private func hotkeysTab(_ model: AppModel) -> some View {
        @Bindable var model = model

        Form {
            LabeledContent("Increase Brightness") {
                KeyRecorderButton(
                    keyCode: $model.increaseKeyCode,
                    modifiers: $model.increaseModifiers
                )
            }

            LabeledContent("Decrease Brightness") {
                KeyRecorderButton(
                    keyCode: $model.decreaseKeyCode,
                    modifiers: $model.decreaseModifiers
                )
            }

            Text("Click a field, then press the key combination you want to use.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "keyboard")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Glow")
                .font(.title2.bold())
            Text("Keyboard Brightness Control")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Version 1.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
