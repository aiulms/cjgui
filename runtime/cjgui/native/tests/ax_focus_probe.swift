import ApplicationServices
import Foundation

// ax_focus_probe <pid> [identifier]
//
// Real-focus evidence for a hidden-proxy text input. On macOS the platform
// first responder for a composable text input is the off-canvas NSTextView
// adapter, and System Events answers `AXFocusedUIElement` / `focused` with
// missing values for it, so the accepted-focus question is asked through the
// AX API directly. Prints:
//   app_focused role=... id=... caret=N focus=0/1
//   node id=<identifier> role=... focus=0/1 caret=N valueChars=N
// The composable node itself reports AXFocused=false while the adapter holds
// focus (AppKit answers that attribute from the focus chain); the node's
// selected range coming back as a real caret is the tie between them.
let pid = pid_t(CommandLine.arguments[1])!
let wanted = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""

func attr(_ el: AXUIElement, _ name: String) -> Any? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, name as CFString, &value) == .success else { return nil }
    return value
}

func rangeValue(_ any: Any?) -> NSRange? {
    guard let any, CFGetTypeID(any as CFTypeRef) == AXValueGetTypeID() else { return nil }
    var range = CFRange()
    guard AXValueGetValue(any as! AXValue, .cfRange, &range) else { return nil }
    return NSRange(location: range.location, length: range.length)
}

func stringValue(_ any: Any?) -> String? { any as? String }

func describe(_ el: AXUIElement, label: String) -> String {
    let role = stringValue(attr(el, kAXRoleAttribute)) ?? "?"
    let id = stringValue(attr(el, kAXIdentifierAttribute)) ?? "-"
    let focus = (attr(el, kAXFocusedAttribute) as? Bool).map { $0 ? "1" : "0" } ?? "?"
    let caret = rangeValue(attr(el, kAXSelectedTextRangeAttribute)).map { "\($0.location)" } ?? "-"
    let chars = stringValue(attr(el, kAXNumberOfCharactersAttribute)) ?? "-"
    return "\(label) role=\(role) id=\(id) focus=\(focus) caret=\(caret) valueChars=\(chars)"
}

let app = AXUIElementCreateApplication(pid)
if let focused = attr(app, kAXFocusedUIElementAttribute) {
    print(describe(focused as! AXUIElement, label: "app_focused"))
} else {
    print("app_focused role=none id=- focus=? caret=- valueChars=-")
}

if !wanted.isEmpty {
    var queue: [AXUIElement] = []
    if let windows = attr(app, kAXWindowsAttribute) as? [AXUIElement] {
        queue.append(contentsOf: windows)
    }
    var visited = 0
    var found = false
    while !queue.isEmpty && visited < 4000 {
        let el = queue.removeFirst()
        visited += 1
        if stringValue(attr(el, kAXIdentifierAttribute)) == wanted {
            print(describe(el, label: "node"))
            found = true
            break
        }
        if let children = attr(el, kAXChildrenAttribute) as? [AXUIElement] {
            queue.append(contentsOf: children)
        }
    }
    if !found { print("node id=\(wanted) missing visited=\(visited)") }
}
