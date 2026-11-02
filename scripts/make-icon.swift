// Builds the app icon (.icns) from the first idle frame of a Codex v2 sprite sheet.
// The artwork is © Gravity, so the icon is made at build time and never committed.
// Usage: swift scripts/make-icon.swift <spritesheet.webp> <out.icns>
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let sheet = NSImage(contentsOfFile: args[1]),
      let cg = sheet.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let cell = cg.cropping(to: CGRect(x: 0, y: 0, width: 192, height: 208)) else {
    FileHandle.standardError.write("usage: make-icon.swift <spritesheet.webp> <out.icns>\n".data(using: .utf8)!)
    exit(1)
}

// The opaque part of the frame, so the character fills the icon whatever its padding.
func opaqueBounds(_ img: CGImage) -> CGRect {
    let w = img.width, h = img.height
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    var (minX, minY, maxX, maxY) = (w, h, -1, -1)
    for y in 0..<h { for x in 0..<w where px[(y * w + x) * 4 + 3] > 16 {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    } }
    // Rows are top-down in the buffer; CGImage cropping is top-down too.
    return maxX < 0 ? CGRect(x: 0, y: 0, width: w, height: h) : CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}
let pet = cell.cropping(to: opaqueBounds(cell)) ?? cell

func render(_ size: Int) -> Data {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // macOS icon grid: an 824/1024 rounded square, centred.
    let inset = s * 100 / 1024
    let tile = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let path = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(starting: NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.94, alpha: 1),
               ending: NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.82, alpha: 1))!.draw(in: path, angle: -90)
    // The character, pixel-sharp, about 70% of the tile.
    let box = tile.width * 0.7
    let k = min(box / CGFloat(pet.width), box / CGFloat(pet.height))
    let w = CGFloat(pet.width) * k, h = CGFloat(pet.height) * k
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.interpolationQuality = .none
    ctx.draw(pet, in: CGRect(x: tile.midX - w / 2, y: tile.midY - h / 2, width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let set = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("angeling-\(getpid()).iconset")
try? fm.removeItem(at: set)
try! fm.createDirectory(at: set, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    try! render(pt).write(to: set.appendingPathComponent("icon_\(pt)x\(pt).png"))
    try! render(pt * 2).write(to: set.appendingPathComponent("icon_\(pt)x\(pt)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", set.path, "-o", args[2]]
try! p.run()
p.waitUntilExit()
try? fm.removeItem(at: set)
exit(p.terminationStatus)
