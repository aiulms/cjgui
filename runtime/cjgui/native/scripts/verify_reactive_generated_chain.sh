#!/usr/bin/env zsh
# DS4.1f reactive generated interfaces: one continuous chain on the PrintPreset
# template with TWO live cards (owners 6301/6302) generated from ONE composite
# kind over the original field definitions.
#
# Chain: structure generated once -> keyboard edit card A -> exact data-refresh
# counters -> the card is READ (title/note/labels are real text) -> external write
# makes card B invalid and its per-field error is VISIBLE -> keyboard corrects B ->
# the ACTUAL Apply (B) / Cancel (A) buttons are pressed through AX -> lock shows
# the owner's reason, disables ALL THREE editors and refuses keyboard input, then
# unlock restores both -> theme switch repaints the accepted card readably ->
# narrow window keeps it readable and editable -> external value change + card
# reorder keeps drafts -> focus AND the exact selection survive a reorder and the
# replacement is computed from the PRE-operation text/range -> explicit rebind
# retires the old owner (old write refused) -> the new object takes keyboard input
# immediately -> precise owner readback vs the AX text -> normal close.
#
# User input (driver), AX actions and client calls are recorded separately.
#
# Delivery discipline: the owned driver reports its own batch (`text_posted`,
# `text_attempts`, `failure`). A segment is retried ONLY on explicit ZERO
# delivery; a partial or unknown delivery keeps its raw evidence and stops that
# segment instead of replaying it (replaying could duplicate characters the host
# already delivered).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="${CJGUI_REACTIVE_APP_DIR:-/private/tmp/ds41f-cards2-20261021/PrintPresetReactive}"
BUNDLE="$APP_DIR/target/release/CJGUIMixedFormStarter.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUIMixedFormStarter"
CLIENT="$APP_DIR/client.py"
OUTPUT_DIR="${CJGUI_REACTIVE_TMPDIR:-/private/tmp/cjgui-reactive-chain}"
EVIDENCE="$RUNTIME_DIR/artifacts/ds41f-components-sdk-20261021"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
PYTHON="${PYTHON:-python3}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"; mkdir -p "$WORK"
LOG="$WORK/chain.log"; : > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -60 "$LOG"; echo "reactive generated chain: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -40 "$LOG"; echo "reactive generated chain: BLOCKED $1" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
APP_PID=""
cleanup() { [[ -n "$APP_PID" ]] && cjgui_terminate_owned "$APP_PID" "" "$APP_EXEC" "$BUNDLE" || true; }
trap cleanup EXIT

[[ -x "$APP_EXEC" ]] || blocked "template app is not built at $BUNDLE"
session_locked && blocked "session locked"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable"
prepare_desktop_driver || blocked "$INPUT_BLOCKED"
AX_PROBE="$WORK/ax_node_probe"
swiftc -O "/Users/jiangxuanyang/Desktop/Pharos Mark/tools/ax_node_probe.swift" -o "$AX_PROBE" > "$WORK/ax-build.log" 2>&1 \
  || blocked "AX probe build failed"
real_input_preflight || blocked "synthetic input permission refused"

APP_LOG="$WORK/app.log"
CJGUI_PRINT_COUNTERS_TRACE=1 CJGUI_PRINT_PRESET_DESCRIPTION="$APP_DIR/assets/styled-description.tsv" \
  "$APP_EXEC" --collaboration > "$APP_LOG" 2>&1 &
APP_PID=$!
for i in {1..80}; do grep -q "CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH" "$APP_LOG" 2>/dev/null && break; sleep 0.25; done
DESC="$(sed -n 's/^CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH //p' "$APP_LOG" | head -1)"
[[ -n "$DESC" && -f "$DESC" ]] || blocked "template descriptor missing"
AX_PID="$APP_PID"; export AX_PID
AX_APP_PATH="$BUNDLE"; export AX_APP_PATH
log "step0 pid=$APP_PID descriptor=$DESC"
real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || blocked "AX tree not ready"
activate_app
[[ "$(app_frontmost)" == "true" ]] || blocked "app not frontmost"

# Owned input target: the driver refuses every post addressed to another
# process, so the card chain binds THIS round's pid/executable explicitly.
SCOPE="$WORK/owned-input-$APP_PID.json"
python3 - "$APP_PID" "$APP_EXEC" "$SCOPE" <<'BIND'
import json, os, sys, uuid
pid, executable, path = sys.argv[1:]
with open(path, "w") as handle:
    json.dump({"pid": int(pid), "nonce": uuid.uuid4().hex, "executable": executable}, handle)
os.chmod(path, 0o600)
BIND
"$WORK/cjgui_desktop_input_driver" bind-target "$SCOPE" > "$WORK/owned-bind.log" 2>&1 \
  || blocked "owned target bind failed"
export CJGUI_DRIVER_TARGET_PID="$APP_PID" CJGUI_DRIVER_TARGET_FILE="$SCOPE"

client() { python3 "$CLIENT" "$DESC" "$@"; }
LEFT_CLICK="$WORK/left_pointer_driver"
cat > "$WORK/left_pointer_driver.swift" <<'CLICK'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 3, let x = Double(args[1]), let y = Double(args[2]) else { exit(2) }
let point = CGPoint(x: x, y: y)
for type in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
    event?.post(tap: .cghidEventTap)
    usleep(30_000)
}
CLICK
swiftc -O "$WORK/left_pointer_driver.swift" -o "$LEFT_CLICK" > "$WORK/left-build.log" 2>&1 \
  || blocked "left click helper build failed"
left_click() { "$LEFT_CLICK" "$1" "$2" >> "$WORK/click.log" 2>&1; }
WHEEL_SCROLL="$WORK/wheel_scroll"
cat > "$WORK/wheel_scroll.swift" <<'WHEEL'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 4, let x = Double(args[1]), let y = Double(args[2]), let lines = Int32(args[3]) else { exit(2) }
let point = CGPoint(x: x, y: y)
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?
    .post(tap: .cghidEventTap)
usleep(30_000)
if let scroll = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines,
                        wheel2: 0, wheel3: 0) {
    scroll.location = point
    scroll.post(tap: .cghidEventTap)
}
WHEEL
swiftc -O "$WORK/wheel_scroll.swift" -o "$WHEEL_SCROLL" > "$WORK/wheel-build.log" 2>&1 \
  || blocked "wheel helper build failed"
# A real corner drag through the raw pointer path. The owned driver's drag is a
# mouse command for ITS OWN process window (it refuses a foreign window base), so
# resizing this round's app uses the same public pointer path as the clicks.
DRAG_RAW="$WORK/drag_raw"
cat > "$WORK/drag_raw.swift" <<'DRAG'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 5, let x1 = Double(args[1]), let y1 = Double(args[2]),
      let x2 = Double(args[3]), let y2 = Double(args[4]) else { exit(2) }
let source = CGEventSource(stateID: .hidSystemState)
CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
        mouseCursorPosition: CGPoint(x: x1, y: y1), mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(60_000)
CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
        mouseCursorPosition: CGPoint(x: x1, y: y1), mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(80_000)
let steps = 12
for index in 1...steps {
    let t = Double(index) / Double(steps)
    let point = CGPoint(x: x1 + (x2 - x1) * t, y: y1 + (y2 - y1) * t)
    CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
            mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(40_000)
}
usleep(80_000)
CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
        mouseCursorPosition: CGPoint(x: x2, y: y2), mouseButton: .left)?.post(tap: .cghidEventTap)
DRAG
swiftc -O "$WORK/drag_raw.swift" -o "$DRAG_RAW" > "$WORK/drag-build.log" 2>&1 \
  || blocked "raw drag helper build failed"
raw_resize_window() { # raw_resize_window <dw> <dh>
  local dw="$1" dh="$2" frame wx wy ww wh
  frame="$(ax_window_frame)"
  wx="$(print -r -- "$frame" | awk '{print $1}')"
  wy="$(print -r -- "$frame" | awk '{print $2}')"
  ww="$(print -r -- "$frame" | awk '{print $3}')"
  wh="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$wx" == <-> && "$wy" == <-> && "$ww" == <-> && "$wh" == <-> ]] || return 1
  activate_app
  "$DRAG_RAW" $(( wx + ww - 4 )) $(( wy + wh - 4 )) $(( wx + ww + dw - 4 )) $(( wy + wh + dh - 4 )) \
    >> "$WORK/click.log" 2>&1
  sleep 1.0
  # The owned input scope freezes the window geometry it was bound to, so every
  # keyboard post after a resize would be refused (exit 3) until it is re-bound.
  # This is a DRIVER-side identity rule, not a product condition: re-bind the
  # same process after the real resize and record the new geometry.
  activate_app
  "$DRIVER" bind-target "$SCOPE" > "$WORK/owned-rebind.log" 2>&1 \
    || { print -r -- "rebind_failed after resize" >> "$WORK/owned-rebind.log"; return 1; }
  print -r -- "rebound frame=$(ax_window_frame)" >> "$WORK/owned-rebind.log"
}
ax_probe() { "$AX_PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_frame() { ax_probe "$1" | sed -n 's/^frame=//p' | head -1; }
ax_focus() { ax_probe "$1" | awk -F= '/^focus=/{print $2}' | head -1; }
ax_value() { ax_probe "$1" | awk '/^value_begin$/{f=1;next} /^value_end$/{f=0} f'; }
ax_press() { "$AX_PROBE" "$APP_PID" press "$1" > "$WORK/press-$1.log" 2>&1; }
# Ordinary wheel gesture at the CENTRE of this round's own window. A fixed screen
# point would miss a narrowed window, and the driver only routes input into the
# owned foreground process.
wheel_window() { # wheel_window <lines>
  local frame wx wy ww wh
  frame="$(ax_window_frame)"
  wx="$(print -r -- "$frame" | awk '{print $1}')"
  wy="$(print -r -- "$frame" | awk '{print $2}')"
  ww="$(print -r -- "$frame" | awk '{print $3}')"
  wh="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$wx" == <-> && "$wy" == <-> && "$ww" == <-> && "$wh" == <-> ]] || return 1
  "$WHEEL_SCROLL" $(( wx + ww / 2 )) $(( wy + wh / 2 )) "$1" >> "$WORK/click.log" 2>&1
}
# Clipped generated content publishes NO AX element at all, and the window's
# content scrolls. Reveal a target with ordinary wheel gestures before reading or
# pressing it; the direction is corrected when a step does not help.
reveal() { # reveal <semanticId> [attempts-per-phase]
  # Phases do not alternate one step at a time: an alternating pair cancels
  # itself and can never reach content more than ONE step below the viewport.
  # Sweep down, then up (twice the distance), then down again to end where a
  # successful sweep would have left it.
  local sem="$1" attempts="${2:-8}" phase lines count i frame=""
  # Sweep DOWN first (the common case: a card's actions below the viewport),
  # then all the way UP, then down again far enough past the starting offset that
  # a target just below it is still reached. Negative wheel lines scroll content
  # down on this platform; the numbers below are steps, not pixels.
  for phase in 1 2 3; do
    case "$phase" in
      1) lines=-6; count=$attempts ;;
      2) lines=6; count=$((attempts * 2)) ;;
      *) lines=-6; count=$attempts ;;
    esac
    for i in {1..$count}; do
      frame="$(ax_frame "$sem")"
      frame_ok "$frame" && { print -r -- "$frame"; return 0; }
      activate_app
      local frontmost=""
      frontmost="$(app_frontmost)"
      wheel_window "$lines" || true
      print -r -- "reveal sem=$sem phase=$phase attempt=$i lines=$lines frontmost=$frontmost frame=[$frame]" >> "$WORK/reveal.log"
      sleep 0.35
    done
  done
  print -r -- ""
  return 1
}
press_visible() { # press_visible <semanticId>: reveal, then AXPress
  local sem="$1" frame
  frame="$(reveal "$sem" 12)" || { print -r -- "press_visible sem=$sem unreachable" >> "$WORK/press-fail.log"; return 1; }
  ax_press "$sem"
}
SEL_PROBE="$WORK/ax_selection"
cat > "$WORK/ax_selection.swift" <<'SEL'
import AppKit
let args = CommandLine.arguments
guard args.count == 3, let pid = Int32(args[1]) else { exit(2) }
let wanted = args[2]
func attr(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
    var v: CFTypeRef?; guard AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success else { return nil }
    return v
}
var winRef: CFTypeRef?
guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(pid), kAXMainWindowAttribute as CFString, &winRef) == .success,
      let winAny = winRef else { print("missing"); exit(0) }
func walk(_ el: AXUIElement) -> AXUIElement? {
    if let id = attr(el, kAXIdentifierAttribute as String) as? String, id == wanted { return el }
    if let kids = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] {
        for kid in kids { if let hit = walk(kid) { return hit } }
    }
    return nil
}
guard let el = walk(winAny as! AXUIElement) else { print("missing"); exit(0) }
if let any = attr(el, kAXSelectedTextRangeAttribute as String), CFGetTypeID(any as CFTypeRef) == AXValueGetTypeID() {
    var range = CFRange(); AXValueGetValue(any as! AXValue, .cfRange, &range)
    var value: CFTypeRef?
    AXUIElementCopyAttributeValue(el, kAXValueAttribute as CFString, &value)
    let text = (value as? String) ?? ""
    print("location=\(range.location) length=\(range.length) chars=\(text.utf16.count)")
} else { print("missing") }
SEL
swiftc -O "$WORK/ax_selection.swift" -o "$SEL_PROBE" > "$WORK/sel-build.log" 2>&1 || blocked "selection probe build failed"
selection_of() { "$SEL_PROBE" "$APP_PID" "$1" 2>/dev/null | head -1; }
# The control's OWN accessibility enabled state (the interface a person or an
# assistant queries), independent of the accepted-scene JSON.
AX_STATE="$WORK/ax_state"
cat > "$WORK/ax_state.swift" <<'AXSTATE'
import AppKit
let args = CommandLine.arguments
guard args.count == 3, let pid = Int32(args[1]) else { exit(2) }
let wanted = args[2]
func attr(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
    var v: CFTypeRef?; guard AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success else { return nil }
    return v
}
func pointValue(_ any: CFTypeRef?) -> CGPoint? {
    guard let any, CFGetTypeID(any) == AXValueGetTypeID() else { return nil }
    var p = CGPoint.zero; guard AXValueGetValue(any as! AXValue, .cgPoint, &p) else { return nil }; return p
}
func sizeValue(_ any: CFTypeRef?) -> CGSize? {
    guard let any, CFGetTypeID(any) == AXValueGetTypeID() else { return nil }
    var s = CGSize.zero; guard AXValueGetValue(any as! AXValue, .cgSize, &s) else { return nil }; return s
}
var winRef: CFTypeRef?
guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(pid), kAXMainWindowAttribute as CFString, &winRef) == .success,
      let winAny = winRef else { print("missing"); exit(0) }
func walk(_ el: AXUIElement) -> AXUIElement? {
    if let id = attr(el, kAXIdentifierAttribute as String) as? String, id == wanted { return el }
    if let kids = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] {
        for kid in kids { if let hit = walk(kid) { return hit } }
    }
    return nil
}
guard let el = walk(winAny as! AXUIElement) else { print("missing"); exit(0) }
let enabled = (attr(el, kAXEnabledAttribute as String) as? Bool).map { $0 ? "1" : "0" } ?? "?"
let role = (attr(el, kAXRoleAttribute as String) as? String) ?? "?"
var frame = "missing"
if let p = pointValue(attr(el, kAXPositionAttribute as String)), let s = sizeValue(attr(el, kAXSizeAttribute as String)) {
    frame = "\(Int(p.x)) \(Int(p.y)) \(Int(s.width)) \(Int(s.height))"
}
print("role=\(role)")
print("enabled=\(enabled)")
print("frame=\(frame)")
print("value_begin")
print((attr(el, kAXValueAttribute as String) as? String) ?? "")
print("value_end")
AXSTATE
swiftc -O "$WORK/ax_state.swift" -o "$AX_STATE" > "$WORK/ax-state-build.log" 2>&1 || blocked "AX state probe build failed"
ax_enabled() { "$AX_STATE" "$APP_PID" "$1" 2>/dev/null | sed -n 's/^enabled=//p' | head -1; }
counts_line() { grep "^CJGUI_MIXED_FORM_COUNTS" "$APP_LOG" 2>/dev/null | tail -1; }
counts_value() { # counts_value <field>
  counts_line | sed -n "s/.* $1=\([0-9-]*\).*/\1/p"
}
frame_ok() { print -r -- "$1" | awk '{ if (NF == 4 && $1+0 > 0 && $2+0 > 0 && $3+0 > 0 && $4+0 > 0) exit 0; exit 1 }'; }
center() { print -r -- "$1" | awk '{print $1 + $3/2, $2 + $4/2}'; }
# One python helper over the SAME public client: card element semantic ids and
# the accepted structure version come from the endpoint, never from a guess.
cat > "$WORK/probe.py" <<'PROBE'
import json, subprocess, sys
client, desc, mode = sys.argv[1:4]
out = subprocess.run(["python3", client, desc, "read"], capture_output=True, text=True)
d = json.loads(out.stdout)
if mode == "semantic":
    key, element = sys.argv[4], sys.argv[5]
    for item in d["instances"]["instances"]:
        if item.get("key") == key and item.get("element_key") == element:
            print(item["semantic_id"]); break
    else:
        print("")
elif mode == "instance":
    key, element, token = sys.argv[4], sys.argv[5], sys.argv[6]
    for item in d["instances"]["instances"]:
        if item.get("key") == key and item.get("element_key") == element:
            value = item.get(token, "")
            # Booleans are emitted as the accepted 1/0 facts they stand for.
            print("1" if value is True else ("0" if value is False else ("" if value is None else value)))
            break
    else:
        print("")
elif mode == "node":
    key = sys.argv[4]
    for item in d["instances"]["instances"]:
        if item.get("key") == key:
            print(item["semantic_id"]); break
    else:
        print("")
elif mode == "owner":
    key = sys.argv[4]
    for item in d["instances"]["instances"]:
        if item.get("key") == key and item.get("element_key") == "root":
            print(item["owner_resource_id"]); break
    else:
        print("-1")
elif mode == "version":
    print(d["instances"]["structure_version"])
elif mode == "bounds":
    key, element = sys.argv[4], sys.argv[5]
    for item in d["instances"]["instances"]:
        if item.get("key") == key and item.get("element_key") == element:
            print(item.get("bounds", "")); break
    else:
        print("")
PROBE
semantic_of() { # semantic_of <instanceKey> <elementKey>; endpoint first, then the
  # cached accepted structure from the last submission (ids are stable while the
  # structure version does not move).
  local i value=""
  for i in {1..6}; do
    value="$(python3 "$WORK/probe.py" "$CLIENT" "$DESC" semantic "$1" "$2" 2>/dev/null || true)"
    [[ -n "$value" ]] && { print -r -- "$value"; return 0; }
    sleep 0.2
  done
  python3 - "$WORK" "$1" "$2" <<'CACHE' 2>/dev/null || true
import json, glob, sys
work, key, element = sys.argv[1:]
for path in sorted(glob.glob(work + "/generate*.json"), reverse=True):
    try:
        d = json.load(open(path))
    except Exception:
        continue
    for item in d.get("instances", {}).get("instances", []):
        if item.get("key") == key and item.get("element_key") == element:
            print(item.get("semantic_id", "")); raise SystemExit(0)
CACHE
}
node_semantic_of() { # node_semantic_of <declared key> for an ORDINARY generated node
  local i value=""
  for i in {1..6}; do
    value="$(python3 "$WORK/probe.py" "$CLIENT" "$DESC" node "$1" 2>/dev/null || true)"
    [[ -n "$value" ]] && { print -r -- "$value"; return 0; }
    sleep 0.2
  done
  print -r -- ""
}
instance_token() { python3 "$WORK/probe.py" "$CLIENT" "$DESC" instance "$1" "$2" "$3" 2>/dev/null || true; }
card_state() { # card_state <instanceKey> <json-file>; tolerant while polling
  client card-read --instance "$1" > "$2" 2> "$2.err" || { echo '{}'; return 0; }
  python3 - "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
actions = {a["name"]: (a["available"], a["blocked_reason"]) for a in d["card_actions"]}
print(json.dumps({"owner": d["card_owner"], "fields": fields,
                  "apply": actions.get("APPLY_DRAFT"), "cancel": actions.get("CANCEL_DRAFT")}, ensure_ascii=False))
PY
}
structure_version() { python3 "$WORK/probe.py" "$CLIENT" "$DESC" version 2>/dev/null || echo "-1"; }
expected_after_selection() { # expected_after_selection <frozen text> <sel> <typed>
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
draft, sel, typed = sys.argv[1], sys.argv[2], sys.argv[3]
m = re.search(r"location=(\d+) length=(\d+) chars=(\d+)", sel)
assert m, sel
loc, length, _ = map(int, m.groups())
units = draft.encode("utf-16-le")
before = units[: loc * 2].decode("utf-16-le")
after = units[(loc + length) * 2:].decode("utf-16-le")
print(before + typed + after)
PY
}

# ---- driver delivery classification ------------------------------------------
# The owned driver prints one JSON batch per `type`/`cmd-key` post and exits 3
# with `delivery_failure: <reason>` when the host refused. ZERO delivery (nothing
# was posted) is the ONLY case a segment may be re-issued; a partial batch or a
# failure without a batch fact is preserved and stops the segment.
driver_delivery() { # driver_delivery <command> <json-file> <err-file> <exit-code>
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, re, sys
command, path, errpath, code = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
if code == 0:
    print("complete"); raise SystemExit(0)
try:
    raw = open(path).read().strip().splitlines()
    fact = json.loads(raw[-1]) if raw else {}
except Exception:
    fact = {}
text = open(errpath).read() if __import__("os").path.exists(errpath) else ""
reason = ""
m = re.search(r"delivery_failure: (\S+)", text)
if m:
    reason = m.group(1)
if command == "type":
    posted = bool(fact.get("text_posted"))
    attempts = int(fact.get("text_attempts") or 0)
    planned = len(fact.get("text_events") or [])
    if posted:
        print("complete"); raise SystemExit(0)
    if attempt := attempts or planned:
        print(f"partial attempts={attempts} planned={planned} reason={reason or fact.get('failure')}")
    else:
        print(f"none reason={reason or fact.get('failure') or 'no_batch'}")
    raise SystemExit(0)
if reason in ("modified_key_target_or_permission", "appkit_up_fact_scope", "no_event_source"):
    print(f"none reason={reason}")
elif reason:
    print(f"unknown reason={reason}")
else:
    print("unknown reason=no_fact")
PY
}

type_into() { # type_into <semanticId> <text> [selectAll]
  # A clipped element publishes no AX frame at all, so reveal it with ordinary
  # wheel scrolling before giving up; failures leave the probe output behind.
  local sem="$1" text="$2" select_all="${3:-0}" frame x y
  for attempt in {1..12}; do
    frame="$(ax_frame "$sem")"; frame_ok "$frame" && break
    activate_app
    if (( attempt % 2 == 0 )); then wheel_window 6 || true; else wheel_window -6 || true; fi
    sleep 0.4
  done
  if ! frame_ok "$frame"; then
    { print -r -- "type_into sem=[$sem] frame=[$frame]"; ax_probe "$sem"; } \
      > "$WORK/type-fail.log" 2>&1 || true
    return 1
  fi
  read -r x y <<< "$(center "$frame")"
  local round out err rc delivery
  for round in {1..4}; do
    activate_app
    left_click "$x" "$y" || { print -r -- "type_into sem=$sem round=$round click=fail" >> "$WORK/type-trace.log"; sleep 0.3; continue; }
    sleep 0.4
    if (( select_all == 1 )); then
      out="$WORK/driver-cmd-$round.json"; err="$WORK/driver-cmd-$round.err"
      "$DRIVER" cmd-key 0 > "$out" 2> "$err"; rc=$?
      delivery="$(driver_delivery cmd-key "$out" "$err" "$rc")"
      print -r -- "type_into sem=$sem round=$round cmd_a=$delivery" >> "$WORK/type-trace.log"
      case "$delivery" in
        complete) ;;
        none*) sleep 0.5; continue ;;
        *) { print -r -- "type_into sem=$sem round=$round PARTIAL_CmdA delivery=$delivery text=$text" >> "$WORK/type-trace.log"; cat "$out" >> "$WORK/driver.log"; } 2>/dev/null || true
           print -r -- "partial_or_unknown_delivery stage=cmd_a sem=$sem" >> "$WORK/delivery-failure.log"
           return 2 ;;
      esac
      sleep 0.2
    fi
    out="$WORK/driver-type-$round.json"; err="$WORK/driver-type-$round.err"
    "$DRIVER" type "$text" > "$out" 2> "$err"; rc=$?
    delivery="$(driver_delivery type "$out" "$err" "$rc")"
    cat "$out" >> "$WORK/driver.log" 2>/dev/null || true
    cat "$err" >> "$WORK/driver.log" 2>/dev/null || true
    case "$delivery" in
      complete)
        print -r -- "type_into sem=$sem frame=$frame text=$text ok round=$round" >> "$WORK/type-trace.log"
        return 0 ;;
      none*)
        # Explicit zero delivery: the host refused before posting anything.
        print -r -- "type_into sem=$sem round=$round type=zero_delivery delivery=$delivery" >> "$WORK/type-trace.log"
        sleep 0.5
        continue ;;
      *)
        # PARTIAL or unknown delivery: the driver may already have posted part
        # of the batch. Never replay the segment; keep the raw facts.
        print -r -- "type_into sem=$sem round=$round PARTIAL_TYPE delivery=$delivery text=$text" >> "$WORK/type-trace.log"
        print -r -- "partial_or_unknown_delivery stage=type sem=$sem delivery=$delivery text=$text" >> "$WORK/delivery-failure.log"
        return 2 ;;
    esac
  done
  return 1
}
shot() {
  local wid=""
  wid="$("$WORK/window_id" "$APP_PID" 2>/dev/null | head -1)"
  if [[ "$wid" == <-> ]]; then
    screencapture -x -l "$wid" "$WORK/$1.png" >/dev/null 2>&1 && log "shot $1 file=$WORK/$1.png" || log "shot $1 skipped"
  else
    log "shot $1 skipped reason=window_id_missing"
  fi
}
cat > "$WORK/window_id.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for entry in list {
    if let owner = entry[kCGWindowOwnerPID as String] as? Int32, owner == pid,
       let number = entry[kCGWindowNumber as String] as? Int, let layer = entry[kCGWindowLayer as String] as? Int, layer == 0 {
        print(number); break
    }
}
SWIFT
swiftc -O "$WORK/window_id.swift" -o "$WORK/window_id" > "$WORK/window-build.log" 2>&1 || blocked "window id tool build failed"
card_point() { # card_point <x y w h> <dx> <dy> -> absolute point inside the card
  print -r -- "$1" | awk -v dx="$2" -v dy="$3" '{print $1 + dx, $2 + dy}'
}
luminance() { # luminance RRGGBB -> 0..1
  python3 - "$1" <<'PY'
import sys
hex_value = sys.argv[1]
r, g, b = (int(hex_value[i:i+2], 16) / 255.0 for i in (0, 2, 4))
print(round(0.2126 * r + 0.7152 * g + 0.0722 * b, 4))
PY
}

# ---- step1: ONE structure submission carries both cards ----------------
client generate > "$WORK/generate.json" 2> "$WORK/generate.err" || fail "generate failed"
python3 - "$WORK/generate.json" <<'PY' >> "$LOG"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["submit"]["candidate_accepted"], d["submit"]
inst = [i for i in d["instances"]["instances"] if i.get("kind") == "vertical" and i.get("element_key") == "root"]
owners = {i["key"]: i["owner_resource_id"] for i in inst if i.get("key") in ("cardA", "cardB")}
assert owners == {"cardA": 6301, "cardB": 6302}, owners
print(f"step1 structure_accepted cards={owners} version={d['instances']['structure_version']}")
PY
a_state="$(card_state cardA "$WORK/a1.json")"; b_state="$(card_state cardB "$WORK/b1.json")"
print -r -- "$a_state" | grep -q '"owner": 6301' || fail "card A owner: $a_state"
print -r -- "$b_state" | grep -q '"owner": 6302' || fail "card B owner: $b_state"
log "step1 cards A=[$a_state] B=[$b_state]"
shot reactive-cards-initial || true

# ---- step2d: the card is READABLE (title, note and field labels) --------
# These are ordinary declared children, addressed by their accepted identities;
# a positive frame means the text really occupies layout and a value means the
# person/assistant channel can read it.
a_title_sem="$(node_semantic_of cardA-title)"
b_title_sem="$(node_semantic_of cardB-title)"
[[ -n "$a_title_sem" && -n "$b_title_sem" ]] || fail "card title children missing"
a_title_frame="$(ax_frame "$a_title_sem")"
frame_ok "$a_title_frame" || fail "card A title is not laid out: [$a_title_frame]"
[[ "$(ax_value "$a_title_sem")" == "卡片 A" ]] || fail "card A title text: [$(ax_value "$a_title_sem")]"
[[ "$(ax_value "$b_title_sem")" == "卡片 B" ]] || fail "card B title text: [$(ax_value "$b_title_sem")]"
a_note_sem="$(node_semantic_of cardA-note)"
frame_ok "$(ax_frame "$a_note_sem")" || fail "card A note is not laid out"
a_label_sem="$(node_semantic_of cardA-jobName-label)"
frame_ok "$(ax_frame "$a_label_sem")" || fail "card A field label is not laid out"
log "step2d readable title=[$(ax_value "$a_title_sem")|$(ax_value "$b_title_sem")] note=[$(ax_value "$a_note_sem")] label=[$(ax_value "$a_label_sem")]"

# ---- step2: keyboard edits card A (driver), no structure resubmit -----
version_before="$(structure_version)"
a_name_sem="$(semantic_of cardA name)"
[[ -n "$a_name_sem" ]] || fail "card A name semantic id missing"
type_into "$a_name_sem" "K" 0 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while typing into card A (see delivery-failure.log)"
  blocked "typing into card A not delivered"
}
typed=0
for _ in {1..30}; do
  a_state="$(card_state cardA "$WORK/a2.json")"
  print -r -- "$a_state" | grep -q '"jobName": "资料 AK"' && { typed=1; break; }
  sleep 0.2
done
(( typed == 1 )) || fail "card A keyboard edit did not reach its owner: $a_state"
[[ "$(structure_version)" == "$version_before" ]] || fail "keyboard edit resubmitted the structure"
log "step2 keyboard_edit A jobName=资料 AK structure_version=$version_before (unchanged)"
shot reactive-cardA-keyboard || true

# ---- step2c: exact counters prove what ONE data refresh does --------------
# The committed promise: a data update builds and commits the scene ONCE, never
# decodes/validates a candidate again, and an idle window builds nothing.
decodes_before="$(counts_value decodes)"; validations_before="$(counts_value validations)"
builds_before="$(counts_value builds)"; commits_before="$(counts_value commits)"
[[ -n "$decodes_before" && -n "$builds_before" ]] || fail "counters trace missing from the app log"
lines_before="$(grep -c '^CJGUI_MIXED_FORM_COUNTS' "$APP_LOG" 2>/dev/null || true)"
client card-set --instance cardA --field jobName --value "资料 AK2" > "$WORK/counter-refresh.json" 2>/dev/null \
  || blocked "counter refresh write failed"
refreshed=0
for _ in {1..30}; do
  lines_now="$(grep -c '^CJGUI_MIXED_FORM_COUNTS' "$APP_LOG" 2>/dev/null || true)"
  [[ "$lines_now" -gt "$lines_before" ]] && { refreshed=1; break; }
  sleep 0.2
done
(( refreshed == 1 )) || fail "data refresh produced no commit line"
sleep 0.6
decodes_after="$(counts_value decodes)"; validations_after="$(counts_value validations)"
builds_after="$(counts_value builds)"; commits_after="$(counts_value commits)"
[[ "$decodes_after" == "$decodes_before" ]] || fail "data refresh decoded a candidate: $decodes_before -> $decodes_after"
[[ "$validations_after" == "$validations_before" ]] || fail "data refresh validated a candidate: $validations_before -> $validations_after"
[[ "$builds_after" -eq $(( builds_before + 1 )) ]] || fail "data refresh builds must be exactly +1: $builds_before -> $builds_after"
[[ "$commits_after" -eq $(( commits_before + 1 )) ]] || fail "data refresh commits must be exactly +1: $commits_before -> $commits_after"
[[ "$(structure_version)" == "$version_before" ]] || fail "data refresh moved the structure version"
# Idle: no input for ~2.5s must not produce another build/commit line.
idle_before="$(grep -c '^CJGUI_MIXED_FORM_COUNTS' "$APP_LOG" 2>/dev/null || true)"
sleep 2.5
idle_after="$(grep -c '^CJGUI_MIXED_FORM_COUNTS' "$APP_LOG" 2>/dev/null || true)"
[[ "$idle_after" == "$idle_before" ]] || fail "idle window kept rebuilding: $idle_before -> $idle_after"
log "step2c counters decodes=$decodes_before->$decodes_after validations=$validations_before->$validations_after builds=$builds_before->$builds_after commits=$commits_before->$commits_after idle_lines=$idle_before->$idle_after structure_version=$version_before"

# ---- step3: external write makes B invalid; the ERROR IS VISIBLE --------
client card-set --instance cardB --field copies --value 99 > "$WORK/b-invalid.json" 2> "$WORK/b-invalid.err" \
  || blocked "external write to B failed"
b_state="$(card_state cardB "$WORK/b2.json")"
print -r -- "$b_state" | grep -q '"copies": "99"' || fail "B draft not written: $b_state"
print -r -- "$b_state" | grep -q '份数需在 1–24 之间' || fail "B error/reason not projected: $b_state"
print -r -- "$b_state" | grep -q '"apply": \[false' || fail "B Apply must be disabled: $b_state"
b_error_sem="$(semantic_of cardB copiesError)"
[[ -n "$b_error_sem" ]] || fail "card B copies error element missing"
b_error_frame="$(reveal "$b_error_sem" 10 || true)"
frame_ok "$b_error_frame" || fail "card B error text is not laid out: [$b_error_frame]"
[[ "$(ax_value "$b_error_sem")" == "份数需在 1–24 之间" ]] \
  || fail "card B visible error text: [$(ax_value "$b_error_sem")]"
# The sibling's error slot holds nothing: A still applies.
[[ -z "$(ax_frame "$(semantic_of cardA copiesError 2>/dev/null || true)")" ]] || fail "card A shows an error it does not have"
a_state="$(card_state cardA "$WORK/a3.json")"
print -r -- "$a_state" | grep -q '"apply": \[true' || fail "A Apply must stay enabled: $a_state"
[[ "$(structure_version)" == "$version_before" ]] || fail "external value update resubmitted the structure"
log "step3 external_invalid B=[$b_state] visible_error=[$(ax_value "$b_error_sem")] frame=[$b_error_frame] structure_version=$version_before"
shot reactive-cardB-invalid || true

# ---- step4: keyboard corrects B ---------------------------------------
b_copies_sem="$(semantic_of cardB copies)"
[[ -n "$b_copies_sem" ]] || fail "card B copies semantic id missing"
type_into "$b_copies_sem" "6" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while correcting card B"
  blocked "typing correction into card B not delivered"
}
fixed=0
for _ in {1..30}; do
  b_state="$(card_state cardB "$WORK/b3.json")"
  print -r -- "$b_state" | grep -q '"copies": "6"' && { fixed=1; break; }
  sleep 0.2
done
(( fixed == 1 )) || fail "keyboard correction did not reach card B: $b_state"
print -r -- "$b_state" | grep -q '"apply": \[true' || fail "B Apply did not re-enable: $b_state"
log "step4 keyboard_corrected B=[$b_state]"

# ---- step5: the ACTUAL Apply (B) and Cancel (A) buttons ----------------
b_apply_sem="$(semantic_of cardB apply)"
[[ -n "$b_apply_sem" ]] || fail "card B apply semantic id missing"
press_visible "$b_apply_sem" || fail "AX press on card B Apply failed"
applied=0
for _ in {1..30}; do
  b_state="$(card_state cardB "$WORK/b4.json")"
  print -r -- "$b_state" | grep -q '"copies": "6"' && print -r -- "$b_state" | grep -q '"cancel": \[false' && { applied=1; break; }
  sleep 0.2
done
(( applied == 1 )) || fail "card B Apply did not commit: $b_state"
# Make A dirty, then cancel through its ACTUAL button. The pre-typing draft is
# read from the owner (earlier steps already changed it), never hardcoded.
a_before_cancel="$(card_state cardA "$WORK/a-pre-cancel.json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fields"]["jobName"])')"
type_into "$a_name_sem" "Z" 0 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while dirtying card A"
  blocked "typing into A for cancel not delivered"
}
a_state="$(card_state cardA "$WORK/a4.json")"
print -r -- "$a_state" | grep -qF "\"jobName\": \"${a_before_cancel}Z\"" || fail "A not dirty before cancel: $a_state (expected ${a_before_cancel}Z)"
a_cancel_sem="$(semantic_of cardA cancel)"
press_visible "$a_cancel_sem" || fail "AX press on card A Cancel failed"
cancelled=0
for _ in {1..30}; do
  a_state="$(card_state cardA "$WORK/a5.json")"
  # Cancel restores the APPLIED value (资料 A), not the pre-cancel draft.
  print -r -- "$a_state" | grep -q '"jobName": "资料 A"' && print -r -- "$a_state" | grep -q '"cancel": \[false' && { cancelled=1; break; }
  sleep 0.2
done
(( cancelled == 1 )) || fail "card A Cancel did not restore the applied value: $a_state"
log "step5 ax_apply B=[$b_state] ax_cancel A=[$a_state]"
shot reactive-after-buttons || true

# ---- step5b: lock and unlock keep every editor honest ------------------
client lock --instance cardB > "$WORK/lock-b.json" 2> "$WORK/lock-b.err" || blocked "card lock failed"
locked_b="$(card_state cardB "$WORK/b-locked.json")"
print -r -- "$locked_b" | grep -q '卡片已锁定' || fail "locked card did not publish the owner reason: $locked_b"
print -r -- "$locked_b" | grep -q '"apply": \[false' || fail "locked card Apply must be disabled: $locked_b"
# ALL THREE editors report the owner's answer through BOTH channels: the accepted
# scene's own control state and the accessibility interface a person uses.
for element in name copies duplex; do
  enabled="$(instance_token cardB "$element" control_enabled)"
  [[ "$enabled" == "0" ]] || fail "locked cardB/$element control_enabled=$enabled (expected 0)"
  sem="$(semantic_of cardB "$element")"
  [[ "$(ax_enabled "$sem")" == "0" ]] || fail "locked cardB/$element AX enabled=$(ax_enabled "$sem") (expected 0)"
done
b_reason_sem="$(semantic_of cardB cardReason)"
reveal "$b_reason_sem" 10 >/dev/null || true
[[ "$(ax_value "$b_reason_sem")" == "卡片已锁定，暂不可编辑" ]] \
  || fail "locked card reason text: [$(ax_value "$b_reason_sem")]"
frame_ok "$(ax_frame "$b_reason_sem")" || fail "locked card reason is not laid out"
# A keyboard write while locked must not reach the owner.
type_into "$b_copies_sem" "8" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while typing into a locked card"
  blocked "typing into locked card not delivered"
}
sleep 0.6
after_locked="$(card_state cardB "$WORK/b-locked2.json")"
print -r -- "$after_locked" | grep -q '"copies": "6"' || fail "locked card accepted a keyboard write: $after_locked"
# Unlock through the same declared action: every editor is editable again and
# the card really accepts a write.
client unlock --instance cardB > "$WORK/unlock-b.json" 2> "$WORK/unlock-b.err" || blocked "card unlock failed"
unlocked_b="$(card_state cardB "$WORK/b-unlocked.json")"
print -r -- "$unlocked_b" | grep -q '"apply": \[true' || fail "unlocked card Apply did not recover: $unlocked_b"
for element in name copies duplex; do
  [[ "$(instance_token cardB "$element" control_enabled)" == "1" ]] || fail "unlocked cardB/$element control_enabled != 1"
  [[ "$(ax_enabled "$(semantic_of cardB "$element")")" == "1" ]] || fail "unlocked cardB/$element AX enabled != 1"
done
[[ -z "$(ax_value "$b_reason_sem")" ]] || fail "unlocked card still shows a blocking reason: [$(ax_value "$b_reason_sem")]"
type_into "$b_copies_sem" "9" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while typing after unlock"
  blocked "typing after unlock not delivered"
}
after_unlock="$(card_state cardB "$WORK/b-unlocked2.json")"
print -r -- "$after_unlock" | grep -q '"copies": "9"' || fail "unlocked card did not accept a write: $after_unlock"
# The handwritten preset follows the same owner rule.
client lock > "$WORK/lock-form.json" 2> "$WORK/lock-form.err" || blocked "form lock failed"
form_locked="$(client read 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print([(f["field_id"], f["available"], f["blocked_reason"]) for f in d["fields"]])' 2>/dev/null || echo "")"
print -r -- "$form_locked" | grep -q "预设已锁定" || fail "handwritten form did not publish the lock reason: $form_locked"
client set --field jobName --value "锁定写入" > "$WORK/form-locked-write.json" 2>/dev/null || true
grep -q "预设已锁定" "$WORK/form-locked-write.json" || fail "locked handwritten form accepted a write"
client unlock > "$WORK/unlock-form.json" 2> "$WORK/unlock-form.err" || blocked "form unlock failed"
form_unlocked="$(client read 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print([(f["field_id"], f["available"]) for f in d["fields"]])' 2>/dev/null || echo "")"
log "step5b lock cardB=[$locked_b -> $unlocked_b] keyboard_blocked=[$after_locked] reason=[$(ax_value "$b_reason_sem")] form=[$form_locked -> $form_unlocked]"
shot reactive-locked || true

# ---- step5d: a NARROW window keeps the cards readable and operable ------
original_window="$(ax_window_frame)"
read -r wx wy ww wh <<< "$original_window"
[[ "$ww" == <-> ]] || blocked "window frame unavailable: [$original_window]"
raw_resize_window -380 0 || blocked "narrow resize failed"
sleep 0.8
narrow_window="$(ax_window_frame)"
read -r nwx nwy nww nwh <<< "$narrow_window"
(( nww < ww )) || fail "window did not narrow: $ww -> $nww"
# Start the reachability sweep from the TOP of the content: the offset before the
# resize was wherever the earlier steps left it, and a sweep is only meaningful
# from a known position.
for i in {1..24}; do wheel_window 6 || true; done
sleep 0.5
narrow_report=""
for key in cardA cardB; do
  for element in name copies duplex apply; do
    sem="$(semantic_of "$key" "$element")"
    frame="$(reveal "$sem" 12 || true)"
    log "step5d probe $key/$element sem=[$sem] frame=[$frame]"
    if ! frame_ok "$frame"; then
      "$AX_PROBE" "$APP_PID" dump 80 > "$WORK/ax-dump-narrow-$key-$element.log" 2>&1 || true
      shot "reactive-narrow-fail-$key-$element" || true
      fail "narrow window clipped $key/$element: [$frame] (ax dump kept)"
    fi
    narrow_report+=" $key/$element=[$frame]"
  done
done
# Readable: the title and the note still publish their text with a real frame.
reveal "$a_title_sem" 10 >/dev/null || true
frame_ok "$(ax_frame "$a_title_sem")" || fail "narrow window clipped the card title"
reveal "$a_note_sem" 10 >/dev/null || true
frame_ok "$(ax_frame "$a_note_sem")" || fail "narrow window clipped the card note"
# Operable: a keyboard edit still reaches the owner while narrow (the whole value
# is replaced, so the result does not depend on where the click placed the caret).
type_into "$a_name_sem" "窄" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery in the narrow window"
  blocked "typing into the narrow window not delivered"
}
narrow_edit=0
for _ in {1..30}; do
  a_state="$(card_state cardA "$WORK/a-narrow.json")"
  print -r -- "$a_state" | grep -q '"jobName": "窄"' && { narrow_edit=1; break; }
  sleep 0.2
done
(( narrow_edit == 1 )) || fail "narrow-window keyboard edit did not reach card A: $a_state"
log "step5d narrow width=$ww->$nww editable=yes jobName=窄 frames:$narrow_report"
shot reactive-narrow-window || true
raw_resize_window 380 0 || blocked "restore resize failed"
sleep 0.8
restored_window="$(ax_window_frame)"
read -r rwx rwy rww rwh <<< "$restored_window"
if (( rww < ww - 20 )); then fail "window did not restore: $ww -> $rww"; fi
frame_ok "$(ax_frame "$a_name_sem")" || fail "card editor lost its frame after restoring the width"
log "step5d window_restored width=$rww"

# ---- step6: external change + reorder keep both drafts ----------------
client card-set --instance cardA --field duplex --value true > "$WORK/a-ext.json" 2> "$WORK/a-ext.err" \
  || blocked "external write to A failed"
a_state="$(card_state cardA "$WORK/a6.json")"
print -r -- "$a_state" | grep -q '"duplex": "true"' || fail "A external change missing: $a_state"
client reorder > "$WORK/reorder.json" 2> "$WORK/reorder.err" || blocked "reorder submission failed"
python3 - "$WORK/reorder.json" <<'PY' >> "$LOG"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["submit"]["candidate_accepted"], d["submit"]
print(f"step6 reorder_accepted version={d['instances']['structure_version']}")
PY
b_before_reorder="$(card_state cardB "$WORK/b-pre-reorder.json")"
b_after_reorder="$(card_state cardB "$WORK/b5.json")"
[[ "$b_before_reorder" == "$b_after_reorder" ]] || fail "reorder changed B: $b_before_reorder -> $b_after_reorder"
a_after_reorder="$(card_state cardA "$WORK/a7.json")"
print -r -- "$a_after_reorder" | grep -q '"duplex": "true"' || fail "reorder lost A value: $a_after_reorder"
frame_ok "$(ax_frame "$a_title_sem")" || fail "reorder lost the card title"
log "step6 reorder_kept A=[$a_after_reorder] B=[$b_after_reorder] title_frame=[$(ax_frame "$a_title_sem")]"

# ---- step6b: same key+owner reorder keeps focus and the EXACT selection --
# Put a known selection in card A's name field, FREEZE the text and the range,
# then submit a reorder candidate and compare against those frozen facts. The
# expected replacement is computed from the PRE-operation text and range - never
# from whatever the post-operation read happens to say.
a_name_sem2="$(semantic_of cardA name)"
type_into "$a_name_sem2" "XY" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while setting up the selection"
  blocked "selection setup typing failed"
}
"$DRIVER" shift-key 123 >> "$WORK/driver.log" 2>&1 || blocked "shift-left not delivered"
sleep 0.4
sel_before="$(selection_of "$a_name_sem2")"
focus_before="$(ax_focus "$a_name_sem2")"
[[ "$focus_before" == "1" ]] || fail "card A field did not hold focus before reorder"
print -r -- "$sel_before" | grep -qE 'length=[1-9]' || fail "no legal selection before reorder: $sel_before"
# Frozen PRE-operation facts: draft text (owner read) and the AX value.
text_before_reorder="$(card_state cardA "$WORK/a-pre-reorder.json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fields"]["jobName"])')"
ax_value_before="$(ax_value "$a_name_sem2")"
[[ "$ax_value_before" == "$text_before_reorder" ]] \
  || fail "AX value and owner draft disagree before the reorder: [$ax_value_before] vs [$text_before_reorder]"
expected_after_sel="$(expected_after_selection "$text_before_reorder" "$sel_before" "Q")"
client reorder > "$WORK/reorder2.json" 2> "$WORK/reorder2.err" || blocked "second reorder failed"
sleep 0.8
a_name_sem3="$(semantic_of cardA name)"
[[ -n "$a_name_sem3" ]] || fail "card A name element disappeared after reorder"
if [[ -z "$(ax_frame "$a_name_sem3")" ]]; then reveal "$a_name_sem3" 10 >/dev/null || true; fi
[[ "$(ax_focus "$a_name_sem3")" == "1" ]] || fail "reorder dropped focus from the same field"
sel_after="$(selection_of "$a_name_sem3")"
draft_after_reorder="$(card_state cardA "$WORK/a-post-reorder.json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fields"]["jobName"])')"
# The draft and the WHOLE selection (location, length, field length) are before == after.
[[ "$draft_after_reorder" == "$text_before_reorder" ]] \
  || fail "reorder changed card A draft: $text_before_reorder -> $draft_after_reorder"
[[ "$sel_after" == "$sel_before" ]] || fail "reorder moved the selection: [$sel_before] -> [$sel_after]"
[[ "$(ax_value "$a_name_sem3")" == "$text_before_reorder" ]] || fail "reorder changed the AX value"
# Typing over the retained selection replaces exactly that range of the FROZEN text.
"$DRIVER" type "Q" >> "$WORK/driver.log" 2>&1 || blocked "typing over the retained selection failed"
sleep 0.6
after_sel_edit="$(card_state cardA "$WORK/a-selection-edit.json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fields"]["jobName"])')"
[[ "$after_sel_edit" == "$expected_after_sel" ]] \
  || fail "selection did not replace the frozen range: expected [$expected_after_sel], got [$after_sel_edit]"
log "step6b focus_kept sel[$sel_before == $sel_after] pre_text=[$text_before_reorder] selection_edit=[$after_sel_edit] expected=[$expected_after_sel]"
shot reactive-after-reorder-selection || true

# ---- step7: explicit rebind; the old owner's write is refused ---------
client card-rebind --instance cardB --new-owner 6303 > "$WORK/rebind.json" 2> "$WORK/rebind.err" \
  || blocked "rebind mapping failed"
grep -q "APPLIED true" "$WORK/rebind.json" || fail "rebind mapping not applied"
client stale-write --owner 6302 --field jobName --value "旧对象" > "$WORK/stale.json" 2> "$WORK/stale.err" || true
grep -q "unknown_target" "$WORK/stale.json" || fail "retired owner write was not refused: $(head -c 300 "$WORK/stale.json")"
# The accepted scene follows only a real candidate carrying the key.
client generate > "$WORK/generate2.json" 2> "$WORK/generate2.err" || fail "rebind candidate failed"
python3 - "$WORK/generate2.json" <<'PY' >> "$LOG"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["submit"]["candidate_accepted"], d["submit"]
roots = [i for i in d["instances"]["instances"] if i.get("key") == "cardB" and i.get("element_key") == "root"]
assert roots and roots[0]["owner_resource_id"] == 6303, roots
print(f"step7 rebind_accepted cardB_owner={roots[0]['owner_resource_id']} version={d['instances']['structure_version']}")
PY
b_state="$(card_state cardB "$WORK/b6.json")"
print -r -- "$b_state" | grep -q '"owner": 6303' || fail "card B did not follow the rebind: $b_state"
print -r -- "$b_state" | grep -q '"jobName": "新对象"' || fail "new object values missing: $b_state"
log "step7 rebind B=[$b_state] old_owner_write=refused"

# ---- step8: the NEW object takes keyboard input immediately -----------
b_name_sem="$(semantic_of cardB name)"
[[ -n "$b_name_sem" ]] || fail "new card B name semantic id missing"
type_into "$b_name_sem" "N" 0 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery on the rebound card"
  blocked "typing into the rebound card not delivered"
}
continued=0
for _ in {1..30}; do
  b_state="$(card_state cardB "$WORK/b7.json")"
  print -r -- "$b_state" | grep -q '"jobName": "新对象N"' && { continued=1; break; }
  sleep 0.2
done
(( continued == 1 )) || fail "new object did not take keyboard input: $b_state"
log "step8 new_object_keyboard B=[$b_state]"

# ---- step9: precise OWNER readback cross-checked with the AX text ------
b_name_sem_after="$(semantic_of cardB name)"
owner_name="$(card_state cardB "$WORK/b8.json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["fields"]["jobName"])')"
ax_name="$(ax_value "$b_name_sem_after")"
[[ "$owner_name" == "新对象N" ]] || fail "precise readback mismatch: [$owner_name]"
[[ "$ax_name" == "$owner_name" ]] || fail "AX text and owner value disagree: [$ax_name] vs [$owner_name]"
print -r -- "$(card_state cardB "$WORK/b8.json")" | grep -q '"owner": 6303' || fail "readback owner mismatch"
# The visible title still names the same instance after the rebind.
[[ "$(ax_value "$b_title_sem")" == "卡片 B" ]] || fail "card B title changed unexpectedly"
[[ -f "$WORK/delivery-failure.log" ]] && blocked "input delivery was partial/unknown somewhere in this chain: $(cat "$WORK/delivery-failure.log")"
log "step9 readback owner=6303 jobName=[$owner_name] ax=[$ax_name]"
# ---- step9c: a theme switch repaints the ACCEPTED card readably --------
# The switch is the application's own control, i.e. a controller rebuild. What
# this step proves: the already accepted card is repainted from the CURRENT theme,
# its owner text stays readable through the accessibility channel, and a visible
# editor still takes input afterwards. It deliberately does NOT exercise wheel
# scrolling after this rebuild: that path is a separate, PRE-EXISTING framework
# limitation (a manual scroll area loses its wheel binding when the controller
# rebuilds the scene - reproduced in `--commands` mode before this batch), which
# is recorded with its repro in RESULT.md instead of being worked around here.
reveal preset-theme 10 >/dev/null || fail "theme button unreachable"
b_surface_frame="$(ax_frame "$b_title_sem")"
frame_ok "$b_surface_frame" || fail "card B title frame missing before the theme switch: [$b_surface_frame]"
read -r px py <<< "$(print -r -- "$b_surface_frame" | awk '{ print $1 + $3 - 8, $2 + $4 / 2 }')"
dark_pixel="$(region_pixel_hex "$px" "$py" 2 || true)"
[[ -n "$dark_pixel" ]] || blocked "card surface pixel unavailable"
dark_luma="$(luminance "$dark_pixel")"
ax_press preset-theme || fail "theme toggle press failed"
sleep 1.0
# The accepted scene is repainted: sample the SAME card surface again (the title
# may have moved with the rebuild, so its frame is re-read) and fall back to the
# window's page surface only when the title is no longer laid out.
light_frame="$(ax_frame "$b_title_sem")"
if frame_ok "$light_frame"; then
  read -r px py <<< "$(print -r -- "$light_frame" | awk '{ print $1 + $3 - 8, $2 + $4 / 2 }')"
  light_sample="card"
else
  window_now="$(ax_window_frame)"
  read -r wx2 wy2 ww2 wh2 <<< "$window_now"
  px=$(( wx2 + ww2 - 24 )); py=$(( wy2 + 64 ))
  light_sample="page"
fi
light_pixel="$(region_pixel_hex "$px" "$py" 2 || true)"
[[ -n "$light_pixel" ]] || blocked "card surface pixel unavailable after theme switch"
light_luma="$(luminance "$light_pixel")"
"$PYTHON" - "$dark_luma" "$light_luma" "$dark_pixel" "$light_pixel" "$light_sample" <<'LUMACHECK' || fail "theme switch did not repaint the card surface"
import sys
before, after = float(sys.argv[1]), float(sys.argv[2])
# The two themes' card surfaces are near-black and near-white; a repaint must
# move the measured compositor output clearly, not just a few levels.
assert after - before > 0.35, (before, after, sys.argv[3], sys.argv[4], sys.argv[5])
LUMACHECK
# The card stays readable and operable in the new theme.
[[ "$(ax_value "$b_title_sem")" == "卡片 B" ]] || fail "title text changed after the theme switch"
[[ -z "$(ax_value "$b_reason_sem")" ]] || fail "theme switch introduced an owner reason"
[[ "$(ax_enabled "$b_name_sem_after")" == "1" ]] || fail "card B editor became disabled after the theme switch"
type_into "$b_name_sem_after" "主题" 1 || {
  rc=$?
  (( rc == 2 )) && blocked "partial input delivery while typing after the theme switch"
  blocked "typing after the theme switch not delivered"
}
themed_edit=0
for _ in {1..30}; do
  themed_state="$(card_state cardB "$WORK/b7-themed.json")"
  print -r -- "$themed_state" | grep -q '"jobName": "主题"' && { themed_edit=1; break; }
  sleep 0.2
done
(( themed_edit == 1 )) || fail "card B did not accept input after the theme switch: $themed_state"
log "step9c theme_switch surface=[$dark_pixel->$light_pixel] luma=[$dark_luma->$light_luma] sample=$light_sample edited=[$themed_state]"
shot reactive-light-theme || true
ax_press preset-theme || fail "theme restore press failed"
sleep 1.0
restored_pixel="$(region_pixel_hex "$px" "$py" 2 || true)"
restored_luma="$(luminance "$restored_pixel")"
"$PYTHON" - "$restored_luma" "$dark_luma" <<'LUMARESTORE' || fail "theme did not return to the dark surface"
import sys
restored, dark = float(sys.argv[1]), float(sys.argv[2])
assert abs(restored - dark) < 0.2, (restored, dark)
LUMARESTORE
log "step9c theme_restored surface=[$restored_pixel] luma=[$restored_luma]"

shot reactive-final || true
"$AX_PROBE" "$APP_PID" close > "$WORK/close.log" 2>&1 || blocked "window close action failed"
waited=0
while (( waited < 40 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after normal close"
grep -q "CJGUI_MIXED_FORM_CLOSED" "$APP_LOG" || fail "close completion line missing"
APP_PID=""
log "step10 normal_close=CJGUI_MIXED_FORM_CLOSED"
mkdir -p "$EVIDENCE"
cp -R "$WORK" "$EVIDENCE/" 2>/dev/null || true
log "PASS reactive_generated_chain"
echo "reactive generated chain: PASS log=$LOG"
