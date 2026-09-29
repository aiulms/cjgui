import ApplicationServices
import Foundation

// control_ax_driver <pid> dump | find-id <id> | find-label <label> | press-id <id>
// Walks the real AXChildren graph. System Events' `every text field of window`
// only traverses one flat level on some macOS releases and therefore misses
// controls under a tab group or outline.
guard CommandLine.arguments.count >= 3, let pid = pid_t(CommandLine.arguments[1]) else {
    fputs("usage: control_ax_driver <pid> dump|find-id|find-label|press-id|focus-id [value]\n", stderr)
    exit(2)
}
let operation = CommandLine.arguments[2]
let wanted = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : ""
let app = AXUIElementCreateApplication(pid)
AXUIElementSetMessagingTimeout(app, 5)

func attribute(_ element: AXUIElement, _ name: String) -> Any? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func string(_ element: AXUIElement, _ name: String) -> String {
    return attribute(element, name) as? String ?? ""
}

func flag(_ element: AXUIElement, _ name: String) -> String {
    guard let value = attribute(element, name) as? Bool else { return "-" }
    return value ? "1" : "0"
}

func point(_ value: Any?) -> CGPoint? {
    guard let value, CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else { return nil }
    var point = CGPoint.zero
    guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else { return nil }
    return point
}

func size(_ value: Any?) -> CGSize? {
    guard let value, CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else { return nil }
    var size = CGSize.zero
    guard AXValueGetValue(value as! AXValue, .cgSize, &size) else { return nil }
    return size
}

func hex(_ value: String) -> String {
    return value.utf8.map { String(format: "%02x", $0) }.joined()
}

var queue: [(AXUIElement, String)] = []
if let windows = attribute(app, kAXWindowsAttribute) as? [AXUIElement] {
    queue.append(contentsOf: windows.map { ($0, "window") })
}
var count = 0
// AppKit may expose an application/menu parent again through AXChildren. Keep
// the graph walk finite without discarding a distinct node on a hash collision.
var seen: [CFHashCode: [AXUIElement]] = [:]
while !queue.isEmpty && count < 4096 {
    let (element, parent) = queue.removeFirst()
    let key = CFHash(element)
    if seen[key, default: []].contains(where: { CFEqual($0, element) }) { continue }
    seen[key, default: []].append(element)
    count += 1
    let identifier = string(element, kAXIdentifierAttribute)
    let label = string(element, kAXDescriptionAttribute).isEmpty
        ? string(element, kAXTitleAttribute) : string(element, kAXDescriptionAttribute)
    let selected = flag(element, kAXSelectedAttribute)
    let expanded = flag(element, kAXExpandedAttribute)
    let enabled = flag(element, kAXEnabledAttribute)
    let role = string(element, kAXRoleAttribute)
    let position = point(attribute(element, kAXPositionAttribute)) ?? .zero
    let dimensions = size(attribute(element, kAXSizeAttribute)) ?? .zero
    let frame = "\(Int(position.x)),\(Int(position.y)),\(Int(dimensions.width)),\(Int(dimensions.height))"
    let summary = "AX_NODE role=\(role) id=\(identifier.isEmpty ? "-" : identifier) " +
        "label_hex=\(label.isEmpty ? "-" : hex(label)) enabled=\(enabled) selected=\(selected) " +
        "expanded=\(expanded) parent=\(parent) frame=\(frame)"
    let matched = (operation == "find-id" || operation == "press-id" || operation == "focus-id")
        ? identifier == wanted : operation == "find-label" ? label == wanted : false
    if operation == "dump" || matched {
        print(summary)
    }
    if matched {
        if operation == "press-id" {
            let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
            print("AX_PRESS result=\(result.rawValue)")
            exit(result == .success ? 0 : 1)
        }
        if operation == "focus-id" {
            let result = AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, true as CFBoolean)
            print("AX_SET_FOCUS result=\(result.rawValue)")
            exit(result == .success ? 0 : 1)
        }
        exit(0)
    }
    if let children = attribute(element, kAXChildrenAttribute) as? [AXUIElement] {
        queue.append(contentsOf: children.map { ($0, identifier.isEmpty ? role : identifier) })
    }
}
if operation == "dump" { print("AX_VISITED count=\(count)"); exit(0) }
print("AX_MISSING wanted=\(wanted) visited=\(count)")
exit(1)
