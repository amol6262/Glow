# Glow ⌨️✨

A lightweight, professional macOS utility that gives you instant keyboard backlight brightness control via customizable global shortcuts, a Control Center-style menu bar popup, and a native on-screen bezel HUD.

<p align="center">
  <img src="Resources/AppIcon.icns" width="128" height="128" alt="Glow Icon" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015+-black?style=flat-square&logo=apple" alt="macOS 15+" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-blue?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?style=flat-square&logo=swift" alt="Swift 6" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License" />
</p>

---

## ✨ Features

- **⏰ Schedule Time (Day & Night)**: Automatically turn off the keyboard backlight during the day to save battery, and automatically restore your preferred brightness at night. Fully customizable hours with instant live status.
- **⚡ Zero-Latency Hotkeys**: Instantaneous brightness adjustment with Carbon hardware-level hotkeys (`RegisterEventHotKey`). Zero polling, zero lag.
- **🎛️ Assign Any Key or Combo**: Customize shortcuts to **any** key (e.g. single keys `O`, `P`, or modifier combinations like `⌥O`, `⌥P`, `⌘⌥O`, etc.).
- **🖥️ Native macOS Bezel (HUD)**: GPU-accelerated translucent Liquid Glass on-screen display overlay matching macOS volume/brightness bezels.
- **🎚️ Control Center Menu Bar Popup**: Interactive thick capsule slider, live percentage readout, and instant presets (0%, 25%, 50%, 75%, 100%).
- **🚀 Start on Boot**: Native launch-at-login support via Apple's modern `SMAppService`.
- **🍃 Ultra-Low Resource Usage**: 0.0% CPU at idle, lightweight memory footprint (<50 MB RSS including system caches). No background timers or energy drain.

---

## 📥 Download & Installation

### Option 1: Download Pre-built DMG (Recommended)

1. Download the latest **[`Glow.dmg`](https://github.com/amol6262/Glow/releases/latest)** from the [Releases](https://github.com/amol6262/Glow/releases) section.
2. Open `Glow.dmg`.
3. Drag **Glow** into your **Applications** folder.
4. Launch **Glow** from `/Applications` or Spotlight (`⌘ Space`).

> **Note on First Launch (Gatekeeper)**:
> If macOS asks for confirmation on first opening, right-click `Glow.app` $\rightarrow$ click **Open** $\rightarrow$ click **Open**, or allow it in **System Settings > Privacy & Security**.

---

## ⌨️ Default Shortcuts

| Action | Default Shortcut | Customizable? |
| :--- | :---: | :---: |
| **Decrease Backlight** | `⌥O` (Option + O) | ✅ Any Key / Combo |
| **Increase Backlight** | `⌥P` (Option + P) | ✅ Any Key / Combo |

To assign custom keys:
1. Click the keyboard icon in the menu bar $\rightarrow$ **Settings…** (or press `⌘,`).
2. Go to the **Hotkeys** tab.
3. Click the recording field and press whatever key you want (single key `O`, `P`, function keys, or key combos).

---

## 🛠️ Building from Source

### Prerequisites
- macOS 15.0 or later
- Swift 6.0+ toolchain (`xcode-select --install` or Xcode)

### Build the App
```bash
git clone https://github.com/amol6262/Glow.git
cd Glow
./build.sh --open
```

### Build Distribution DMG
```bash
./tools/package_dmg.sh
```
The output disk image will be created at `dist/Glow.dmg`.

---

## 🧩 Architecture

- **`KeyboardBrightness.swift`**: Directly interfaces with Apple's private `CoreBrightness` engine (`KeyboardBrightnessClient`) with immediate hardware commits.
- **`HotkeyManager.swift`**: Kernel-level Carbon event hotkeys for instantaneous response without Accessibility permissions.
- **`OSDController.swift`**: Hardware-accelerated CoreAnimation layer bezel (`CALayer`) with native macOS blur (`.hudWindow`).
- **`AppDelegate.swift` & `MenuBarView.swift`**: Lightweight AppKit status item host running a pure SwiftUI Control Center interface.

---

## 📄 License

Glow is open source under the [MIT License](LICENSE).
