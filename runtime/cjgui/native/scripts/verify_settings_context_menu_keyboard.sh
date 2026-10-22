#!/usr/bin/env zsh
# Real-input acceptance for the public single-layer context menu in its
# constrained-height form.
#
# Chain: launch the existing settings bundle in narrow mode (460x760, menu
# maxHeight 132) -> right-click A -> wheel to the bottom of the menu -> Down
# skips the disabled row and brings the last item into view -> Enter executes
# exactly one scoped command -> all-disabled menu shows a named close entry
# (Enter only closes) -> Esc still cancels -> click the endpoint field and keep
# typing -> exact owner readback -> normal close.
#
# Uses the existing settings bundle in place (no per-round copy/build); the
# descriptor path printed by the app selects exactly this round's PID.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/settings_form_window_app"
BUNDLE="$APP_DIR/target/release/CJGUISettingsForm.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUISettingsForm"
CLIENT="$APP_DIR/settings_form_client.py"
OUTPUT_DIR="${CJGUI_SETTINGS_CONTEXT_MENU_TMPDIR:-/private/tmp/cjgui-settings-context-menu}"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"; mkdir -p "$WORK"
LOG="$WORK/keyboard.log"; : > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -100 "$LOG"; echo "settings context menu keyboard: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -80 "$LOG"; echo "settings context menu keyboard: BLOCKED $1" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
APP_PID=""; AX_PID=""
cleanup() {
  if [[ -n "$APP_PID" ]]; then
    cjgui_terminate_owned "$APP_PID" "" "$APP_EXEC" "$BUNDLE" || true
  fi
}
trap cleanup EXIT

[[ -x "$APP_EXEC" ]] || blocked "settings bundle is not built at $BUNDLE"
session_locked && blocked "session locked; posted input cannot be delivered"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable"
prepare_desktop_driver || blocked "$INPUT_BLOCKED"
AX_PROBE="$WORK/ax_node_probe"
PHAROS_ROOT="${PHAROS_ROOT:-/Users/jiangxuanyang/Desktop/Pharos Mark}"
AX_SOURCE="$PHAROS_ROOT/tools/ax_node_probe.swift"
[[ -f "$AX_SOURCE" ]] || blocked "missing AX probe source $AX_SOURCE"
swiftc -O "$AX_SOURCE" -o "$AX_PROBE" > "$WORK/ax-build.log" 2>&1 \
  || blocked "could not build AX probe"
RIGHT_CLICK="$WORK/right_pointer_driver"
cat > "$WORK/right_pointer_driver.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 3, let x = Double(args[1]), let y = Double(args[2]) else { exit(2) }
let point = CGPoint(x: x, y: y)
for type in [CGEventType.mouseMoved, .rightMouseDown, .rightMouseUp] {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .right)
    event?.post(tap: .cghidEventTap)
    usleep(30_000)
}
print("posted=CGEvent.mouseEventRightMouseDown+Up screen_x=\(Int(x)) screen_y=\(Int(y))")
SWIFT
swiftc -O "$WORK/right_pointer_driver.swift" -o "$RIGHT_CLICK" > "$WORK/right-build.log" 2>&1 \
  || blocked "could not build right click helper"
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
guard args.count == 2, let pid = Int(args[1]) else { exit(2) }
let windows = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
var best = 0; var bestArea = 0.0
for window in windows {
    guard (window[kCGWindowOwnerPID as String] as? Int) == pid,
          (window[kCGWindowLayer as String] as? Int) == 0,
          let number = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Double, let height = bounds["Height"] as? Double else { continue }
    let area = width * height
    if area > bestArea { best = number; bestArea = area }
}
print(best)
SWIFT
swiftc -O "$WORK/window_id_for_pid.swift" -o "$WINDOW_ID_TOOL" > "$WORK/window-build.log" 2>&1 \
  || blocked "could not build window id helper"
left_click() { "$LEFT_CLICK" "$1" "$2" >> "$WORK/click.log" 2>&1; }
right_click() { "$RIGHT_CLICK" "$1" "$2" >> "$WORK/click.log" 2>&1; }
# The owned driver refuses a wheel whose NSEvent window-base cannot be
# reconstructed in the producer process (a foreign application window). The
# wheel therefore uses the same plain HID CGEvent channel as the click helpers;
# delivery is proven by the clip-intersected AX frames moving, never assumed.
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
print("posted=CGEvent.scrollWheel lines=\(lines) screen_x=\(Int(x)) screen_y=\(Int(y))")
SWIFT
swiftc -O "$WORK/wheel_pointer_driver.swift" -o "$WHEEL_TOOL" > "$WORK/wheel-build.log" 2>&1 \
  || blocked "could not build wheel helper"
wheel_at() { "$WHEEL_TOOL" "$1" "$2" "$3" >> "$WORK/wheel.log" 2>&1; }
real_input_preflight || blocked "synthetic input permission refused"

APP_LOG="$WORK/app.log"
CJGUI_SETTINGS_NARROW=1 "$APP_EXEC" > "$APP_LOG" 2>&1 &
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
log "step0 pid=$APP_PID descriptor=$descriptor exec=$APP_EXEC narrow=true"
real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || blocked "AX tree not ready"
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
log "step0b owned_input_bound $(cat "$WORK/owned-bind.log")"

ax_find() { "$AX_PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_frame() { ax_find "$1" | sed -n 's/^frame=//p' | head -1; }
ax_focus() { ax_find "$1" | awk -F= '/^focus=/{print $2}'; }
ax_value() { ax_find "$1" | awk '/^value_begin$/{p=1;next}/^value_end$/{p=0}p'; }
field_value() {
  python3 "$CLIENT" "$descriptor" read 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); print([f["draft"] for f in d["after"]["fields"] if f["field_id"]==sys.argv[1]][0])' "$1"
}
center_of() { print -r -- "$1" | awk '{print $1 + $3/2, $2 + $4/2}'; }
inside_vertical() { # inside_vertical <frame> <containerFrame>
  print -r -- "$1 $2" | awk '{
    y=$2; h=$4; cy=$6; ch=$8;
    if (y >= cy - 1 && y + h <= cy + ch + 1) exit 0;
    exit 1;
  }'
}
shorter_than() { # shorter_than <frame> <unclippedHeight>
  # AX reports a scroll-clipped node as its visible extent; a row that has
  # scrolled partly out of the menu keeps a positive frame but a reduced height.
  print -r -- "$1" | awk -v limit="$2" '{
    if (NF == 4 && $4 ~ /^[0-9]+$/ && $4 < limit) exit 0;
    exit 1;
  }'
}
wait_focus() { # wait_focus <semanticId> <0|1> [tries]
  local tries="${3:-30}" i=0 got=""
  while (( i < tries )); do
    got="$(ax_focus "$1")"
    [[ "$got" == "$2" ]] && return 0
    sleep 0.2; i=$((i + 1))
  done
  return 1
}
last_request() { sed -n 's/^SETTINGS_CONTEXT_MENU phase=opened request_id=\([0-9]*\) .*/\1/p' "$APP_LOG" | tail -1; }
count_log() { grep -c "$1" "$APP_LOG" 2>/dev/null || true; }
await_line() { local tries="${3:-40}" i=0; while (( i < tries )); do grep -qE "$1" "$APP_LOG" && return 0; sleep 0.2; i=$((i + 1)); done; return 1; }
shot() { # shot <name>
  local number; number="$("$WINDOW_ID_TOOL" "$APP_PID")"
  [[ "$number" == <-> && "$number" -gt 0 ]] || { log "shot $1 skipped reason=window_id_missing"; return 1; }
  screencapture -x -l "$number" "$WORK/$1.png" >/dev/null 2>&1 || {
    log "shot $1 skipped reason=screencapture_failed"; return 1
  }
  [[ -s "$WORK/$1.png" ]] || { log "shot $1 skipped reason=empty_file"; return 1 }
  log "shot $1 file=$WORK/$1.png bytes=$(stat -f %z "$WORK/$1.png")"
}

body_frame="$(ax_frame settings-scope-a-control)"
if ! frame_is_positive "$body_frame"; then
  # The narrow form can put A below the fold; wheel the app's own root viewport
  # until its AX frame (already clip-intersected) is positive.
  activate_app; sleep 0.3
  for direction in -6 6; do
    wheel_at 700 600 "$direction"
    sleep 0.6
    body_frame="$(ax_frame settings-scope-a-control)"
    if frame_is_positive "$body_frame"; then break; fi
  done
fi
[[ "$body_frame" != "missing" ]] || fail "A control AX frame missing"
frame_is_positive "$body_frame" || fail "A control is not visible in the narrow window"
read -r cx cy <<< "$(center_of "$body_frame")"
use_proxy_before="$(field_value useProxy)"
endpoint_before="$(field_value endpoint)"
[[ "$use_proxy_before" == "false" ]] || fail "unexpected initial useProxy=$use_proxy_before"
log "step1 target_control=$body_frame useProxy=$use_proxy_before endpoint=$endpoint_before"

# 1. Narrow menu: constrained layer, wheel reaches the tail, Down reveals the
#    last item while skipping the disabled row.
right_click "$cx" "$cy" || blocked "right click not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened" || fail "context menu did not open"
req1="$(last_request)"; [[ "$req1" == <-> ]] || fail "request id missing"
wait_focus settings-context-menu-a-item-settings-instance-a-toggle 1 40 || fail "initial menu focus missing"
menu_frame="$(ax_frame settings-context-menu-a-scroll)"
frame_is_positive "$menu_frame" || fail "menu layer AX frame missing"
read -r mx my mw mh <<< "$menu_frame"
[[ "$mw" == 172 && "$mh" == 132 ]] || fail "narrow menu layer is ${mw}x${mh}, expected 172x132"
installed_line="$(grep "phase=installed request_id=$req1 " "$APP_LOG" | tail -1)"
print -r -- "$installed_line" | grep -q "rect=[0-9-]*,[0-9-]*,172,132" || fail "accepted layer rect is not 172x132"
[[ "$(ax_focus settings-context-menu-a-item-settings-instance-a-reset)" == "0" ]] || fail "disabled reset row received focus"
enable_sem="settings-context-menu-a-item-settings-instance-a-enable"
close_sem="settings-context-menu-a-close"
enable_before="$(ax_frame "$enable_sem")"
frame_is_positive "$enable_before" && fail "last row is visible before any wheel; menu does not overflow"
read -r mx_center my_center <<< "$(center_of "$menu_frame")"
scrolled=0
for direction in -6 6; do
  wheel_at "$mx_center" "$my_center" "$direction"
  sleep 0.6
  enable_after="$(ax_frame "$enable_sem")"
  if frame_is_positive "$enable_after"; then scrolled=1; break; fi
done
(( scrolled == 1 )) || fail "wheel did not reveal the last menu row"
log "step2a wheel menu=$menu_frame enable=$enable_after focus_toggle=$(ax_focus settings-context-menu-a-item-settings-instance-a-toggle) focus_scroll=$(ax_focus settings-context-menu-a-scroll)"
inside_vertical "$enable_after" "$menu_frame" || fail "wheel-revealed last row is outside the menu"
shot "menu-narrow-wheel-tail" || true
# Wheel back to the top, then use ONLY the keyboard: the first Down lands on the
# visible disabled row's successor, the second Down moves to a last row that is
# still clipped, and the window's existing focus reveal must scroll it into the
# visible part of the same viewport.
at_top=0
for direction in 6 8 6; do
  wheel_at "$mx_center" "$my_center" "$direction"
  sleep 0.6
  toggle_top="$(ax_frame settings-context-menu-a-item-settings-instance-a-toggle)"
  enable_top="$(ax_frame "$enable_sem")"
  if frame_is_positive "$toggle_top"; then
    if ! frame_is_positive "$enable_top"; then at_top=1; break; fi
  fi
done
(( at_top == 1 )) || fail "wheel did not return the menu to the top"
"$WORK/cjgui_desktop_input_driver" key 125 > "$WORK/key-down-1.log" 2>&1 || blocked "Down not delivered"
wait_focus settings-context-menu-a-item-settings-instance-a-disable 1 || fail "Down did not reach disable"
[[ "$(ax_focus settings-context-menu-a-item-settings-instance-a-reset)" == "0" ]] || fail "Down focused the disabled row"
"$WORK/cjgui_desktop_input_driver" key 125 > "$WORK/key-down-2.log" 2>&1 || blocked "second Down not delivered"
wait_focus "$enable_sem" 1 || fail "second Down did not reach the last item"
enable_focused="$(ax_frame "$enable_sem")"
frame_is_positive "$enable_focused" || fail "focused last row is clipped"
inside_vertical "$enable_focused" "$menu_frame" || fail "focused last row is outside the menu"
toggle_revealed="$(ax_frame settings-context-menu-a-item-settings-instance-a-toggle)"
toggle_row_height="$(print -r -- "$toggle_top" | awk '{print $4}')"
[[ "$toggle_row_height" == <-> && "$toggle_row_height" -gt 0 ]] || fail "could not read the unclipped toggle row height ($toggle_top)"
reveal_waits=0
while (( reveal_waits < 20 )) && ! shorter_than "$toggle_revealed" "$toggle_row_height"; do
  sleep 0.1
  toggle_revealed="$(ax_frame settings-context-menu-a-item-settings-instance-a-toggle)"
  reveal_waits=$((reveal_waits + 1))
done
log "step2b keyboard_reveal menu=$menu_frame enable=$enable_focused toggle=$toggle_revealed at_top_toggle=$toggle_top at_top_enable=$enable_top"
shorter_than "$toggle_revealed" "$toggle_row_height" || fail "focus reveal did not scroll the menu"
shot "menu-narrow-focused-last" || true
log "step2 request=$req1 menu=${mw}x${mh} wheel=tail+top keyboard_reveal=toggle->disable->enable skipped=reset"

# 2. Enter executes exactly the highlighted command once.
scoped_before="$(count_log SETTINGS_SCOPED_COMMAND)"
accepted_before="$(count_log phase=command_accepted)"
"$WORK/cjgui_desktop_input_driver" key 36 > "$WORK/key-enter.log" 2>&1 || blocked "Enter not delivered"
[[ "$(field_value useProxy)" == "true" ]] || fail "Enter did not apply the scoped command"
scoped_after="$(count_log SETTINGS_SCOPED_COMMAND)"
accepted_after="$(count_log phase=command_accepted)"
[[ $((scoped_after - scoped_before)) -eq 1 ]] || fail "expected one owner command, got $((scoped_after - scoped_before))"
[[ $((accepted_after - accepted_before)) -eq 1 ]] || fail "expected one command_accepted, got $((accepted_after - accepted_before))"
grep -q "phase=command_accepted request_id=$req1 command_id=settings.instance-a.enable scene=" "$APP_LOG" \
  || fail "accepted line does not name enable"
await_line "phase=ended request_id=$req1 reason=(dismissed|target_or_selection_changed)" || fail "menu did not end after execution"
enter_reason="$(sed -n "s/^CJGUI_CONTEXT_MENU phase=ended request_id=$req1 reason=//p" "$APP_LOG" | tail -1)"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after execution"
log "step3 Enter=enable once owner_useProxy=true request=$req1 ended=$enter_reason"

# 3. All-disabled in the same constrained layer: a named close entry is the
#    only live row; Enter closes without executing a business command.
"$AX_PROBE" "$APP_PID" press settings-cycle-commands > "$WORK/cycle.log" 2>&1 || blocked "cycle press failed"
sleep 0.5
right_click "$cx" "$cy" || blocked "all-disabled right click not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened" || fail "all-disabled menu did not open"
req2="$(last_request)"
[[ "$req2" != "$req1" ]] || fail "all-disabled request reused the first id"
wait_focus "$close_sem" 1 40 || fail "all-disabled menu did not focus the named close entry"
close_frame="$(ax_frame "$close_sem")"
frame_is_positive "$close_frame" || fail "named close entry is not visible"
inside_vertical "$close_frame" "$menu_frame" || fail "named close entry is outside the menu"
[[ "$(ax_value "$close_sem")" == "关闭菜单" ]] || fail "close entry lost its name: $(ax_value "$close_sem")"
for key in toggle reset disable enable; do
  got="$(ax_focus "settings-context-menu-a-item-settings-instance-a-$key")"
  # A clipped disabled row publishes no AX focus element at all; a row that is
  # addressable must not hold focus while the close entry does.
  [[ -z "$got" || "$got" == "0" ]] || fail "disabled $key row received focus"
done
[[ "$(ax_focus "$close_sem")" == "1" ]] || fail "close entry lost focus before Enter"
menu2_frame="$(ax_frame settings-context-menu-a-scroll)"
read -r mx2 my2 mw2 mh2 <<< "$menu2_frame"
[[ "$mw2" == 172 && "$mh2" == 132 ]] || fail "all-disabled layer is ${mw2}x${mh2}, expected 172x132"
shot "menu-narrow-all-disabled-close" || true
scoped_before="$(count_log SETTINGS_SCOPED_COMMAND)"
accepted_before="$(count_log phase=command_accepted)"
"$WORK/cjgui_desktop_input_driver" key 36 > "$WORK/key-close-enter.log" 2>&1 || blocked "close Enter not delivered"
await_line "phase=ended request_id=$req2 reason=dismissed" || fail "close entry did not end the request"
[[ "$(count_log SETTINGS_SCOPED_COMMAND)" == "$scoped_before" ]] || fail "close entry executed a business command"
[[ "$(count_log phase=command_accepted)" == "$accepted_before" ]] || fail "close entry was accepted as a command"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after closing the all-disabled menu"
[[ "$(field_value useProxy)" == "true" ]] || fail "close entry changed the owner"
log "step4 all_disabled request=$req2 close=visible+named enter=dismissed execution=none"

# 4. Esc still cancels the same constrained all-disabled layer.
right_click "$cx" "$cy" || blocked "all-disabled Esc right click not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened" || fail "second all-disabled menu did not open"
req3="$(last_request)"
wait_focus "$close_sem" 1 40 || fail "second all-disabled menu lost its close focus"
"$WORK/cjgui_desktop_input_driver" key 53 > "$WORK/key-escape.log" 2>&1 || blocked "Escape not delivered"
await_line "phase=ended request_id=$req3 reason=escape" || fail "Escape did not end request $req3"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after Escape"
[[ "$(field_value useProxy)" == "true" ]] || fail "Escape changed the owner"
log "step5 all_disabled request=$req3 escape=pass"

# 5. Continue typing in the field after the menus; exact owner readback. The
#    narrow form puts the endpoint below the fold, so the app's own root
#    viewport is wheeled until its clip-intersected AX frame is pressable.
endpoint_frame=""
for direction in -6 6 -8 8; do
  endpoint_frame="$(ax_frame settings-form-field-endpoint)"
  if frame_is_positive "$endpoint_frame"; then break; fi
  wheel_at 700 600 "$direction"
  sleep 0.6
done
frame_is_positive "$endpoint_frame" || fail "endpoint field could not be revealed"
read -r fx fy <<< "$(center_of "$endpoint_frame")"
left_click "$fx" "$fy" || blocked "field click not delivered"
wait_focus settings-form-field-endpoint 1 30 || fail "endpoint field did not take focus"
"$WORK/cjgui_desktop_input_driver" key 124 > "$WORK/key-end.log" 2>&1 || blocked "caret move not delivered"
"$WORK/cjgui_desktop_input_driver" type "Z9" > "$WORK/type.log" 2>&1 || blocked "typing not delivered"
expected_endpoint="${endpoint_before}Z9"
waited=0
while (( waited < 30 )); do
  [[ "$(field_value endpoint)" == "$expected_endpoint" ]] && break
  sleep 0.2; waited=$((waited + 1))
done
[[ "$(field_value endpoint)" == "$expected_endpoint" ]] || fail "owner endpoint mismatch expected=$expected_endpoint"
log "step6 typing_after_menus=$expected_endpoint"

# 6. Disabled window command cannot execute through the consumer entry. The
#    field reveal moved the root viewport; return the toolbar into view first.
for direction in 6 -6 8 -8; do
  invoke_frame="$(ax_frame settings-invoke-a)"
  if frame_is_positive "$invoke_frame"; then break; fi
  wheel_at 700 600 "$direction"
  sleep 0.5
done
scoped_before="$(count_log SETTINGS_SCOPED_COMMAND)"
"$AX_PROBE" "$APP_PID" press settings-invoke-a > "$WORK/invoke-disabled.log" 2>&1 || blocked "invoke press failed"
sleep 0.5
[[ "$(count_log SETTINGS_SCOPED_COMMAND)" == "$scoped_before" ]] || fail "disabled invoke executed a scoped command"
[[ "$(field_value useProxy)" == "true" ]] || fail "disabled invoke changed the owner"
log "step7 disabled_invoke_refused=pass"

# 7. Normal close through the application's own close control. Return the root
#    viewport to the top first when the field reveal moved it.
for direction in 6 -6 8 -8; do
  close_frame_now="$(ax_frame settings-actions-settings-close)"
  if frame_is_positive "$close_frame_now"; then break; fi
  wheel_at 700 600 "$direction"
  sleep 0.5
done
"$AX_PROBE" "$APP_PID" press settings-actions-settings-close > "$WORK/close.log" 2>&1 || blocked "close press failed"
waited=0
while (( waited < 40 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after normal close"
grep -q "destroy complete" "$APP_LOG" || fail "destroy completion missing"
APP_PID=""
log "step8 normal_close=destroy_complete"
log "PASS narrow=true requests=$req1,$req2,$req3 endpoint=$expected_endpoint useProxy=true"
echo "settings context menu keyboard: PASS narrow requests=$req1,$req2,$req3 log=$LOG"
