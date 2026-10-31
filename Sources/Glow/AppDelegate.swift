import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let model = AppModel.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let img = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "Glow Keyboard Brightness"
            )
            img?.isTemplate = true
            button.image = img
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = item
    }

    private func setupPopover() {
        let p = NSPopover()
        p.behavior = .transient
        p.animates = true

        let menuView = MenuBarView(
            model: model,
            onOpenSettings: { [weak self] in
                self?.popover?.performClose(nil)
                SettingsWindowController.shared.show()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        p.contentViewController = NSHostingController(rootView: menuView)
        self.popover = p
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let currentEvent = NSApp.currentEvent else { return }

        // Right click opens a quick context menu
        if currentEvent.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Glow Settings…", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Glow", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
            return
        }

        // Left click toggles the popover
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            model.refreshBrightness()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
