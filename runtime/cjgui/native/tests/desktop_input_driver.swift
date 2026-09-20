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

func postUnicode(_ text: String) {
    for scalar in text.unicodeScalars {
        guard let source = CGEventSource(stateID: .hidSystemState) else { continue }
        var unit = UniChar(scalar.value)
        if let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
            up.post(tap: .cghidEventTap)
        }
        usleep(30_000)
    }
}

func postKey(virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
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

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    FileHandle.standardError.write("usage: driver (type <text> | tab | key <code> | key-down <code> | key-up <code> | click <x> <y> | hold-click <modifier> <x> <y> | cmd-click <x> <y> | shift-click <x> <y>)\n".data(using: .utf8)!)
    exit(2)
}
switch command {
case "type":
    postUnicode(args.dropFirst().joined(separator: " "))
case "tab":
    postKey(virtualKey: 48)
case "key":
    postKey(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0))
case "click":
    click(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "key-down":
    keyDown(CGKeyCode(UInt16(args[1]) ?? 0))
case "key-up":
    keyUp(CGKeyCode(UInt16(args[1]) ?? 0))
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
