import AppKit
import ApplicationServices
import Foundation

// Independent macOS TextKit oracle for verify_range_text_window_app_position.sh.
// It receives only the fixed fixture and the ordinary app's AX body frame; it
// never reads a CJGUI position/caret result to decide what the answer should be.

func fail(_ message: String) -> Never {
    fputs("position oracle: \(message)\n", stderr)
    exit(2)
}

func field(_ name: String, _ value: Any) {
    print("\(name)=\(value)")
}

func axValue(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func selectedRange(pid: pid_t, identifier: String) {
    let app = AXUIElementCreateApplication(pid)
    guard let windows = axValue(app, kAXWindowsAttribute) as? [AXUIElement] else { fail("no AX windows") }
    var queue = windows
    var visited = 0
    while !queue.isEmpty && visited < 4000 {
        let element = queue.removeFirst()
        visited += 1
        if (axValue(element, kAXIdentifierAttribute) as? String) == identifier {
            guard let raw = axValue(element, kAXSelectedTextRangeAttribute),
                  CFGetTypeID(raw) == AXValueGetTypeID() else { fail("selected text range unavailable") }
            var range = CFRange()
            guard AXValueGetValue(raw as! AXValue, .cfRange, &range) else { fail("selected range decode failed") }
            let role = (axValue(element, kAXRoleAttribute) as? String) ?? "?"
            print("ax_range role=\(role) location=\(range.location) length=\(range.length)")
            return
        }
        if let children = axValue(element, kAXChildrenAttribute) as? [AXUIElement] {
            queue.append(contentsOf: children)
        }
    }
    fail("AXIdentifier \(identifier) not found visited=\(visited)")
}

func selectedValue(pid: pid_t, identifier: String) {
    let app = AXUIElementCreateApplication(pid)
    guard let windows = axValue(app, kAXWindowsAttribute) as? [AXUIElement] else { fail("no AX windows") }
    var queue = windows
    var visited = 0
    while !queue.isEmpty && visited < 4000 {
        let element = queue.removeFirst()
        visited += 1
        if (axValue(element, kAXIdentifierAttribute) as? String) == identifier {
            guard let value = axValue(element, kAXValueAttribute) as? String else { fail("AX value unavailable") }
            FileHandle.standardOutput.write(value.data(using: .utf8)!)
            return
        }
        if let children = axValue(element, kAXChildrenAttribute) as? [AXUIElement] {
            queue.append(contentsOf: children)
        }
    }
    fail("AXIdentifier \(identifier) not found visited=\(visited)")
}

func makeView(text: String, width: CGFloat, height: CGFloat) -> NSTextView {
    let view = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: height))
    view.isHorizontallyResizable = false
    view.isVerticallyResizable = true
    view.textContainerInset = .zero
    view.minSize = NSSize(width: width, height: height)
    view.maxSize = NSSize(width: width, height: height)
    view.textContainer?.widthTracksTextView = false
    view.textContainer?.heightTracksTextView = false
    view.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
    view.textContainer?.lineFragmentPadding = 0
    view.textContainer?.maximumNumberOfLines = 0
    view.textContainer?.lineBreakMode = .byWordWrapping
    view.layoutManager?.allowsNonContiguousLayout = true
    view.font = NSFont.systemFont(ofSize: 13.0)
    view.string = text
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineBreakStrategy = .pushOut
    if !text.isEmpty {
        view.textStorage?.addAttribute(.paragraphStyle, value: paragraph,
                                       range: NSRange(location: 0, length: (text as NSString).length))
    }
    view.layoutManager?.ensureLayout(for: view.textContainer!)
    return view
}

func screenAndViewPoint(_ view: NSTextView, containerPoint: NSPoint,
                        bodyX: CGFloat, bodyY: CGFloat) -> (screen: NSPoint, view: NSPoint) {
    // Quantize exactly as the CGEvent driver must: integer global screen point.
    // Convert that same point back to NSTextView coordinates for the system hit
    // API, including the view's text-container origin.
    let screen = NSPoint(x: (bodyX + 7 + containerPoint.x).rounded(.toNearestOrAwayFromZero),
                         y: (bodyY + 6 + containerPoint.y).rounded(.toNearestOrAwayFromZero))
    let origin = view.textContainerOrigin
    let local = NSPoint(x: screen.x - bodyX - 7 + origin.x,
                        y: screen.y - bodyY - 6 + origin.y)
    return (screen, local)
}

func hitIndex(_ view: NSTextView, _ viewPoint: NSPoint) -> Int {
    let systemIndex = view.characterIndexForInsertion(at: viewPoint)
    return min(systemIndex, (view.string as NSString).length)
}

func glyphCenter(_ view: NSTextView, character: Int) -> NSPoint {
    guard let manager = view.layoutManager, let container = view.textContainer else { fail("TextKit graph missing") }
    let length = (view.string as NSString).length
    guard character >= 0 && character < length else { fail("fixture character out of range: \(character)") }
    let glyph = manager.glyphIndexForCharacter(at: character)
    let rect = manager.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: container)
    guard !rect.isNull && !rect.isInfinite && rect.width > 0 && rect.height > 0 else {
        fail("fixture glyph has no visible rect at \(character)")
    }
    return NSPoint(x: rect.midX, y: rect.midY)
}

func moveResult(_ view: NSTextView, start: Int, affinity: NSSelectionAffinity,
                command: String) -> (Int, Int, NSSelectionAffinity) {
    let movingView = makeView(text: view.string, width: view.frame.width, height: view.frame.height)
    movingView.setSelectedRange(NSRange(location: start, length: 0), affinity: affinity, stillSelecting: false)
    switch command {
    case "left": movingView.moveLeft(nil)
    case "right": movingView.moveRight(nil)
    case "up": movingView.moveUp(nil)
    case "down": movingView.moveDown(nil)
    default: fail("unknown movement \(command)")
    }
    let range = movingView.selectedRange()
    return (range.location, range.length, movingView.selectionAffinity)
}

func moveDefaultAffinity(_ view: NSTextView, start: Int) -> NSSelectionAffinity {
    view.setSelectedRange(NSRange(location: start, length: 0))
    return view.selectionAffinity
}

struct VisualLine {
    let glyphs: NSRange
    let characters: NSRange
    let rect: NSRect
    let used: NSRect
}

func visualLines(_ view: NSTextView) -> [VisualLine] {
    guard let manager = view.layoutManager else { fail("TextKit layout manager missing") }
    var result: [VisualLine] = []
    var glyph = 0
    while glyph < manager.numberOfGlyphs {
        var glyphRange = NSRange(location: 0, length: 0)
        let rect = manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &glyphRange)
        let used = manager.lineFragmentUsedRect(forGlyphAt: glyph, effectiveRange: nil)
        let chars = manager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        guard glyphRange.length > 0 && chars.location != NSNotFound else { fail("invalid line fragment") }
        result.append(VisualLine(glyphs: glyphRange, characters: chars, rect: rect, used: used))
        glyph = NSMaxRange(glyphRange)
    }
    return result
}

struct SoftWrapChoice {
    let containerPoint: NSPoint
    let position: (screen: NSPoint, view: NSPoint)
    let seam: Int
    let affinity: NSSelectionAffinity
    let left: (Int, Int, NSSelectionAffinity)
    let right: (Int, Int, NSSelectionAffinity)
    let up: (Int, Int, NSSelectionAffinity)
    let down: (Int, Int, NSSelectionAffinity)
    let crossedDirection: String
}

func findSoftWrapChoice(_ view: NSTextView, bodyX: CGFloat, bodyY: CGFloat,
                        paragraphRange: NSRange) -> SoftWrapChoice? {
    let lines = visualLines(view)
    let screenOriginX = bodyX + 7
    let screenOriginY = bodyY + 6
    for index in 0..<(max(0, lines.count - 1)) {
        let previous = lines[index]
        let next = lines[index + 1]
        let seam = NSMaxRange(previous.characters)
        // Only adjacent visual fragments sharing a logical boundary inside the
        // first paragraph count; hard newline boundaries are outside this range.
        guard seam == next.characters.location,
              seam > paragraphRange.location,
              seam < NSMaxRange(paragraphRange) else { continue }

        let candidates: [(VisualLine, NSSelectionAffinity)] = [
            (previous, .upstream), (next, .downstream)
        ]
        for (line, affinity) in candidates {
            let screenY = Int((screenOriginY + line.rect.midY).rounded(.toNearestOrAwayFromZero))
            let xStart = Int(ceil(screenOriginX + line.used.minX - 2))
            let xEnd = Int(floor(screenOriginX + line.used.maxX + 2))
            if xStart > xEnd { continue }
            for screenX in xStart...xEnd {
                let screenPoint = NSPoint(x: CGFloat(screenX), y: CGFloat(screenY))
                let origin = view.textContainerOrigin
                let viewPoint = NSPoint(x: screenPoint.x - bodyX - 7 + origin.x,
                                        y: screenPoint.y - bodyY - 6 + origin.y)
                guard hitIndex(view, viewPoint) == seam else { continue }
                let containerPoint = NSPoint(x: screenPoint.x - bodyX - 7,
                                             y: screenPoint.y - bodyY - 6)
                let left = moveResult(view, start: seam, affinity: affinity, command: "left")
                let right = moveResult(view, start: seam, affinity: affinity, command: "right")
                let crossed: String
                if affinity == .upstream && right.0 == seam && right.2 == .downstream {
                    crossed = "right"
                } else if affinity == .downstream && left.0 == seam && left.2 == .upstream {
                    crossed = "left"
                } else {
                    continue
                }
                let up = moveResult(view, start: seam, affinity: affinity, command: "up")
                let down = moveResult(view, start: seam, affinity: affinity, command: "down")
                return SoftWrapChoice(containerPoint: containerPoint,
                    position: (screenPoint, viewPoint), seam: seam, affinity: affinity,
                    left: left, right: right, up: up, down: down, crossedDirection: crossed)
            }
        }
    }
    return nil
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else { fail("usage: oracle fixture <body-x> <body-y> <body-width> <body-height> | ax-range|ax-value <pid> <identifier>") }
if arguments[1] == "ax-range" {
    guard arguments.count == 4, let pid = Int32(arguments[2]) else { fail("bad ax-range arguments") }
    selectedRange(pid: pid_t(pid), identifier: arguments[3])
    exit(0)
}
if arguments[1] == "ax-value" {
    guard arguments.count == 4, let pid = Int32(arguments[2]) else { fail("bad ax-value arguments") }
    selectedValue(pid: pid_t(pid), identifier: arguments[3])
    exit(0)
}
guard arguments[1] == "fixture", arguments.count == 6,
      let bodyX = Double(arguments[2]), let bodyY = Double(arguments[3]),
      let bodyWidth = Double(arguments[4]), let bodyHeight = Double(arguments[5]),
      let text = ProcessInfo.processInfo.environment["POSITION_ORACLE_TEXT"] else { fail("bad fixture arguments or missing POSITION_ORACLE_TEXT") }

let contentWidth = CGFloat(max(1, bodyWidth - 14))
let contentHeight = CGFloat(max(1, bodyHeight - 12))
let view = makeView(text: text, width: contentWidth, height: contentHeight)
let nsText = text as NSString
let wrapRange = nsText.range(of: "SOFT_WRAP_RUN_")
let bidiRange = nsText.range(of: "אבג")
guard wrapRange.location != NSNotFound, bidiRange.location != NSNotFound else { fail("fixed fixture markers missing") }

let firstParagraphEnd = nsText.range(of: "\n").location
guard firstParagraphEnd != NSNotFound && firstParagraphEnd > wrapRange.location else {
    fail("fixed soft-wrap paragraph terminator missing")
}
let softChoice = findSoftWrapChoice(view, bodyX: CGFloat(bodyX), bodyY: CGFloat(bodyY),
                                    paragraphRange: NSRange(location: wrapRange.location,
                                        length: firstParagraphEnd - wrapRange.location))
let softPoint: NSPoint
let softPosition: (screen: NSPoint, view: NSPoint)
let softHit: Int
let softLeft: (Int, Int, NSSelectionAffinity)
let softRight: (Int, Int, NSSelectionAffinity)
let softUp: (Int, Int, NSSelectionAffinity)
let softDown: (Int, Int, NSSelectionAffinity)
if let choice = softChoice {
    softPoint = choice.containerPoint
    softPosition = choice.position
    softHit = choice.seam
    softLeft = choice.left
    softRight = choice.right
    softUp = choice.up
    softDown = choice.down
    fputs("POSITION_ORACLE_WRAP boundary=\(choice.seam) screen=\(Int(choice.position.screen.x)),\(Int(choice.position.screen.y)) affinity=\(choice.affinity == .upstream ? "upstream" : "downstream") hit=\(choice.seam) crossed=\(choice.crossedDirection) left=\(choice.left.0),\(choice.left.1),\(choice.left.2 == .upstream ? "upstream" : "downstream") right=\(choice.right.0),\(choice.right.1),\(choice.right.2 == .upstream ? "upstream" : "downstream")\n", stderr)
} else {
    // Keep a useful interior-wrap sample if the system hit API has no integer
    // global pixel that selects either visual alias of the soft-wrap seam.
    let softCharacter = wrapRange.location + 180
    softPoint = glyphCenter(view, character: softCharacter)
    softPosition = screenAndViewPoint(view, containerPoint: softPoint,
                                      bodyX: CGFloat(bodyX), bodyY: CGFloat(bodyY))
    softHit = hitIndex(view, softPosition.view)
    let fallbackAffinity = moveDefaultAffinity(view, start: softHit)
    softLeft = moveResult(view, start: softHit, affinity: fallbackAffinity, command: "left")
    softRight = moveResult(view, start: softHit, affinity: fallbackAffinity, command: "right")
    softUp = moveResult(view, start: softHit, affinity: fallbackAffinity, command: "up")
    softDown = moveResult(view, start: softHit, affinity: fallbackAffinity, command: "down")
    fputs("POSITION_ORACLE_WRAP boundary=unavailable reason=no_system_hit_affinity_crossing_found fallback=interior_character_\(softCharacter)\n", stderr)
}

let bidiCharacter = bidiRange.location + 1
let bidiPoint = glyphCenter(view, character: bidiCharacter)
let bidiPosition = screenAndViewPoint(view, containerPoint: bidiPoint,
                                      bodyX: CGFloat(bodyX), bodyY: CGFloat(bodyY))
let bidiHit = hitIndex(view, bidiPosition.view)
let bidiAffinity = moveDefaultAffinity(view, start: bidiHit)
let bidiLeft = moveResult(view, start: bidiHit, affinity: bidiAffinity, command: "left")
let bidiRight = moveResult(view, start: bidiHit, affinity: bidiAffinity, command: "right")

var visualLines = Set<Int>()
if view.layoutManager!.numberOfGlyphs > 0 {
    for glyph in 0..<view.layoutManager!.numberOfGlyphs {
        let line = view.layoutManager!.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        visualLines.insert(Int(line.minY.rounded()))
    }
}

field("oracle", "AppKit_TextKit")
field("font", "system_13pt_uniform")
field("body_frame", "\(Int(bodyWidth)),\(Int(bodyHeight))")
field("body_origin", "\(Int(bodyX)),\(Int(bodyY))")
field("text_container", "\(Int(contentWidth)),\(Int(contentHeight))")
field("text_container_origin", "\(view.textContainerOrigin.x),\(view.textContainerOrigin.y)")
field("visual_line_count", visualLines.count)
field("soft_container_point", "\(softPoint.x),\(softPoint.y)")
field("soft_screen", "\(Int(softPosition.screen.x)),\(Int(softPosition.screen.y))")
field("soft_hit", softHit)
field("soft_left", "\(softLeft.0),\(softLeft.1)")
field("soft_right", "\(softRight.0),\(softRight.1)")
field("soft_up", "\(softUp.0),\(softUp.1)")
field("soft_down", "\(softDown.0),\(softDown.1)")
field("bidi_container_point", "\(bidiPoint.x),\(bidiPoint.y)")
field("bidi_screen", "\(Int(bidiPosition.screen.x)),\(Int(bidiPosition.screen.y))")
field("bidi_hit", bidiHit)
field("bidi_left", "\(bidiLeft.0),\(bidiLeft.1)")
field("bidi_right", "\(bidiRight.0),\(bidiRight.1)")
field("expected_utf16_length", nsText.length)
