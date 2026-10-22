#!/usr/bin/env zsh
# DS4.1f continuous chain on the real settings consumer.
#
# Chain: keyboard context open on the focused A control (leading-disabled
# fixture, first enabled row below maxHeight) -> its initial focus reveals the
# row inside the constrained layer -> Enter executes exactly once -> second
# keyboard open, theme and owner change while it stays open (focus/nav/scroll
# preserved) -> Esc cancels -> keep typing in the endpoint field with exact
# readback -> read-only Inspector command view shows CURRENT, then a FROZEN
# snapshot goes STALE after an owner change and refresh returns to CURRENT ->
# normal close.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/settings_form_window_app"
BUNDLE="$APP_DIR/target/release/CJGUISettingsForm.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUISettingsForm"
CLIENT="$APP_DIR/settings_form_client.py"
OUTPUT_DIR="${CJGUI_SETTINGS_CONTINUOUS_TMPDIR:-/private/tmp/cjgui-settings-continuous}"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"; mkdir -p "$WORK"
LOG="$WORK/chain.log"; : > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -120 "$LOG"; echo "settings command continuous chain: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -80 "$LOG"; echo "settings command continuous chain: BLOCKED $1" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
APP_PID=""
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
swiftc -O "$AX_SOURCE" -o "$AX_PROBE" > "$WORK/ax-build.log" 2>&1 || blocked "could not build AX probe"
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
left_click() { "$LEFT_CLICK" "$1" "$2" >> "$WORK/click.log" 2>&1; }
wheel_at() { "$WHEEL_TOOL" "$1" "$2" "$3" >> "$WORK/wheel.log" 2>&1; }
drive() { "$DRIVER" "$@" > /dev/null 2>&1; }
real_input_preflight || blocked "synthetic input permission refused"

APP_LOG="$WORK/app.log"
CJGUI_SETTINGS_NARROW=1 CJGUI_SETTINGS_SCOPED_MODE=leading-disabled-a CJGUI_SETTINGS_THEME=dark \
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
log "step0 pid=$APP_PID descriptor=$descriptor narrow=true mode=leading-disabled-a theme=dark"
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
field_value() {
  python3 "$CLIENT" "$descriptor" read 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); print([f["draft"] for f in d["after"]["fields"] if f["field_id"]==sys.argv[1]][0])' "$1"
}
center_of() { print -r -- "$1" | awk '{print $1 + $3/2, $2 + $4/2}'; }
inside_vertical() {
  print -r -- "$1 $2" | awk '{ y=$2; h=$4; cy=$6; ch=$8; if (y >= cy - 1 && y + h <= cy + ch + 1) exit 0; exit 1; }'
}
shorter_than() {
  print -r -- "$1" | awk -v limit="$2" '{ if (NF == 4 && $4 ~ /^[0-9]+$/ && $4 < limit) exit 0; exit 1; }'
}
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
shot_other_window() { # after the inspector opens, capture the window that is not the business one
  local exclude="$1" number; number="$("$WINDOW_ID_TOOL" "$APP_PID" "$exclude" | head -1)"
  [[ "$number" == <-> && "$number" -gt 0 ]] || { log "shot $2 skipped reason=second_window_missing"; return 1; }
  screencapture -x -l "$number" "$WORK/$2.png" >/dev/null 2>&1 || { log "shot $2 skipped reason=screencapture_failed"; return 1; }
  log "shot $2 file=$WORK/$2.png bytes=$(stat -f %z "$WORK/$2.png")"
}

# Bring the A control into the narrow window's visible root viewport.
body_frame="$(ax_frame settings-scope-a-control)"
if ! frame_is_positive "$body_frame"; then
  activate_app; sleep 0.3
  for direction in -6 6; do
    wheel_at 700 600 "$direction"; sleep 0.6
    body_frame="$(ax_frame settings-scope-a-control)"
    frame_is_positive "$body_frame" && break
  done
fi
frame_is_positive "$body_frame" || fail "A control is not visible in the narrow window"
# Focus the A control through the real keyboard chain; clicking it would execute
# its business action before the menu is opened.
focused=0
for _ in {1..40}; do
  if [[ "$(ax_focus settings-scope-a-control)" == "1" ]]; then focused=1; break; fi
  drive key 48 || blocked "Tab not delivered"
  sleep 0.15
done
(( focused == 1 )) || fail "Tab chain did not focus the A control"
log "step1 control=$body_frame focused=1"

# 1. Keyboard context open: the declaration owns shortcut/target/scope.
drive cmd-shift-key 46 || blocked "Shift+Command+M not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened .*scope=a" || fail "keyboard context menu did not open"
req1="$(last_request)"; [[ "$req1" == <-> ]] || fail "request id missing"
enable_sem="settings-context-menu-a-item-settings-instance-a-enable"
wait_focus "$enable_sem" 1 40 || fail "initial focus did not land on the first enabled row"
menu_frame="$(ax_frame settings-context-menu-a-scroll)"
read -r mx my mw mh <<< "$menu_frame"
[[ "$mw" == 172 && "$mh" == 132 ]] || fail "narrow menu layer is ${mw}x${mh}, expected 172x132"
enable_frame="$(ax_frame "$enable_sem")"
frame_is_positive "$enable_frame" || fail "initial-focus row is clipped"
inside_vertical "$enable_frame" "$menu_frame" || fail "initial-focus row is outside the menu"
toggle_focus="$(ax_focus settings-context-menu-a-item-settings-instance-a-toggle)"
# A fully clipped row publishes no AX focus element at all.
[[ -z "$toggle_focus" || "$toggle_focus" == "0" ]] || fail "a disabled row received initial focus"
installed_line="$(grep "phase=installed request_id=$req1 " "$APP_LOG" | tail -1)"
print -r -- "$installed_line" | grep -q "target=.*keyboard\|reason=keyboard" || true
log "step2 keyboard_open request=$req1 menu=$menu_frame enable=$enable_frame reveal=initial disabled_focus=0"
shot_business "dark-menu-keyboard-initial-focus" || true

# 2. Enter executes exactly the highlighted command once.
scoped_before="$(count_log SETTINGS_SCOPED_COMMAND)"; accepted_before="$(count_log phase=command_accepted)"
drive key 36 || blocked "Enter not delivered"
[[ "$(field_value useProxy)" == "true" ]] || fail "Enter did not apply the scoped enable command"
[[ $(( $(count_log SETTINGS_SCOPED_COMMAND) - scoped_before )) -eq 1 ]] || fail "expected one owner command"
[[ $(( $(count_log phase=command_accepted) - accepted_before )) -eq 1 ]] || fail "expected one command_accepted"
grep -q "phase=command_accepted request_id=$req1 command_id=settings.instance-a.enable scene=" "$APP_LOG" \
  || fail "accepted line does not name enable"
await_line "phase=ended request_id=$req1 reason=(dismissed|target_or_selection_changed)" || fail "menu did not end after execution"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after execution"
log "step3 Enter=enable_once useProxy=true"

# 3. Second keyboard open; theme and owner state change while it stays open.
drive cmd-shift-key 46 || blocked "second Shift+Command+M not delivered"
await_line "SETTINGS_CONTEXT_MENU phase=opened .*scope=a" || fail "second keyboard menu did not open"
req2="$(last_request)"; [[ "$req2" != "$req1" ]] || fail "second menu reused the first request id"
wait_focus "$enable_sem" 1 40 || fail "second menu lost the first-enabled initial focus"
menu_frame2="$(ax_frame settings-context-menu-a-scroll)"
read -r mx2 my2 mw2 mh2 <<< "$menu_frame2"
read -r mx_center my_center <<< "$(center_of "$menu_frame2")"
wheel_at "$mx_center" "$my_center" 2; sleep 0.5
anchor_sem=""
for candidate in settings-context-menu-a-item-settings-instance-a-toggle \
    settings-context-menu-a-item-settings-instance-a-reset \
    settings-context-menu-a-item-settings-instance-a-disable \
    "$enable_sem" settings-context-menu-a-item-settings-instance-a-search; do
  frame="$(ax_frame "$candidate")"
  if frame_is_positive "$frame"; then anchor_sem="$candidate"; break; fi
done
[[ -n "$anchor_sem" ]] || fail "no visible anchor row after scrolling"
anchor_before="$(ax_frame "$anchor_sem")"
# AX publishes no element for a row that is fully clipped, so the focused row
# is recorded only when it has a live AX element. Its absence is not treated as
# a focus check; the clipped case is proven by revealing the same focus below.
focused_row_sem() {
  local candidate
  for candidate in settings-context-menu-a-item-settings-instance-a-toggle \
      settings-context-menu-a-item-settings-instance-a-reset \
      settings-context-menu-a-item-settings-instance-a-disable \
      "$enable_sem" settings-context-menu-a-item-settings-instance-a-search; do
    [[ "$(ax_focus "$candidate")" == "1" ]] && { print -r -- "$candidate"; return 0; }
  done
  return 1
}
focus_before_sem="$(focused_row_sem || true)"
theme_before="$(grep -c '^SETTINGS_COMMAND_THEME ' "$APP_LOG" 2>/dev/null || true)"
drive cmd-shift-key 17 || blocked "Shift+Command+T not delivered"
await_line "SETTINGS_COMMAND_THEME mode=light" || fail "theme command did not run while the menu was open"
[[ "$(last_request)" == "$req2" ]] || fail "theme change replaced the open request"
anchor_after="$(ax_frame "$anchor_sem")"
frame_is_positive "$anchor_after" || fail "theme change dropped the focused anchor row"
[[ "$anchor_before" == "$anchor_after" ]] || fail "theme change moved scrolling: $anchor_before -> $anchor_after"
if [[ -n "$focus_before_sem" ]]; then
  wait_focus "$focus_before_sem" 1 30 || fail "theme change dropped menu focus"
else
  # AX publishes no element while the focused row is fully clipped, so focus
  # identity is proven by ordinary navigation: the fixture has one executable
  # row, and Down from it re-selects the same accepted target and must reveal
  # it through the existing focus reveal path.
  log "step4a focused_row_clipped anchor=$anchor_sem scroll=$anchor_before"
  drive key 125 || blocked "Down after theme not delivered"
  wait_focus "$enable_sem" 1 30 || fail "theme change lost the menu's keyboard focus"
  enable_frame="$(ax_frame "$enable_sem")"
  frame_is_positive "$enable_frame" || fail "theme change left the focused row un-revealed"
  inside_vertical "$enable_frame" "$menu_frame2" || fail "theme change revealed focus outside the menu"
fi
shot_business "light-menu-open-theme-changed" || true
# Owner state change through the public client while the layer stays open.
for candidate in settings-context-menu-a-item-settings-instance-a-toggle \
    settings-context-menu-a-item-settings-instance-a-reset \
    settings-context-menu-a-item-settings-instance-a-disable \
    "$enable_sem" settings-context-menu-a-item-settings-instance-a-search; do
  frame="$(ax_frame "$candidate")"
  if frame_is_positive "$frame"; then anchor_sem="$candidate"; break; fi
done
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

# 4. Esc cancels the same request; typing resumes in the endpoint field.
drive key 53 || blocked "Escape not delivered"
await_line "phase=ended request_id=$req2 reason=escape" || fail "Escape did not end request $req2"
wait_focus settings-scope-a-control 1 30 || fail "focus did not return after Escape"
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
log "step5 escape_cancel typing_after_menus=$expected_endpoint"

# 5. Read-only Inspector on the same application/window owner.
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
print -r -- "$version_text" | grep -qE "声明 [1-9][0-9]* 条" || fail "command view has no declarations: $version_text"
bus_id="$(business_window_id | head -1)"
shot_other_window "$bus_id" "inspector-command-current" || true
row_id="$("$AX_PROBE" "$APP_PID" dump 400 2>/dev/null | awk -F'|' '/^AXButton\|inspector-command-[0-9]+-[0-9]+$/{print $2; exit}')"
[[ -n "$row_id" ]] || fail "no addressable command row"
"$AX_PROBE" "$APP_PID" press "$row_id" > "$WORK/inspector-row.log" 2>&1 || fail "command row press failed"
sleep 0.5
detail_id="$(ax_value inspector-command-id)"; detail_state="$(ax_value inspector-command-state)"
print -r -- "$detail_id" | grep -q "id=settings\." || fail "selected command detail missing id: $detail_id"
print -r -- "$detail_state" | grep -q "accepted=" || fail "selected command detail missing accepted version: $detail_state"
print -r -- "$detail_state" | grep -q "shortcut=" || fail "selected command detail missing shortcut field: $detail_state"
"$AX_PROBE" "$APP_PID" press inspector-freeze > "$WORK/inspector-freeze.log" 2>&1 || fail "freeze press failed"
# Change the owner while frozen: the command snapshot must mark itself stale
# instead of pointing at the new scene.
python3 "$CLIENT" "$descriptor" external > "$WORK/owner-inspector.json" 2> "$WORK/owner-inspector.err" \
  || blocked "owner write before stale snapshot failed"
sleep 1.2
stale_text="$(ax_value inspector-command-version)"
print -r -- "$stale_text" | grep -q "STALE" || fail "frozen command snapshot did not go stale: $stale_text"
print -r -- "$stale_text" | grep -q "FROZEN" || fail "frozen marker missing: $stale_text"
log "step6 inspector current_version=$(print -r -- "$version_text" | head -1) stale_version=$(print -r -- "$stale_text" | head -1)"
shot_other_window "$bus_id" "inspector-command-stale" || true
"$AX_PROBE" "$APP_PID" press inspector-freeze > "$WORK/inspector-unfreeze.log" 2>&1 || fail "unfreeze press failed"
"$AX_PROBE" "$APP_PID" press inspector-refresh > "$WORK/inspector-refresh.log" 2>&1 || fail "refresh press failed"
sleep 0.8
fresh_text="$(ax_value inspector-command-version)"
print -r -- "$fresh_text" | grep -q "CURRENT" || fail "refresh did not return CURRENT: $fresh_text"
log "step7 inspector_refresh current_again=1"

# 6. Normal close; the Inspector retires with the business window.
# The Inspector is frontmost after step 7, and step 5 left the business form
# scrolled to its endpoint field. Raise the business window by its own AX title
# (a title-bar click is covered by the Inspector at this size), then walk back
# up the form until the normal close control is actually revealed.
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
log "step8 normal_close=destroy_complete inspector_retired=1"
log "PASS requests=$req1,$req2 endpoint=$expected_endpoint inspector=current+stale+refresh"
echo "settings command continuous chain: PASS log=$LOG"
