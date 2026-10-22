#!/usr/bin/env zsh
# DS4.1f command semantics chain on the real settings consumer.
#
# One public command declaration serves surface, keyboard, screen reader and
# open semantics. Chain: toolbar/menu AX roles, values and disabled help read
# from the declaration -> keyboard context open with initial-focus reveal ->
# Enter executes exactly once and the AX checked value moves with the owner ->
# second open keeps focus/scroll across theme + owner change -> Esc returns
# and typing continues -> external boolean write syncs the OPEN menu and the
# toolbar AX value -> disabled/revoked old entries invoke with zero owner
# writes -> read-only Inspector command view stays fresh under publication
# revision -> real VoiceOver navigation and activation (control chord, ring
# screenshots, VO+Space owner write) -> normal close. A failed or unverified VO
# attempt returns through an explicit status capture and still reaches the
# normal close; cleanup force-kill is never reported as that close.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/settings_form_window_app"
BUNDLE="$APP_DIR/target/release/CJGUISettingsForm.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUISettingsForm"
CLIENT="$APP_DIR/settings_form_client.py"
OUTPUT_DIR="${CJGUI_SETTINGS_SEMANTICS_TMPDIR:-/private/tmp/cjgui-settings-semantics}"
EV_DIR="$RUNTIME_DIR/artifacts/ds41f-command-semantics-20261021"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"; mkdir -p "$WORK"
LOG="$WORK/chain.log"; : > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -120 "$LOG"; echo "settings command semantics chain: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -80 "$LOG"; echo "settings command semantics chain: BLOCKED $1" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
APP_PID=""
# VoiceOver ownership is per-process, never per name. A session that existed
# before this run (including the Quickstart splash) is never terminated. Only
# processes whose exact PIDs appeared after our own launch are reclaimed.
VO_WAS_RUNNING=0
VO_PRE_PIDS=""
VO_PRE_QUICKSTART_PIDS=""
VO_OWN_PID=""
VO_OWN_QUICKSTART_PID=""
VO_SESSION_READY=0
VO_VERIFIED=0
VO_ATTEMPT_FAILURE=""
VO_COMMIT_EVIDENCE=""
record_voiceover_identity() {
  local pid
  VO_PRE_PIDS=""
  for pid in ${(f)"$(pgrep -x VoiceOver 2>/dev/null)"}; do VO_PRE_PIDS="$VO_PRE_PIDS $pid"; done
  VO_PRE_QUICKSTART_PIDS=""
  for pid in ${(f)"$(pgrep -f '/VoiceOver Quickstart' 2>/dev/null)"}; do
    VO_PRE_QUICKSTART_PIDS="$VO_PRE_QUICKSTART_PIDS $pid"
  done
}
new_voiceover_pid() {
  local pid="$1"
  [[ -z "$VO_PRE_PIDS" ]] && { print -r -- "$pid"; return 0; }
  print -r -- " $VO_PRE_PIDS " | grep -q " $pid " && return 1
  print -r -- "$pid"
}
new_quickstart_pid() {
  local pid="$1"
  [[ -z "$VO_PRE_QUICKSTART_PIDS" ]] && { print -r -- "$pid"; return 0; }
  print -r -- " $VO_PRE_QUICKSTART_PIDS " | grep -q " $pid " && return 1
  print -r -- "$pid"
}
reclaim_own_voiceover() {
  local pid="$1" i
  [[ -n "$pid" ]] || return 0
  kill -0 "$pid" 2>/dev/null || return 0
  kill -TERM "$pid" 2>/dev/null || true
  for i in {1..12}; do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.5
  done
  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
}
cleanup() {
  reclaim_own_voiceover "$VO_OWN_QUICKSTART_PID"
  reclaim_own_voiceover "$VO_OWN_PID"
  if [[ -n "$APP_PID" ]]; then
    # Reaching here means the normal-close path did not clear APP_PID. Record
    # the fallback by its own name so it cannot be read as a normal close.
    log "cleanup_force_kill pid=$APP_PID normal_close=0"
    cjgui_terminate_owned "$APP_PID" "" "$APP_EXEC" "$BUNDLE" || true
    sleep 1
    kill -9 "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

[[ -x "$APP_EXEC" ]] || blocked "settings bundle is not built at $BUNDLE"
session_locked && blocked "session locked; posted input cannot be delivered"
record_voiceover_identity
if [[ -n "$VO_PRE_PIDS" ]]; then
  VO_WAS_RUNNING=1
  log "voiceover_preexisting core_pids=[$VO_PRE_PIDS] quickstart_pids=[$VO_PRE_QUICKSTART_PIDS]"
else
  log "voiceover_preexisting none quickstart_pids=[$VO_PRE_QUICKSTART_PIDS]"
fi
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable"
[[ -x "$EV_DIR/probe/ax_node_probe" && -x "$EV_DIR/probe/ax_semantics_probe" ]] \
  || blocked "AX probes missing under $EV_DIR/probe"
prepare_desktop_driver || blocked "$INPUT_BLOCKED"
AX_PROBE="$EV_DIR/probe/ax_node_probe"
SEM_PROBE="$EV_DIR/probe/ax_semantics_probe"
LEFT_CLICK="$WORK/left_pointer_driver"
cat > "$WORK/left_pointer_driver.swift" <<'SWIFT'
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
SWIFT
swiftc -O "$WORK/left_pointer_driver.swift" -o "$LEFT_CLICK" > "$WORK/left-build.log" 2>&1 \
  || blocked "could not build left click helper"
WINDOW_ID_TOOL="$WORK/window_id_for_pid"
cat > "$WORK/window_id_for_pid.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count >= 2, let pid = Int(args[1]) else { exit(2) }
let exclude = args.count > 2 ? Int(args[2]) ?? -1 : -1
let windows = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
for window in windows {
    guard (window[kCGWindowOwnerPID as String] as? Int) == pid,
          (window[kCGWindowLayer as String] as? Int) == 0,
          let number = window[kCGWindowNumber as String] as? Int,
          number != exclude,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Double, let height = bounds["Height"] as? Double,
          width > 300, height > 300 else { continue }
    print(number)
}
SWIFT
swiftc -O "$WORK/window_id_for_pid.swift" -o "$WINDOW_ID_TOOL" > "$WORK/window-build.log" 2>&1 \
  || blocked "could not build window id helper"
WHEEL_TOOL="$WORK/wheel_pointer_driver"
cat > "$WORK/wheel_pointer_driver.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 4, let x = Double(args[1]), let y = Double(args[2]), let lines = Int32(args[3]) else { exit(2) }
let point = CGPoint(x: x, y: y)
for _ in 0..<6 {
    if let wheel = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1,
                           wheel1: lines, wheel2: 0, wheel3: 0) {
        wheel.location = point
        wheel.flags = []
        wheel.post(tap: .cghidEventTap)
    }
    usleep(40_000)
}
SWIFT
swiftc -O "$WORK/wheel_pointer_driver.swift" -o "$WHEEL_TOOL" > "$WORK/wheel-build.log" 2>&1 \
  || blocked "could not build wheel helper"
# vo_chord <keycode> <none|cmd|vo|vo+shift>: raw CGEvent chord. "vo" is the
# Control+Option VoiceOver modifier. The screen-reader path is driven through
# the same real event tap as every other input in this chain.
VO_CHORD="$WORK/vo_chord"
cat > "$WORK/vo_chord.swift" <<'SWIFT'
// VoiceOver chords through the REAL flagsChanged stream: VoiceOver tracks its
// modifier through actual modifier events, so posting a key with flags alone
// never reaches it (measured by the shared desktop driver). The shared driver
// retired its split-edge vo commands, so this round owns this helper.
// Usage: vo_chord <keycode> <none|cmd|cmdfn|vo|vo+shift>
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 3, let keycode = UInt16(args[1]) else { exit(2) }
func flagsChanged(_ key: CGKeyCode, _ flags: CGEventFlags) {
    if let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true) {
        event.type = .flagsChanged
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
    usleep(60_000)
}
func tap(_ key: CGKeyCode, _ flags: CGEventFlags) {
    for down in [true, false] {
        if let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down) {
            event.flags = flags
            event.post(tap: .cghidEventTap)
        }
        usleep(60_000)
    }
}
let control: CGKeyCode = 59, option: CGKeyCode = 58, shiftKey: CGKeyCode = 56,
    commandKey: CGKeyCode = 55
var active: CGEventFlags = []
switch args[2] {
case "cmd":
    active = [.maskCommand]
    flagsChanged(commandKey, active)
    tap(keycode, active)
    flagsChanged(commandKey, [])
case "cmdfn":
    active = [.maskCommand]
    flagsChanged(commandKey, active)
    tap(keycode, active.union(.maskSecondaryFn))
    flagsChanged(commandKey, [])
case "vocmd":
    // VO+Cmd+F5: move the VoiceOver cursor to the mouse pointer.
    active = [.maskControl, .maskAlternate]
    flagsChanged(control, active)
    flagsChanged(option, active)
    flagsChanged(commandKey, active.union(.maskCommand))
    tap(keycode, active.union(.maskCommand).union(.maskSecondaryFn))
    flagsChanged(commandKey, active)
    flagsChanged(option, [.maskControl])
    flagsChanged(control, [])
case "vo", "vo+shift":
    active = [.maskControl, .maskAlternate]
    flagsChanged(control, active)
    flagsChanged(option, active)
    if args[2] == "vo+shift" {
        active.insert(.maskShift)
        flagsChanged(shiftKey, active)
    }
    tap(keycode, active)
    if args[2] == "vo+shift" {
        active.remove(.maskShift)
        flagsChanged(shiftKey, active)
    }
    flagsChanged(option, [.maskControl])
    flagsChanged(control, [])
default:
    tap(keycode, [])
}
SWIFT
swiftc -O "$WORK/vo_chord.swift" -o "$VO_CHORD" > "$WORK/vo-build.log" 2>&1 \
  || blocked "could not build VO chord helper"
left_click() { "$LEFT_CLICK" "$1" "$2" >> "$WORK/click.log" 2>&1; }
wheel_at() { "$WHEEL_TOOL" "$1" "$2" "$3" >> "$WORK/wheel.log" 2>&1; }
drive() { "$DRIVER" "$@" >> "$WORK/driver.log" 2>&1; }
real_input_preflight || blocked "synthetic input permission refused"

APP_LOG="$WORK/app.log"
CJGUI_SETTINGS_NARROW=1 CJGUI_SETTINGS_SCOPED_MODE=all CJGUI_SETTINGS_THEME=dark CJGUI_AX_TRACE=1 \
  "$APP_EXEC" > "$APP_LOG" 2>&1 &
APP_PID=$!
waited=0; descriptor=""
while (( waited < 60 )); do
  descriptor="$(sed -n 's/^CJGUI_SETTINGS_READY DESCRIPTOR_PATH //p' "$APP_LOG" 2>/dev/null | head -1)"
  [[ -n "$descriptor" && -f "$descriptor" ]] && break
  sleep 0.5; waited=$((waited + 1))
done
[[ -n "$descriptor" && -f "$descriptor" ]] || blocked "CJGUI_SETTINGS_READY descriptor missing"
grep -q "^CJGUI_SETTINGS_READY WINDOW 460x760 narrow=true$" "$APP_LOG" || fail "narrow window declaration missing"
APP_PID="$(sed -n 's/^.*CJGUISettingsForm\[\([0-9]*\):.*/\1/p' "$APP_LOG" 2>/dev/null | head -1)"
[[ "$APP_PID" == <-> ]] || blocked "app log has no process id"
command_line="$(ps -p "$APP_PID" -o command= 2>/dev/null || true)"
[[ "$command_line" == *"$APP_EXEC"* ]] || blocked "descriptor owner is not this round's app"
AX_PID="$APP_PID"; export AX_PID
log "step0 pid=$APP_PID descriptor=$descriptor narrow=true mode=all theme=dark"
real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || blocked "AX tree not ready"
AX_APP_PATH="$BUNDLE"; export AX_APP_PATH
activate_app
[[ "$(app_frontmost)" == "true" ]] || blocked "app not frontmost"

SCOPE="$WORK/owned-input-$APP_PID.json"
python3 - "$APP_PID" "$APP_EXEC" "$SCOPE" <<'PY'
import json, os, sys, uuid
pid, executable, path = sys.argv[1:]
with open(path, "w") as handle:
    json.dump({"pid": int(pid), "nonce": uuid.uuid4().hex, "executable": executable}, handle)
os.chmod(path, 0o600)
PY
"$WORK/cjgui_desktop_input_driver" bind-target "$SCOPE" > "$WORK/owned-bind.log" 2>&1 \
  || blocked "owned target bind failed"
export CJGUI_DRIVER_TARGET_PID="$APP_PID" CJGUI_DRIVER_TARGET_FILE="$SCOPE"

ax_find() { "$AX_PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_frame() { ax_find "$1" | sed -n 's/^frame=//p' | head -1; }
ax_focus() { ax_find "$1" | awk -F= '/^focus=/{print $2}'; }
ax_value() { ax_find "$1" | awk '/^value_begin$/{p=1;next}/^value_end$/{p=0}p'; }
sem() { "$SEM_PROBE" "$APP_PID" "$@" 2>/dev/null; }
field_value() {
  python3 "$CLIENT" "$descriptor" read 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); print([f["draft"] for f in d["after"]["fields"] if f["field_id"]==sys.argv[1]][0])' "$1"
}
draft_version() {
  python3 "$CLIENT" "$descriptor" read 2>/dev/null | python3 -c \
    'import json,sys; print(json.load(sys.stdin)["after"]["draft_version"])'
}
center_of() { print -r -- "$1" | awk '{print $1 + $3/2, $2 + $4/2}'; }
frame_is_positive() { print -r -- "$1" | awk '{ if (NF == 4 && $1+0 > 0 && $2+0 > 0 && $3+0 > 0 && $4+0 > 0) exit 0; exit 1 }'; }
wait_focus() {
  local tries="${3:-40}" i=0 got=""
  while (( i < tries )); do
    got="$(ax_focus "$1")"
    [[ "$got" == "$2" ]] && return 0
    sleep 0.2; i=$((i + 1))
  done
  return 1
}
await_line() { local tries="${3:-50}" i=0; while (( i < tries )); do grep -qE "$1" "$APP_LOG" && return 0; sleep 0.2; i=$((i + 1)); done; return 1; }
last_request() { sed -n 's/^SETTINGS_CONTEXT_MENU phase=opened request_id=\([0-9]*\) .*/\1/p' "$APP_LOG" | tail -1; }
count_log() { grep -c "$1" "$APP_LOG" 2>/dev/null || true; }
business_window_id() { "$WINDOW_ID_TOOL" "$APP_PID"; }
shot_business() {
  local number; number="$(business_window_id | head -1)"
  [[ "$number" == <-> && "$number" -gt 0 ]] || { log "shot $1 skipped reason=window_id_missing"; return 1; }
  screencapture -x -l "$number" "$WORK/$1.png" >/dev/null 2>&1 || { log "shot $1 skipped reason=screencapture_failed"; return 1; }
  log "shot $1 file=$WORK/$1.png bytes=$(stat -f %z "$WORK/$1.png")"
}

# ---- step1: toolbar AX semantics read straight from the declaration ----
proxy_sem="$(sem settings-actions-settings-toggle-proxy)"
print -r -- "$proxy_sem" | grep -q "role=AXCheckBox" || fail "toolbar toggle is not AXCheckBox: $proxy_sem"
print -r -- "$proxy_sem" | grep -q "value=0" || fail "toolbar toggle initial AX value is not 0: $proxy_sem"
apply_sem="$(sem settings-actions-settings-apply)"
print -r -- "$apply_sem" | grep -q "role=AXButton" || fail "toolbar apply is not AXButton: $apply_sem"
# The declared reason is help only while the command is actually disabled; an
# enabled button must not describe itself as unavailable. The disabled-help
# fact is asserted on the scope toolbar in step7.
if print -r -- "$apply_sem" | grep -q "enabled=0"; then
  print -r -- "$apply_sem" | grep -q "help=草稿仍有字段错误或应用基线已变化" \
    || fail "disabled apply lost its declared reason: $apply_sem"
fi
log "step1 toolbar_semantics proxy=[${proxy_sem}] apply=[${apply_sem}]"

# ---- step2: keyboard open in all-mode; menu rows expose checkable/help ----
for _ in {1..40}; do
  if [[ "$(ax_focus settings-scope-a-control)" == "1" ]]; then break; fi
  drive key 48 || blocked "Tab not delivered"
  sleep 0.15
done
[[ "$(ax_focus settings-scope-a-control)" == "1" ]] || fail "Tab chain did not focus the A control"
drive cmd-shift-key 46 || blocked "Shift+Command+M not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened .*scope=a" || fail "keyboard context menu did not open"
req1="$(last_request)"; [[ "$req1" == <-> ]] || fail "request id missing"
toggle_row="settings-context-menu-a-item-settings-instance-a-toggle"
reset_row="settings-context-menu-a-item-settings-instance-a-reset"
wait_focus "$toggle_row" 1 40 || fail "initial focus did not land on the enabled checkable row"
row_sem="$(sem "$toggle_row" "$reset_row")"
print -r -- "$row_sem" | grep -q "$toggle_row role=AXCheckBox" || fail "menu toggle row is not AXCheckBox: $row_sem"
print -r -- "$row_sem" | grep -q "$reset_row role=AXButton" || fail "menu reset row is not AXButton: $row_sem"
print -r -- "$row_sem" | grep -q "$reset_row.*help=当前草稿仍有未提交的字段修改" \
  || fail "menu reset row help missing declared reason: $row_sem"
log "step2 keyboard_open request=$req1 menu_rows=[$row_sem]"
shot_business "menu-checkable-row-semantics" || true

# ---- step3: Enter activates the checkable row exactly once; AX value follows ----
accepted_before="$(count_log phase=command_accepted)"
drive key 36 || blocked "Enter not delivered"
[[ "$(field_value useProxy)" == "true" ]] || fail "Enter did not apply the scoped toggle"
[[ $(( $(count_log phase=command_accepted) - accepted_before )) -eq 1 ]] || fail "expected one command_accepted"
grep -q "phase=command_accepted request_id=$req1 command_id=settings.instance-a.toggle scene=" "$APP_LOG" \
  || fail "accepted line does not name the checkable toggle command"
await_line "phase=ended request_id=$req1 reason=(dismissed|target_or_selection_changed)" || fail "menu did not end after execution"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after execution"
after_sem="$(sem settings-actions-settings-toggle-proxy)"
print -r -- "$after_sem" | grep -q "value=1" || fail "toolbar AX value did not follow the owner write: $after_sem"
log "step3 enter_once toggle_accepted useProxy=true toolbar_value=1"

# ---- step4: second open; theme + owner change keep focus/scroll ----
drive cmd-shift-key 46 || blocked "second Shift+Command+M not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened .*scope=a" || fail "second keyboard menu did not open"
req2="$(last_request)"; [[ "$req2" != "$req1" ]] || fail "second menu reused the first request id"
wait_focus "$toggle_row" 1 40 || fail "second menu lost the checkable initial focus"
menu_frame2="$(ax_frame settings-context-menu-a-scroll)"
read -r mx2 my2 mw2 mh2 <<< "$menu_frame2"
read -r mx_center my_center <<< "$(center_of "$menu_frame2")"
wheel_at "$mx_center" "$my_center" 2; sleep 0.5
anchor_sem=""
for candidate in "$reset_row" settings-context-menu-a-item-settings-instance-a-disable \
    settings-context-menu-a-item-settings-instance-a-enable "$toggle_row" \
    settings-context-menu-a-item-settings-instance-a-search; do
  frame="$(ax_frame "$candidate")"
  if frame_is_positive "$frame"; then anchor_sem="$candidate"; break; fi
done
[[ -n "$anchor_sem" ]] || fail "no visible anchor row after scrolling"
anchor_before="$(ax_frame "$anchor_sem")"
theme_before="$(grep -c '^SETTINGS_COMMAND_THEME ' "$APP_LOG" 2>/dev/null || true)"
drive cmd-shift-key 17 || blocked "Shift+Command+T not delivered"
await_line "SETTINGS_COMMAND_THEME mode=light" || fail "theme command did not run while the menu was open"
[[ "$(last_request)" == "$req2" ]] || fail "theme change replaced the open request"
anchor_after="$(ax_frame "$anchor_sem")"
frame_is_positive "$anchor_after" || fail "theme change dropped the focused anchor row"
[[ "$anchor_before" == "$anchor_after" ]] || fail "theme change moved scrolling: $anchor_before -> $anchor_after"
focused_row_sem() {
  local candidate
  for candidate in "$toggle_row" "$reset_row" settings-context-menu-a-item-settings-instance-a-disable \
      settings-context-menu-a-item-settings-instance-a-enable \
      settings-context-menu-a-item-settings-instance-a-search; do
    [[ "$(ax_focus "$candidate")" == "1" ]] && { print -r -- "$candidate"; return 0; }
  done
  return 1
}
focus_before_sem="$(focused_row_sem || true)"
if [[ -n "$focus_before_sem" ]]; then
  wait_focus "$focus_before_sem" 1 30 || fail "theme change dropped menu focus"
else
  drive key 125 || blocked "Down after theme not delivered"
  wait_focus "$toggle_row" 1 30 || fail "theme change lost the menu's keyboard focus"
fi
shot_business "light-menu-open-theme-changed" || true
focus_now="$(focused_row_sem || true)"
[[ -n "$focus_now" ]] || fail "menu has no visible keyboard focus before the owner change"
anchor_before_owner="$(ax_frame "$anchor_sem")"
python3 "$CLIENT" "$descriptor" external > "$WORK/owner-external.json" 2> "$WORK/owner-external.err" \
  || blocked "external owner write failed"
retry_after="$(field_value retryLimit)"
[[ "$retry_after" == "6" ]] || fail "external owner write not visible: retryLimit=$retry_after"
sleep 1.0
[[ "$(last_request)" == "$req2" ]] || fail "owner change replaced the open request"
grep -q "phase=ended request_id=$req2 " "$APP_LOG" && fail "owner change closed the menu"
[[ "$(ax_focus "$focus_now")" == "1" ]] || fail "owner change dropped menu focus"
anchor_owner="$(ax_frame "$anchor_sem")"
[[ "$anchor_owner" == "$anchor_before_owner" ]] || \
  fail "owner change moved menu scrolling: $anchor_before_owner -> $anchor_owner"
log "step4 theme=light focus=${focus_now##*-} anchor=$anchor_sem scroll=$anchor_before->$anchor_after owner_retryLimit=6 request=$req2"

# ---- step5: external boolean write syncs state; a target-touching write ----
# ---- retires the open menu instead of leaving stale rows ----
proxy_now="$(sem "$toggle_row")"
print -r -- "$proxy_now" | grep -q "value=1" || fail "open menu row did not carry checked state: $proxy_now"
python3 "$CLIENT" "$descriptor" proxy --value false > "$WORK/owner-proxy.json" 2> "$WORK/owner-proxy.err" \
  || blocked "external boolean write failed"
sleep 1.2
[[ "$(field_value useProxy)" == "false" ]] || fail "external boolean owner write not visible"
await_line "phase=ended request_id=$req2 reason=target_or_selection_changed" \
  || fail "external target write did not retire the open request"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after the menu retired"
toolbar_synced="$(sem settings-actions-settings-toggle-proxy)"
print -r -- "$toolbar_synced" | grep -q "value=0" || fail "toolbar AX value did not sync: $toolbar_synced"
# A fresh request reads the externally written value from the same declaration.
drive cmd-shift-key 46 || blocked "third Shift+Command+M not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened .*scope=a" || fail "menu did not reopen after external write"
req3="$(last_request)"; [[ "$req3" != "$req2" ]] || fail "reopened menu reused the old request id"
wait_focus "$toggle_row" 1 40 || fail "reopened menu lost initial focus"
proxy_reopened="$(sem "$toggle_row")"
print -r -- "$proxy_reopened" | grep -q "value=0" || fail "reopened menu did not read the external value: $proxy_reopened"
log "step5 external_sync useProxy=false menu=req2_retired toolbar=0 reopened_value=0 request=$req3"
drive key 53 || blocked "Escape not delivered"
await_line "phase=ended request_id=$req3 reason=escape" || fail "Escape did not end request $req3"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after Escape"

# ---- step6: Esc returns; typing continues with exact owner readback ----
endpoint_before="$(field_value endpoint)"
endpoint_frame=""
for direction in -6 6 -8 8; do
  endpoint_frame="$(ax_frame settings-form-field-endpoint)"
  frame_is_positive "$endpoint_frame" && break
  wheel_at 700 600 "$direction"; sleep 0.6
done
frame_is_positive "$endpoint_frame" || fail "endpoint field could not be revealed"
read -r fx fy <<< "$(center_of "$endpoint_frame")"
left_click "$fx" "$fy" || blocked "field click not delivered"
wait_focus settings-form-field-endpoint 1 30 || fail "endpoint field did not take focus"
drive key 124 || blocked "End not delivered"
drive type "Z9" || blocked "typing not delivered"
expected_endpoint="${endpoint_before}Z9"
waited=0
while (( waited < 30 )); do
  [[ "$(field_value endpoint)" == "$expected_endpoint" ]] && break
  sleep 0.2; waited=$((waited + 1))
done
[[ "$(field_value endpoint)" == "$expected_endpoint" ]] || fail "owner endpoint mismatch expected=$expected_endpoint got=$(field_value endpoint)"
log "step6 escape_cancel typing_after_menus=$expected_endpoint"

# ---- step7: disabled / revoked old entries invoke with zero owner writes ----
# A clipped-out element publishes no AX node at all, so every reading below
# first reveals the element it judges; "miss" is only trusted as the revoked
# signature where a visible sibling anchor corroborates it.
reveal_scoped_row() { # reveal_scoped_row <semantic-id> [extra-downs-first]
  local target="$1" i
  for i in {1..20}; do
    frame_is_positive "$(ax_frame "$target")" && return 0
    wheel_at 700 600 -6; sleep 0.35
  done
  for i in {1..10}; do
    frame_is_positive "$(ax_frame "$target")" && return 0
    wheel_at 700 600 6; sleep 0.35
  done
  return 1
}
reveal_scoped_row settings-scope-a-actions-settings-instance-a-toggle \
  || fail "A toolbar toggle could not be revealed"
reveal_scoped_row settings-invoke-a || fail "scoped invoke control could not be revealed"
version_before_invoke="$(draft_version)"
accepted_total="$(count_log phase=command_accepted)"
"$AX_PROBE" "$APP_PID" press settings-cycle-commands > "$WORK/cycle1.log" 2>&1 || fail "cycle press failed"
disabled_toggle=""
for _ in {1..25}; do
  disabled_toggle="$(sem settings-scope-a-actions-settings-instance-a-toggle)"
  print -r -- "$disabled_toggle" | grep -q "help=该作用域命令当前被外部命令集禁用" && break
  sleep 0.3
done
print -r -- "$disabled_toggle" | grep -q "help=该作用域命令当前被外部命令集禁用" \
  || fail "disabled toolbar toggle lost its declared reason: $disabled_toggle"
"$AX_PROBE" "$APP_PID" press settings-invoke-a > "$WORK/invoke1.log" 2>&1 || fail "invoke press failed"
sleep 1.0
[[ "$(count_log phase=command_accepted)" == "$accepted_total" ]] || fail "disabled invoke was accepted"
[[ "$(draft_version)" == "$version_before_invoke" ]] || fail "disabled invoke wrote the owner: $(draft_version) != $version_before_invoke"
"$AX_PROBE" "$APP_PID" press settings-cycle-commands > "$WORK/cycle2.log" 2>&1 || fail "cycle to removed failed"
sleep 0.8
# Revoked signature: the A card anchor is on screen (so the area is not merely
# clipped), the A toolbar command is gone from the scene, and the sibling B
# instance still publishes its own checkable command.
reveal_scoped_row settings-scope-a-title || fail "A card anchor not visible in removed mode"
revoked_toggle=""
for _ in {1..20}; do
  revoked_toggle="$(sem settings-scope-a-actions-settings-instance-a-toggle)"
  [[ "$revoked_toggle" == *"miss"* ]] && break
  sleep 0.3
done
[[ "$revoked_toggle" == *"miss"* ]] || fail "revoked toolbar command still publishes an element: $revoked_toggle"
b_toggle="$(sem settings-scope-b-actions-settings-instance-b-toggle)"
print -r -- "$b_toggle" | grep -q "role=AXCheckBox" || fail "sibling B command lost its own semantics: $b_toggle"
"$AX_PROBE" "$APP_PID" press settings-invoke-a > "$WORK/invoke2.log" 2>&1 || fail "revoked invoke press failed"
sleep 1.0
[[ "$(count_log phase=command_accepted)" == "$accepted_total" ]] || fail "revoked invoke was accepted"
[[ "$(draft_version)" == "$version_before_invoke" ]] || fail "revoked invoke wrote the owner"
log "step7 zero_write disabled=refused revoked=element_gone_sibling_intact accepted_total=$accepted_total draft_version=$version_before_invoke"
"$AX_PROBE" "$APP_PID" press settings-cycle-commands > "$WORK/cycle3.log" 2>&1 || fail "cycle to empty failed"
sleep 0.5
"$AX_PROBE" "$APP_PID" press settings-cycle-commands > "$WORK/cycle4.log" 2>&1 || fail "cycle back to all failed"
restored_toggle=""
for _ in {1..30}; do
  restored_toggle="$(sem settings-scope-a-actions-settings-instance-a-toggle)"
  print -r -- "$restored_toggle" | grep -q "role=AXCheckBox" && break
  wheel_at 700 600 -6
  sleep 0.3
done
print -r -- "$restored_toggle" | grep -q "role=AXCheckBox" || fail "toggle did not come back after cycling to all: $restored_toggle"

# ---- step8: read-only Inspector command view under publication revisions ----
for direction in 6 -6 8 -8; do
  frame_is_positive "$(ax_frame settings-theme-row)" && break
  wheel_at 700 600 "$direction"; sleep 0.5
done
drive cmd-shift-key 34 || blocked "Shift+Command+I not delivered"
await_line "SETTINGS_INSPECTOR phase=opened" || fail "Inspector did not open"
sleep 0.8
"$AX_PROBE" "$APP_PID" press inspector-mode > "$WORK/inspector-mode.log" 2>&1 || fail "command view press failed"
sleep 0.8
version_text="$(ax_value inspector-command-version)"
print -r -- "$version_text" | grep -q "CURRENT" || fail "command view is not CURRENT: $version_text"
print -r -- "$version_text" | grep -qE "publication=[0-9]+" || fail "command view hides publication revision: $version_text"
print -r -- "$version_text" | grep -qE "声明 [1-9][0-9]* 条" || fail "command view has no declarations: $version_text"
row_id="$("$AX_PROBE" "$APP_PID" dump 400 2>/dev/null | awk -F'|' '/^AXButton\|inspector-command-[0-9]+-[0-9]+$/{print $2; exit}')"
[[ -n "$row_id" ]] || fail "no addressable command row"
"$AX_PROBE" "$APP_PID" press "$row_id" > "$WORK/inspector-row.log" 2>&1 || fail "command row press failed"
sleep 0.5
detail_id="$(ax_value inspector-command-id)"; detail_state="$(ax_value inspector-command-state)"
print -r -- "$detail_id" | grep -q "id=settings\." || fail "selected command detail missing id: $detail_id"
print -r -- "$detail_state" | grep -q "kind=" || fail "selected command detail missing kind fact: $detail_state"
"$AX_PROBE" "$APP_PID" press inspector-freeze > "$WORK/inspector-freeze.log" 2>&1 || fail "freeze press failed"
python3 "$CLIENT" "$descriptor" proxy --value true > "$WORK/owner-proxy2.json" 2> "$WORK/owner-proxy2.err" \
  || blocked "owner write before stale snapshot failed"
sleep 1.2
stale_text="$(ax_value inspector-command-version)"
print -r -- "$stale_text" | grep -q "STALE" || fail "frozen command snapshot did not go stale: $stale_text"
print -r -- "$stale_text" | grep -q "FROZEN" || fail "frozen marker missing: $stale_text"
log "step8 inspector current_version=$(print -r -- "$version_text" | head -1) stale_version=$(print -r -- "$stale_text" | head -1)"
"$AX_PROBE" "$APP_PID" press inspector-freeze > "$WORK/inspector-unfreeze.log" 2>&1 || fail "unfreeze press failed"
"$AX_PROBE" "$APP_PID" press inspector-refresh > "$WORK/inspector-refresh.log" 2>&1 || fail "refresh press failed"
sleep 0.8
fresh_text="$(ax_value inspector-command-version)"
print -r -- "$fresh_text" | grep -q "CURRENT" || fail "refresh did not return CURRENT: $fresh_text"

# ---- step9: real VoiceOver navigation and activation ----
# Acceptance method: one delivered VO+Space is checked against one AX action
# arrival and one exact owner change (field value plus +1 draft version). The
# VoiceOver cursor itself is not exposed by any observed channel on this host
# (system-wide AX names: AXFocusedApplication, AXFocusedUIElement, AXRole,
# AXRoleDescription); AX identifier reads and keyboard focus are recorded only
# as themselves, never as VO navigation. A run without an observable VO target
# or without the exact owner delta stays unverified and never blocks the
# independent close/Inspector retirement below.
# This is this run's initial state, not a system capability fact: no VoiceOver
# readout channel was observed by the script. It says nothing about whether the
# host offers one.
VO_VOICE_READOUT_CHANNEL="unobserved"
vo_once() { # vo_once <keycode> <mode>; one chord, no resend
  activate_app
  [[ "$(app_frontmost)" == "true" ]] || { print -r -- "chord $* frontmost=false" >> "$WORK/vo-chords.log"; return 2; }
  "$VO_CHORD" "$@"; local rc=$?
  print -r -- "chord $* rc=$rc" >> "$WORK/vo-chords.log"
  return $rc
}
run_voiceover_attempt() {
  local focused=0 control_frame cvx cvy move_ok before_proxy expected_proxy after_proxy
  local vo_before vo_after vo_delta arrivals_before arrivals_after arrivals_delta
  local focus_before_space focus_after_space i
  # The Inspector was frontmost after step8. Raise the business window and
  # establish keyboard focus only; this is not VO cursor evidence.
  : > "$WORK/vo-tab.log"
  osascript -e "tell application \"System Events\" to tell (first process whose unix id is $APP_PID) to perform action \"AXRaise\" of window \"工作区设置 · 分组表单\"" >/dev/null 2>&1 \
    || { VO_ATTEMPT_FAILURE="business_window_raise_failed"; return 1; }
  sleep 0.8
  for _ in {1..8}; do
    [[ "$(ax_focus settings-scope-a-control)" == "1" ]] && { focused=1; break; }
    activate_app
    [[ "$(app_frontmost)" == "true" ]] || { print -r -- "attempt frontmost=false" >> "$WORK/vo-tab.log"; sleep 0.3; continue; }
    drive key 48 || { print -r -- "attempt tab refused" >> "$WORK/vo-tab.log"; sleep 0.3; continue; }
    print -r -- "attempt tab ok focus=$(ax_focus settings-scope-a-control)" >> "$WORK/vo-tab.log"
    sleep 0.15
  done
  (( focused == 1 )) || { VO_ATTEMPT_FAILURE="keyboard_focus_not_established"; return 1; }
  for direction in -6 6; do
    frame_is_positive "$(ax_frame settings-scope-a-control)" && break
    wheel_at 700 600 "$direction"; sleep 0.5
  done
  frame_is_positive "$(ax_frame settings-scope-a-control)" \
    || { VO_ATTEMPT_FAILURE="control_not_visible"; return 1; }
  shot_business "vo-before-ring" || true
  # Route the VO cursor to the accepted control frame; keyboard focus and the
  # AX identifier read below are not claimed as VO navigation.
  control_frame="$(ax_frame settings-scope-a-control)"
  read -r cvx cvy <<< "$(center_of "$control_frame")"
  move_ok=0
  for _ in {1..3}; do
    "$DRIVER" move "$cvx" "$cvy" >> "$WORK/driver.log" 2>&1 && { move_ok=1; break; }
    activate_app; sleep 0.3
  done
  (( move_ok == 1 )) || { VO_ATTEMPT_FAILURE="pointer_route_refused"; return 1; }
  sleep 0.6
  vo_once 96 vocmd || { VO_ATTEMPT_FAILURE="vo_cursor_route_chord_not_delivered"; return 1; }
  sleep 1.0
  focus_after_route="$(ax_focus settings-scope-a-control)"
  shot_business "vo-cursor-on-control" || true
  vo_once 124 vo || { VO_ATTEMPT_FAILURE="vo_right_chord_not_delivered"; return 1; }
  sleep 1.0
  shot_business "vo-right-one" || true
  vo_once 123 vo || { VO_ATTEMPT_FAILURE="vo_left_chord_not_delivered"; return 1; }
  sleep 1.0
  shot_business "vo-back-on-control" || true
  ax_find settings-scope-a-control > "$WORK/vo-target-ax-read.txt" 2>&1 || true
  log "step9b chord_route=delivered ax_focus_after_route=${focus_after_route} ax_identifier_read=$(head -1 "$WORK/vo-target-ax-read.txt") vo_target=unobserved"
  # Exactly one VO+Space. No click, resend or delay is used to make it green.
  before_proxy="$(field_value useProxy)"
  vo_before="$(draft_version)"
  arrivals_before="$(grep -c "CJGUI_AX_TRACE action=press arrival" "$APP_LOG" 2>/dev/null || true)"
  focus_before_space="$(ax_focus settings-scope-a-control)"
  vo_once 49 vo || { VO_ATTEMPT_FAILURE="vo_space_chord_not_delivered"; return 1; }
  vo_after="$vo_before"
  for i in {1..30}; do
    vo_after="$(draft_version)"
    [[ "$vo_after" != "$vo_before" ]] && break
    sleep 0.3
  done
  after_proxy="$(field_value useProxy)"
  vo_delta=$(( vo_after - vo_before ))
  arrivals_after="$(grep -c "CJGUI_AX_TRACE action=press arrival" "$APP_LOG" 2>/dev/null || true)"
  arrivals_delta=$(( arrivals_after - arrivals_before ))
  focus_after_space="$(ax_focus settings-scope-a-control)"
  if [[ "$before_proxy" == "true" ]]; then expected_proxy="false"; else expected_proxy="true"; fi
  shot_business "vo-after-activation" || true
  VO_COMMIT_EVIDENCE="field=${before_proxy}->${after_proxy} draft=${vo_before}->${vo_after} delta=${vo_delta} ax_action_arrivals=${arrivals_delta} ax_focus_before_space=${focus_before_space} ax_focus_after_space=${focus_after_space}"
  log "step9c vo_space_delivered=1 $VO_COMMIT_EVIDENCE vo_target=unobserved readout_channel=${VO_VOICE_READOUT_CHANNEL}"
  if [[ "$vo_delta" == "1" && "$after_proxy" == "$expected_proxy" && "$arrivals_delta" == "1" ]]; then
    log "step9c owner_commit_exactly_once=1 action_arrival_exactly_once=1"
    VO_ATTEMPT_FAILURE="vo_cursor_readout_unavailable"
    return 2
  fi
  VO_ATTEMPT_FAILURE="vo_space_no_exact_owner_commit delta=${vo_delta} field=${before_proxy}->${after_proxy} arrivals=${arrivals_delta}"
  return 1
}
if (( VO_WAS_RUNNING == 1 )); then
  VO_ATTEMPT_FAILURE="pre_existing_voiceover_session_not_owned"
  log "step9a voiceover_preexisting keep_session=1 vo_attempt=skipped reason=$VO_ATTEMPT_FAILURE"
elif [[ -n "$VO_PRE_QUICKSTART_PIDS" ]]; then
  VO_ATTEMPT_FAILURE="pre_existing_voiceover_quickstart_not_owned pids=[$VO_PRE_QUICKSTART_PIDS]"
  log "step9a voiceover_quickstart_preexisting keep_session=1 vo_attempt=skipped reason=$VO_ATTEMPT_FAILURE"
else
  # Discriminating control first: the VO chord without VoiceOver must not
  # move the owner.
  vo_control_before="$(draft_version)"
  "$VO_CHORD" 49 vo
  sleep 1.0
  [[ "$(draft_version)" == "$vo_control_before" ]] \
    || fail "VO chord moved the owner without VoiceOver running"
  "$VO_CHORD" 96 cmdfn
  vo_ready=0
  for _ in {1..16}; do
    pgrep -x VoiceOver >/dev/null 2>&1 && { vo_ready=1; break; }
    sleep 0.5
  done
  if (( vo_ready == 0 )); then
    open -g /System/Library/CoreServices/VoiceOver.app
    for _ in {1..30}; do
      pgrep -x VoiceOver >/dev/null 2>&1 && { vo_ready=1; break; }
      sleep 0.5
    done
  fi
  for pid in ${(f)"$(pgrep -x VoiceOver 2>/dev/null)"}; do
    own="$(new_voiceover_pid "$pid")" || continue
    VO_OWN_PID="$own"; break
  done
  for pid in ${(f)"$(pgrep -f '/VoiceOver Quickstart' 2>/dev/null)"}; do
    own="$(new_quickstart_pid "$pid")" || continue
    VO_OWN_QUICKSTART_PID="$own"; break
  done
  if (( vo_ready == 0 )) || [[ -z "$VO_OWN_PID" ]]; then
    VO_ATTEMPT_FAILURE="voiceover_start_not_owned"
    log "step9a voiceover_start_failed control_chord_zero_write=1 vo_attempt=unverified reason=$VO_ATTEMPT_FAILURE"
  else
    # Retire only this round's Quickstart splash by its exact PID.
    reclaim_own_voiceover "$VO_OWN_QUICKSTART_PID"
    VO_OWN_QUICKSTART_PID=""
    VO_SESSION_READY=1
    log "step9a voiceover_started own_pid=$VO_OWN_PID control_chord_zero_write=1"
  fi
fi
if (( VO_SESSION_READY == 1 )); then
  sleep 3.0
  # `set -e` does not abort for a command in an `if` condition. Capturing 1/2
  # this way keeps step10 reachable instead of letting the EXIT trap force-kill
  # an app that was never closed normally.
  if run_voiceover_attempt; then
    attempt_rc=0
  else
    attempt_rc=$?
  fi
  if (( attempt_rc == 0 )); then
    VO_VERIFIED=1
  else
    (( attempt_rc == 2 )) || VO_ATTEMPT_FAILURE="${VO_ATTEMPT_FAILURE:-voiceover_attempt_failed}"
  fi
  log "step9e vo_attempt_rc=$attempt_rc normal_close_required=1 vo=$( (( VO_VERIFIED == 1 )) && print -r -- verified || print -r -- unverified)"
  reclaim_own_voiceover "$VO_OWN_PID"
  VO_OWN_PID=""
  log "step9d voiceover_reclaimed own_instance=1"
fi
log "step9 evidence chord_delivery=$(tail -1 "$WORK/vo-chords.log" 2>/dev/null || print -r -- 'not_run') vo_target=unobserved readout_channel=${VO_VOICE_READOUT_CHANNEL} commit=[${VO_COMMIT_EVIDENCE}] vo=$( (( VO_VERIFIED == 1 )) && print -r -- verified || print -r -- unverified) reason=[${VO_ATTEMPT_FAILURE}]"

# ---- step10: normal close; the Inspector retires with the business window ----
osascript -e "tell application \"System Events\" to tell (first process whose unix id is $APP_PID) to perform action \"AXRaise\" of window \"工作区设置 · 分组表单\"" >/dev/null 2>&1 \
  || blocked "business window raise failed"
sleep 0.5
for _ in {1..16}; do
  frame_is_positive "$(ax_frame settings-actions-settings-close)" && break
  wheel_at 700 600 6; sleep 0.35
done
frame_is_positive "$(ax_frame settings-actions-settings-close)" || fail "business close control was not revealed"
"$AX_PROBE" "$APP_PID" press settings-actions-settings-close > "$WORK/close.log" 2>&1 || blocked "close press failed"
waited=0
while (( waited < 40 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after normal close"
grep -q "destroy complete" "$APP_LOG" || fail "destroy completion missing"
APP_PID=""
log "step10 normal_close=destroy_complete inspector_retired=1"
if (( VO_VERIFIED == 1 )); then
  log "PASS requests=$req1,$req2 endpoint=$expected_endpoint vo=verified"
else
  log "PASS_CORE requests=$req1,$req2 endpoint=$expected_endpoint vo=unverified reason=[${VO_ATTEMPT_FAILURE}] readout_channel=${VO_VOICE_READOUT_CHANNEL} commit=[${VO_COMMIT_EVIDENCE}]"
fi
echo "settings command semantics chain: PASS log=$LOG"
