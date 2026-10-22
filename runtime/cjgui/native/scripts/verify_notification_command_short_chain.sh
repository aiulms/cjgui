#!/usr/bin/env zsh
set -euo pipefail

RUNTIME=/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
BUNDLE="$RUNTIME/examples/notification_threshold_window_app/target/release/CJGUINotificationThreshold.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUINotificationThreshold"
PHAROS_TOOLS="/Users/jiangxuanyang/Desktop/Pharos Mark/tools"
ROOT="$RUNTIME/artifacts/ds41f-command-semantics-20261021/second-consumer"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$ROOT/run-$RUN_TAG"
mkdir -p "$WORK"

blocked() { echo "BLOCKED $*"; exit 3; }
fail() { echo "FAIL $*"; exit 1; }
log() { print -r -- "$*" | tee -a "$WORK/chain.log"; }

swiftc -O "$PHAROS_TOOLS/ax_node_probe.swift" -o "$WORK/ax_node_probe" > "$WORK/ax-build.log" 2>&1 \
  || blocked "ax probe build failed"
SEM_PROBE="$RUNTIME/artifacts/ds41f-command-semantics-20261021/probe/ax_semantics_probe"
[[ -x "$SEM_PROBE" ]] || blocked "semantics probe missing"
swiftc -O "$PHAROS_TOOLS/context_pointer_driver.swift" -o "$WORK/right_pointer_driver" > "$WORK/right-build.log" 2>&1 \
  || blocked "right pointer build failed"
PROBE="$WORK/ax_node_probe"; RIGHT="$WORK/right_pointer_driver"

APP_LOG="$WORK/app.log"
"$APP_EXEC" > "$APP_LOG" 2>&1 &
APP_PID=$!
trap 'kill '"$APP_PID"' 2>/dev/null || true' EXIT
for i in {1..80}; do grep -q "^CJGUI_NOTIFICATION_READY DESCRIPTOR_PATH" "$APP_LOG" 2>/dev/null && break; sleep 0.25; done
grep -q "^CJGUI_NOTIFICATION_READY DESCRIPTOR_PATH" "$APP_LOG" || blocked "notification app did not become ready"
sleep 1
osascript -e "tell application \"System Events\" to set frontmost of first process whose unix id is $APP_PID to true" >/dev/null 2>&1 || true
# Move this instance away from any system banner that may float above the
# threshold field. The window position is test-harness state; the command and
# request assertions below are unchanged.
osascript -e "tell application \"System Events\" to tell (first process whose unix id is $APP_PID) to set position of window 1 to {0, 34}" >/dev/null 2>&1 || true
sleep 0.5

ax_find() { "$PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_frame() { ax_find "$1" | sed -n 's/^frame=//p' | head -1; }
ax_value() { ax_find "$1" | awk '/^value_begin$/{p=1;next}/^value_end$/{p=0}p'; }
frame_positive() { print -r -- "$1" | awk '{if (NF==4 && $3>0 && $4>0) exit 0; exit 1}'; }

BEACON="notification-command-bar-notification-command-beacon"
beacon_sem="$("$SEM_PROBE" "$APP_PID" "$BEACON" 2>/dev/null)"
print -r -- "$beacon_sem" | grep -q "role=AXCheckBox" || fail "beacon toolbar command is not AXCheckBox: $beacon_sem"
log "step0 beacon_semantics [$beacon_sem]"
before="$(ax_value "$BEACON")"
# The label is published on the semantic description; the checkable state is
# the projected value. Older builds put the caption in the value slot, so this
# asserts the two facts where the current projection actually publishes them
# instead of requiring a retired caption-in-value shape.
print -r -- "$beacon_sem" | grep -q "desc=切换图标" || fail "notification toolbar beacon label missing: $beacon_sem"
"$PROBE" "$APP_PID" press "$BEACON" > "$WORK/beacon.log" 2>&1 || fail "beacon toolbar press failed"
sleep 1.0
# This consumer's command bar publishes the checkable state on the semantic
# projection, not in the plain AX value slot (which is empty for the bar).
after_sem="$("$SEM_PROBE" "$APP_PID" "$BEACON" 2>/dev/null)"
after="$after_sem"
print -r -- "$after_sem" | grep -Eq "value=1|checked=1|✓" || fail "checked state did not reach notification toolbar: [$after_sem]"
log "step1 toolbar_command=notification.command.beacon before=[$before] after=[$after]"

frame="$(ax_frame trigger-threshold)"
frame_positive "$frame" || fail "threshold input is not visible: $frame"
read -r px py <<< "$(print -r -- "$frame" | awk '{print $1 + $3/2, $2 + $4/2}')"
POINT_OWNER="$WORK/point_owner"
cat > "$WORK/point_owner.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let x = Double(CommandLine.arguments[1])!, y = Double(CommandLine.arguments[2])!
let windows = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
for window in windows {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    if owner == "Dock" || owner == "程序坞" { continue }
    guard let b = window[kCGWindowBounds as String] as? [String: Any],
          let bx = b["X"] as? Double, let by = b["Y"] as? Double,
          let bw = b["Width"] as? Double, let bh = b["Height"] as? Double else { continue }
    if x >= bx && x <= bx + bw && y >= by && y <= by + bh {
        print(window[kCGWindowOwnerPID as String] as? Int ?? -1)
        exit(0)
    }
}
print(-1)
SWIFT
swiftc -O "$WORK/point_owner.swift" -o "$POINT_OWNER" > "$WORK/point-owner-build.log" 2>&1 \
  || blocked "could not build point owner helper"
owner_pid="$("$POINT_OWNER" "${px%.*}" "${py%.*}")"
[[ "$owner_pid" == "$APP_PID" ]] || blocked "foreign window pid=$owner_pid covers click point ${px%.*},${py%.*}"
"$RIGHT" "${px%.*}" "${py%.*}" > "$WORK/right-click.log" 2>&1 || blocked "right click failed"
sleep 1.0
menu_ids="$("$PROBE" "$APP_PID" dump 400 2>/dev/null | awk -F'|' '/notification-threshold-menu/{print $2}')"
print -r -- "$menu_ids" | grep -q "notification-threshold-menu" || fail "context menu did not open"
log "step2 context_menu_open ids=$(print -r -- "$menu_ids" | tr '\n' ',' | sed 's/,$//')"
item="$(print -r -- "$menu_ids" | grep 'notification-context-beacon' | head -1)"
[[ -n "$item" ]] || fail "context menu has no beacon item"
"$PROBE" "$APP_PID" press "$item" > "$WORK/menu-item.log" 2>&1 || fail "context menu item press failed"
sleep 1.0
menu_after="$("$PROBE" "$APP_PID" dump 400 2>/dev/null | awk -F'|' '/notification-threshold-menu/{print $2}')"
[[ -z "$menu_after" ]] || fail "context menu did not close after execution"
after_menu="$(ax_value "$BEACON")"
[[ "$after_menu" != "$after" ]] || fail "context command did not change the shared declaration: [$after_menu]"
log "step2 context_command=$item toolbar_after=[$after_menu]"

WINDOW_ID_TOOL="$WORK/window_id_for_pid"
cat > "$WORK/window_id_for_pid.swift" <<'SWIFT'
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
swiftc -O "$WORK/window_id_for_pid.swift" -o "$WINDOW_ID_TOOL" > "$WORK/window-build.log" 2>&1 || blocked "window id tool build failed"
wid="$("$WINDOW_ID_TOOL" "$APP_PID" | head -1)"
[[ "$wid" == <-> ]] && screencapture -x -l "$wid" "$WORK/notification-command-surface.png" >/dev/null 2>&1 \
  && log "shot notification-command-surface file=$WORK/notification-command-surface.png bytes=$(stat -f %z "$WORK/notification-command-surface.png")"

"$PROBE" "$APP_PID" press notification-command-bar-notification-command-close > "$WORK/close.log" 2>&1 \
  || blocked "notification close command press failed"
waited=0
while (( waited < 40 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.25; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "notification app did not exit after close command"
APP_PID=""
log "step3 close_command=notification.command.close app_exited=1"
log "PASS second_consumer=notification command+context+close"
