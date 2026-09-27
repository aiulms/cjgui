#!/usr/bin/env zsh
# Integration skeleton for the PNG paste + real cross-window drag acceptance.
# The parent task supplies the built app and semantic AX/readback markers once
# the two consumers' public identifiers are fixed. This script is intentionally
# not part of a framework build and must be run only after that wiring exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
OUTPUT_DIR="${CJGUI_PNG_TRANSFER_TMPDIR:-/private/tmp/cjgui-png-transfer}/$RUN_TAG"
APP_DIR="${CJGUI_PNG_TRANSFER_APP_DIR:-}"
APP_EXEC_PATH="${CJGUI_PNG_TRANSFER_APP_EXEC_PATH:-}"
READY_MARKER="${CJGUI_PNG_TRANSFER_READY_MARKER:-}"
PASTE_TARGET_DESCRIPTION="${CJGUI_PNG_PASTE_TARGET_DESCRIPTION:-}"
DRAG_SOURCE_DESCRIPTION="${CJGUI_PNG_DRAG_SOURCE_DESCRIPTION:-}"
DROP_TARGET_DESCRIPTION="${CJGUI_PNG_DROP_TARGET_DESCRIPTION:-}"
PASTE_ACCEPT_PATTERN="${CJGUI_PNG_PASTE_ACCEPT_PATTERN:-}"
DROP_ACCEPT_PATTERN="${CJGUI_PNG_DROP_ACCEPT_PATTERN:-}"
APP_PID=""
GUARD=""
ORIGINAL_SNAPSHOT=""
EXPECTED_SNAPSHOT=""
CGDRAG=""

mkdir -p "$OUTPUT_DIR"
RUN_LOG="$OUTPUT_DIR/app.log"
DRIVER_LOG="$OUTPUT_DIR/driver.log"
RESULT_LOG="$OUTPUT_DIR/result.log"
: > "$DRIVER_LOG"
: > "$RESULT_LOG"
say() { print -r -- "$*" | tee -a "$RESULT_LOG"; }
fail() { say "FAIL $*"; exit 1; }

for required in APP_DIR APP_EXEC_PATH READY_MARKER PASTE_TARGET_DESCRIPTION \
  DRAG_SOURCE_DESCRIPTION DROP_TARGET_DESCRIPTION PASTE_ACCEPT_PATTERN DROP_ACCEPT_PATTERN; do
  [[ -n "${(P)required}" ]] || fail "missing required CJGUI_PNG_TRANSFER value: $required"
done
[[ -d "$APP_DIR" && -x "$APP_DIR/run.sh" && -x "$APP_EXEC_PATH" ]] \
  || fail "APP_DIR/run.sh or APP_EXEC_PATH is unavailable"

cleanup() {
  if [[ -n "$GUARD" && -n "$ORIGINAL_SNAPSHOT" && -n "$EXPECTED_SNAPSHOT" ]]; then
    "$GUARD" restore-if-current "$ORIGINAL_SNAPSHOT" "$EXPECTED_SNAPSHOT" \
      >> "$DRIVER_LOG" 2>&1 || true
  fi
  if [[ -n "$APP_PID" ]] && pid_is_ours; then
    osascript -e "tell application \"System Events\"
      set p to (first process whose unix id is $APP_PID)
      try
        perform action \"AXPress\" of (first button of window 1 of p whose subrole is \"AXCloseButton\")
      end try
    end tell" >> "$DRIVER_LOG" 2>&1 || true
    sleep 2
  fi
  if [[ -n "$APP_PID" ]] && pid_is_ours; then
    kill "$APP_PID" 2>/dev/null || true
    sleep 2
  fi
  if [[ -n "$APP_PID" ]] && pid_is_ours; then
    kill -9 "$APP_PID" 2>/dev/null || true
    sleep 1
  fi
  if [[ -n "$APP_PID" ]] && pid_is_ours; then
    say "cleanup=failed pid=$APP_PID executable=$APP_EXEC_PATH"
  fi
}
pid_is_ours() {
  [[ -n "$APP_PID" ]] && ps -p "$APP_PID" >/dev/null 2>&1 \
    && lsof -a -p "$APP_PID" -d txt -Fn 2>/dev/null | grep -Fxq "n$APP_EXEC_PATH"
}
trap cleanup EXIT

# This is the standard AppKit guard path: it snapshots the pre-run general
# pasteboard, writes public.png bytes, and restores only if bytes and count
# still match. Any foreign clipboard update survives cleanup.
GUARD="$OUTPUT_DIR/cjgui_clipboard_guard"
clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" \
  -o "$GUARD" 2>"$OUTPUT_DIR/guard-build.log" || fail "clipboard guard compile failed"
FIXTURE="$OUTPUT_DIR/png-near-limit.png"
EVIDENCE="$(python3 "$RUNTIME_DIR/native/tests/png_fixture.py" near-limit "$FIXTURE")" \
  || fail "near-limit PNG fixture generation failed"
PNG_SHA256="$(shasum -a 256 "$FIXTURE" | awk '{print $1}')"
PNG_BYTES="$(wc -c < "$FIXTURE" | tr -d ' ')"
say "fixture bytes=$PNG_BYTES sha256=$PNG_SHA256 evidence=$EVIDENCE"
ORIGINAL_SNAPSHOT="$OUTPUT_DIR/clipboard-original.plist"
EXPECTED_SNAPSHOT="$OUTPUT_DIR/clipboard-expected.plist"
"$GUARD" start-png "$ORIGINAL_SNAPSHOT" "$EXPECTED_SNAPSHOT" "$FIXTURE" \
  || fail "standard NSPasteboardTypePNG fixture write failed"
"$GUARD" is-current "$EXPECTED_SNAPSHOT" \
  || fail "pasteboard raw bytes/changeCount differ from the fixture"

# Reuse the combined-session CGEvent mouse path used by the established
# cross-window verifier. No AXPress operation stands in for the drag.
CGDRAG="$OUTPUT_DIR/cgdrag"
cat > "$OUTPUT_DIR/cgdrag.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let source = CGEventSource(stateID: .combinedSessionState)
func post(_ type: CGEventType, _ point: CGPoint, _ button: CGMouseButton = .left) {
    CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button)?.post(tap: .cghidEventTap)
    usleep(30_000)
}
let args = CommandLine.arguments
if args.count == 4 && args[1] == "click", let x = Double(args[2]), let y = Double(args[3]) {
    let p = CGPoint(x: x, y: y)
    post(.mouseMoved, p); post(.leftMouseDown, p); post(.leftMouseUp, p); exit(0)
}
if args.count == 2 && args[1] == "command-v" {
    let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
    down?.flags = .maskCommand; down?.post(tap: .cghidEventTap)
    let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
    up?.flags = .maskCommand; up?.post(tap: .cghidEventTap); exit(0)
}
guard args.count == 6 && args[1] == "drag", let x1 = Double(args[2]), let y1 = Double(args[3]),
      let x2 = Double(args[4]), let y2 = Double(args[5]) else { exit(2) }
let start = CGPoint(x: x1, y: y1), end = CGPoint(x: x2, y: y2)
post(.mouseMoved, start); post(.leftMouseDown, start); usleep(150_000)
for index in 1...60 {
    let t = Double(index) / 60.0
    post(.leftMouseDragged, CGPoint(x: start.x + (end.x - start.x) * t,
                                    y: start.y + (end.y - start.y) * t))
    usleep(20_000)
}
usleep(200_000); post(.leftMouseUp, end); usleep(100_000)
SWIFT
swiftc "$OUTPUT_DIR/cgdrag.swift" -o "$CGDRAG" 2>> "$DRIVER_LOG" \
  || fail "CGEvent driver compile failed"

( cd "$APP_DIR" && CJGUI_DATA_TRANSFER_TRACE=1 nohup zsh run.sh > "$RUN_LOG" 2>&1 & )
for _ in {1..40}; do
  grep -Fq "$READY_MARKER" "$RUN_LOG" 2>/dev/null && break
  sleep 0.5
done
grep -Fq "$READY_MARKER" "$RUN_LOG" 2>/dev/null || fail "application readiness marker was not observed"

# Resolve only the configured semantic AX descriptions. No guessed screen
# coordinates are used if the app fails to publish them.
APP_PID=""
for candidate in ${(f)"$(pgrep -f "$APP_EXEC_PATH" 2>/dev/null || true)"}; do
  if ps -p "$candidate" >/dev/null 2>&1 \
    && lsof -a -p "$candidate" -d txt -Fn 2>/dev/null | grep -Fxq "n$APP_EXEC_PATH"; then
    APP_PID="$candidate"
    break
  fi
done
[[ -n "$APP_PID" ]] || fail "could not identify the exact app executable PID"
print -r -- "$APP_PID" > "$OUTPUT_DIR/app.pid"

positions_for() {
  local description="$1"
  osascript - "$APP_PID" "$description" <<'OSA' 2>/dev/null
on run argv
  set pidText to item 1 of argv
  set wanted to item 2 of argv
  tell application "System Events"
    set p to (first process whose unix id is (pidText as integer))
    repeat with w in windows of p
      repeat with e in UI elements of w
        try
          if description of e is wanted then
            set pos to position of e
            set sz to size of e
            return (((item 1 of pos) + ((item 1 of sz) div 2)) as text) & " " & (((item 2 of pos) + ((item 2 of sz) div 2)) as text)
          end if
        end try
      end repeat
    end repeat
  end tell
  return ""
end run
OSA
}
paste_pos="$(positions_for "$PASTE_TARGET_DESCRIPTION")"
source_pos="$(positions_for "$DRAG_SOURCE_DESCRIPTION")"
drop_pos="$(positions_for "$DROP_TARGET_DESCRIPTION")"
[[ -n "$paste_pos" && -n "$source_pos" && -n "$drop_pos" ]] \
  || fail "configured paste/source/drop semantic AX target was not found"
print -r -- "paste=$paste_pos source=$source_pos drop=$drop_pos" > "$OUTPUT_DIR/positions.txt"
osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $APP_PID) to true" \
  >> "$DRIVER_LOG" 2>&1
"$CGDRAG" click ${(z)paste_pos} >> "$DRIVER_LOG" 2>&1
"$CGDRAG" command-v >> "$DRIVER_LOG" 2>&1
grep -Fq "$PASTE_ACCEPT_PATTERN" "$RUN_LOG" || fail "paste owner/accepted readback marker was not observed"

"$CGDRAG" click ${(z)source_pos} >> "$DRIVER_LOG" 2>&1
"$CGDRAG" drag ${(z)source_pos} ${(z)drop_pos} >> "$DRIVER_LOG" 2>&1
grep -Fq "$DROP_ACCEPT_PATTERN" "$RUN_LOG" || fail "cross-window drag accepted marker was not observed"
"$GUARD" is-current "$EXPECTED_SNAPSHOT" \
  || fail "general pasteboard changed during the guarded run; original will be preserved by refusal"
say "PASSED png paste + real cross-window drag pid=$APP_PID output=$OUTPUT_DIR"
