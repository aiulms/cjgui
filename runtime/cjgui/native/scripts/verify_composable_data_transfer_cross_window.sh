#!/usr/bin/env zsh
# Real same-process cross-window drag proof.
#
# Generates a minimal two-window application from the framework template
# (window A declares the transfer source "DRAG9", window B the target),
# builds it as a normal macOS bundle via run.sh, launches it, then performs
# a REAL mouse drag with posted CGEvent mouse-down/move/up (combined session
# event source) from the source button to the target button, and checks that
# the target owner received the payload.  Public application surface only;
# no test seam is linked.
#
# Bring-up notes: bare probe executables are invisible to the accessibility
# tree (no bundle, no regular activation policy), so the windows must live in
# a real bundle; System Events element "click" only performs AXPress (which
# cannot start a drag); the CGEvent source must use the combined session
# state; and the source button is clicked once to activate before the drag.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
OUTPUT_DIR="${CJGUI_COMPOSABLE_DATA_TRANSFER_CROSS_WINDOW_TMPDIR:-/private/tmp/cjgui-composable-data-transfer-cross-window}/$RUN_TAG"
APP_DIR="$OUTPUT_DIR/app"
APP_EXEC_NAME="CJGUICrossDrag$RUN_TAG"
APP_PID=""
CGDRAG="$OUTPUT_DIR/cgdrag"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
export SDKROOT="$SDKROOT_PATH"

# A locked session cannot deliver the posted CGEvent mouse drag this script is
# built around: the target never reports draggingEntered and the script would
# exit 1 ("A2 invalid"), which is an environment precondition misread as a
# product failure. Report the measured lock as BLOCKED (exit 3) instead; the
# sweep classifies exit 3 as BLOCKED.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "cross-window drag probe: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); posted CGEvent drags cannot reach the target window" >&2
  exit 3
fi

mkdir -p "$OUTPUT_DIR"

# --- generate + build the two-window application --------------------------
rm -rf "$APP_DIR"
zsh "$RUNTIME_DIR/scripts/create_macos_application.sh" ui-only "$APP_DIR" --framework "$RUNTIME_DIR" \
  > "$OUTPUT_DIR/create.log" 2>&1

python3 - "$APP_DIR" "$RUNTIME_DIR" "$RUN_TAG" <<'PYFIX'
import os
import re
import sys
app, runtime, tag = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(f"{app}/cjpm.toml").read()
s = re.sub(r'cjgui = \{ path = "[^"]+" \}',
           f'cjgui = {{ path = "{runtime}" }}\n'
           f'cjgui_shared_operation_core = {{ path = "{runtime}/shared_operation_core" }}',
           s, count=1)
open(f"{app}/cjpm.toml", "w").write(s)
m = open(f"{app}/cjgui_macos_app.sh").read()
m = m.replace("CJGUIUiOnlyStarter", f"CJGUICrossDrag{tag}")
m = m.replace("org.example.cjgui.ui-only-starter",
              f"org.cangjie.cjgui.cross-drag.e2e.{tag}")
open(f"{app}/cjgui_macos_app.sh", "w").write(m)
PYFIX

cat > "$APP_DIR/src/main.cj" <<'MAIN'
// Cross-window drag consumer: two windows of one normal application host.
// Window A declares the transfer source (payload DRAG9), window B the
// target. The verifier performs a real mouse drag between the two visible
// windows; this application only reports what the target owner received.
package cjgui_ui_only_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

public class CrossDragReadback {
    public var drops: Int64 = 0
    public var lastPayload: String = ""
}

public class CrossDragSourceOwner <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private var revision: Int64 = 1
    private var workspace: ?CjguiTextDocumentWorkspace = None
    public init() {}
    public func bindWorkspace(workspace: CjguiTextDocumentWorkspace): Unit {
        this.workspace = Some(workspace)
    }
    public func externalWorkspace(): ?CjguiTextDocumentWorkspace {
        return workspace
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "cross-source-root",
            CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "cross-source-title", "拖动源窗口",
            CjguiComposableUiStyle(fontSize: 15.0)))
        root.add(cjguiComposableButton(13, "cross-source-button", "拖动源",
            "TRANSFER_COPY", 21, CjguiComposableUiStyle(fixedHeight: 32), enabled: true))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (let Some(offer) <- CjguiSharedOperationTransferOffer.create(
            "COPY", "cross_drag_source", "cross-drag-session", 21,
            CjguiSharedOperationTransferFormat.utf8Text(), "DRAG9")) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source("cross-source-button", offer))
        }
        return declarations
    }
    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }
}

public class CrossDragTargetOwner <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private var revision: Int64 = 1
    private let readback: CrossDragReadback
    public init(readback: CrossDragReadback) { this.readback = readback }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "cross-target-root",
            CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "cross-target-title", "拖动目标窗口",
            CjguiComposableUiStyle(fontSize: 15.0)))
        root.add(cjguiComposableButton(14, "cross-target-button", "拖动目标",
            "TRANSFER_DROP", 22, CjguiComposableUiStyle(fixedHeight: 32), enabled: true))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        declarations.add(CjguiComposableUiDataTransferDeclaration.target(
            "cross-target-button", CjguiSharedOperationTransferFormat.utf8Text()))
        return declarations
    }
    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP) {
            readback.drops += 1
            readback.lastPayload = event.offer.payload
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
}

main(): Int64 {
    let readback = CrossDragReadback()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let sourceOwner = CrossDragSourceOwner()
    let targetOwner = CrossDragTargetOwner(readback)
    // A2 fairness experiment: the source window owns a real workspace so an
    // authorized external client can mutate it through the public UDS while
    // the drag is held over the target window.
    let sourceWorkspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(31, "公平性探针", "A2|")
    ]))
    sourceOwner.bindWorkspace(sourceWorkspace)
    let sourceOpen = application.openWindow(sourceOwner,
        configuration: CjguiMacosApplicationWindowConfiguration("Cross Source", 420u32, 220u32))
    let targetOpen = application.openWindow(targetOwner,
        configuration: CjguiMacosApplicationWindowConfiguration("Cross Target", 420u32, 220u32))
    if (!sourceOpen.didOpen || !targetOpen.didOpen) {
        application.close()
        return 2
    }
    let sourceId = if (let Some(value) <- sourceOpen.identifier) { value } else { application.close(); return 2 }
    let sourceWindow = if (let Some(value) <- application.window(sourceId)) { value } else { application.close(); return 2 }
    // A2: authorized external clients mutate the SOURCE window's workspace
    // through the public UDS connection while the drag is held.
    let connectionAuthorization = CjguiSharedOperationExternalAuthorization(
        "cross-drag-external", "cross-drag-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([31]), false),
            CjguiSharedOperationExternalActionScope("REPLACE_RANGE", ArrayList<Int64>([31]), false)
        ]))
    let connection = CjguiSharedOperationExternalConnection(sourceWorkspace, connectionAuthorization, sourceWorkspace, sourceWindow)
    if (!connection.enableTargetedContextReads(sourceWorkspace) || !connection.enableRangeReads(sourceWorkspace) ||
        !application.attachExternalConnection(connection)) {
        application.close()
        return 2
    }
    let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
    println("CJGUI_CROSS_DRAG_READY")
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_CROSS_DRAG_DESCRIPTOR ${info.descriptorPath}")
    }
    getStdOut().flush()
    // The verifier performs the real mouse drag while this loop pumps.
    var turns: Int64 = 0
    while (turns < 11000 && readback.drops == 0) {
        let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
        sleep(Duration.millisecond * 8)
        turns += 1
    }
    let passed = readback.drops >= 1 && readback.lastPayload == "DRAG9"
    println("CJGUI_CROSS_DRAG_RESULT drops=${readback.drops} payload=${readback.lastPayload} passed=${passed}")
    getStdOut().flush()
    application.close()
    return if (passed) { 0 } else { 1 }
}
MAIN

# --- real-mouse driver ----------------------------------------------------
cat > "$OUTPUT_DIR/cgdrag.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let source = CGEventSource(stateID: .combinedSessionState)
func post(_ type: CGEventType, _ point: CGPoint, button: CGMouseButton = .left) {
    let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button)
    event?.post(tap: .cghidEventTap)
    usleep(30_000)
}
let args = CommandLine.arguments
guard args.count >= 4 else {
    fputs("usage: cgdrag click X Y | cgdrag drag X1 Y1 X2 Y2\n", stderr)
    exit(2)
}
if args[1] == "hold" {
    guard args.count == 7, let x1 = Double(args[2]), let y1 = Double(args[3]),
          let x2 = Double(args[4]), let y2 = Double(args[5]),
          let holdMs = Double(args[6]) else { exit(2); }
    let start = CGPoint(x: x1, y: y1)
    let end = CGPoint(x: x2, y: y2)
    post(.mouseMoved, start)
    post(.leftMouseDown, start)
    usleep(150_000)
    let steps = 60
    for index in 1...steps {
        let t = Double(index) / Double(steps)
        let p = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
        post(.leftMouseDragged, p)
        usleep(20_000)
    }
    // Hold inside the target: keep the drag session alive without moving so
    // the verifier can run an external operation during AppKit tracking.
    print("HOLD_START \(DispatchTime.now().uptimeNanoseconds)")
    fflush(stdout)
    let holdTicks = Int(holdMs / 100.0)
    for _ in 1...holdTicks {
        post(.leftMouseDragged, end)
        usleep(100_000)
    }
    post(.leftMouseUp, end)
    usleep(100_000)
    print("UP \(DispatchTime.now().uptimeNanoseconds)")
    fflush(stdout)
    exit(0)
}
if args[1] == "click" {
    guard let cx = Double(args[2]), let cy = Double(args[3]) else { exit(2); }
    let p = CGPoint(x: cx, y: cy)
    post(.mouseMoved, p)
    post(.leftMouseDown, p)
    usleep(60_000)
    post(.leftMouseUp, p)
    exit(0)
}
guard args.count == 6, args[1] == "drag", let x1 = Double(args[2]), let y1 = Double(args[3]),
      let x2 = Double(args[4]), let y2 = Double(args[5]) else {
    fputs("usage: cgdrag click X Y | cgdrag drag X1 Y1 X2 Y2\n", stderr)
    exit(2)
}
let start = CGPoint(x: x1, y: y1)
let end = CGPoint(x: x2, y: y2)
post(.mouseMoved, start)
post(.leftMouseDown, start)
usleep(150_000)
let steps = 60
for index in 1...steps {
    let t = Double(index) / Double(steps)
    let p = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
    post(.leftMouseDragged, p)
    usleep(20_000)
}
usleep(200_000)
post(.leftMouseUp, end)
usleep(100_000)
SWIFT
swiftc "$OUTPUT_DIR/cgdrag.swift" -o "$CGDRAG" 2>> "$OUTPUT_DIR/driver.log" || {
  echo "cross-window drag probe: cgdrag build failed" >&2
  exit 2
}

# --- run ------------------------------------------------------------------
RUN_LOG="$OUTPUT_DIR/probe.log"
( cd "$APP_DIR" && CJGUI_DATA_TRANSFER_TRACE=1 nohup zsh run.sh > "$RUN_LOG" 2>&1 & )
pid_is_ours() {
  [[ -n "${APP_PID:-}" ]] && ps -p "$APP_PID" -o comm= 2>/dev/null | grep -q "$APP_EXEC_NAME"
}
cleanup() {
  restore_guard_result=""
  if pid_is_ours; then
    osascript -e "tell application \"System Events\"
      set p to (first process whose unix id is $APP_PID)
      try
        perform action \"AXPress\" of (first button of window 1 of p whose subrole is \"AXCloseButton\")
      end try
    end tell" >> "$OUTPUT_DIR/driver.log" 2>&1 || true
    sleep 2
  fi
  if pid_is_ours; then
    kill "$APP_PID" 2>/dev/null || true
    sleep 2
  fi
  if pid_is_ours; then
    kill -9 "$APP_PID" 2>/dev/null || true
    sleep 1
  fi
  if pid_is_ours; then
    echo "cross-window drag probe: cleanup instance still alive" >&2
  fi
}
trap cleanup EXIT
PROBE_OK=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  grep -q 'CJGUI_CROSS_DRAG_DESCRIPTOR' "$RUN_LOG" 2>/dev/null && { PROBE_OK=1; break; }
  sleep 2
done
if [[ -z "$PROBE_OK" ]]; then
  echo "cross-window drag probe: not ready" >&2
  exit 1
fi
APP_PID="$(pgrep -f "$APP_DIR" | head -1 || true)"
if [[ -z "$APP_PID" ]] || ! ps -p "$APP_PID" -o comm= 2>/dev/null | grep -q "$APP_EXEC_NAME"; then
  echo "cross-window drag probe: application pid not identified" >&2
  exit 1
fi
printf '%s\n' "$APP_PID" > "$OUTPUT_DIR/app.pid"
DESCRIPTOR="$(grep 'CJGUI_CROSS_DRAG_DESCRIPTOR' "$RUN_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
if [[ -z "$DESCRIPTOR" || ! -f "$DESCRIPTOR" ]]; then
  echo "cross-window drag probe: external descriptor missing" >&2
  exit 1
fi
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

# The accessibility tree appears slightly after launch; retry.
POSITIONS=""
for _ in 1 2 3 4 5 6 7 8; do
  POSITIONS="$(osascript -e "tell application \"System Events\"
    set p to (first process whose unix id is $APP_PID)
    set out to \"\"
    repeat with w in windows of p
      repeat with e in UI elements of w
        try
          set d to description of e
          if d is \"拖动源\" or d is \"拖动目标\" then
            set pos to position of e
            set sz to size of e
            set out to out & d & \" \" & ((item 1 of pos) + ((item 1 of sz) div 2)) & \" \" & ((item 2 of pos) + ((item 2 of sz) div 2)) & linefeed
          end if
        end try
      end repeat
    end repeat
    return out
  end tell" 2>/dev/null || true)"
  [[ -n "$POSITIONS" ]] && break
  sleep 1
done
echo "$POSITIONS" > "$OUTPUT_DIR/button-positions.txt"
SRC_X="$(print -r -- "$POSITIONS" | awk '$1=="拖动源"{print $2}')"
SRC_Y="$(print -r -- "$POSITIONS" | awk '$1=="拖动源"{print $3}')"
DST_X="$(print -r -- "$POSITIONS" | awk '$1=="拖动目标"{print $2}')"
DST_Y="$(print -r -- "$POSITIONS" | awk '$1=="拖动目标"{print $3}')"
if [[ -z "$SRC_X" || -z "$DST_X" ]]; then
  # Deterministic fallback: the two-window host layout is stable on this
  # display (verified by prior AX reads), so a transient accessibility
  # failure does not have to stop the experiment.
  echo "AX enumeration unavailable; using layout fallback positions" >> "$OUTPUT_DIR/driver.log"
  SRC_X=756; SRC_Y=280; DST_X=1200; DST_Y=280
fi

osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $APP_PID) to true" \
  >> "$OUTPUT_DIR/driver.log" 2>&1
sleep 0.5
"$CGDRAG" click "$SRC_X" "$SRC_Y" >> "$OUTPUT_DIR/driver.log" 2>&1
sleep 0.4

# A2 fairness: hold the drag inside the target for 3s while an independent,
# authorized client performs a REPLACE_RANGE on the SOURCE window through
# the public UDS. Timestamps show whether the mutation completed during the
# hold (fair scheduling) or only after the drag ended.
HOLD_MS=3000
A2_TIMELINE="$OUTPUT_DIR/a2-timeline.log"
: > "$A2_TIMELINE"
"$CGDRAG" hold "$SRC_X" "$SRC_Y" "$DST_X" "$DST_Y" "$HOLD_MS" > "$OUTPUT_DIR/a2-cgdrag.log" 2>&1 &
DRAG_JOB=$!
# Gate on the real system event: the target must report draggingEntered
# before the external operation is sent; a fixed sleep proves nothing.
T_ENTERED_SEEN=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  if grep -q 'transfer target entered' "$RUN_LOG" 2>/dev/null; then
    T_ENTERED_SEEN="$(python3 -c 'import time; print(time.monotonic_ns())')"
    break
  fi
  kill -0 "$DRAG_JOB" 2>/dev/null || break
  sleep 0.25
done
if [[ -z "$T_ENTERED_SEEN" ]]; then
  print -r -- "A2 INVALID experiment: target never entered (drag delivery failed)" >> "$A2_TIMELINE"
  wait "$DRAG_JOB" 2>/dev/null || true
  echo "cross-window drag probe: A2 invalid (no target enter)" >&2
  exit 1
fi
T_REQUEST="$(python3 -c 'import time; print(time.monotonic_ns())')"
EXT_LOG="$OUTPUT_DIR/a2-external-op.log"
python3 "$CLIENT" "$DESCRIPTOR" invoke 0 REPLACE_RANGE --target 31 \
  --arg start=INTEGER:0 --arg end=INTEGER:3 --arg text=STRING:"A2EXT|" \
  > "$EXT_LOG" 2>&1
EXT_EXIT=$?
T_REPLY="$(python3 -c 'import time; print(time.monotonic_ns())')"
DRAG_ALIVE_AT_REPLY=0
kill -0 "$DRAG_JOB" 2>/dev/null && DRAG_ALIVE_AT_REPLY=1
wait "$DRAG_JOB" 2>/dev/null || true
T_UP="$(python3 -c 'import time; print(time.monotonic_ns())')"
HOLD_START="$(grep -o 'HOLD_START [0-9]*' "$OUTPUT_DIR/a2-cgdrag.log" 2>/dev/null | awk '{print $2}' | head -1 || true)"
UP_TS="$(grep -o 'UP [0-9]*' "$OUTPUT_DIR/a2-cgdrag.log" 2>/dev/null | awk '{print $2}' | head -1 || true)"
print -r -- "A2 monotonic: entered_seen=$T_ENTERED_SEEN request=$T_REQUEST reply=$T_REPLY up=$T_UP " \
  >> "$A2_TIMELINE"
print -r -- "A2 cgdrag: hold_start=${HOLD_START:-none} up=${UP_TS:-none} ext_exit=$EXT_EXIT " \
  >> "$A2_TIMELINE"
print -r -- "A2 drag_alive_at_reply=$DRAG_ALIVE_AT_REPLY" >> "$A2_TIMELINE"
cat "$EXT_LOG" >> "$A2_TIMELINE"
if [[ "$EXT_EXIT" != 0 || "$DRAG_ALIVE_AT_REPLY" != 1 ]]; then
  echo "cross-window drag probe: A2 external client did not complete during the hold" >&2
  exit 1
fi

RESULT=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  RESULT="$(grep 'CJGUI_CROSS_DRAG_RESULT' "$RUN_LOG" 2>/dev/null || true)"
  [[ -n "$RESULT" ]] && break
  sleep 1
done
tail -3 "$RUN_LOG"
if print -r -- "$RESULT" | grep -q 'passed=true'; then
  print -r -- "cross-window drag probe: raw_log=$RUN_LOG status=0"
  exit 0
fi
print -r -- "cross-window drag probe: raw_log=$RUN_LOG status=1"
exit 1
