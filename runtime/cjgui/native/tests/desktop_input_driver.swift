// Authorized desktop input driver for verification scripts.
//
// The scripts post *real* input events (pointer clicks with optional modifier
// flags, Unicode text, Tab and raw key codes) to the frontmost application and
// read the effect back only through public projections. It is a real input
// driver, not a test seam: it needs the same accessibility/automation trust as
// any other synthetic-input tool, and it fails closed (no output, non-zero exit
// only for usage errors) when the host does not deliver its events.
//
// Why it exists next to System Events: on this host `osascript ... keystroke`
// and `key code` do not reach a cjgui window, while posted CGEvents do. A
// verification script must state which driver produced a delivered keystroke
// rather than treating "System Events did nothing" as a property of the app.
//
// Usage:
//   driver type <text> | tab | key <virtual-key-code> | key-down <code> | key-up <code>
//   driver click <x> <y>
//   driver hold-click <command|shift|control|option> <x> <y>
//
// `hold-click` presses the real modifier key, posts the click with the matching
// event flags, then releases the modifier: that is what a human does, and it
// also refreshes the system modifier state that a synthetic click alone does
// not touch. `cmd-click`/`shift-click` remain as flag-only shortcuts.
import Cocoa

// Event-posting trust: a synthetic event is only delivered when the process
// holds the post-event permission. This is queried up front so a caller can
// tell "the host refused to deliver input" apart from "the app mishandled a
// delivered event" - the two need different verdicts.
func postEventAccessGranted() -> Bool {
    if #available(macOS 10.15, *) {
        return CGPreflightPostEventAccess()
    }
    return true
}

// Set when an event object could not be created or posted, so main can exit
// non-zero instead of silently claiming a delivered input.
var deliveryFailure: String? = nil

func failDelivery(_ reason: String) {
    if deliveryFailure == nil { deliveryFailure = reason }
}

func postUnicode(_ text: String) {
    for scalar in text.unicodeScalars {
        guard let source = CGEventSource(stateID: .hidSystemState) else { failDelivery("no_event_source"); return }
        // A non-BMP scalar (emoji, rare CJK extensions) is one UTF-16 surrogate
        // pair: both units must travel in the SAME event. Truncating the scalar
        // into one UniChar trapped the driver (exit 133) on any astral input,
        // and two lone-surrogate events would be dropped by AppKit anyway.
        var units = Array(String(scalar).utf16)
        if let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            down.flags = []
            down.keyboardSetUnicodeString(stringLength: units.count, unicodeString: &units)
            down.post(tap: .cghidEventTap)
        } else { failDelivery("no_keyboard_event") }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            up.flags = []
            up.keyboardSetUnicodeString(stringLength: units.count, unicodeString: &units)
            up.post(tap: .cghidEventTap)
        }
        usleep(30_000)
    }
}

func postKey(virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { failDelivery("no_event_source"); return }
    if let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
        down.flags = flags
        down.post(tap: .cghidEventTap)
    }
    if let up = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
        up.flags = flags
        up.post(tap: .cghidEventTap)
    }
    usleep(40_000)
}

/// One VoiceOver command = a real Control+Option chord around `virtualKey`:
/// press both modifiers as flagsChanged events, tap the key with the combined
/// flags, then release the modifiers in reverse order. Posting the key with
/// flags alone is unreliable because VoiceOver tracks its modifier through
/// the real flagsChanged stream.
func postVoiceOverCommand(virtualKey: CGKeyCode, shift: Bool, command: Bool = false,
                          functionKey: Bool = false) {
    let control: CGKeyCode = 59
    let option: CGKeyCode = 58
    let shiftKey: CGKeyCode = 56
    let commandKey: CGKeyCode = 55
    var active: CGEventFlags = [.maskControl, .maskAlternate]
    flagsChanged(control, flags: active)
    flagsChanged(option, flags: active)
    if shift {
        active.insert(.maskShift)
        flagsChanged(shiftKey, flags: active)
    }
    if command {
        active.insert(.maskCommand)
        flagsChanged(commandKey, flags: active)
    }
    if functionKey { active.insert(.maskSecondaryFn) }
    postKey(virtualKey: virtualKey, flags: active)
    if functionKey { active.remove(.maskSecondaryFn) }
    if command {
        active.remove(.maskCommand)
        flagsChanged(commandKey, flags: active)
    }
    if shift {
        active.remove(.maskShift)
        flagsChanged(shiftKey, flags: active)
    }
    flagsChanged(option, flags: [.maskControl])
    flagsChanged(control, flags: [])
}

// A real modifier press is a flagsChanged event, not a key down/up: posting a
// key event for command/shift/control/option does not change the system
// modifier state, so a following click would still arrive unmodified.
func flagsChanged(_ virtualKey: CGKeyCode, flags: CGEventFlags) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let event = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
        event.type = .flagsChanged
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
    usleep(60_000)
}

func keyDown(_ virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
        down.flags = flags
        down.post(tap: .cghidEventTap)
    }
    usleep(40_000)
}

func keyUp(_ virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let up = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
        up.flags = flags
        up.post(tap: .cghidEventTap)
    }
    usleep(40_000)
}

func click(x: Double, y: Double, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left) {
        down.flags = flags
        down.post(tap: .cghidEventTap)
    }
    usleep(40_000)
    if let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
        up.flags = flags
        up.post(tap: .cghidEventTap)
    }
}

// A real pointer drag: press, move in bounded steps so the window server and the
// application both see a continuous gesture, then release. Used to resize an
// owned test window through the SAME input path a person uses instead of an
// Accessibility size assignment, which leaves the window visible but not key.
func drag(x1: Double, y1: Double, x2: Double, y2: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let start = CGPoint(x: x1, y: y1)
    if let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                          mouseCursorPosition: start, mouseButton: .left) {
        down.post(tap: .cghidEventTap)
    }
    usleep(120_000)
    let steps = 24
    for step in 1...steps {
        let fraction = Double(step) / Double(steps)
        let point = CGPoint(x: x1 + (x2 - x1) * fraction, y: y1 + (y2 - y1) * fraction)
        if let moved = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
                               mouseCursorPosition: point, mouseButton: .left) {
            moved.post(tap: .cghidEventTap)
        }
        usleep(25_000)
    }
    usleep(120_000)
    let end = CGPoint(x: x2, y: y2)
    if let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                        mouseCursorPosition: end, mouseButton: .left) {
        up.post(tap: .cghidEventTap)
    }
    usleep(60_000)
}

// A real scroll-wheel gesture at one screen point. The pointer is moved there
// first, so the application's own hit test decides which scroll container owns
// the gesture; the driver never writes an offset or a field.
// A real pointer move with no button pressed: the hover state a person produces
// by moving the mouse over a control.
func movePointer(x: Double, y: Double, settleMicros: UInt32 = 90_000) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) {
        move.post(tap: .cghidEventTap)
    }
    usleep(settleMicros)
}

// A real press that STAYS down, so the pressed paint can be observed before the
// release. The matching `release` always follows in the same verification step.
func mouseDown(x: Double, y: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: point, mouseButton: .left) {
        move.post(tap: .cghidEventTap)
    }
    usleep(60_000)
    if let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                          mouseCursorPosition: point, mouseButton: .left) {
        down.post(tap: .cghidEventTap)
    }
    usleep(80_000)
}

func mouseUp(x: Double, y: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                        mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) {
        up.post(tap: .cghidEventTap)
    }
    usleep(90_000)
}

func scroll(x: Double, y: Double, lines: Int32) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: point, mouseButton: .left) {
        move.post(tap: .cghidEventTap)
    }
    usleep(80_000)
    // A continuous gesture, not one synthetic jump: a trackpad flick posts a
    // bounded series of wheel steps the window server delivers to the view.
    for _ in 0..<6 {
        if let wheel = CGEvent(scrollWheelEvent2Source: source, units: .line, wheelCount: 1,
                               wheel1: lines, wheel2: 0, wheel3: 0) {
            wheel.location = point
            wheel.post(tap: .cghidEventTap)
        }
        usleep(40_000)
    }
    usleep(60_000)
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    FileHandle.standardError.write("usage: driver (type <text> | tab | key <code> | vo <code> | vo-shift <code> | shift-key <code> | cmd-key <code> | opt-key <code> | ctrl-key <code> | key-down <code> | key-up <code> | click <x> <y> | hold-click <modifier> <x> <y> | cmd-click <x> <y> | shift-click <x> <y> | scroll <x> <y> <lines> | move <x> <y> | move-fast <x> <y> | press <x> <y> | release <x> <y> | preflight)\n".data(using: .utf8)!)
    exit(2)
}
switch command {
case "preflight":
    // Prints the measured post-event trust so the caller records the exact
    // condition; a refused host exits 3 (delivery unavailable) instead of
    // silently no-op'ing the segment.
    if postEventAccessGranted() {
        print("post_event_access=granted")
        exit(0)
    } else {
        print("post_event_access=refused")
        exit(3)
    }
case "type":
    postUnicode(args.dropFirst().joined(separator: " "))
case "tab":
    postKey(virtualKey: 48)
case "key":
    postKey(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0))
case "vo":
    // VoiceOver chord: keycodes right=124 left=123 down=125 up=126 space=49.
    postVoiceOverCommand(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0), shift: false)
case "shift-key", "cmd-key", "opt-key", "ctrl-key":
    // One modified key press through the real flagsChanged stream, e.g.
    // shift-key 124 extends a text selection; cmd-key 0 selects all.
    let mask: CGEventFlags
    switch command {
    case "shift-key": mask = [.maskShift]
    case "cmd-key": mask = [.maskCommand]
    case "opt-key": mask = [.maskAlternate]
    default: mask = [.maskControl]
    }
    let keyCode = CGKeyCode(UInt16(args[1]) ?? 0)
    if let source = CGEventSource(stateID: .hidSystemState) {
        if let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            down.flags = mask
            down.post(tap: .cghidEventTap)
        }
        usleep(40_000)
        if let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            up.flags = mask
            up.post(tap: .cghidEventTap)
        }
    }
    usleep(40_000)
case "vo-shift":
    postVoiceOverCommand(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0), shift: true)
case "vo-cmd":
    // ctrl+opt+cmd chord, e.g. keycode 96 (F5) = move the VoiceOver cursor to
    // the mouse pointer position.
    postVoiceOverCommand(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0), shift: false, command: true)
case "vo-cmd-fn":
    // ctrl+opt+cmd + fn-flagged function key: without .maskSecondaryFn a raw
    // F5 keycode is delivered as the media (brightness) key and VoiceOver
    // never sees the chord as F5.
    postVoiceOverCommand(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0), shift: false, command: true,
                         functionKey: true)
case "vo-toggle":
    // cmd+F5 with the fn flag: the real VoiceOver on/off toggle.
    if let source = CGEventSource(stateID: .hidSystemState) {
        var flags: CGEventFlags = [.maskCommand, .maskSecondaryFn]
        if let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(UInt16(args[1]) ?? 96), keyDown: true) {
            down.flags = flags
            down.post(tap: .cghidEventTap)
        }
        usleep(50_000)
        if let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(UInt16(args[1]) ?? 96), keyDown: false) {
            up.flags = flags
            up.post(tap: .cghidEventTap)
        }
    }
    usleep(60_000)
case "click":
    click(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "drag":
    drag(x1: Double(args[1]) ?? 0, y1: Double(args[2]) ?? 0,
         x2: Double(args[3]) ?? 0, y2: Double(args[4]) ?? 0)
case "key-down":
    keyDown(CGKeyCode(UInt16(args[1]) ?? 0))
case "key-up":
    keyUp(CGKeyCode(UInt16(args[1]) ?? 0))
case "scroll":
    scroll(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0, lines: Int32(args[3]) ?? 1)
case "move":
    movePointer(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "move-fast":
    // One real CGEvent without the normal settling delay. Verification can
    // reverse a pointer transition before its 160 ms tween reaches the target.
    movePointer(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0, settleMicros: 1_000)
case "press":
    mouseDown(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "drag-move":
    // Continue the existing press without an extra down/up. Acceptance can
    // observe the picture while the button is still held, including residence.
    if let source = CGEventSource(stateID: .hidSystemState),
       let event = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
                           mouseCursorPosition: CGPoint(x: Double(args[1]) ?? 0,
                                                        y: Double(args[2]) ?? 0),
                           mouseButton: .left) {
        event.post(tap: .cghidEventTap)
    }
    usleep(25_000)
case "release":
    mouseUp(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "cmd-click":
    click(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0, flags: .maskCommand)
case "shift-click":
    click(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0, flags: .maskShift)
case "shortcut":
    // Real modifier press + key with that flag + release: proves whether the
    // host delivers synthesized *keyboard* modifiers when it delivers clicks.
    let modifier = args[1]
    let modifierKey: CGKeyCode
    let modifierFlag: CGEventFlags
    switch modifier {
    case "command": modifierKey = 55; modifierFlag = .maskCommand
    case "shift": modifierKey = 56; modifierFlag = .maskShift
    case "control": modifierKey = 59; modifierFlag = .maskControl
    case "option": modifierKey = 58; modifierFlag = .maskAlternate
    default:
        FileHandle.standardError.write("unknown modifier: \(modifier)\n".data(using: .utf8)!)
        exit(2)
    }
    flagsChanged(modifierKey, flags: modifierFlag)
    postKey(virtualKey: CGKeyCode(UInt16(args[2]) ?? 0), flags: modifierFlag)
    flagsChanged(modifierKey, flags: [])
case "hold-click":
    // Real modifier key codes: command 55, shift 56, control 59, option 58.
    let modifier = args[1]
    let modifierKey: CGKeyCode
    let modifierFlag: CGEventFlags
    switch modifier {
    case "command": modifierKey = 55; modifierFlag = .maskCommand
    case "shift": modifierKey = 56; modifierFlag = .maskShift
    case "control": modifierKey = 59; modifierFlag = .maskControl
    case "option": modifierKey = 58; modifierFlag = .maskAlternate
    default:
        FileHandle.standardError.write("unknown modifier: \(modifier)\n".data(using: .utf8)!)
        exit(2)
    }
    flagsChanged(modifierKey, flags: modifierFlag)
    click(x: Double(args[2]) ?? 0, y: Double(args[3]) ?? 0, flags: modifierFlag)
    usleep(60_000)
    flagsChanged(modifierKey, flags: [])
default:
    FileHandle.standardError.write("unknown command\n".data(using: .utf8)!)
    exit(2)
}

// A posting failure inside any subcommand must not look like a successful
// delivery: report it and exit 3 ("input could not be delivered").
if let failure = deliveryFailure {
    FileHandle.standardError.write("delivery_failure: \(failure)\n".data(using: .utf8)!)
    exit(3)
}
if !postEventAccessGranted() {
    FileHandle.standardError.write("delivery_failure: post_event_access_refused\n".data(using: .utf8)!)
    exit(3)
}
