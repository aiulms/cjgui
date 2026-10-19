// Process-directed system synthetic input for explicitly owned verification windows.
// Posting attempts are not proof of application receipt or physical human input.
import Cocoa
import Darwin
// The caller creates a private scope for its own launch, then binds it once.
// Every new edge validates the same process instance and window. Releases use
// only that original live process instance, even after a foreground switch.
struct OwnedTarget: Codable, Equatable {
    var schema: Int = 3
    var pid: Int32
    var nonce: String
    var executable: String
    var bundle: String
    var startSeconds: UInt64
    var startMicros: UInt64
    var device: UInt64
    var inode: UInt64
    var size: Int64
    var modifiedSeconds: Int64
    var modifiedNanos: Int64
    var window: UInt32
}
var ownedCancelled: Int32 = 0
var ownedTarget: OwnedTarget? = nil
var ownedScopeBytes: Data? = nil
var ownedPending: [String: CGEvent] = [:]
var ownedNextRelease: CGEvent? = nil
var ownedHeldLocation: CGPoint? = nil
#if OWNED_DRIVER_TEST
var ownedTestClock: UInt64 = 1_000_000_000
var ownedTestPosts = 0
var ownedTestChecks = 0
let ownedTestScenario = ProcessInfo.processInfo.environment["OWNED_TEST_SCENARIO"] ?? "positive"
func ownedMockTarget() -> OwnedTarget {
    return OwnedTarget(pid:123,nonce:"private-test",executable:"/owned/App",bundle:"/owned/App.app",startSeconds:99,startMicros:1,device:1,inode:2,size:30,modifiedSeconds:4,modifiedNanos:5,window:7)
}
#endif
func ownedForeground() -> Int32 {
#if OWNED_DRIVER_TEST
    if ownedTestScenario == "wrong_foreground" || (ownedTestScenario == "switch_before_down" && ownedTestChecks >= 2) ||
        (ownedTestScenario == "switch_after_down" && ownedTestPosts >= 1) ||
        (ownedTestScenario == "unicode_mid_batch" && ownedTestPosts >= 2) ||
        (ownedTestScenario == "long_drag_switch" && ownedTestPosts >= 3) { return 999 }
    return 123
#else
    return NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
#endif
}
func ownedProcessSnapshot(_ expected: OwnedTarget) -> OwnedTarget? {
    var current=expected
#if OWNED_DRIVER_TEST
    if ownedTestScenario == "exited" || (ownedTestScenario == "exit_after_down" && ownedTestPosts >= 1) {return nil}
    if ownedTestScenario == "replaced" || (ownedTestScenario == "replace_after_down" && ownedTestPosts >= 1) {current.startSeconds += 1}
    if ownedTestScenario == "wrong_executable" {current.executable="/other/App"}
    if ownedTestScenario == "changed_binary" {current.inode += 1}
#else
    var b=proc_bsdinfo()
    guard proc_pidinfo(expected.pid,PROC_PIDTBSDINFO,0,&b,Int32(MemoryLayout.size(ofValue:b))) == MemoryLayout.size(ofValue:b) else {return nil}
    var path=[CChar](repeating:0,count:4096)
    guard proc_pidpath(expected.pid,&path,UInt32(path.count)) > 0 else {return nil}
    current.startSeconds=b.pbi_start_tvsec;current.startMicros=b.pbi_start_tvusec
    current.executable=String(cString:path)
    var st=stat()
    guard stat(current.executable,&st) == 0 else {return nil}
    current.device=UInt64(st.st_dev);current.inode=st.st_ino;current.size=st.st_size
    current.modifiedSeconds=Int64(st.st_mtimespec.tv_sec);current.modifiedNanos=Int64(st.st_mtimespec.tv_nsec)
#endif
    return current
}
func ownedProcess(_ expected: OwnedTarget) -> Bool {
    return ownedProcessSnapshot(expected) == expected
}

func ownedWindow(_ expected: OwnedTarget) -> Bool {
#if OWNED_DRIVER_TEST
    return ownedTestScenario != "wrong_window" && ownedTestScenario != "moved_window"
#else
    guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements],kCGNullWindowID) as? [[String:Any]] else {return false}
    guard let row=rows.first(where:{ ($0[kCGWindowOwnerPID as String] as? Int32) == expected.pid &&
        ($0[kCGWindowNumber as String] as? UInt32) == expected.window }) else {return false}
    if let bytes=ownedScopeBytes,let scope=try? JSONSerialization.jsonObject(with:bytes) as? [String:Any],
       let frozen=scope["window_bounds"] as? [String:Double] {
        guard let actual=row[kCGWindowBounds as String] as? [String:Double],actual==frozen else {return false}
    }
    return true
#endif
}
func ownedScopeIntact() -> Bool {
#if OWNED_DRIVER_TEST
    return ownedTestScenario != "replaced_descriptor"
#else
    guard let path=ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_FILE"],let original=ownedScopeBytes,
        let data=try? Data(contentsOf:URL(fileURLWithPath:path)) else {return false}
    return data == original
#endif
}
func ownedNewActionAllowed() -> Bool {
#if OWNED_DRIVER_TEST
    ownedTestChecks += 1
#endif
    guard deliveryFailure == nil,ownedCancelled == 0,let target=ownedTarget,
        ownedProcess(target),ownedScopeIntact(),ownedWindow(target),ownedForeground() == target.pid else {
        failDelivery("owned_target_identity_window_foreground_or_cancelled");return false
    }
    return true
}
func ownedSend(_ event: CGEvent, _ target: OwnedTarget) {
#if OWNED_DRIVER_TEST
    ownedTestPosts += 1
    var fact=trajectoryKeyboardFact(event)
    fact["pid"]=target.pid;fact["type"]=event.type.rawValue;fact["x"]=event.location.x;fact["y"]=event.location.y
    fact["clock_ns"]=ownedTestClock
    fact["ns_window"]=NSEvent(cgEvent:event)?.windowNumber ?? -1
    if let d=try? JSONSerialization.data(withJSONObject:fact,options:[.sortedKeys]) {
        print("MOCK_OWNED_POST "+String(decoding:d,as:UTF8.self))
    }
    if ownedTestScenario == "cancel_after_down" && ownedTestPosts == 1 { ownedCancelled = 1 }
#else
    event.postToPid(target.pid)
#endif
}
func ownedReleasePending() {
    let pending=ownedPending;ownedPending.removeAll()
    guard let target=ownedTarget,ownedProcess(target) else {return}
    for (key,up) in pending {
        if key == "mouse:left",let point=ownedHeldLocation {up.location=point}
        ownedSend(up,target)
    }
    ownedHeldLocation=nil
}
@discardableResult func ownedPost(_ event: CGEvent) -> Bool {
    guard ownedNewActionAllowed(),let target=ownedTarget else {ownedReleasePending();return false}
    // Remember the original paired edge, not a new down or a different target.
    let key="key:\(event.getIntegerValueField(.keyboardEventKeycode))"
    switch event.type {
    case .keyDown:
        guard let up=ownedNextRelease ?? event.copy() else {failDelivery("owned_release_copy_failed");ownedReleasePending();return false}
        up.type = .keyUp;ownedPending[key]=up;ownedNextRelease=nil
    case .leftMouseDown:
        guard let up=ownedNextRelease ?? event.copy() else {failDelivery("owned_release_copy_failed");ownedReleasePending();return false}
        up.type = .leftMouseUp;ownedPending["mouse:left"]=up;ownedNextRelease=nil;ownedHeldLocation=event.location
    case .leftMouseDragged:
        ownedHeldLocation=event.location
    case .keyUp: ownedPending.removeValue(forKey:key)
    case .leftMouseUp: ownedPending.removeValue(forKey:"mouse:left");ownedHeldLocation=nil
    default:break
    }
    ownedSend(event,target)
    return true
}
// Public AppKit envelope for an explicit target window. Quartz points stay in
// the original display coordinate domain; window-base points use the frozen
// frame bottom, independently checked against the target's convertPointToScreen.
func ownedMouseEvent(mouseEventSource source:CGEventSource?,mouseType type:CGEventType,
    mouseCursorPosition point:CGPoint,mouseButton button:CGMouseButton) -> CGEvent? {
    guard let original=CGEvent(mouseEventSource:source,mouseType:type,mouseCursorPosition:point,mouseButton:button) else {return nil}
    if ProcessInfo.processInfo.environment["CJGUI_DRIVER_RAW_POINTER_BASELINE"] == "1" {return original}
    guard let target=ownedTarget,let nsType=NSEvent.EventType(rawValue:UInt(type.rawValue)) else {failDelivery("owned_mouse_target_required");return nil}
    let baseX:Double,baseY:Double,top:Double
#if OWNED_DRIVER_TEST
    baseX=0;baseY=362;top=982
#else
    guard let bytes=ownedScopeBytes,let scope=try? JSONSerialization.jsonObject(with:bytes) as? [String:Any],
        let bounds=scope["window_bounds"] as? [String:Double],let x=bounds["X"],let y=bounds["Y"],let h=bounds["Height"],
        let screen=NSScreen.screens.first else {failDelivery("owned_mouse_frozen_geometry_required");return nil}
    top=screen.frame.maxY;baseX=x;baseY=top-y-h
    if let independent=scope["window_geometry"] as? [String:Double] {
        guard independent["pid"]==Double(target.pid),independent["window"]==Double(target.window),
            abs((independent["base_x"] ?? .infinity)-baseX)<0.01,
            abs((independent["base_y"] ?? .infinity)-baseY)<0.01,
            abs((independent["quartz_top"] ?? .infinity)-top)<0.01 else {failDelivery("owned_mouse_independent_geometry_mismatch");return nil}
    }
#endif
    let local=CGPoint(x:point.x-baseX,y:top-point.y-baseY)
    let number=original.getIntegerValueField(.mouseEventNumber)
    let clicks=original.getIntegerValueField(.mouseEventClickState)
    let pressure=original.getDoubleValueField(.mouseEventPressure)
    guard let native=NSEvent.mouseEvent(with:nsType,location:local,
        modifierFlags:NSEvent.ModifierFlags(rawValue:UInt(original.flags.rawValue)),timestamp:Double(original.timestamp)/1e9,
        windowNumber:Int(target.window),context:nil,eventNumber:Int(number),clickCount:Int(clicks),pressure:Float(pressure)),
        native.windowNumber==Int(target.window),native.locationInWindow==local,
        let event=native.cgEvent?.copy() else {failDelivery("owned_mouse_public_window_construction");return nil}
    event.location=point;event.timestamp=original.timestamp;event.flags=original.flags
    event.setIntegerValueField(.mouseEventNumber,value:number)
    event.setIntegerValueField(.mouseEventClickState,value:clicks)
    event.setDoubleValueField(.mouseEventPressure,value:pressure)
    event.setIntegerValueField(.mouseEventDeltaX,value:original.getIntegerValueField(.mouseEventDeltaX))
    event.setIntegerValueField(.mouseEventDeltaY,value:original.getIntegerValueField(.mouseEventDeltaY))
    guard event.location==point,NSEvent(cgEvent:event)?.windowNumber==Int(target.window),
        event.timestamp==original.timestamp,event.flags==original.flags else {failDelivery("owned_mouse_window_quartz_intent_mismatch");return nil}
    // The foreign window is not present in this producer's NSApplication.
    // A surviving window number/global point does not prove window-base data.
    // Refuse rather than post the known contradictory native representation.
    guard let decoded=NSEvent(cgEvent:event),decoded.locationInWindow==local else {
        failDelivery("owned_mouse_foreign_window_base_readback_mismatch");return nil
    }
    return event
}

func ownedSleep(_ micros: UInt32) {
#if OWNED_DRIVER_TEST
    ownedTestClock += UInt64(micros)*1000
#else
    usleep(micros)
#endif
}
func ownedLoad() -> Bool {
#if OWNED_DRIVER_TEST
    if ownedTestScenario == "missing_target" {failDelivery("owned_target_required");return false}
    ownedTarget=ownedMockTarget()
#else
    guard let path=ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_FILE"],
        let bytes=try? Data(contentsOf:URL(fileURLWithPath:path)),bytes.count<=16384,
        let t=try? JSONDecoder().decode(OwnedTarget.self,from:bytes), t.schema == 3,t.pid>0,!t.nonce.isEmpty,
        ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_PID"] == String(t.pid) else {
        failDelivery("owned_target_envelope_required");return false
    }
    ownedTarget=t;ownedScopeBytes=bytes
#endif
    return ownedNewActionAllowed()
}
func ownedBind(_ path: String) throws {
    let url=URL(fileURLWithPath:path)
    let bytes=try Data(contentsOf:url)
    guard bytes.count<=16384,let scope=try JSONSerialization.jsonObject(with:bytes) as? [String:Any],
        let pid=scope["pid"] as? Int32,pid>0,let nonce=scope["nonce"] as? String,nonce.count>=16,
        let executable=scope["executable"] as? String,
        let app=NSRunningApplication(processIdentifier:pid),app.executableURL?.path == executable,
        let bundle=app.bundleURL?.path,ownedForeground() == pid else {throw NSError(domain:"owned_bind_scope",code:1)}
    var b=proc_bsdinfo();var s=stat()
    guard proc_pidinfo(pid,PROC_PIDTBSDINFO,0,&b,Int32(MemoryLayout.size(ofValue:b))) == MemoryLayout.size(ofValue:b),stat(executable,&s) == 0,
        let rows=CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements],kCGNullWindowID) as? [[String:Any]],
        let w=rows.first(where:{ row in (row[kCGWindowOwnerPID as String] as? Int32)==pid && (row[kCGWindowLayer as String] as? Int)==0 &&
            ((scope["window_title"] as? String).map { title in (row[kCGWindowName as String] as? String)==title } ?? true)}),
        let window=w[kCGWindowNumber as String] as? UInt32,
        let bounds=w[kCGWindowBounds as String] as? [String:Double] else {throw NSError(domain:"owned_bind_process_window",code:2)}
    let t=OwnedTarget(pid:pid,nonce:nonce,executable:executable,bundle:bundle,startSeconds:b.pbi_start_tvsec,startMicros:b.pbi_start_tvusec,
        device:UInt64(s.st_dev),inode:s.st_ino,size:s.st_size,modifiedSeconds:Int64(s.st_mtimespec.tv_sec),modifiedNanos:Int64(s.st_mtimespec.tv_nsec),window:window)
    guard ownedProcess(t),ownedWindow(t) else {throw NSError(domain:"owned_bind_raced",code:3)}
    var encoded=try JSONSerialization.jsonObject(with:JSONEncoder().encode(t)) as! [String:Any]
    encoded["window_bounds"]=bounds
    try JSONSerialization.data(withJSONObject:encoded,options:[.sortedKeys]).write(to:url,options:.atomic)
    print("owned_target_bound schema=3 pid=\(pid) window=\(window)")
}


// Event-posting trust: a synthetic event is only delivered when the process
// holds the post-event permission. This is queried up front so a caller can
// tell "the host refused to deliver input" apart from "the app mishandled a
// delivered event" - the two need different verdicts.
func postEventAccessGranted() -> Bool {
    if #available(macOS 10.15, *) {
        #if OWNED_DRIVER_TEST
        return true
#else
        return CGPreflightPostEventAccess()
#endif
    }
    return true
}

// Set when an event object could not be created or posted, so main can exit
// non-zero instead of silently claiming a delivered input.
var deliveryFailure: String? = nil

func failDelivery(_ reason: String) {
    if deliveryFailure == nil { deliveryFailure = reason }
}

func postUnicode(_ text: String, checkOnly: Bool = false, notBefore: UInt64? = nil, notAfter: UInt64? = nil) {
    let target=ownedTarget?.pid
    let batchBegin=ownedMonotonicNanos();var facts:[[String:Any]]=[]
    var prepared:[(String,CGEvent,CGEvent,[UInt64])]=[]
    if !checkOnly && (target == nil || ownedForeground() != target || !postEventAccessGranted()) {
        failDelivery("unicode_target_or_permission")
    } else if let source=CGEventSource(stateID:.hidSystemState) {
        // Both edges of every original scalar exist before the first post.
        for (index,scalar) in text.unicodeScalars.enumerated() {
            var units=Array(String(scalar).utf16)
            guard let down=CGEvent(keyboardEventSource:source,virtualKey:0,keyDown:true),
                  let up=CGEvent(keyboardEventSource:source,virtualKey:0,keyDown:false) else {
                failDelivery("unicode_pair_creation_index_\(index)");break
            }
            let constructed=[down.flags.rawValue,up.flags.rawValue]
            down.flags=[];up.flags=[]
            down.setIntegerValueField(.eventSourceUserData,value:Int64(index+1))
            up.setIntegerValueField(.eventSourceUserData,value:Int64(index+1))
            down.keyboardSetUnicodeString(stringLength:units.count,unicodeString:&units)
            up.keyboardSetUnicodeString(stringLength:units.count,unicodeString:&units)
            guard trajectoryKeyboardFact(down)["unicode_utf16"] as? [UniChar] == units,
                  trajectoryKeyboardFact(up)["unicode_utf16"] as? [UniChar] == units else {
                failDelivery("unicode_intent_mismatch_index_\(index)");break
            }
            prepared.append((String(scalar),down,up,constructed))
        }
    } else {failDelivery("no_event_source")}
    if deliveryFailure == nil, !checkOnly, let earliest=notBefore {
        let now=ownedMonotonicNanos();if now<earliest {ownedSleep(UInt32((earliest-now+999)/1000))}
        if let latest=notAfter,ownedMonotonicNanos()>latest {failDelivery("first_text_driver_deadline_missed")}
    }
    if deliveryFailure == nil {
        for (index,row) in prepared.enumerated() {
            if !checkOnly && ownedForeground() != target {
                failDelivery("unicode_frontmost_changed_index_\(index)");break
            }
            let down=trajectoryKeyboardFact(row.1),up=trajectoryKeyboardFact(row.2)
            let begin=ownedMonotonicNanos()
            if !checkOnly {ownedNextRelease=row.2;guard ownedPost(row.1),ownedPost(row.2) else {break}}
            let end=ownedMonotonicNanos()
            facts.append(["text":row.0,"batch_index":index,"posted_down":down,"posted_up":up,
                "constructed_flags_raw":row.3,"post_begin_ns":begin,"post_end_ns":end,"post_attempts":checkOnly ? 0 : 1])
            if !checkOnly {ownedSleep(30_000)}
        }
    }
    let result:[String:Any]=["operation":"type","payload":text,"driver_pid":getpid(),
        "target_pid":target as Any? ?? NSNull(),"batch_begin_ns":batchBegin,"batch_end_ns":ownedMonotonicNanos(),
        "check_only":checkOnly,"text_events":facts,"text_attempts":checkOnly ? 0 : facts.count,
        "text_posted": !checkOnly && facts.count==text.unicodeScalars.count && deliveryFailure == nil,
        "failure":deliveryFailure as Any? ?? NSNull(),"interval_us":30000]
    if let data=try? JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]) {
        FileHandle.standardOutput.write(data);FileHandle.standardOutput.write(Data([10]))
    }
}

// The modified-key command preserves its existing 40ms down/up spacing.
// Facts describe this original pair; callers do not infer native receipt.
func postModifiedKeyFacts(_ key: CGKeyCode, flags: CGEventFlags, checkOnly: Bool = false) {
    let target = ownedTarget?.pid

    var facts: [String:Any] = ["operation":"modified_key", "key_code":key,
        "target_pid":target as Any? ?? NSNull(), "driver_pid":getpid(), "check_only":checkOnly,
        "hold_us":40000, "after_us":40000, "post_attempts":0]
    if !checkOnly && (target == nil || ownedForeground() != target || !postEventAccessGranted()) {
        failDelivery("modified_key_target_or_permission")
    } else if let source=CGEventSource(stateID:.hidSystemState),
              let down=CGEvent(keyboardEventSource:source,virtualKey:key,keyDown:true),
              let up=CGEvent(keyboardEventSource:source,virtualKey:key,keyDown:false) {
        facts["constructed_flags_raw"]=[down.flags.rawValue,up.flags.rawValue]
        down.flags=flags;up.flags=flags
        facts["posted_down"]=trajectoryKeyboardFact(down)
        facts["posted_up"]=trajectoryKeyboardFact(up)
        if !checkOnly {
            facts["post_begin_ns"]=ownedMonotonicNanos()
            ownedNextRelease=up
            ownedPost(down);ownedSleep(40000)
            ownedPost(up)
            facts["post_end_ns"]=ownedMonotonicNanos();facts["post_attempts"]=1
            ownedSleep(40000)
        }
    } else { failDelivery("modified_key_pair_creation") }
    facts["failure"]=deliveryFailure as Any? ?? NSNull()
    if let data=try? JSONSerialization.data(withJSONObject:facts,options:[.sortedKeys]) {
        FileHandle.standardOutput.write(data);FileHandle.standardOutput.write(Data([10]))
    }
}

func postKey(virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { failDelivery("no_event_source"); return }
    if let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
        down.flags = flags
        ownedPost(down)
    }
    if let up = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
        up.flags = flags
        ownedPost(up)
    }
    ownedSleep(40_000)
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
        ownedPost(event)
    }
    ownedSleep(60_000)
}

func keyDown(_ virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
        down.flags = flags
        ownedPost(down)
    }
    ownedSleep(40_000)
}

func keyUp(_ virtualKey: CGKeyCode, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let up = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
        up.flags = flags
        ownedPost(up)
    }
    ownedSleep(40_000)
}

func click(x: Double, y: Double, flags: CGEventFlags = []) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let down = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left) {
        down.flags = flags
        ownedPost(down)
    }
    ownedSleep(40_000)
    if let up = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
        up.flags = flags
        ownedPost(up)
    }
}

// A real pointer drag: press, move in bounded steps so the window server and the
// application both see a continuous gesture, then release. Used to resize an
// owned test window through the SAME input path a person uses instead of an
// Accessibility size assignment, which leaves the window visible but not key.
func drag(x1: Double, y1: Double, x2: Double, y2: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let start = CGPoint(x: x1, y: y1)
    if let down = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                          mouseCursorPosition: start, mouseButton: .left) {
        ownedPost(down)
    }
    ownedSleep(120_000)
    let steps = 24
    for step in 1...steps {
        let fraction = Double(step) / Double(steps)
        let point = CGPoint(x: x1 + (x2 - x1) * fraction, y: y1 + (y2 - y1) * fraction)
        if let moved = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
                               mouseCursorPosition: point, mouseButton: .left) {
            ownedPost(moved)
        }
        ownedSleep(25_000)
    }
    ownedSleep(120_000)
    let end = CGPoint(x: x2, y: y2)
    if let up = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                        mouseCursorPosition: end, mouseButton: .left) {
        ownedPost(up)
    }
    ownedSleep(60_000)
}

// A real scroll-wheel gesture at one screen point. The pointer is moved there
// first, so the application's own hit test decides which scroll container owns
// the gesture; the driver never writes an offset or a field.
// A real pointer move with no button pressed: the hover state a person produces
// by moving the mouse over a control.
func movePointer(x: Double, y: Double, settleMicros: UInt32 = 90_000) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let move = ownedMouseEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) {
        ownedPost(move)
    }
    ownedSleep(settleMicros)
}

// A real press that STAYS down, so the pressed paint can be observed before the
// release. The matching `release` always follows in the same verification step.
func mouseDown(x: Double, y: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let move = ownedMouseEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: point, mouseButton: .left) {
        ownedPost(move)
    }
    ownedSleep(60_000)
    if let down = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                          mouseCursorPosition: point, mouseButton: .left) {
        let before=ownedMonotonicNanos()
        ownedPost(down)
        let after=ownedMonotonicNanos()
        emitObservedMousePost("press",x:x,y:y,before:before,after:after)
    } else { failDelivery("no_mouse_down") }
    ownedSleep(80_000)
}

func mouseUp(x: Double, y: Double) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    if let up = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                        mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) {
        let before=ownedMonotonicNanos()
        ownedPost(up)
        let after=ownedMonotonicNanos()
        emitObservedMousePost("release",x:x,y:y,before:before,after:after)
    } else { failDelivery("no_mouse_up") }
    ownedSleep(90_000)
}

func scroll(x: Double, y: Double, lines: Int32) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    let point = CGPoint(x: x, y: y)
    if let move = ownedMouseEvent(mouseEventSource: source, mouseType: .mouseMoved,
                          mouseCursorPosition: point, mouseButton: .left) {
        move.flags = []
        ownedPost(move)
    }
    ownedSleep(80_000)
    // A continuous gesture, not one synthetic jump: a trackpad flick posts a
    // bounded series of wheel steps the window server delivers to the view.
    for _ in 0..<6 {
        if let wheel = CGEvent(scrollWheelEvent2Source: source, units: .line, wheelCount: 1,
                               wheel1: lines, wheel2: 0, wheel3: 0) {
            wheel.location = point
            wheel.flags = []
            ownedPost(wheel)
        }
        ownedSleep(40_000)
    }
    ownedSleep(60_000)
}

func ownedMonotonicNanos() -> UInt64 {
#if OWNED_DRIVER_TEST
    return ownedTestClock
#else
    var scale = mach_timebase_info_data_t()
    mach_timebase_info(&scale)
    let ticks = mach_absolute_time()
    let denominator = UInt64(scale.denom), numerator = UInt64(scale.numer)
    return (ticks / denominator) * numerator + ((ticks % denominator) * numerator) / denominator
#endif
}

func emitObservedMousePost(_ operation:String,x:Double,y:Double,before:UInt64,after:UInt64) {
    guard ownedBoundaryTraceEnabled else { return }
    let fact:[String:Any] = ["actual_event_post":true,"operation":operation,
        "action_id":ProcessInfo.processInfo.environment["CJGUI_DRIVER_ACTION_ID"] ?? "unassigned",
        "driver_pid":getpid(),"target_pid":ownedBoundaryTargetPid,"x":x,"y":y,
        "post_begin_ns":before,"post_end_ns":after,"post_attempts":1]
    if let data=try? JSONSerialization.data(withJSONObject:fact,options:[.sortedKeys]) {
        FileHandle.standardOutput.write(data);FileHandle.standardOutput.write(Data("\n".utf8))
    }
}

func firstTextDeadlineDecision(up: UInt64, now: UInt64, expectedPid: Int32,
                               frontPid: Int32) -> String? {
    if frontPid != expectedPid { return "first_text_frontmost_changed" }
    if now < up + 50_000_000 { return "first_text_before_fixed_deadline" }
    if now > up + 100_000_000 { return "first_text_driver_deadline_missed" }
    return nil
}

// Verification-only HID sequence. Pre-create events; do not wait for any
// owner/install or activate a window between the sole UP and first text.
func releaseThenFirstX(x: Double, y: Double) {
    guard let target = ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_PID"],
          let expected = Int32(target), expected > 0, postEventAccessGranted(),
          let source = CGEventSource(stateID: .hidSystemState),
          let up = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                           mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left),
          let textDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
          let textUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
    else { failDelivery("first_text_event_or_target_unavailable"); return }
    var unit: [UniChar] = [88]
    textDown.flags = []; textUp.flags = []
    textDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
    textUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unit)
    let beforeFront = ownedForeground()
    let upBegin = ownedMonotonicNanos()
    ownedPost(up)
    let upEnd = ownedMonotonicNanos()
    let deadline = upBegin + 50_000_000
    let now = ownedMonotonicNanos()
    if now < deadline { ownedSleep(UInt32((deadline - now + 999) / 1000)) }
    let front = ownedForeground()
    let textBegin = ownedMonotonicNanos()
    let failure = beforeFront != expected ? "first_text_frontmost_changed_before_UP" :
        firstTextDeadlineDecision(up: upBegin, now: textBegin, expectedPid: expected, frontPid: front)
    if failure == nil {
        ownedPost(textDown)
        ownedPost(textUp)
    } else { failDelivery(failure!) }
    let textEnd = ownedMonotonicNanos()
    let result: [String: Any] = ["up_post_begin_ns": upBegin, "up_post_end_ns": upEnd,
        "text_post_begin_ns": textBegin, "text_post_end_ns": textEnd,
        "first_text_deadline_ns": deadline, "expected_pid": expected,
        "front_before_up": beforeFront, "front_before_text": front,
        "text_posted": failure == nil, "failure": failure as Any? ?? NSNull(),
        "up_attempts": 1, "text_attempts": failure == nil ? 1 : 0]
    if let json = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]) {
        FileHandle.standardOutput.write(json); FileHandle.standardOutput.write(Data("\n".utf8))
    }
}

// One process/one call posts the entire immutable trajectory. No owner/log/
// screenshot round trip in the MOVE loop; original post intervals are retained.
func trajectoryPlan(_ path:String) throws -> (Int32,[[String:Any]],String) {
    let data=try Data(contentsOf:URL(fileURLWithPath:path))
    guard data.count<=1024*1024,let plan=try JSONSerialization.jsonObject(with:data) as? [String:Any],
        let target=plan["target_pid"] as? Int32,target>0,let rows=plan["events"] as? [[String:Any]],rows.count>=3,rows.count<=4096,
        rows.first?["kind"] as? String=="down",rows.last?["kind"] as? String=="up" else {throw NSError(domain:"trajectory_plan",code:1)}
    var previous = -1.0
    for (index,row) in rows.enumerated() {
        guard let at=row["at_ms"] as? Double,let x=row["x"] as? Double,let y=row["y"] as? Double,
          at.isFinite,x.isFinite,y.isFinite,at>=0,at>previous,at<=120000,
          row["kind"] as? String==(index==0 ? "down" : index==rows.count-1 ? "up" : "move") else {throw NSError(domain:"trajectory_plan_order",code:2)}
        previous=at
    }
    return (target,rows,plan["after_up_text"] as? String ?? "")
}
func trajectoryKeyboardFact(_ event:CGEvent) -> [String:Any] {
    var length=0;var units=[UniChar](repeating:0,count:8)
    event.keyboardGetUnicodeString(maxStringLength:units.count,actualStringLength:&length,unicodeString:&units)
    return ["flags_raw":event.flags.rawValue,
            "key_code":event.getIntegerValueField(.keyboardEventKeycode),
            "event_type":event.type.rawValue,
            "unicode_utf16_length":length,"unicode_utf16":Array(units.prefix(length)),
            "source_user_data":event.getIntegerValueField(.eventSourceUserData)]
}
func dragTrajectory(_ path:String,checkOnly:Bool=false) {
    do {
        let (target,rows,text)=try trajectoryPlan(path)
        if checkOnly {print("TRAJECTORY_PLAN_PASS events=\(rows.count) target=\(target)");return}
        guard ownedTarget?.pid==target,ownedForeground()==target,postEventAccessGranted(),let source=CGEventSource(stateID:.hidSystemState) else {failDelivery("trajectory_target_or_permission");return}
        var events:[CGEvent]=[];var constructedMouseFlags:[UInt64]=[]
        for (index,row) in rows.enumerated() {
            let type:CGEventType=index==0 ? .leftMouseDown : index==rows.count-1 ? .leftMouseUp : .leftMouseDragged
            guard let e=ownedMouseEvent(mouseEventSource:source,mouseType:type,mouseCursorPosition:CGPoint(x:row["x"] as! Double,y:row["y"] as! Double),mouseButton:.left) else {failDelivery("trajectory_event_creation");return}
            constructedMouseFlags.append(e.flags.rawValue)
            e.flags=[]  // This trajectory declares an ordinary, unmodified drag.
            e.setIntegerValueField(.eventSourceUserData,value:Int64(index+1));events.append(e)
        }
        ownedNextRelease=events.last
        let origin=ownedMonotonicNanos()+20_000_000;var facts:[[String:Any]]=[]
        for (index,event) in events.enumerated() {
            let deadline=origin+UInt64((rows[index]["at_ms"] as! Double)*1e6)
            let now=ownedMonotonicNanos();if now<deadline {ownedSleep(UInt32((deadline-now+999)/1000))}
            let before=ownedMonotonicNanos();guard ownedPost(event) else {break};let after=ownedMonotonicNanos()
            facts.append(["index":index,"kind":rows[index]["kind"]!,"x":rows[index]["x"]!,"y":rows[index]["y"]!,"deadline_ns":deadline,"post_begin_ns":before,"post_end_ns":after,"post_attempts":1,"synthetic_system_CGEvent":true,"flags_raw":event.flags.rawValue,"constructed_flags_raw":constructedMouseFlags[index],"source_user_data":event.getIntegerValueField(.eventSourceUserData)])
        }
        guard facts.count == rows.count, let last=facts.last else {ownedReleasePending();return}
        let up=last["post_begin_ns"] as! UInt64;var textFacts:[[String:Any]]=[]
        for (index,scalar) in text.unicodeScalars.enumerated() {
            let deadline=up+50_000_000+UInt64(index)*30_000_000;let now=ownedMonotonicNanos();if now<deadline {ownedSleep(UInt32((deadline-now+999)/1000))}
            guard ownedForeground()==target else {failDelivery("trajectory_text_frontmost_changed");break}
            var units=Array(String(scalar).utf16)
            guard let d=CGEvent(keyboardEventSource:source,virtualKey:0,keyDown:true),let u=CGEvent(keyboardEventSource:source,virtualKey:0,keyDown:false) else {failDelivery("trajectory_text_event_creation");break}
            let constructedFlags=[d.flags.rawValue,u.flags.rawValue]
            // Freeze only our own ordinary-text events, never system key state.
            d.flags=[];u.flags=[]
            d.setIntegerValueField(.eventSourceUserData,value:Int64(rows.count+index+1))
            u.setIntegerValueField(.eventSourceUserData,value:Int64(rows.count+index+1))
            d.keyboardSetUnicodeString(stringLength:units.count,unicodeString:&units);u.keyboardSetUnicodeString(stringLength:units.count,unicodeString:&units)
            let downFact=trajectoryKeyboardFact(d);let upFact=trajectoryKeyboardFact(u)
            guard d.flags.isEmpty,u.flags.isEmpty,
                downFact["unicode_utf16"] as? [UniChar] == units,
                upFact["unicode_utf16"] as? [UniChar] == units else {failDelivery("trajectory_text_intent_mismatch_before_post");break}
            ownedNextRelease=u
            let before=ownedMonotonicNanos();guard ownedPost(d),ownedPost(u) else {break};let after=ownedMonotonicNanos()
            textFacts.append(["text":String(scalar),"post_begin_ns":before,"post_end_ns":after,"post_attempts":1,"batch_index":index,"constructed_flags_raw":constructedFlags,"posted_down":downFact,"posted_up":upFact])
        }
        let first=textFacts.first;let result:[String:Any]=["target_pid":target,"driver_pid":getpid(),"events":facts,"text_events":textFacts,"up_post_begin_ns":up,"up_post_end_ns":facts.last!["post_end_ns"]!,"text_post_begin_ns":first?["post_begin_ns"] as Any? ?? NSNull(),"text_post_end_ns":first?["post_end_ns"] as Any? ?? NSNull(),"text_attempts":textFacts.count,"text_posted":textFacts.count==text.unicodeScalars.count,"up_attempts":1,"failure":deliveryFailure as Any? ?? NSNull(),"scope":"one synthetic system trajectory; OS coalescing permitted; no per-MOVE observation or retry"]
        let encoded=try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]);FileHandle.standardOutput.write(encoded);FileHandle.standardOutput.write(Data([10]))
    } catch {failDelivery("trajectory_invalid: \(error)")}
}

// Reuse the safe keyboard producer; wait only for original UP enqueue, never owner.
func typeAfterAppKitUp(_ path:String,text:String) {
    guard let target=ownedTarget,let scopePath=ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_FILE"],
        URL(fileURLWithPath:path).deletingLastPathComponent()==URL(fileURLWithPath:scopePath).deletingLastPathComponent()
        else {failDelivery("appkit_up_fact_scope");return}
    let end=ownedMonotonicNanos()+120_000_000_000
    while ownedMonotonicNanos()<end {
        guard ownedCancelled==0,ownedProcess(target) else {failDelivery("appkit_up_original_process_ended");return}
        if let bytes=try? Data(contentsOf:URL(fileURLWithPath:path)),bytes.count>0,bytes.count<=4096,
           let fact=try? JSONSerialization.jsonObject(with:bytes) as? [String:Any] {
            guard fact["pid"] as? Int32==target.pid,fact["window"] as? UInt32==target.window,
                fact["nonce"] as? String==target.nonce,fact["cancelled"] as? Bool==false,
                let up=fact["up_begin_ns"] as? UInt64,up<UInt64.max-100_000_000 else {
                failDelivery("appkit_up_fact_identity_or_cancelled");return
            }
            postUnicode(text,notBefore:up+50_000_000,notAfter:up+100_000_000);return
        }
        ownedSleep(5000)
    }
    failDelivery("appkit_up_fact_timeout")
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    FileHandle.standardError.write("usage: driver (type <text> | tab | key <code> | vo <code> | vo-shift <code> | shift-key <code> | cmd-key <code> | cmd-shift-key <code> | opt-key <code> | ctrl-key <code> | key-down <code> | key-up <code> | click <x> <y> | hold-click <modifier> <x> <y> | cmd-click <x> <y> | shift-click <x> <y> | scroll <x> <y> <lines> | move <x> <y> | move-fast <x> <y> | press <x> <y> | release <x> <y> | preflight)\n".data(using: .utf8)!)
    exit(2)
}
// Opt-in bounded call boundaries share the renderer's mach monotonic clock.
// No document text or unrelated application arguments enter this record.
let ownedBoundaryTraceEnabled = ProcessInfo.processInfo.environment["CJGUI_DRIVER_BOUNDARIES"] == "1"
let ownedBoundaryOperation = command
let ownedBoundaryTargetPid = ProcessInfo.processInfo.environment["CJGUI_DRIVER_TARGET_PID"] ?? "unknown"
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

let readonlyCommands: Set<String> = ["preflight","keyboard-plan-check","unicode-plan-check","trajectory-plan-check","bind-target"]
if command == "bind-target" {
    do { guard args.count == 2 else {exit(2)};try ownedBind(args[1]);exit(0) }
    catch {FileHandle.standardError.write(Data("owned_bind_failed: \(error)\n".utf8));exit(3)}
}
if !readonlyCommands.contains(command) {
    signal(SIGINT) { _ in ownedCancelled = 1 };signal(SIGTERM) { _ in ownedCancelled = 1 }
    // Split gestures cannot own cancellation across separate processes. Current
    // consumers use one immutable down/move/up trajectory instead.
    if ["press","drag-move","release","release-first-X","key-down","key-up","vo","vo-shift","vo-cmd","vo-cmd-fn","vo-toggle","shortcut","hold-click"].contains(command) {
        failDelivery("split_edge_commands_retired_use_owned_trajectory");exit(3)
    }
    guard ownedLoad() else {exit(3)}
}
switch command {
case "drag-trajectory", "trajectory-plan-check":
    guard args.count==2 else {exit(2)}
    dragTrajectory(args[1],checkOnly:command=="trajectory-plan-check")
case "preflight":
    // Prints the measured post-event trust so the caller records the exact
    // condition; a refused host exits 3 (delivery unavailable) instead of
    // silently no-op'ing the segment.
    if postEventAccessGranted() {
        print("post_event_access=granted")
        print("driver_facts_version=4 mouse_modifiers=owned unicode_modifiers=owned ordinary_unicode_facts=1 target_identity=process_start_executable_window route=process_directed window_route=blocked_foreign_window_base")
        exit(0)
    } else {
        print("post_event_access=refused")
        exit(3)
    }
case "keyboard-plan-check":
    postModifiedKeyFacts(CGKeyCode(UInt16(args[1]) ?? 0),flags:.maskCommand,checkOnly:true)
case "unicode-plan-check":
    postUnicode(args.dropFirst().joined(separator: " "),checkOnly:true)
case "type-after-appkit-up":
    guard args.count==3 else {exit(2)}
    typeAfterAppKitUp(args[1],text:args[2])
case "type":
    postUnicode(args.dropFirst().joined(separator: " "))
case "tab":
    postKey(virtualKey: 48)
case "key":
    postKey(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0))
case "vo":
    // VoiceOver chord: keycodes right=124 left=123 down=125 up=126 space=49.
    postVoiceOverCommand(virtualKey: CGKeyCode(UInt16(args[1]) ?? 0), shift: false)
case "shift-key", "cmd-key", "cmd-shift-key", "opt-key", "ctrl-key":
    // One modified key press through the real flagsChanged stream, e.g.
    // shift-key 124 extends a text selection; cmd-key 0 selects all.
    let mask: CGEventFlags
    switch command {
    case "shift-key": mask = [.maskShift]
    case "cmd-key": mask = [.maskCommand]
    case "cmd-shift-key": mask = [.maskCommand, .maskShift]
    case "opt-key": mask = [.maskAlternate]
    default: mask = [.maskControl]
    }
    postModifiedKeyFacts(CGKeyCode(UInt16(args[1]) ?? 0), flags:mask)
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
        let flags: CGEventFlags = [.maskCommand, .maskSecondaryFn]
        if let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(UInt16(args[1]) ?? 96), keyDown: true) {
            down.flags = flags
            ownedPost(down)
        }
        ownedSleep(50_000)
        if let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(UInt16(args[1]) ?? 96), keyDown: false) {
            up.flags = flags
            ownedPost(up)
        }
    }
    ownedSleep(60_000)
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
       let event = ownedMouseEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
                           mouseCursorPosition: CGPoint(x: Double(args[1]) ?? 0,
                                                        y: Double(args[2]) ?? 0),
                           mouseButton: .left) {
        let before = ownedMonotonicNanos()
        ownedPost(event)
        let after = ownedMonotonicNanos()
        if ownedBoundaryTraceEnabled {
            let fact: [String: Any] = ["actual_event_post":true,"operation":"drag-move",
                "action_id":ProcessInfo.processInfo.environment["CJGUI_DRIVER_ACTION_ID"] ?? "unassigned",
                "driver_pid":getpid(),"target_pid":ownedBoundaryTargetPid,
                "x":Double(args[1]) ?? 0,"y":Double(args[2]) ?? 0,
                "post_begin_ns":before,"post_end_ns":after,"post_attempts":1]
            if let data=try? JSONSerialization.data(withJSONObject:fact,options:[.sortedKeys]) {
                FileHandle.standardOutput.write(data);FileHandle.standardOutput.write(Data("\n".utf8))
            }
        }
    } else { failDelivery("no_drag_event") }
    ownedSleep(25_000)
case "release":
    mouseUp(x: Double(args[1]) ?? 0, y: Double(args[2]) ?? 0)
case "release-first-X":
    guard args.count == 3, let x = Double(args[1]), let y = Double(args[2]), x.isFinite, y.isFinite else {
        exit(2)
    }
    releaseThenFirstX(x: x, y: y)
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
    ownedSleep(60_000)
    flagsChanged(modifierKey, flags: [])
default:
    FileHandle.standardError.write("unknown command\n".data(using: .utf8)!)
    exit(2)
}

ownedReleasePending()

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
