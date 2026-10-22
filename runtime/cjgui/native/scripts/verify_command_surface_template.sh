#!/usr/bin/env zsh
set -euo pipefail

RUNTIME=/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
BUNDLE="${CJGUI_TEMPLATE_BUNDLE:-/private/tmp/ds41f-template-20261021/CJGUICommandSurfaceStarter/target/release/CJGUICommandSurfaceStarter.app}"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUICommandSurfaceStarter"
PHAROS_TOOLS="/Users/jiangxuanyang/Desktop/Pharos Mark/tools"
ROOT="$RUNTIME/artifacts/ds41f-command-semantics-20261021/template"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$ROOT/run-$RUN_TAG"
mkdir -p "$WORK"

blocked() { echo "BLOCKED $*"; exit 3; }
fail() { echo "FAIL $*"; exit 1; }
log() { print -r -- "$*" | tee -a "$WORK/chain.log"; }

swiftc -O "$PHAROS_TOOLS/ax_node_probe.swift" -o "$WORK/ax_node_probe" > "$WORK/ax-build.log" 2>&1 \
  || blocked "ax probe build failed"
PROBE="$WORK/ax_node_probe"

APP_LOG="$WORK/app.log"
"$APP_EXEC" > "$APP_LOG" 2>&1 &
APP_PID=$!
trap 'kill '"$APP_PID"' 2>/dev/null || true' EXIT
for i in {1..80}; do grep -q "^CJGUI_COMMAND_SURFACE_READY" "$APP_LOG" 2>/dev/null && break; sleep 0.25; done
grep -q "^CJGUI_COMMAND_SURFACE_READY" "$APP_LOG" || blocked "command-surface template did not become ready"
sleep 1
osascript -e "tell application \"System Events\" to set frontmost of first process whose unix id is $APP_PID to true" >/dev/null 2>&1 || true
sleep 0.5

ax_find() { "$PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_value() { ax_find "$1" | awk '/^value_begin$/{p=1;next}/^value_end$/{p=0}p'; }

reading0="$(ax_value command-surface-reading)"
print -r -- "$reading0" | grep -q "当前读数：0" || fail "initial reading missing: $reading0"
"$PROBE" "$APP_PID" press command-surface-toolbar-starter-add > "$WORK/add.log" 2>&1 \
  || fail "toolbar add press failed"
sleep 1.0
reading1="$(ax_value command-surface-reading)"
print -r -- "$reading1" | grep -q "当前读数：1" || fail "toolbar command did not reach the owner: $reading1"
log "step1 toolbar_command=starter.add reading=[$reading1]"

"$PROBE" "$APP_PID" press command-surface-toolbar-starter-inspector > "$WORK/inspector-open.log" 2>&1 \
  || fail "inspector command press failed"
opened=0
for i in {1..40}; do
  ax_find inspector-mode 2>/dev/null | grep -q '^role=' && opened=1 && break
  sleep 0.25
done
(( opened == 1 )) || fail "inspector window did not open"
"$PROBE" "$APP_PID" press inspector-mode > "$WORK/inspector-mode.log" 2>&1 \
  || fail "command view press failed"
sleep 0.7
version="$(ax_value inspector-command-version)"
print -r -- "$version" | grep -q "CURRENT" || fail "command view is not current: $version"
print -r -- "$version" | grep -q "accepted=" || fail "command view has no accepted version: $version"
row="$("$PROBE" "$APP_PID" dump 400 2>/dev/null | awk -F'|' '/^AXButton\|inspector-command-[0-9]+-[0-9]+$/{print $2; exit}')"
[[ -n "$row" ]] || fail "command view has no command row"
"$PROBE" "$APP_PID" press "$row" > "$WORK/inspector-row.log" 2>&1 || fail "command row press failed"
sleep 0.5
detail="$(ax_value inspector-command-id)"
print -r -- "$detail" | grep -q "starter.add" || fail "selected row is not starter.add: $detail"
state="$(ax_value inspector-command-state)"
print -r -- "$state" | grep -q "kind=action" || fail "command state missing kind fact: $state"
print -r -- "$state" | grep -q "enabled=true" || fail "command state missing enabled: $state"
print -r -- "$state" | grep -q "accepted=" || fail "command state missing accepted: $state"
print -r -- "$state" | grep -q "publication=" || fail "command state missing publication: $state"
log "step2 inspector_version=$(print -r -- "$version" | head -1) row_id=$(print -r -- "$detail" | head -1)"

WINDOW_ID_TOOL="$WORK/window_id_for_pid"
cat > "$WORK/window_id_for_pid.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for entry in list {
    if let owner = entry[kCGWindowOwnerPID as String] as? Int32, owner == pid,
       let number = entry[kCGWindowNumber as String] as? Int, let layer = entry[kCGWindowLayer as String] as? Int, layer == 0,
       let bounds = entry[kCGWindowBounds as String] as? [String: Any],
       let height = bounds["Height"] as? Double, height > 100 {
        print(number)
    }
}
SWIFT
swiftc -O "$WORK/window_id_for_pid.swift" -o "$WINDOW_ID_TOOL" > "$WORK/window-build.log" 2>&1 || blocked "window id tool build failed"
wid=0
index=0
while read -r id; do
  [[ "$id" == <-> ]] || continue
  index=$((index + 1))
  screencapture -x -l "$id" "$WORK/template-window-$index.png" >/dev/null 2>&1 || true
  [[ -f "$WORK/template-window-$index.png" ]] && log "shot template-window-$index file=$WORK/template-window-$index.png bytes=$(stat -f %z "$WORK/template-window-$index.png")"
done < <("$WINDOW_ID_TOOL" "$APP_PID")
(( index >= 2 )) || fail "expected business and inspector windows, saw $index"

"$PROBE" "$APP_PID" press command-surface-toolbar-starter-close > "$WORK/close.log" 2>&1 \
  || blocked "template close command press failed"
waited=0
while (( waited < 40 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.25; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "template app did not exit after close command"
APP_PID=""
log "step3 close_command=starter.close app_exited=1"
log "PASS template=command-surface command+inspector+close"
