// Import a pet sprite sheet into assets/pets/<id>/ as a Codex v2 pet (pet.json + spritesheet.png).
//
//   swift scripts/import-pet.swift <sheet.png|webp> <id> "<Display Name>" ["description"]
//
// Generated sheets are often the wrong size and their rows are unevenly spaced, so this finds
// the frames instead of trusting a grid: each row is a horizontal band of non-transparent
// pixels, each frame a run of columns inside it (runs a few pixels apart are one frame). Frames
// keep their place within the source's 8 columns and stand on their row's lowest point, then
// everything is redrawn at one scale onto the exact 1536x2288 grid of 192x208 cells.
// Like the rest of the artwork the result is not committed; it ships as the pets.zip release asset.
import AppKit

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("usage: swift scripts/import-pet.swift <sheet> <id> \"<Display Name>\" [\"description\"]\n".data(using: .utf8)!)
    exit(1)
}
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let outDir = root.appendingPathComponent("assets/pets/\(args[2])")
let cols = 8, rows = 11, cellW = 192, cellH = 208, baseline = 12
let frameCounts = [7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8]

guard let cg = NSImage(contentsOf: URL(fileURLWithPath: args[1]))?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("Cannot read \(args[1])\n".data(using: .utf8)!)
    exit(1)
}
let w = cg.width, h = cg.height
var px = [UInt8](repeating: 0, count: w * h * 4)
CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
func solid(_ x: Int, _ y: Int) -> Bool { px[(y * w + x) * 4 + 3] > 32 }   // y counts from the top

/// Runs of `true` in 0..<n, joining runs separated by `join` or fewer empty steps.
func runs(_ n: Int, join: Int, _ on: (Int) -> Bool) -> [Range<Int>] {
    var out: [Range<Int>] = [], start = -1, lastOn = -1
    for i in 0..<n where on(i) {
        if start < 0 { start = i } else if i - lastOn - 1 > join { out.append(start..<lastOn + 1); start = i }
        lastOn = i
    }
    if start >= 0 { out.append(start..<lastOn + 1) }
    return out
}

let bands = runs(h, join: 0) { y in (0..<w).contains { solid($0, y) } }
guard bands.count == rows else {
    FileHandle.standardError.write("Found \(bands.count) rows, expected \(rows)\n".data(using: .utf8)!)
    exit(1)
}
let slotW = Double(w) / Double(cols)
var frames: [[Range<Int>]] = []
for (r, band) in bands.enumerated() {
    let f = runs(w, join: 4) { x in band.contains { solid(x, $0) } }
    guard f.count == frameCounts[r] else {
        FileHandle.standardError.write("Row \(r): found \(f.count) frames, expected \(frameCounts[r])\n".data(using: .utf8)!)
        exit(1)
    }
    frames.append(f)
}

// One scale for the whole sheet: fill the 8 columns, but never let a frame leave its cell.
let widest = frames.joined().map(\.count).max()!, tallest = bands.map(\.count).max()!
let scale = min(Double(cols * cellW) / Double(w), Double(cellW - 8) / Double(widest), Double(cellH - baseline - 4) / Double(tallest))

let outW = cols * cellW, outH = rows * cellH
let ctx = CGContext(data: nil, width: outW, height: outH, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high
for (r, band) in bands.enumerated() {
    for (c, xs) in frames[r].enumerated() {
        let crop = cg.cropping(to: CGRect(x: xs.lowerBound, y: band.lowerBound, width: xs.count, height: band.count))!
        let dw = Double(xs.count) * scale, dh = Double(band.count) * scale
        // Offset from the source column's centre, kept so effects beside the pet don't shift it.
        let dx = (Double(xs.lowerBound + xs.upperBound) / 2 - (Double(c) + 0.5) * slotW) * scale
        let x = Double(c * cellW) + Double(cellW) / 2 + dx - dw / 2
        let y = Double(outH - (r + 1) * cellH + baseline)   // CGContext counts from the bottom
        ctx.draw(crop, in: CGRect(x: x, y: y, width: dw, height: dh))
    }
}

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let png = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: outDir.appendingPathComponent("spritesheet.png"))
let meta: [String: Any] = ["id": args[2], "displayName": args[3], "description": args.count > 4 ? args[4] : "",
                           "spriteVersionNumber": 2, "spritesheetPath": "spritesheet.png"]
try JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted, .sortedKeys]).write(to: outDir.appendingPathComponent("pet.json"))
print("\(args[3]): \(frames.joined().count) frames, scale \(String(format: "%.2f", scale)) -> \(outDir.path)")
