import AppKit
import CoreGraphics

func makeIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: s * 0.08, y: s * 0.08, width: s * 0.84, height: s * 0.84)
    let corner = s * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Background squircle with deep dark blue-gray metallic gradient
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colors = [
        NSColor(red: 0.16, green: 0.18, blue: 0.24, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor
    ] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

    // Ambient keyboard warm gold/amber glow from center-bottom
    let glowColors = [
        NSColor(red: 1.0, green: 0.78, blue: 0.35, alpha: 0.45).cgColor,
        NSColor(red: 1.0, green: 0.65, blue: 0.20, alpha: 0.0).cgColor
    ] as CFArray
    let glowGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(
        glowGrad,
        startCenter: CGPoint(x: s * 0.5, y: s * 0.42),
        startRadius: 0,
        endCenter: CGPoint(x: s * 0.5, y: s * 0.42),
        endRadius: s * 0.40,
        options: []
    )

    // Border highlight
    ctx.setStrokeColor(NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.35).cgColor)
    ctx.setLineWidth(s * 0.015)
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()

    // Draw keyboard symbol in the center
    let config = NSImage.SymbolConfiguration(pointSize: s * 0.38, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let drawRect = CGRect(
            x: (s - symbolSize.width) / 2,
            y: (s - symbolSize.height) / 2 + s * 0.02,
            width: symbolSize.width,
            height: symbolSize.height
        )

        // Draw symbol with warm amber tint
        ctx.saveGState()
        symbol.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        ctx.restoreGState()
    }

    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "Glow.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let image = makeIcon(size: size)
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(name)"
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

try? fileManager.createDirectory(atPath: "Resources", withIntermediateDirectories: true)
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
try? task.run()
task.waitUntilExit()

try? fileManager.removeItem(atPath: iconsetDir)
print("Generated Resources/AppIcon.icns successfully!")
