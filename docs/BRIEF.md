# Glow

A lightweight menu bar utility that controls keyboard backlight brightness with customizable global hotkeys.

## Replaces
Reaching for function keys or Touch Bar to adjust keyboard brightness.

## Main jobs
1. Increase keyboard brightness with a global hotkey
2. Decrease keyboard brightness with a global hotkey
3. Show and adjust current keyboard brightness from the menu bar

## Data
- Preferences: increase hotkey (keyCode + modifiers), decrease hotkey, step size, launch at login

## Shape
Menu bar extra (LSUIElement, no Dock icon), macOS 15 or later.
Local preferences only. Works offline. No accounts.

## System hooks
Global hotkey (Carbon RegisterEventHotKey), menu bar item (MenuBarExtra), launch at login (SMAppService).

## Reference
None.

## Look
Native with system accent color. Minimal UI: a menu bar icon and a compact settings window.

## Not in version one
- Display brightness control
- Automatic brightness based on ambient light
- Multiple keyboard support
- Custom brightness OSD overlay
