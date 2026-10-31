import AppKit
import QuartzCore

/// Displays a sleek, native macOS bezel HUD (identical to system volume/brightness overlays)
/// using hardware-accelerated CoreAnimation layers for zero-latency, buttery-smooth animations.
@MainActor
final class OSDController {
    static let shared = OSDController()

    private var panel: NSPanel?
    private var iconView: NSImageView?
    private var trackLayer: CALayer?
    private var fillLayer: CALayer?
    private var percentageLabel: NSTextField?
    private var dismissWorkItem: DispatchWorkItem?

    private let panelWidth: CGFloat = 210
    private let panelHeight: CGFloat = 54
    private let trackWidth: CGFloat = 100
    private let trackHeight: CGFloat = 8

    private init() {
        buildPanel()
    }

    private func buildPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
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

        // Native Visual Effect (Liquid Glass / HUD Material)
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderWidth = 0.5
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.15).cgColor

        // Left Icon: SF Symbol keyboard
        let icon = NSImageView(frame: NSRect(x: 16, y: (panelHeight - 22) / 2, width: 22, height: 22))
        icon.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "Keyboard Brightness")
        icon.contentTintColor = .labelColor
        visualEffect.addSubview(icon)
        self.iconView = icon

        // Progress Track (GPU Layer)
        let track = CALayer()
        track.frame = CGRect(x: 48, y: (panelHeight - trackHeight) / 2, width: trackWidth, height: trackHeight)
        track.cornerRadius = trackHeight / 2
        track.backgroundColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        track.masksToBounds = true

        // Progress Fill Bar (GPU Layer)
        let fill = CALayer()
        fill.frame = CGRect(x: 0, y: 0, width: 0, height: trackHeight)
        fill.cornerRadius = trackHeight / 2
        fill.backgroundColor = NSColor.white.cgColor
        track.addSublayer(fill)

        visualEffect.layer?.addSublayer(track)
        self.trackLayer = track
        self.fillLayer = fill

        // Percentage Text Label
        let label = NSTextField(labelWithString: "50%")
        label.frame = NSRect(x: 154, y: (panelHeight - 16) / 2 - 1, width: 42, height: 16)
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        label.textColor = NSColor(white: 1.0, alpha: 0.9)
        label.alignment = .right
        visualEffect.addSubview(label)
        self.percentageLabel = label

        p.contentView = visualEffect
        self.panel = p
    }

    func show(brightness: Double) {
        guard let p = panel, let screen = NSScreen.main else { return }

        let clamped = max(0.0, min(1.0, brightness))
        let targetWidth = trackWidth * CGFloat(clamped)

        // Hardware-accelerated smooth layer animation
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.08)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        fillLayer?.frame = CGRect(x: 0, y: 0, width: targetWidth, height: trackHeight)
        CATransaction.commit()

        percentageLabel?.stringValue = "\(Int(round(clamped * 100)))%"

        // Update icon intensity
        if clamped < 0.05 {
            iconView?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
            iconView?.contentTintColor = NSColor(white: 1.0, alpha: 0.4)
        } else {
            iconView?.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: nil)
            iconView?.contentTintColor = .white
        }

        // Center on screen horizontally, bottom position matching Apple's HUD
        let screenFrame = screen.visibleFrame
        let x = screenFrame.origin.x + (screenFrame.width - panelWidth) / 2
        let y = screenFrame.origin.y + 110
        p.setFrameOrigin(NSPoint(x: x, y: y))

        // Reset previous dismissal
        dismissWorkItem?.cancel()

        if p.alphaValue < 1.0 || !p.isVisible {
            p.alphaValue = 1.0
            p.orderFrontRegardless()
        }

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
