#!/usr/bin/env zsh
# The same rule-set consumer, through its NORMAL window: create two records
# with real clicks, edit the rendered one through the CONVERGED public detail
# with real keys, Apply, save to a file from the retention page, close, reopen
# with --open, and read the SAME applied values back exactly.
set -u
SCRIPT_DIR="${0:A:h}"
RUNTIME_DIR="${CJGUI_SDK_RUNTIME:-${SCRIPT_DIR:h:h}}"
APP_DIR="${CJGUI_RULE_APP_DIR:-$RUNTIME_DIR/examples/rule_set_window_app}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
WORK="${CJGUI_RULE_PERSIST_TMPDIR:-/private/tmp/cjgui-rule-persist-$(date +%H%M%S)-$$}"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" | tee -a "$LOG"; }
fail() { log "FAIL $*"; exit 1; }
blocked() { log "BLOCKED $*"; exit 3; }

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh" >/dev/null 2>&1
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
[[ "${LOCK_STATE//[[:space:]]/}" == "Yes" ]] && blocked "session locked"

# --- tools -----------------------------------------------------------------
AX="$WORK/ax_node_probe"
swiftc -O "${CJGUI_AX_PROBE_SOURCE:-/Users/jiangxuanyang/Desktop/Pharos Mark/tools/ax_node_probe.swift}" -o "$AX" > "$WORK/ax-build.log" 2>&1 || \
  blocked "AX probe build failed"
DRIVER_SOURCE="${CJGUI_INPUT_DRIVER_SOURCE:-$RUNTIME_DIR/native/tests/desktop_input_driver.swift}"
swiftc -O "$DRIVER_SOURCE" -o "$WORK/driver" > "$WORK/driver-build.log" 2>&1 || blocked "input driver build failed"
cat > "$WORK/left.swift" <<'S'
import CoreGraphics
import Foundation
let a = CommandLine.arguments
let p = CGPoint(x: Double(a[1])!, y: Double(a[2])!)
for t in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
  CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
  usleep(40_000)
}
S
swiftc -O "$WORK/left.swift" -o "$WORK/left" > /dev/null 2>&1 || blocked "click helper build failed"
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
swiftc -O "$WORK/wheel_scroll.swift" -o "$WHEEL_SCROLL" > /dev/null 2>&1 || blocked "wheel helper build failed"
# The detail area scrolls as one public viewport; content below the fold (the
# public page's lower fields and its action row) is materialized only after a
# real wheel event, exactly as a human reveals it.
reveal_id() {
  local id="$1" frame="" i
  frame="$(frame_of "$id")"
  [[ -n "$frame" && "$frame" != "missing" ]] && { print -r -- "$frame"; return 0; }
  local sf; sf="$(frame_of rule-set-scroll)"
  [[ -n "$sf" && "$sf" != "missing" ]] || return 1
  local sx sy sw sh
  read -r sx sy sw sh <<< "$sf"
  local cx=$(( sx + sw / 2 )) cy=$(( sy + sh * 2 / 3 ))
  for i in {1..10}; do
    "$WHEEL_SCROLL" $cx $cy 3 > /dev/null 2>&1; sleep 0.1
    frame="$(frame_of "$id")"
    [[ -n "$frame" && "$frame" != "missing" ]] && { print -r -- "$frame"; return 0; }
  done
  for i in {1..16}; do
    "$WHEEL_SCROLL" $cx $cy -3 > /dev/null 2>&1; sleep 0.08
    frame="$(frame_of "$id")"
    [[ -n "$frame" && "$frame" != "missing" ]] && { print -r -- "$frame"; return 0; }
  done
  return 1
}

DETAIL_MODE="${CJGUI_PERSIST_DETAIL:-public}"
# The INPUT PLAN: what this run is supposed to produce. The reopen check compares
# the readback against THIS plan, not against whatever happened to be saved.
case "$DETAIL_MODE" in
  public) A_LABEL=甲; A_RETENTION=7; B_LABEL=乙; B_RETENTION=11 ;;
  basic|legacy) A_LABEL=甲; A_RETENTION=7; B_LABEL=乙; B_RETENTION=7 ;;
esac
PLAN_NOTE="legacy: label-only edits, retention left at the create default 7, Apply through the public invoke"
[[ "$DETAIL_MODE" == "public" ]] && PLAN_NOTE="public page: label+retention typed, Apply through the page's own button"
# public: the converged page (this round's layout); basic: the app's handwritten
# page; legacy: an OLD consumer whose public block still sits on the basic page.
[[ "$DETAIL_MODE" == "public" || "$DETAIL_MODE" == "basic" || "$DETAIL_MODE" == "legacy" ]] || \
  { log "FAIL unknown detail mode $DETAIL_MODE"; exit 1; }
TAG="Rp$(date +%H%M%S)"
ROUND="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND" "$RUNTIME_DIR" "CJGUIRuleSet" "$TAG" \
  "org.cangjie.cjgui.rule-set.example" || fail "application copy failed"
# The bundle name is whatever the runner produced from THIS source tree (an
# upgraded consumer may carry its own tag suffix): derive it after the build so
# the owned-input scope names the executable that actually runs.
APP_BUNDLE=""
EXEC=""
SAVE_PATH="$WORK/persisted-$TAG.ruleset"
APP_PID=""; DESCRIPTOR=""
cleanup() { [[ -n "${APP_PID:-}" ]] && cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$EXEC" "$ROUND" || true; }
trap cleanup EXIT

frame_of() { "$AX" "$APP_PID" find "$1" 2>/dev/null | sed -n 's/^frame=//p' | head -1; }
ax_text() { "$AX" "$APP_PID" find "$1" 2>/dev/null | sed -n '/value_begin/,/value_end/p' | sed '1d;$d'; }
click_at() { local f="$1"; [[ -n "$f" && "$f" != "missing" ]] || return 1; read -r x y w h <<< "$f"; "$WORK/left" $(( x + w / 2 )) $(( y + h / 2 )); sleep 0.35; }
click_id() { click_at "$(frame_of "$1")"; }
type_into() { # type_into <semantic id> <text>
  click_id "$1" || return 1
  "$WORK/driver" cmd-key 0 > /dev/null 2>&1 || return 1
  "$WORK/driver" type "$2" > /dev/null 2>&1 || return 1
  sleep 0.5
}
field_hex() { pub generated-fields 2>/dev/null | awk -v f="FIELD $1 " 'index($0,f)==1 {for(i=1;i<=NF;i++) if($i=="DRAFT_HEX") print $(i+1)}'; }
field_word() { pub generated-fields 2>/dev/null | awk -v f="FIELD $1 " -v w="$2" 'index($0,f)==1 {for(i=1;i<=NF;i++) if($i==w) print $(i+1)}'; }
text_of() { print -r -- "$1" | python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("","-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
ver() { pub get 2>/dev/null | awk '/^VERSION /{print $2}'; }
launch_app() { # launch_app <label> [extra args...]
  local label="$1"; shift
  ( cd "$ROUND" && nohup zsh run.sh "$@" > "$WORK/app-${label}.log" 2>&1 & )
}

# --- build + launch --------------------------------------------------------
( cd "$ROUND" && zsh run.sh --build-only > "$WORK/build.log" 2>&1 ) || fail "build failed: $(tail -3 "$WORK/build.log")"
APP_BUNDLE="$(ls -d "$ROUND"/target/release/*.app 2>/dev/null | head -1)"
[[ -n "$APP_BUNDLE" ]] || fail "no built app bundle"
EXEC="$(ls "$APP_BUNDLE"/Contents/MacOS/* 2>/dev/null | head -1)"
[[ -n "$EXEC" ]] || fail "no built executable"
launch_app initial
DESCRIPTOR="$(cjgui_wait_descriptor "$WORK/app-initial.log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 180)" || \
  fail "no descriptor: $(tail -5 "$WORK/app-initial.log")"
APP_PID="$(pgrep -f "$ROUND/target/release" | head -1)"
[[ -n "$APP_PID" ]] || fail "no app process"
open "$APP_BUNDLE" > /dev/null 2>&1 || true
sleep 2.0
APP_PID="$(pgrep -f "$ROUND/target/release" | head -1)"
osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $APP_PID) to true" > /dev/null 2>&1
sleep 1.2
SCOPE="$WORK/owned-input.json"
python3 - "$APP_PID" "$EXEC" "$SCOPE" <<'PY'
import json, os, sys, uuid
pid, exe, path = sys.argv[1:]
json.dump({"pid": int(pid), "nonce": uuid.uuid4().hex, "executable": exe}, open(path, "w"))
os.chmod(path, 0o600)
PY
export CJGUI_DRIVER_TARGET_PID="$APP_PID" CJGUI_DRIVER_TARGET_FILE="$SCOPE"
# A covering window can steal the first activation: retry with a real raise.
bound=0
for attempt in 1 2 3; do
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    try
      perform action \"AXRaise\" of window 1 of p
    end try
  end tell" > /dev/null 2>&1
  sleep 1.0
  if "$WORK/driver" bind-target "$SCOPE" > "$WORK/bind-$attempt.log" 2>&1; then bound=1; break; fi
done
[[ "$bound" == "1" ]] || blocked "owned bind failed: $(cat "$WORK"/bind-*.log 2>/dev/null | tail -1)"
log "launched pid=$APP_PID save_path=$SAVE_PATH"

# --- step1: create record A through the toolbar, edit+apply on the PUBLIC page
click_id create || fail "create button unreachable"
sleep 1.2
A_ID=1
if [[ "$DETAIL_MODE" == "public" ]]; then
  click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
  sleep 0.8
  reveal_id public-detail-label > /dev/null || fail "public detail label not reachable"
type_into public-detail-label "甲" || fail "public detail label not editable"
  reveal_id public-detail-retentionCount > /dev/null || fail "public detail retention not reachable"
type_into public-detail-retentionCount "7" || fail "public detail retention not editable"
  [[ "$(text_of "$(field_hex label)")" == "甲" ]] || fail "A label not in the owner: [$(text_of "$(field_hex label)")]"
  reveal_id public-detail-apply > /dev/null || fail "public detail apply button not reachable"
click_id public-detail-apply || fail "public detail apply button unreachable"
elif [[ "$DETAIL_MODE" == "basic" ]]; then
  click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable"
  sleep 0.8
  type_into field-label "甲" || fail "handwritten label not editable"
  type_into field-retentionCount "7" || fail "handwritten retention not editable"
  [[ "$(text_of "$(field_hex label)")" == "甲" ]] || fail "A label not in the owner: [$(text_of "$(field_hex label)")]"
  click_id apply || fail "handwritten apply button unreachable"
else
  # LEGACY (an OLD consumer tree): its public block is a presentation without a
  # routed writer, so the supported entry is the handwritten label; Apply goes
  # through the public invoke. Retention is left at the create default (7).
  click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable"
  sleep 0.8
  type_into field-label "甲" || fail "old interface handwritten label not editable"
  [[ "$(text_of "$(field_hex label)")" == "甲" ]] || fail "A label not in the owner: [$(text_of "$(field_hex label)")]"
  LEGACY_VERSION="$(field_word label VERSION)"
  pub invoke "$(ver)" APPLY_DRAFT --target "$A_ID" --arg expectedDraftVersion=INTEGER:"$LEGACY_VERSION" > "$WORK/apply-a.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/apply-a.log" || fail "A apply (legacy) failed: $(awk '/^REASON /{print $2}' "$WORK/apply-a.log")"
fi
sleep 1.0
log "step1 A created+edited+applied label=[${A_LABEL}] retention=[${A_RETENTION}] plan=${DETAIL_MODE}"

# --- step2: create record B (selected by the app), edit it the same way ----
click_id create || fail "create button unreachable (second)"
sleep 1.2
B_ID=2
if [[ "$DETAIL_MODE" == "public" ]]; then
  click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable (B)"
  sleep 0.8
  reveal_id public-detail-label > /dev/null || fail "public detail label not reachable (B)"
type_into public-detail-label "乙" || fail "public detail label not editable (B)"
  reveal_id public-detail-retentionCount > /dev/null || fail "public detail retention not reachable (B)"
type_into public-detail-retentionCount "11" || fail "public detail retention not editable (B)"
  [[ "$(text_of "$(field_hex label)")" == "乙" ]] || fail "B label not in the owner"
  reveal_id public-detail-apply > /dev/null || fail "public detail apply button not reachable (B)"
click_id public-detail-apply || fail "public detail apply button unreachable (B)"
elif [[ "$DETAIL_MODE" == "basic" ]]; then
  click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable (B)"
  sleep 0.8
  type_into field-label "乙" || fail "handwritten label not editable (B)"
  type_into field-retentionCount "11" || fail "handwritten retention not editable (B)"
  [[ "$(text_of "$(field_hex label)")" == "乙" ]] || fail "B label not in the owner"
  click_id apply || fail "handwritten apply button unreachable (B)"
else
  click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable (B)"
  sleep 0.8
  type_into field-label "乙" || fail "old interface handwritten label not editable (B)"
  [[ "$(text_of "$(field_hex label)")" == "乙" ]] || fail "B label not in the owner"
  LEGACY_VERSION="$(field_word label VERSION)"
  pub invoke "$(ver)" APPLY_DRAFT --target "$B_ID" --arg expectedDraftVersion=INTEGER:"$LEGACY_VERSION" > "$WORK/apply-b.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/apply-b.log" || fail "B apply (legacy) failed: $(awk '/^REASON /{print $2}' "$WORK/apply-b.log")"
fi
sleep 1.0
log "step2 B created+edited+applied label=[${B_LABEL}] retention=[${B_RETENTION}] plan=${DETAIL_MODE}"

# --- step3: pre-save exact readback of both records -----------------------
read_record() { # read_record <id> -> "label|retention|enabled|excluded|draftVersion|appliedVersion"
  pub invoke "$(ver)" SELECT_RECORD --target "$1" > /dev/null 2>&1 || true
  sleep 0.5
  print -r -- "$(text_of "$(field_hex label)")|$(text_of "$(field_hex retentionCount)")|$(text_of "$(field_hex enabled)")|$(text_of "$(field_hex excludedType)")"
}
A_BEFORE="$(read_record 1)"
B_BEFORE="$(read_record 2)"
log "step3 before_save A=[$A_BEFORE] B=[$B_BEFORE]"
A_EXPECT="${A_LABEL}|${A_RETENTION}|true|cache"
B_EXPECT="${B_LABEL}|${B_RETENTION}|true|cache"
[[ "$A_BEFORE" == "$A_EXPECT" ]] || \
  fail "A pre-save state [${A_BEFORE}] does not match the input plan [${A_EXPECT}]"
[[ "$B_BEFORE" == "$B_EXPECT" ]] || \
  fail "B pre-save state [${B_BEFORE}] does not match the input plan [${B_EXPECT}]"
log "step3 plan_checked A=[$A_BEFORE] B=[$B_BEFORE] note=${PLAN_NOTE}"

# --- step4: save from the retention page (real tab click + real path input)
click_id rule-detail-tabs-tab-retention || fail "retention tab unreachable"
sleep 0.8
type_into file-path "$SAVE_PATH" || fail "file path field not editable"
[[ "$(ax_text file-path)" == "$SAVE_PATH" ]] || fail "file path not in the field: [$(ax_text file-path)]"
click_id save-as || fail "save-as button unreachable"
sleep 1.2
[[ -f "$SAVE_PATH" ]] || fail "save produced no file: $(ls -l "$WORK" | tail -3)"
log "step4 saved bytes=$(wc -c < "$SAVE_PATH" | tr -d ' ') head=$(head -c 60 "$SAVE_PATH" | tr '\n' ' ')"

# --- step5: close through the app's own close action ----------------------
click_id close || fail "close button unreachable"
waited=0
while (( waited < 60 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$(( waited + 1 )); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after save+close"
APP_PID=""
log "step5 closed_after_save"

# --- step6: reopen the saved file and read the SAME values back -----------
launch_app reopen --open "$SAVE_PATH"
DESCRIPTOR="$(cjgui_wait_descriptor "$WORK/app-reopen.log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 180)" || \
  fail "reopened app published no descriptor: $(tail -5 "$WORK/app-reopen.log")"
APP_PID="$(pgrep -f "$ROUND/target/release" | head -1)"
[[ -n "$APP_PID" ]] || fail "reopened app process missing"
sleep 1.0
A_AFTER="$(read_record 1)"
B_AFTER="$(read_record 2)"
log "step6 after_reopen A=[$A_AFTER] B=[$B_AFTER]"
[[ "$A_AFTER" == "$A_EXPECT" ]] || fail "A after reopen [${A_AFTER}] does not match the input plan"
[[ "$B_AFTER" == "$B_EXPECT" ]] || fail "B after reopen [${B_AFTER}] does not match the input plan"
log "step7 exact_readback_against_plan A=[$A_AFTER] B=[$B_AFTER]"
# The reopened window is closed through its OWN close entry and must exit by
# itself; the EXIT trap only TERMs a window that failed to close (abnormal).
APP_PID="$(pgrep -f "$ROUND/target/release" | head -1)"
if [[ -n "$APP_PID" ]]; then
  click_id rule-detail-tabs-tab-retention || fail "retention tab unreachable after reopen"
  sleep 0.6
  click_id close || fail "close button unreachable after reopen"
  waited=0
  while (( waited < 60 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$(( waited + 1 )); done
  kill -0 "$APP_PID" 2>/dev/null && fail "reopened window did not close normally"
fi
APP_PID=""
log "step8 normal_close_after_reopen"
log "PASS rule_persistence_chain"
print -r -- "chain: PASS log=$LOG save=$SAVE_PATH"
