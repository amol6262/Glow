import AppKit

/// Displays a sleek, native macOS on-screen bezel HUD when adjusting keyboard brightness.
@MainActor
final class OSDController {
    static let shared = OSDController()

    private var panel: NSPanel?
    private var levelIndicator: NSProgressIndicator?
    private var percentageLabel: NSTextField?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {
        buildPanel()
    }

    private func buildPanel() {
        let width: CGFloat = 200
        let height: CGFloat = 64

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .floating
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        // Visual Effect view (blurred translucent bezel)
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true

        // Keyboard Symbol Icon
        let iconView = NSImageView(frame: NSRect(x: 16, y: (height - 24) / 2, width: 24, height: 24))
        iconView.image = NSImage(
            systemSymbolName: "keyboard.fill",
            accessibilityDescription: "Keyboard Backlight"
        )
        iconView.contentTintColor = .labelColor
        visualEffect.addSubview(iconView)

        // Progress Bar
        let indicator = NSProgressIndicator(frame: NSRect(x: 48, y: (height - 10) / 2, width: 98, height: 10))
        indicator.isIndeterminate = false
        indicator.minValue = 0.0
        indicator.maxValue = 1.0
        indicator.doubleValue = 0.5
        indicator.style = .bar
        visualEffect.addSubview(indicator)
        self.levelIndicator = indicator

        // Percentage Label
        let label = NSTextField(labelWithString: "50%")
        label.frame = NSRect(x: 152, y: (height - 18) / 2, width: 36, height: 18)
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .right
        visualEffect.addSubview(label)
        self.percentageLabel = label

        p.contentView = visualEffect
        self.panel = p
    }

    func show(brightness: Double) {
        guard let p = panel, let screen = NSScreen.main else { return }

        // Update values
        levelIndicator?.doubleValue = brightness
        percentageLabel?.stringValue = "\(Int(round(brightness * 100)))%"

        // Center horizontally, positioned near bottom like native macOS HUD
        let screenFrame = screen.visibleFrame
        let x = screenFrame.origin.x + (screenFrame.width - p.frame.width) / 2
        let y = screenFrame.origin.y + 100
        p.setFrameOrigin(NSPoint(x: x, y: y))

        // Reset previous dismissal
        dismissWorkItem?.cancel()

        p.alphaValue = 1.0
        p.orderFrontRegardless()

        // Auto-fade after 1.2s
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let panel = self.panel else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.35
                panel.animator().alphaValue = 0.0
            }, completionHandler: {
                Task { @MainActor in
                    panel.orderOut(nil)
                }
            })
        }
        self.dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }
}
