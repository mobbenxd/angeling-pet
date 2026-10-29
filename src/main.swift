// Angeling — a floating desktop pet that reports Claude Code task status (Codex-pet style).
// Reads per-session JSON written by ~/.claude/angeling-pet/hook.sh.
//
// Interaction (modelled on the Codex pet overlay):
//   click pet          hop + expand/collapse the activity stack
//   click a row        jump to that session (Claude desktop / Terminal / iTerm / VS Code …)
//   right-click row    dismiss that row until the session does something new
//   drag pet           move (runs left/right while dragging)
//   right-click pet    menu: hide activity, hide Angeling, …
//   menu bar icon      always there; shows/hides Angeling, lists sessions
//   ⌥⌘A                show / hide Angeling
//   LINE row           unread total + latest message; click opens LINE
import AppKit
import Carbon.HIToolbox
import SQLite3

let home = FileManager.default.homeDirectoryForCurrentUser
let baseDir = home.appendingPathComponent(".claude/angeling-pet")
let stateDir = baseDir.appendingPathComponent("state")

// MARK: - Sprite sheet (Codex pet format v2: 8 cols x 11 rows, 192x208 cells)

struct Anim {
    let row: Int
    let durations: [Double] // ms per frame
    let loops: Bool
}

func strip(_ row: Int, _ count: Int, _ dur: Double, _ last: Double, loops: Bool = true) -> Anim {
    Anim(row: row, durations: Array(repeating: dur, count: count - 1) + [last], loops: loops)
}

let anims: [String: Anim] = [
    "idle": Anim(row: 0, durations: [1400, 110, 110, 140, 140, 320, 900], loops: true),
    "running-right": strip(1, 8, 120, 220),
    "running-left": strip(2, 8, 120, 220),
    "waving": strip(3, 4, 140, 280),
    "jumping": strip(4, 5, 140, 280, loops: false),
    "failed": strip(5, 8, 140, 240),
    "waiting": strip(6, 6, 150, 260),
    "running": strip(7, 6, 120, 220),
    "review": strip(8, 6, 150, 280),
]

final class SpriteSheet {
    let cellW = 192, cellH = 208
    private var cache: [String: NSImage] = [:]
    let image: CGImage

    init?(url: URL) {
        guard let img = NSImage(contentsOf: url),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        image = cg
    }

    func frame(row: Int, col: Int) -> NSImage? {
        let key = "\(row)-\(col)"
        if let c = cache[key] { return c }
        let rect = CGRect(x: col * cellW, y: row * cellH, width: cellW, height: cellH)
        guard let cg = image.cropping(to: rect) else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: cellW, height: cellH))
        cache[key] = img
        return img
    }
}

// MARK: - Session state

struct PlanItem: Decodable { let c: String; let s: String }

struct SessionState: Decodable {
    let session: String?
    let cwd: String?
    let project: String?
    let task: String?
    let state: String?
    let text: String?
    let updated: Double?
    let plan: [PlanItem]?
    // Where the session lives, for click-to-open.
    let host: String?   // Claude desktop session id (local_…)
    let app: String?    // bundle id of the hosting app
    let term: String?
    let tty: String?
    let iterm: String?
}

func loadSessions() -> [SessionState] {
    let fm = FileManager.default
    guard let files = try? fm.contentsOfDirectory(at: stateDir, includingPropertiesForKeys: nil) else { return [] }
    let now = Date().timeIntervalSince1970
    var out: [SessionState] = []
    for f in files where f.pathExtension == "json" {
        guard let data = try? Data(contentsOf: f),
              let s = try? JSONDecoder().decode(SessionState.self, from: data) else { continue }
        // Forget sessions that went silent for 6 hours (crashed / closed without SessionEnd).
        if now - (s.updated ?? 0) > 6 * 3600 { try? fm.removeItem(at: f); continue }
        out.append(s)
    }
    return out
}

/// What a session means right now, after aging out transient states.
func effective(_ s: SessionState, now: Double) -> String {
    let age = now - (s.updated ?? 0)
    switch s.state ?? "idle" {
    case "running", "review": return age > 600 ? "idle" : s.state!
    case "failed": return age > 20 ? "running" : "failed"
    case "done": return age > 1800 ? "idle" : "done"
    case "waiting": return "waiting"
    default: return "idle"
    }
}

func priority(_ st: String) -> Int {
    switch st {
    case "waiting": return 5
    case "failed": return 4
    case "running", "review": return 3
    case "done": return 2
    default: return 1
    }
}

let lineGreen = NSColor(calibratedRed: 0.02, green: 0.66, blue: 0.3, alpha: 1)
let lineTime: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
let icons: [String: String] = ["waiting": "🙋", "failed": "😣", "running": "⚙️", "review": "🔍", "done": "✨", "idle": "💤"]
let statusLabel: [String: String] = ["waiting": "รอคุณ", "failed": "ติดปัญหา", "running": "กำลังทำ",
                                     "review": "กำลังอ่าน", "done": "เสร็จแล้ว", "idle": "ว่าง"]

// MARK: - Jump to a session's window

enum Focus {
    static func open(_ s: SessionState) {
        let app = s.app ?? ""
        if let host = s.host, host.hasPrefix("local_") {
            openURL("claude://code/continue?session=\(host)&source=desktop_action")
        } else if app == "com.apple.Terminal" || s.term == "Apple_Terminal", let tty = s.tty {
            osa("""
            tell application "Terminal"
              repeat with w in windows
                repeat with t in tabs of w
                  if tty of t is "\(tty)" then
                    set selected of t to true
                    set index of w to 1
                  end if
                end repeat
              end repeat
              activate
            end tell
            """)
        } else if app == "com.googlecode.iterm2" || s.term == "iTerm.app", let it = s.iterm,
                  let uuid = it.split(separator: ":").last {
            osa("""
            tell application "iTerm2"
              repeat with w in windows
                repeat with t in tabs of w
                  repeat with ss in sessions of t
                    if unique id of ss is "\(uuid)" then
                      select w
                      select t
                      select ss
                    end if
                  end repeat
                end repeat
              end repeat
              activate
            end tell
            """)
        } else if ["com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92", "com.exafunction.windsurf"].contains(app)
                    || s.term == "vscode", let cwd = s.cwd {
            // Re-opening the folder focuses the window that already has it.
            let bid = app.isEmpty ? "com.microsoft.VSCode" : app
            run("/usr/bin/open", ["-b", bid, cwd])
        } else if !app.isEmpty, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    static func openURL(_ s: String) { if let u = URL(string: s) { NSWorkspace.shared.open(u) } }

    static func osa(_ script: String) {
        DispatchQueue.global().async { run("/usr/bin/osascript", ["-e", script]) }
    }

    static func run(_ path: String, _ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try? p.run()
    }
}

// MARK: - LINE notifications
//   unread  = LINE's Dock badge (lsappinfo; no permission needed, LINE must be running)
//   latest  = newest LINE entry in the macOS notification database (needs Full Disk Access)

struct LineStatus: Equatable {
    var unread = 0
    var title = ""
    var body = ""
    var date: Double = 0       // unix time of the latest notification
    var canReadMessages = true // false when the notification database is off-limits
}

enum LineWatch {
    static let bundle = "jp.naver.line.mac"
    static var dbPath: String {
        ProcessInfo.processInfo.environment["ANGELING_NOTIF_DB"]
            ?? home.appendingPathComponent("Library/Group Containers/group.com.apple.usernoted/db2/db").path
    }

    static func poll() -> LineStatus {
        var s = LineStatus()
        let latest = latestNotification()
        s.canReadMessages = latest != nil
        if let l = latest { (s.title, s.body, s.date) = (l.title, l.body, l.date) }
        s.unread = badgeCount() ?? latest?.badge ?? 0
        return s
    }

    /// Dock badge of the running LINE app, e.g. `"StatusLabel"={ "label"="676" }`.
    static func badgeCount() -> Int? {
        if let fake = ProcessInfo.processInfo.environment["ANGELING_LINE_UNREAD"] { return Int(fake) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/lsappinfo")
        p.arguments = ["info", "-only", "StatusLabel", "-app", bundle]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        guard !text.isEmpty else { return nil } // LINE not running
        guard let r = text.range(of: #""label"="[^"]*""#, options: .regularExpression) else { return 0 }
        return Int(text[r].filter(\.isNumber)) ?? 0
    }

    /// Newest LINE notification still in Notification Center; nil when the database can't be opened.
    static func latestNotification() -> (title: String, body: String, date: Double, badge: Int?)? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { sqlite3_close(db); return nil }
        defer { sqlite3_close(db) }
        var stmt: OpaquePointer?
        let sql = """
            SELECT r.data, r.delivered_date, a.badge FROM app a LEFT JOIN record r ON r.app_id = a.app_id
            WHERE lower(a.identifier) = '\(bundle)' ORDER BY r.delivered_date DESC LIMIT 1
            """
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return ("", "", 0, nil) } // readable, nothing from LINE
        let badge = sqlite3_column_type(stmt, 2) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 2))
        guard let blob = sqlite3_column_blob(stmt, 0) else { return ("", "", 0, badge) }
        let data = Data(bytes: blob, count: Int(sqlite3_column_bytes(stmt, 0)))
        let delivered = sqlite3_column_double(stmt, 1) + 978_307_200 // Core Data epoch -> unix
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let req = plist["req"] as? [String: Any] else { return ("", "", delivered, badge) }
        let title = [req["titl"], req["subt"]].compactMap { $0 as? String }.filter { !$0.isEmpty }.joined(separator: " · ")
        let body = (req["body"] as? String ?? "").replacingOccurrences(of: "\n", with: " ")
        return (title, body, delivered, badge)
    }

    static func open() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}

// MARK: - Activity rows + bubble

final class RowView: NSView {
    let label = NSTextField(wrappingLabelWithString: "")
    var onClick: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    private var hovering = false { didSet { needsDisplay = true } }

    var accent: NSColor? { didSet { needsDisplay = true } }

    init(text: NSAttributedString, width: CGFloat, clickable: Bool) {
        super.init(frame: .zero)
        label.attributedStringValue = text
        label.isSelectable = false
        label.drawsBackground = false
        label.isBezeled = false
        label.preferredMaxLayoutWidth = width - 16
        let h = ceil(label.fittingSize.height)
        frame = NSRect(x: 0, y: 0, width: width, height: h + 10)
        label.frame = NSRect(x: 8, y: 5, width: width - 16, height: h)
        addSubview(label)
        if clickable {
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                           owner: self, userInfo: nil))
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? {
        frame.contains(point) && (onClick != nil || onRightClick != nil) ? self : super.hitTest(point)
    }
    override func draw(_ dirtyRect: NSRect) {
        if let a = accent {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.75, dy: 0.75), xRadius: 8, yRadius: 8)
            a.withAlphaComponent(hovering ? 0.22 : 0.1).setFill()
            path.fill()
            a.setStroke()
            path.lineWidth = 1.5
            path.stroke()
            return
        }
        guard hovering else { return }
        NSColor(calibratedRed: 1, green: 0.85, blue: 0.88, alpha: 0.7).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
    }
    override func mouseEntered(with e: NSEvent) { hovering = true; NSCursor.pointingHand.set() }
    override func mouseExited(with e: NSEvent) { hovering = false; NSCursor.arrow.set() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) {
        if bounds.contains(convert(e.locationInWindow, from: nil)) { onClick?() }
    }
    override func rightMouseDown(with e: NSEvent) { onRightClick?(e) }
}

final class BubbleView: NSView {
    var onClick: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) { onClick?() }
    let tail: CGFloat = 9
    let pad: CGFloat = 6

    /// Lays the rows out top-to-bottom and returns the bubble size.
    func set(rows: [RowView], width: CGFloat) -> NSSize {
        subviews.forEach { $0.removeFromSuperview() }
        let gap: CGFloat = 4
        let inner = rows.reduce(0) { $0 + $1.frame.height } + gap * CGFloat(max(0, rows.count - 1))
        let h = inner + pad * 2 + tail
        var y = h - pad
        for r in rows {
            y -= r.frame.height
            r.frame.origin = NSPoint(x: pad, y: y)
            addSubview(r)
            y -= gap
        }
        return NSSize(width: width, height: h)
    }

    override func draw(_ dirtyRect: NSRect) {
        let body = NSRect(x: 1, y: tail, width: bounds.width - 2, height: bounds.height - tail - 1)
        let path = NSBezierPath(roundedRect: body, xRadius: 12, yRadius: 12)
        let mid = bounds.midX
        path.move(to: NSPoint(x: mid - 8, y: tail + 0.5))
        path.line(to: NSPoint(x: mid, y: 1))
        path.line(to: NSPoint(x: mid + 8, y: tail + 0.5))
        NSColor(calibratedRed: 1, green: 0.98, blue: 0.97, alpha: 0.97).setFill()
        path.fill()
        NSColor(calibratedRed: 0.86, green: 0.55, blue: 0.6, alpha: 1).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}

// Ragnarok Online emote (animated GIF from iRO wiki) that pops up beside the pet.
final class EmoteView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil } // never steal clicks
}

let emoteDir = baseDir.appendingPathComponent("emotes")
let emoteImages: [String: NSImage] = {
    var m: [String: NSImage] = [:]
    for n in ["lv", "heh", "swt", "wah", "omg", "slur"] {
        if let i = NSImage(contentsOf: emoteDir.appendingPathComponent("\(n).gif")) { m[n] = i }
    }
    return m
}()

// Little red count shown on the pet while the activity bubble is hidden (like Codex's badge).
// Small pill beside the pet that hides / shows the activity bubble.
final class ToggleButton: NSView {
    var onClick: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    var shown = true { didSet { needsDisplay = true; toolTip = shown ? "ซ่อนกิจกรรม" : "แสดงกิจกรรม" } }
    private var hovering = false { didSet { needsDisplay = true } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }
    required init?(coder: NSCoder) { fatalError() }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) {
        if bounds.contains(convert(e.locationInWindow, from: nil)) { onClick?() }
    }
    override func mouseEntered(with e: NSEvent) { hovering = true; NSCursor.pointingHand.set(); onHover?(true) }
    override func mouseExited(with e: NSEvent) { hovering = false; NSCursor.arrow.set(); onHover?(false) }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2)
        NSColor(calibratedRed: 1, green: hovering ? 0.9 : 0.97, blue: hovering ? 0.92 : 0.96, alpha: 0.95).setFill()
        path.fill()
        NSColor(calibratedRed: 0.86, green: 0.55, blue: 0.6, alpha: 1).setStroke()
        path.lineWidth = 1.2
        path.stroke()
        let name = shown ? "eye.slash" : "text.bubble"
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: toolTip)?
            .withSymbolConfiguration(.init(pointSize: 11, weight: .semibold)) {
            let tinted = NSImage(size: img.size, flipped: false) { rect in
                img.draw(in: rect)
                NSColor(calibratedRed: 0.72, green: 0.3, blue: 0.4, alpha: 1).set()
                rect.fill(using: .sourceAtop)
                return true
            }
            let sz = tinted.size
            tinted.draw(in: NSRect(x: (bounds.width - sz.width) / 2, y: (bounds.height - sz.height) / 2,
                                   width: sz.width, height: sz.height))
        }
    }
}

final class BadgeView: NSView {
    var count = 0 { didSet { isHidden = count == 0; needsDisplay = true } }
    var color = NSColor(calibratedRed: 0.9, green: 0.25, blue: 0.35, alpha: 1)
    var text: String { count > 999 ? "999+" : "\(count)" }
    /// Circle for one digit, pill for more.
    var width: CGFloat { max(18, ceil(NSAttributedString(string: text, attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]).size().width) + 10) }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func draw(_ dirtyRect: NSRect) {
        color.setFill()
        let r = bounds.insetBy(dx: 1, dy: 1)
        NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2).fill()
        let s = NSAttributedString(string: text, attributes: [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white])
        let sz = s.size()
        s.draw(at: NSPoint(x: (bounds.width - sz.width) / 2, y: (bounds.height - sz.height) / 2))
    }
}

// MARK: - Pet view (click / drag)

final class PetView: NSImageView {
    var onClick: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }
    override func mouseEntered(with e: NSEvent) { onHover?(true) }
    override func mouseExited(with e: NSEvent) { onHover?(false) }
    var onDrag: ((CGFloat) -> Void)?
    var onDragEnd: (() -> Void)?
    var menuProvider: (() -> NSMenu)?
    private var downPoint: NSPoint = .zero
    private var winOrigin: NSPoint = .zero
    private var dragged = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {
        downPoint = NSEvent.mouseLocation
        winOrigin = window?.frame.origin ?? .zero
        dragged = false
    }
    override func mouseDragged(with e: NSEvent) {
        let p = NSEvent.mouseLocation
        let dx = p.x - downPoint.x, dy = p.y - downPoint.y
        if !dragged && hypot(dx, dy) < 3 { return }
        dragged = true
        window?.setFrameOrigin(NSPoint(x: winOrigin.x + dx, y: winOrigin.y + dy))
        onDrag?(e.deltaX)
    }
    override func mouseUp(with e: NSEvent) {
        if dragged { onDragEnd?() } else { onClick?() }
    }
    override func rightMouseDown(with e: NSEvent) {
        if let m = menuProvider?() { NSMenu.popUpContextMenu(m, with: e, for: self) }
    }
}

// MARK: - Controller

final class PetController: NSObject, NSMenuDelegate {
    let petSize = NSSize(width: 67, height: 73)
    let winWidth: CGFloat = 300
    let panel: NSPanel
    let bubble = BubbleView(frame: .zero)
    let pet = PetView(frame: .zero)
    let badge = BadgeView(frame: .zero)
    let lineBadge = BadgeView(frame: .zero)
    var line = LineStatus()
    var lineDismissed: (Int, Double)?  // (unread, latest date) when the LINE row was hidden
    let toggle = ToggleButton(frame: .zero)
    let emote = EmoteView(frame: .zero)
    var emoteName: String?
    var emoteUntil = Date.distantPast
    var prevStates: [String: (String, Double)] = [:]   // session -> (effective state, updated)
    var runningSince: [String: Double] = [:]
    var sweatShown: Set<String> = []
    var lastActive = Date()
    var lastSlur = Date.distantPast
    let sheet: SpriteSheet
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var animName = "idle"
    var frameIndex = 0
    var frameTimer: Timer?
    var overrideAnim: String?       // transient (jumping, dragging)
    var overrideUntil: Date = .distantPast
    var lastPrimaryKey = ""
    var expanded = false
    var sessions: [(SessionState, String)] = []
    var dismissed: [String: Double] = [:]  // session -> updated stamp at dismissal
    var didFirstRefresh = false
    var lastRowsSig = ""
    var bubbleSize = NSSize.zero
    func flag(_ k: String) -> Bool { d.object(forKey: k) as? Bool ?? true }
    var showTask: Bool { flag("showTask") }
    var showText: Bool { flag("showText") }
    var showPlan: Bool { flag("showPlan") }
    var showLine: Bool { flag("showLine") }

    let d = UserDefaults.standard
    var activityHidden: Bool { get { d.bool(forKey: "activityHidden") } set { d.set(newValue, forKey: "activityHidden") } }
    var petHidden: Bool { get { d.bool(forKey: "petHidden") } set { d.set(newValue, forKey: "petHidden") } }
    var popWhenWaiting: Bool { get { d.object(forKey: "popWhenWaiting") as? Bool ?? true } set { d.set(newValue, forKey: "popWhenWaiting") } }

    init(sheet: SpriteSheet) {
        self.sheet = sheet
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 140),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false

        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = content
        pet.imageScaling = .scaleProportionallyUpOrDown
        pet.onClick = { [weak self] in self?.clicked() }
        pet.onDrag = { [weak self] dx in self?.dragging(dx) }
        pet.onDragEnd = { [weak self] in self?.dragEnded() }
        pet.menuProvider = { [weak self] in self?.makeMenu(forStatusBar: false) ?? NSMenu() }
        content.addSubview(bubble)
        content.addSubview(pet)
        content.addSubview(badge)
        content.addSubview(lineBadge)
        lineBadge.color = lineGreen
        lineBadge.toolTip = "LINE ยังไม่อ่าน"
        content.addSubview(toggle)
        bubble.onClick = { [weak self] in self?.clicked() }
        emote.animates = true
        emote.imageScaling = .scaleNone
        emote.isHidden = true
        content.addSubview(emote)
        toggle.onClick = { [weak self] in self?.toggleActivity() }
        // The toggle only appears while the pointer is over the pet (or the toggle itself).
        toggle.isHidden = true
        pet.onHover = { [weak self] on in self?.hover(on) }
        toggle.onHover = { [weak self] on in self?.hover(on) }
        badge.count = 0

        if d.object(forKey: "x") != nil {
            panel.setFrameOrigin(NSPoint(x: d.double(forKey: "x"), y: d.double(forKey: "y")))
        } else if let s = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: s.maxX - winWidth - 20, y: s.minY + 20))
        }

        // Menu bar icon: the way back when Angeling is tucked away.
        if let b = statusItem.button {
            b.image = statusIcon()
            b.imagePosition = .imageLeading
        }
        let m = NSMenu()
        m.delegate = self
        statusItem.menu = m

        if !petHidden { panel.orderFrontRegardless() }
        play("idle")
        refresh()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
        pollLine()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.pollLine() }
    }

    func pollLine() {
        guard showLine else { if line != LineStatus() { line = LineStatus(); refresh() }; return }
        DispatchQueue.global(qos: .utility).async {
            let s = LineWatch.poll()
            DispatchQueue.main.async { [weak self] in
                guard let self, s != self.line else { return }
                // A new LINE message brings the row back after it was hidden.
                if let (n, t) = self.lineDismissed, s.unread > n || s.date > t { self.lineDismissed = nil }
                self.line = s
                self.refresh()
            }
        }
    }

    var lineVisible: Bool { showLine && line.unread > 0 && lineDismissed == nil }

    func statusIcon() -> NSImage? {
        guard let f = sheet.frame(row: 0, col: 0) else { return nil }
        let img = NSImage(size: NSSize(width: 20, height: 20))
        img.lockFocus()
        f.draw(in: NSRect(x: 0, y: -1, width: 20, height: 21.6))
        img.unlockFocus()
        return img
    }

    // MARK: animation

    func play(_ name: String) {
        guard name != animName || frameTimer == nil else { return }
        animName = name
        frameIndex = 0
        showFrame()
    }

    func showFrame() {
        frameTimer?.invalidate()
        let a = anims[animName] ?? anims["idle"]!
        pet.image = sheet.frame(row: a.row, col: frameIndex)
        let dur = a.durations[frameIndex] / 1000
        frameTimer = Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.frameIndex + 1 < a.durations.count {
                self.frameIndex += 1
            } else if a.loops {
                self.frameIndex = 0
            } else {
                self.overrideAnim = nil
                self.refresh()
                return
            }
            self.showFrame()
        }
    }

    func setOverride(_ name: String, for seconds: Double) {
        overrideAnim = name
        overrideUntil = Date().addingTimeInterval(seconds)
        animName = ""
        play(name)
    }

    // MARK: interaction

    /// Clicking Angeling (or the bubble's background) brings up the most recently active Claude session.
    func clicked() {
        setOverride("jumping", for: 1.0)
        openLatest()
        if sessions.allSatisfy({ $0.1 == "idle" }) { showEmote("slur", for: 2.5) }
        refresh()
    }

    func dragging(_ dx: CGFloat) {
        let name = dx >= 0 ? "running-right" : "running-left"
        overrideAnim = name
        overrideUntil = .distantFuture
        play(name)
    }

    func dragEnded() {
        overrideAnim = nil
        let o = panel.frame.origin
        d.set(o.x, forKey: "x")
        d.set(o.y, forKey: "y")
        refresh()
    }

    func openLatest() {
        // Prefer the newest session that is still working (or waiting on you); else the newest of all.
        let latest = { (xs: [SessionState]) in xs.max(by: { ($0.updated ?? 0) < ($1.updated ?? 0) }) }
        let active = sessions.filter { ["running", "review", "waiting", "failed"].contains($0.1) }.map { $0.0 }
        if let s = latest(active) ?? latest(sessions.map { $0.0 }) {
            Focus.open(s)
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.anthropic.claudefordesktop") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    func openSession(_ s: SessionState) {
        setOverride("waving", for: 0.8)
        Focus.open(s)
    }

    func dismiss(_ s: SessionState) {
        if let id = s.session { dismissed[id] = s.updated ?? 0 }
        refresh()
    }

    // Menus: the pet's right-click menu and the menu bar menu share items.
    func makeMenu(forStatusBar: Bool) -> NSMenu {
        let m = NSMenu()
        func item(_ title: String, _ sel: Selector, on: Bool = false, key: String = "") {
            let i = m.addItem(withTitle: title, action: sel, keyEquivalent: key)
            i.target = self
            i.state = on ? .on : .off
        }
        if forStatusBar {
            let live = visibleSessions()
            if live.isEmpty {
                m.addItem(withTitle: "ยังไม่มี session", action: nil, keyEquivalent: "").isEnabled = false
            }
            for (s, st) in live {
                let i = m.addItem(withTitle: "\(icons[st] ?? "") \(s.project ?? "?") — \(statusLabel[st] ?? "")",
                                  action: #selector(menuOpenSession(_:)), keyEquivalent: "")
                i.target = self
                i.representedObject = s.session
                i.toolTip = s.text
            }
            m.addItem(.separator())
            item(petHidden ? "แสดง Angeling" : "ซ่อน Angeling", #selector(togglePet))
        } else {
            item(expanded ? "ย่อรายการ" : "ดูทุก session", #selector(toggleExpand))
        }
        item(activityHidden ? "แสดงกิจกรรม" : "ซ่อนกิจกรรม", #selector(toggleActivity))
        if !forStatusBar { item("ซ่อน Angeling (⌥⌘A)", #selector(togglePet)) }
        let opts = NSMenu()
        for (title, key) in [("งานที่สั่ง (prompt)", "showTask"), ("ข้อความล่าสุด / สิ่งที่กำลังทำ", "showText"), ("Task list", "showPlan")] {
            let i = opts.addItem(withTitle: title, action: #selector(toggleShow(_:)), keyEquivalent: "")
            i.target = self; i.representedObject = key; i.state = flag(key) ? .on : .off
        }
        m.addItem(withTitle: "แสดงในบับเบิล", action: nil, keyEquivalent: "").submenu = opts
        item("โผล่ออกมาเมื่อมีงานรอคุณ", #selector(togglePop), on: popWhenWaiting)
        item("แจ้งเตือน LINE", #selector(toggleLine), on: showLine)
        if showLine && !line.canReadMessages { item("ให้สิทธิ์ Full Disk Access เพื่ออ่านข้อความ LINE…", #selector(openFullDiskAccess)) }
        item("ล้าง session ที่เสร็จแล้ว", #selector(clearDone))
        m.addItem(.separator())
        item("ปิด Angeling", #selector(quit))
        return m
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        for i in makeMenu(forStatusBar: true).items { i.menu?.removeItem(i); menu.addItem(i) }
    }

    @objc func menuOpenSession(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let s = sessions.first(where: { $0.0.session == id })?.0 else { return }
        openSession(s)
    }
    @objc func toggleExpand() { expanded.toggle(); activityHidden = false; refresh() }
    var hoverHide: DispatchWorkItem?
    func hover(_ on: Bool) {
        hoverHide?.cancel()
        if on { toggle.isHidden = false; return }
        let w = DispatchWorkItem { [weak self] in self?.toggle.isHidden = true }
        hoverHide = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: w) // time to move onto the toggle
    }

    @objc func toggleActivity() { activityHidden.toggle(); expanded = false; refresh() }
    @objc func togglePet() {
        petHidden.toggle()
        if petHidden { panel.orderOut(nil) } else { panel.orderFrontRegardless(); setOverride("waving", for: 1.2) }
        refresh()
    }
    @objc func toggleShow(_ sender: NSMenuItem) {
        guard let k = sender.representedObject as? String else { return }
        d.set(!flag(k), forKey: k)
        refresh()
    }
    @objc func togglePop() { popWhenWaiting.toggle() }
    @objc func toggleLine() { d.set(!showLine, forKey: "showLine"); lineDismissed = nil; pollLine(); refresh() }
    @objc func openFullDiskAccess() {
        Focus.openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles")
    }
    @objc func openLine() { setOverride("waving", for: 0.8); LineWatch.open() }
    @objc func dismissLine() { lineDismissed = (line.unread, line.date); refresh() }
    @objc func clearDone() {
        let now = Date().timeIntervalSince1970
        for s in loadSessions() where ["done", "idle"].contains(effective(s, now: now)) {
            if let id = s.session { try? FileManager.default.removeItem(at: stateDir.appendingPathComponent("\(id).json")) }
        }
        refresh()
    }
    @objc func quit() { NSApp.terminate(nil) }

    // MARK: state -> view

    func visibleSessions() -> [(SessionState, String)] {
        sessions.filter { s, st in
            if st == "idle" { return false }
            guard let id = s.session, let stamp = dismissed[id] else { return true }
            return (s.updated ?? 0) > stamp
        }
    }

    func refresh() {
        let now = Date().timeIntervalSince1970
        let previouslyWaiting = Set(sessions.filter { $0.1 == "waiting" }.compactMap { $0.0.session })
        sessions = loadSessions().map { ($0, effective($0, now: now)) }
            .sorted { a, b in
                priority(a.1) != priority(b.1) ? priority(a.1) > priority(b.1) : (a.0.updated ?? 0) > (b.0.updated ?? 0)
            }
        let live = visibleSessions()
        let primary = live.first

        // A tucked-away Angeling pops back out when a session starts waiting on you.
        let newlyWaiting = live.contains { $0.1 == "waiting" && !previouslyWaiting.contains($0.0.session ?? "") }
        if petHidden && popWhenWaiting && newlyWaiting && didFirstRefresh {
            petHidden = false
            panel.orderFrontRegardless()
        }

        // Menu bar: icon + count of sessions needing you.
        let attention = live.filter { $0.1 == "waiting" || $0.1 == "failed" }.count
        statusItem.button?.title = attention > 0 ? " \(attention)" : ""

        // Pet animation
        if let o = overrideAnim, Date() < overrideUntil {
            play(o)
        } else {
            overrideAnim = nil
            var st = primary?.1 ?? "idle"
            let key = "\(primary?.0.session ?? "")|\(primary?.0.state ?? "")|\(primary?.0.updated ?? 0)"
            if st == "done" {
                // Celebrate on arrival, then wave for a bit, then rest.
                if key != lastPrimaryKey && lastPrimaryKey != "" { lastPrimaryKey = key; setOverride("jumping", for: 1.2); layout(live); return }
                let age = now - (primary?.0.updated ?? 0)
                st = age < 8 ? "waving" : "idle"
            }
            lastPrimaryKey = key
            play(st)
        }
        updateEmote(live, now: now)
        didFirstRefresh = true
        layout(live)
    }

    // MARK: emotes
    //   /heh  got a new task        /lv   task finished       /wah  needs your input (stays)
    //   /omg  a tool failed         /swt  still grinding after 5 min
    //   /slur nothing to do for a while (or poked while idle) — hungry for work

    func showEmote(_ name: String, for seconds: Double) {
        guard let img = emoteImages[name] else { return }
        if emoteName != name {
            emoteName = name
            emote.image = img
        }
        emoteUntil = Date().addingTimeInterval(seconds)
        emote.isHidden = false
        placeEmote()
    }

    func placeEmote() { layout(visibleSessions()) }

    func updateEmote(_ live: [(SessionState, String)], now: Double) {
        var pick: (String, Double, Int)?   // name, seconds, priority
        func offer(_ n: String, _ secs: Double, _ pr: Int) { if pick == nil || pr > pick!.2 { pick = (n, secs, pr) } }

        for (s, st) in sessions {
            guard let id = s.session else { continue }
            let prev = prevStates[id]
            let updated = s.updated ?? 0
            if didFirstRefresh, prev?.0 != st || (st == "running" && s.text == "รับงานแล้ว!" && prev?.1 != updated) {
                switch st {
                case "waiting": offer("wah", 4, 5)
                case "failed": offer("omg", 3, 4)
                case "done": offer("lv", 4, 3)
                case "running", "review":
                    if prev == nil || ["idle", "done"].contains(prev!.0) || s.text == "รับงานแล้ว!" { offer("heh", 3, 2) }
                default: break
                }
            }
            // Track continuous work for the sweat drop.
            if st == "running" || st == "review" {
                if runningSince[id] == nil || !["running", "review"].contains(prev?.0 ?? "") {
                    runningSince[id] = now; sweatShown.remove(id)
                }
                if let t0 = runningSince[id], now - t0 > 300, !sweatShown.contains(id) {
                    sweatShown.insert(id); offer("swt", 3, 1)
                }
            } else {
                runningSince[id] = nil
            }
            prevStates[id] = (st, updated)
        }

        let busy = live.contains { ["running", "review", "waiting", "failed"].contains($0.1) }
        if busy { lastActive = Date() }
        // Bored: nothing happening for 10 min -> drool now and then.
        if !busy, Date().timeIntervalSince(lastActive) > 600, Date().timeIntervalSince(lastSlur) > 600 {
            lastSlur = Date(); offer("slur", 3, 0)
        }

        if let p = pick { showEmote(p.0, for: p.1) }
        else if Date() > emoteUntil {
            // Keep calling for help while someone is waiting on you.
            if live.first?.1 == "waiting" { showEmote("wah", for: 1) }
            else if !emote.isHidden { emote.isHidden = true; emoteName = nil; emote.image = nil; placeEmote() }
        }
    }

    func layout(_ live: [(SessionState, String)]) {
        guard !petHidden else { return }
        // Rebuilding every tick would swallow clicks and hover, so only rebuild on change.
        let sig = activityHidden ? "hidden" : rowsSignature(live)
        if sig != lastRowsSig {
            lastRowsSig = sig
            let rows = activityHidden ? [] : makeRows(live)
            bubbleSize = rows.isEmpty ? .zero : bubble.set(rows: rows, width: winWidth)
        }
        let showBubble = bubbleSize != .zero
        bubble.isHidden = !showBubble
        badge.count = activityHidden ? live.filter { ["waiting", "failed", "running", "review"].contains($0.1) }.count : 0

        // Emote floats above the head (like in RO); the bubble moves up to make room for it.
        var emoteRect = NSRect.zero
        if !emote.isHidden, let img = emote.image {
            let sz = img.size
            let petX = (winWidth - petSize.width) / 2
            emoteRect = NSRect(x: round(petX + petSize.width / 2 - sz.width / 2 - 12), y: petSize.height - 12,
                               width: sz.width, height: sz.height)
        }
        let bubbleY = max(petSize.height - 4, emoteRect.maxY - 12)
        let h = showBubble ? bubbleY + bubbleSize.height : max(petSize.height, emoteRect.maxY)
        var f = panel.frame
        if f.height != h || f.width != winWidth {
            f.size = NSSize(width: winWidth, height: h) // origin (bottom) stays put, grows upward
            panel.setFrame(f, display: true)
        }
        keepOnScreen()
        pet.frame = NSRect(x: (winWidth - petSize.width) / 2, y: 0, width: petSize.width, height: petSize.height)
        badge.frame = NSRect(x: pet.frame.maxX - 16, y: pet.frame.maxY - 22, width: 18, height: 18)
        lineBadge.count = activityHidden && showLine ? line.unread : 0
        lineBadge.frame = NSRect(x: pet.frame.minX - lineBadge.width + 16, y: pet.frame.maxY - 22, width: lineBadge.width, height: 18)
        toggle.frame = NSRect(x: pet.frame.minX - 32, y: 22, width: 28, height: 22)
        toggle.shown = !activityHidden
        emote.frame = emoteRect
        if showBubble {
            bubble.frame = NSRect(x: 0, y: bubbleY, width: bubbleSize.width, height: bubbleSize.height)
            bubble.needsDisplay = true
        }
    }

    func rowsSignature(_ live: [(SessionState, String)]) -> String {
        let now = Date().timeIntervalSince1970
        let idleQuiet = live.first.map { $0.1 == "idle" && now - ($0.0.updated ?? 0) > 60 } ?? true
        let lineSig = lineVisible ? "\(line.unread)|\(line.date)|\(line.title)|\(line.body)|\(line.canReadMessages)" : "-"
        return "\(expanded)|\(showTask)\(showText)\(showPlan)|\(idleQuiet)|\(lineSig)|" + live.map { s, st in
            "\(s.session ?? "")\(st)\(s.updated ?? 0)"
        }.joined(separator: ",")
    }

    /// Clamp the window into the visible area of whichever screen holds the pet.
    func keepOnScreen() {
        var f = panel.frame
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: f.midX, y: f.minY + 50)) } ?? NSScreen.main
        guard let v = screen?.visibleFrame else { return }
        f.origin.x = min(max(f.origin.x, v.minX), v.maxX - f.width)
        f.origin.y = min(max(f.origin.y, v.minY), v.maxY - f.height)
        if f.origin != panel.frame.origin { panel.setFrameOrigin(f.origin) }
    }

    func makeRows(_ live: [(SessionState, String)]) -> [RowView] {
        let w = winWidth - bubble.pad * 2
        let green = NSColor(calibratedRed: 0.2, green: 0.62, blue: 0.33, alpha: 1)
        let bold = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor(calibratedRed: 0.72, green: 0.3, blue: 0.4, alpha: 1)]
        let normal = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
                      .foregroundColor: NSColor(calibratedWhite: 0.15, alpha: 1)]
        let dim = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 11),
                   .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1)]

        let doneLabel = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: green]

        func rowText(_ s: SessionState, _ st: String, detailed: Bool) -> NSAttributedString {
            let out = NSMutableAttributedString()
            func add(_ t: String, _ a: [NSAttributedString.Key: Any]) { out.append(NSAttributedString(string: t, attributes: a)) }
            add("\(icons[st] ?? "") \(s.project ?? "?")", bold)
            add("  \(statusLabel[st] ?? "")", st == "done" ? doneLabel : dim)
            if let plan = s.plan, !plan.isEmpty {
                add(" · \(plan.filter { $0.s == "completed" }.count)/\(plan.count)", dim)
            }
            if detailed && showTask, let t = s.task, !t.isEmpty { add("\nงาน: \(t)", dim) }
            if showText, let t = s.text, !t.isEmpty { add("\n" + t, normal) }
            if detailed && showPlan, let plan = s.plan, !plan.isEmpty {
                for p in plan {
                    let mark = p.s == "completed" ? "✓" : (p.s == "in_progress" ? "▸" : "○")
                    add("\n  \(mark) \(p.c)", p.s == "in_progress" ? normal : dim)
                }
            }
            return out
        }

        func sessionRow(_ s: SessionState, _ st: String, detailed: Bool) -> RowView {
            let r = RowView(text: rowText(s, st, detailed: detailed), width: w, clickable: true)
            r.toolTip = "คลิกเพื่อไปที่ session นี้ · คลิกขวาเพื่อซ่อนแถวนี้"
            if st == "done" {
                r.accent = green
                r.onClick = { [weak self] in self?.openSession(s); self?.dismiss(s) }
            } else {
                r.onClick = { [weak self] in self?.openSession(s) }
            }
            r.onRightClick = { [weak self] e in
                let m = NSMenu()
                let open = m.addItem(withTitle: "ไปที่ session นี้", action: #selector(PetController.rowMenuOpen(_:)), keyEquivalent: "")
                open.target = self; open.representedObject = s.session
                let hide = m.addItem(withTitle: "ซ่อนแถวนี้", action: #selector(PetController.rowMenuDismiss(_:)), keyEquivalent: "")
                hide.target = self; hide.representedObject = s.session
                m.addItem(.separator())
                m.addItem(withTitle: "แสดงในบับเบิล", action: nil, keyEquivalent: "").isEnabled = false
                for (title, key) in [("งานที่สั่ง (prompt)", "showTask"), ("ข้อความล่าสุด / สิ่งที่กำลังทำ", "showText"), ("Task list", "showPlan")] {
                    let i = m.addItem(withTitle: title, action: #selector(PetController.toggleShow(_:)), keyEquivalent: "")
                    i.target = self; i.representedObject = key; i.state = (self?.flag(key) ?? true) ? .on : .off
                    i.indentationLevel = 1
                }
                NSMenu.popUpContextMenu(m, with: e, for: r)
            }
            return r
        }

        func lineRow() -> RowView {
            let out = NSMutableAttributedString()
            func add(_ t: String, _ a: [NSAttributedString.Key: Any]) { out.append(NSAttributedString(string: t, attributes: a)) }
            add("💬 LINE", [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: lineGreen])
            add("  ยังไม่อ่าน \(line.unread) ข้อความ", dim)
            if showText && !line.body.isEmpty {
                let time = line.date > 0 ? "  " + lineTime.string(from: Date(timeIntervalSince1970: line.date)) : ""
                if !line.title.isEmpty { add("\n" + line.title, bold.merging([.foregroundColor: NSColor(calibratedWhite: 0.2, alpha: 1)]) { $1 }) }
                add(time, dim)
                let body = line.body.count > 90 ? String(line.body.prefix(90)) + "…" : line.body
                add("\n" + body, normal)
            }
            let r = RowView(text: out, width: w, clickable: true)
            r.accent = lineGreen
            r.toolTip = line.canReadMessages ? "คลิกเพื่อเปิด LINE · คลิกขวาเพื่อซ่อน"
                : "คลิกเพื่อเปิด LINE · ให้สิทธิ์ Full Disk Access กับ Angeling เพื่อดูข้อความล่าสุด"
            r.onClick = { [weak self] in self?.openLine() }
            r.onRightClick = { [weak self] e in
                let m = NSMenu()
                for (title, sel) in [("เปิด LINE", #selector(PetController.openLine)), ("ซ่อนจนกว่าจะมีข้อความใหม่", #selector(PetController.dismissLine)),
                                     ("ปิดแจ้งเตือน LINE", #selector(PetController.toggleLine))] {
                    m.addItem(withTitle: title, action: sel, keyEquivalent: "").target = self
                }
                if self?.line.canReadMessages == false {
                    m.addItem(withTitle: "ให้สิทธิ์ Full Disk Access…", action: #selector(PetController.openFullDiskAccess), keyEquivalent: "").target = self
                }
                NSMenu.popUpContextMenu(m, with: e, for: r)
            }
            return r
        }
        let lineRows = lineVisible ? [lineRow()] : []

        if expanded {
            if live.isEmpty && lineRows.isEmpty {
                return [RowView(text: NSAttributedString(string: "ยังไม่มีงานที่กำลังทำ~", attributes: normal), width: w, clickable: false)]
            }
            return lineRows + live.map { sessionRow($0.0, $0.1, detailed: true) }
        }

        let activeStates = ["running", "review", "waiting", "failed"]
        let active = live.filter { activeStates.contains($0.1) }
        let finished = live.filter { $0.1 == "done" }
        var rows: [RowView] = lineRows
        if let (s, st) = active.first {
            rows.append(sessionRow(s, st, detailed: false))
        }
        // Finished tasks stay listed in green until opened, dismissed, or 30 min old.
        rows += finished.prefix(3).map { sessionRow($0.0, $0.1, detailed: false) }
        if finished.count > 3 {
            let more = RowView(text: NSAttributedString(string: "+\(finished.count - 3) งานเสร็จแล้ว  ▾", attributes: dim), width: w, clickable: true)
            more.onClick = { [weak self] in self?.toggleExpand() }
            rows.append(more)
        }
        let others = active.dropFirst()
        if !others.isEmpty {
            let waiting = others.filter { $0.1 == "waiting" }.count
            let more = RowView(text: NSAttributedString(string: "+\(others.count) session กำลังทำงาน" + (waiting > 0 ? " · \(waiting) รอคุณ" : "") + "  ▾",
                                                        attributes: dim), width: w, clickable: true)
            more.onClick = { [weak self] in self?.toggleExpand() }
            rows.append(more)
        }
        return rows
    }

    @objc func rowMenuOpen(_ sender: NSMenuItem) { menuOpenSession(sender) }
    @objc func rowMenuDismiss(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let s = sessions.first(where: { $0.0.session == id })?.0 else { return }
        dismiss(s)
    }
}

// MARK: - Global hotkey ⌥⌘A (Carbon; needs no Accessibility permission)

var hotKeyRef: EventHotKeyRef?
func registerHotKey(_ action: @escaping () -> Void) {
    hotKeyAction = action
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in hotKeyAction?(); return noErr }, 1, &spec, nil, nil)
    let id = EventHotKeyID(signature: OSType(0x414E474C), id: 1) // 'ANGL'
    RegisterEventHotKey(UInt32(kVK_ANSI_A), UInt32(cmdKey | optionKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)
}
var hotKeyAction: (() -> Void)?

// MARK: - App entry

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
try? FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
guard let sheet = SpriteSheet(url: baseDir.appendingPathComponent("spritesheet.webp")) else {
    FileHandle.standardError.write("Cannot load spritesheet.webp\n".data(using: .utf8)!)
    exit(1)
}
let controller = PetController(sheet: sheet)
registerHotKey { controller.togglePet() }

// Debug: ANGELING_SNAPSHOT=/path.png renders the window to a PNG after a moment, then quits.
if let snap = ProcessInfo.processInfo.environment["ANGELING_SNAPSHOT"] {
    let env = ProcessInfo.processInfo.environment
    let savedActivity = controller.activityHidden, savedPet = controller.petHidden
    controller.petHidden = false
    controller.activityHidden = env["ANGELING_HIDE_ACTIVITY"] != nil
    if env["ANGELING_EXPANDED"] != nil { controller.expanded = true }
    controller.line = LineWatch.poll()
    controller.refresh()
    if env["ANGELING_HOVER"] != nil { controller.toggle.isHidden = false }
    if let e = env["ANGELING_EMOTE"] { controller.showEmote(e, for: 10) }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        let v = controller.panel.contentView!
        if let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) {
            v.cacheDisplay(in: v.bounds, to: rep)
            let bg = NSImage(size: v.bounds.size)
            bg.lockFocus()
            NSColor(calibratedWhite: 0.35, alpha: 1).setFill(); v.bounds.fill()
            rep.draw(in: v.bounds)
            bg.unlockFocus()
            if let t = bg.tiffRepresentation, let b = NSBitmapImageRep(data: t),
               let png = b.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: snap))
            }
        }
        controller.activityHidden = savedActivity
        controller.petHidden = savedPet
        exit(0)
    }
}
app.run()
