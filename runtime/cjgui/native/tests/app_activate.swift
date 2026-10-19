import AppKit
import Darwin

// app_activate: pid-addressed activation and frontmost query for real-input
// verification scripts.
//
// Measured 2026-09-27: the System Events form
//   `set p to first process whose unix id is N` then `set frontmost of p to true`
// can resolve to a DIFFERENT running process that shares the application name.
// A query made with our own round's pid answered `PharosMark|pid=<other>`, so the
// script raised the OTHER instance's window above ours while `frontmost of p`
// still answered true; every posted click then landed in that other window.
// This tool addresses the process by pid only -- NSRunningApplication for the
// activation and the AX API for the raise -- so a name collision cannot redirect
// the activation to another process.
//
// usage:
//   app_activate <pid> [--no-raise]   activate, then AX-raise window 1 of that pid
//   app_activate <pid> --frontmost    print "true"/"false": that pid is frontmost
let args = CommandLine.arguments
guard args.count >= 2, let pid = pid_t(args[1]) else {
    FileHandle.standardError.write("usage: app_activate <pid> [--no-raise|--frontmost]\n".data(using: .utf8)!)
    exit(2)
}
let mode = args.count > 2 ? args[2] : ""

// Opt-in bounded call boundaries share the renderer's mach monotonic clock.
// No document text or unrelated application arguments enter this record.
let ownedBoundaryTraceEnabled = ProcessInfo.processInfo.environment["CJGUI_DRIVER_BOUNDARIES"] == "1"
let ownedBoundaryOperation = "activate:" + mode
let ownedBoundaryTargetPid = String(pid)
func traceOwnedDriverBoundary(_ phase: String) {
    guard ownedBoundaryTraceEnabled else { return }
    var scale = mach_timebase_info_data_t()
    mach_timebase_info(&scale)
    let ticks = mach_absolute_time()
    let denominator = UInt64(scale.denom), numerator = UInt64(scale.numer)
    let nanos = (ticks / denominator) * numerator + ((ticks % denominator) * numerator) / denominator
    let line = "CJGUI_DRIVER_BOUNDARY mono_ns=\(nanos) phase=\(phase) operation=\(ownedBoundaryOperation) driver_pid=\(getpid()) target_pid=\(ownedBoundaryTargetPid) buttons=\(NSEvent.pressedMouseButtons)\n"
    FileHandle.standardError.write(Data(line.utf8))
}
traceOwnedDriverBoundary("begin")
atexit { traceOwnedDriverBoundary("end") }

if mode == "--frontmost" {
    let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
    print(frontmost == pid ? "true" : "false")
    exit(frontmost == pid ? 0 : 1)
}

guard let app = NSRunningApplication(processIdentifier: pid) else {
    print("activated=false reason=no_such_pid")
    exit(1)
}
let activated = app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
var raiseResult = "skipped"
if mode != "--no-raise" {
    let axApp = AXUIElementCreateApplication(pid)
    var windowsRef: CFTypeRef?
    if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
        let window = (windowsRef as? [AXUIElement])?.first
    {
        let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        raiseResult = result == .success ? "ok" : "failed:\(result.rawValue)"
    } else {
        raiseResult = "missing"
    }
}
let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
print(
    "activated=\(activated) isActive=\(app.isActive) policy=\(app.activationPolicy.rawValue) raise=\(raiseResult) frontmost_pid=\(frontmost.map(String.init) ?? "none")"
)
exit(frontmost == pid ? 0 : 1)
