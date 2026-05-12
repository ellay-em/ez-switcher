import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

// Background
let rect = NSRect(origin: .zero, size: size)
let bgPath = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)
NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).setFill()
bgPath.fill()

// Draw two arrows (neon style)
let center = NSPoint(x: 512, y: 512)
let arrowColor = NSColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
arrowColor.setStroke()

let path = NSBezierPath()
path.lineWidth = 60
path.lineCapStyle = .round
path.lineJoinStyle = .round

// Left arrow
path.move(to: NSPoint(x: 350, y: 600))
path.line(to: NSPoint(x: 200, y: 512))
path.line(to: NSPoint(x: 350, y: 424))
path.move(to: NSPoint(x: 200, y: 512))
path.line(to: NSPoint(x: 450, y: 512))

// Right arrow
path.move(to: NSPoint(x: 674, y: 600))
path.line(to: NSPoint(x: 824, y: 512))
path.line(to: NSPoint(x: 674, y: 424))
path.move(to: NSPoint(x: 824, y: 512))
path.line(to: NSPoint(x: 574, y: 512))

path.stroke()

image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))
    print("✓ Created Resources/AppIcon.png")
}
