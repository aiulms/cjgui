#!/usr/bin/env zsh
# Independent position acceptance for the ordinary range_text_window_app.
# The oracle is a separate AppKit/TextKit view fed only the fixed corpus and
# the accepted body AX frame. Pointer/key actions are posted CGEvents; this is
# synthetic system input, not physical keyboard or IME acceptance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/range_text_window_app"
OUTPUT_DIR="${CJGUI_RANGE_TEXT_POSITION_TMPDIR:-/private/tmp/cjgui-range-text-window-position}"

LONG_RUN=""
for _ in {1..12}; do LONG_RUN+="abcdefghijklmnopqrstuvwxyz0123456789"; done
CORPUS="Soft wrap: SOFT_WRAP_RUN_${LONG_RUN}"$'\n'"Bidi: abc אבג xyz"$'\n'"Reverse insert: pre|XYZ"
EXPECTED="Soft wrap: SOFT_WRAP_RUN_${LONG_RUN}"$'\n'"Bidi: abc אבג xyz"$'\n'"Reverse insert: pre|Q"
export RANGE_TEXT_INITIAL="$CORPUS"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
if [[ -n "${CJ_GUI_SDKROOT:-}" && -d "$CJ_GUI_SDKROOT" ]]; then export SDKROOT="$CJ_GUI_SDKROOT"
else export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"; fi

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/position.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
field() { print -r -- "$1" | tr ' ' '\n' | awk -F= -v k="$2" '$1 == k {print $2; exit}'; }
fail() { log "FAIL $*"; tail -60 "$LOG"; echo "range text window position: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -60 "$LOG"; echo "range text window position: BLOCKED $1" >&2; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

APP_PID=""
ROUND_DIR="$WORK/round-app"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app/Contents/MacOS/CJGUIRangeTextPosition${RUN_TAG//-/}"
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
CANDIDATE_EXECS=("")
CANDIDATE_DIRS=("$ROUND_DIR")
CANDIDATE_DESCS=("")
cleanup() {
  if [[ -n "$APP_PID" ]]; then cjgui_terminate_owned "$APP_PID" "" "$ROUND_EXEC" "$ROUND_DIR" || true; fi
  cjgui_reclaim_candidates log || true
}
trap cleanup EXIT

session_locked && blocked "session locked; posted input cannot be delivered"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable"
DRIVER="$WORK/desktop_input_driver"
AX_PROBE="$WORK/ax_focus_probe"
ORACLE="$WORK/position_oracle"
for entry in \
  "$RUNTIME_DIR/native/tests/desktop_input_driver.swift:$DRIVER" \
  "$RUNTIME_DIR/native/tests/ax_focus_probe.swift:$AX_PROBE" \
  "$SCRIPT_DIR/range_text_window_position_oracle.swift:$ORACLE"; do
  source_file="${entry%%:*}"
  binary="${entry#*:}"
  [[ -f "$source_file" ]] || blocked "missing verification source $source_file"
  swiftc -O "$source_file" -o "$binary" > "$WORK/$(basename "$source_file").build.log" 2>&1 \
    || blocked "could not compile $(basename "$source_file")"
done
real_input_preflight || blocked "synthetic event permission refused"
log "step0 driver=ax_focus_probe=oracle=built preflight=granted input=CGEvent_synthetic physical_IME=not_claimed"

NAME="CJGUIRangeTextConsumer"
SUFFIX="Ps${RUN_TAG//-/}"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app/Contents/MacOS/${NAME}${SUFFIX}"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME" "$SUFFIX" \
  "org.cangjie.cjgui.range-text-consumer.example" || blocked "could not prepare round-owned app copy"
CANDIDATE_EXECS=("${NAME}${SUFFIX}")
[[ -x "$ROUND_DIR/run.sh" ]] || blocked "app copy has no run.sh"
STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && RANGE_TEXT_INITIAL="$CORPUS" nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )

waited=0
ready_line=""
while (( waited < 900 )); do
  ready_line="$(grep '^RANGE_TEXT_READY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$ready_line" ]] && break
  sleep 2; waited=$((waited + 2))
done
[[ -n "$ready_line" ]] || blocked "RANGE_TEXT_READY missing (see $STDOUT_LOG)"
ready_owner_bytes="$(field "$ready_line" owner_bytes)"
ready_mirror_bytes="$(field "$ready_line" mirror_bytes)"
seed_bytes="$(printf '%s' "$CORPUS" | wc -c | tr -d ' ')"
[[ "$ready_owner_bytes" == "$seed_bytes" && "$ready_mirror_bytes" == "$seed_bytes" ]] \
  || fail "fixed fixture did not become the full owner/session mirror: ready=$ready_line seed_bytes=$seed_bytes"
APP_PID="$(cjgui_unique_round_pid "${NAME}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "round-owned app pid missing"
cjgui_unique_round_owns "$APP_PID" "${NAME}${SUFFIX}" "$ROUND_DIR" || blocked "pid ownership mismatch"
AX_PID="$APP_PID"
AX_APP_PATH="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app"
export AX_APP_PATH
log "step1 pid=$APP_PID ready=$ready_line"

ax_value() { # semantic id -> full, untrimmed AX string value
  "$ORACLE" ax-value "$APP_PID" "$1" 2>/dev/null
}
status_field() {
  local name="$1" consumer_state
  consumer_state="$(ax_value range-text-status || true)"
  print -r -- "$consumer_state" | tr ' ' '\n' | awk -F= -v k="$name" '
    $1 == k {print $2; exit}
    k=="v" && $0 ~ /^v[0-9]+$/ {sub(/^v/, ""); print; exit}'
}
ax_range() { "$ORACLE" ax-range "$APP_PID" range-text-body 2>/dev/null | awk '/^ax_range /{loc="";len="";for(i=1;i<=NF;i++){if($i~/^location=/){sub(/^location=/,"",$i);loc=$i}if($i~/^length=/){sub(/^length=/,"",$i);len=$i}}if(loc!=""&&len!="")print loc "," len}'; }
wait_range() {
  local expected="$1" tries="${2:-20}" i=0 got=""
  while (( i < tries )); do
    got="$(ax_range || true)"
    [[ "$got" == "$expected" ]] && { print -r -- "$got"; return 0; }
    sleep 0.15; i=$((i + 1))
  done
  print -r -- "${got:-missing}"; return 1
}
click_oracle_point() { # oracle's quantized global screen point expected-range label
  local screen="$1" expected="$2" label="$3" sx sy
  sx="${screen%%,*}"; sy="${screen#*,}"
  drive click "$sx" "$sy" || blocked "$label click not delivered"
  local got
  got="$(wait_range "$expected" 25 || true)"
  [[ "$got" == "$expected" ]] || fail "$label hit mismatch expected=$expected actual=$got screen=$sx,$sy"
  log "hit label=$label screen=$sx,$sy range=$got source=CGEvent oracle=AppKit_TextKit"
}
move_oracle() { # point expected-range label keycode
  local point="$1" expected="$2" label="$3" key="$4" got
  click_oracle_point "$point" "${SOFT_HIT},0" "${label}_reset"
  drive key "$key" || blocked "$label key not delivered"
  got="$(wait_range "$expected" 25 || true)"
  [[ "$got" == "$expected" ]] || fail "$label mismatch expected=$expected actual=$got"
  log "move label=$label range=$got source=CGEvent oracle=AppKit_TextKit"
}

real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || true
activate_app
[[ "$(app_frontmost)" == "true" ]] || blocked "round app did not become frontmost"
BODY_FRAME="$(ax_identifier_frame range-text-body "text area")"
if [[ "$BODY_FRAME" == "missing" ]] || ! frame_is_positive "$BODY_FRAME"; then
  BODY_FRAME="$(ax_identifier_frame range-text-body "UI element")"
fi
frame_is_positive "$BODY_FRAME" || blocked "accepted body AX frame missing"
read -r BX BY BW BH <<< "$BODY_FRAME"
ORACLE_OUTPUT="$(POSITION_ORACLE_TEXT="$CORPUS" "$ORACLE" fixture "$BX" "$BY" "$BW" "$BH" 2>"$WORK/oracle.stderr")" \
  || fail "independent AppKit/TextKit oracle rejected the fixed fixture: $(cat "$WORK/oracle.stderr")"
print -r -- "$ORACLE_OUTPUT" > "$WORK/oracle.log"
ofield() { print -r -- "$ORACLE_OUTPUT" | awk -F= -v k="$1" '$1 == k {print $2; exit}'; }
SOFT_POINT="$(ofield soft_screen)"; SOFT_HIT="$(ofield soft_hit)"
BIDI_POINT="$(ofield bidi_screen)"; BIDI_HIT="$(ofield bidi_hit)"
[[ "$(ofield oracle)" == "AppKit_TextKit" && "$(ofield font)" == "system_13pt_uniform" ]] \
  || fail "oracle identity/style mismatch: $(ofield oracle) $(ofield font)"
[[ "$(ofield visual_line_count)" == <-> ]] && (( $(ofield visual_line_count) > 1 )) \
  || fail "fixture did not wrap in accepted viewport: lines=$(ofield visual_line_count) width=$BW"
[[ "$SOFT_POINT" == *,* && "$SOFT_HIT" == <-> && "$BIDI_POINT" == *,* && "$(ofield bidi_hit)" == <-> ]] \
  || fail "oracle outputs missing: $ORACLE_OUTPUT"
log "step2 fixture_seed_bytes=$(printf '%s' "$CORPUS" | wc -c | tr -d ' ') expected_owner_bytes=$(printf '%s' "$EXPECTED" | wc -c | tr -d ' ') body_ax=$BODY_FRAME text_container=$(ofield text_container) font=$(ofield font) visual_lines=$(ofield visual_line_count)"
log "oracle $(print -r -- "$ORACLE_OUTPUT" | tr '\n' ' ')"
log "fixture_hex=$(printf '%s' "$CORPUS" | od -An -tx1 | tr -d ' \n')"
log "expected_owner_hex=$(printf '%s' "$EXPECTED" | od -An -tx1 | tr -d ' \n')"

# Establish the normal editor focus by a real click, then compare pointer hits
# and each navigation direction against the independent TextKit calculation.
click_oracle_point "$SOFT_POINT" "${SOFT_HIT},0" "soft_wrap_hit"
FOCUS_LINES="$("$AX_PROBE" "$APP_PID" range-text-body 2>/dev/null || true)"
FOCUS_ROLE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{for(i=1;i<=NF;i++) if($i~/^role=/){sub(/^role=/,"",$i);print $i;exit}}')"
FOCUS_VALUE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{for(i=1;i<=NF;i++) if($i~/^focus=/){sub(/^focus=/,"",$i);print $i;exit}}')"
[[ "$FOCUS_ROLE" == "AXTextArea" && "$FOCUS_VALUE" == "1" ]] \
  || fail "ordinary editor adapter did not receive platform keyboard focus: $FOCUS_LINES"
log "focus app_role=$FOCUS_ROLE focused=$FOCUS_VALUE node=$(print -r -- "$FOCUS_LINES" | awk '/^node /{print;exit}')"
move_oracle "$SOFT_POINT" "$(ofield soft_left)" soft_wrap_left 123
move_oracle "$SOFT_POINT" "$(ofield soft_right)" soft_wrap_right 124
move_oracle "$SOFT_POINT" "$(ofield soft_up)" soft_wrap_up 126
move_oracle "$SOFT_POINT" "$(ofield soft_down)" soft_wrap_down 125
click_oracle_point "$BIDI_POINT" "${BIDI_HIT},0" "bidi_hit"
for direction in left right; do
  expected="$(ofield "bidi_${direction}")"
  key=124; [[ "$direction" == left ]] && key=123
  click_oracle_point "$BIDI_POINT" "${BIDI_HIT},0" "bidi_${direction}_reset"
  drive key "$key" || blocked "bidi $direction key not delivered"
  got="$(wait_range "$expected" 25 || true)"
  [[ "$got" == "$expected" ]] || fail "bidi $direction mismatch expected=$expected actual=$got"
  log "move label=bidi_$direction range=$got source=CGEvent oracle=AppKit_TextKit"
done
[[ "$(status_field v)" == "1" && "$(status_field edits)" == "0" && "$(status_field bytes)" == "$(printf '%s' "$CORPUS" | wc -c | tr -d ' ')" ]] \
  || fail "position-only actions changed owner: $(ax_value range-text-status)"
log "step3 position_oracle=pass soft_wrap=hit,left,right,up,down bidi=hit,left,right owner_writes=0"

# Reverse Shift insertion: place caret at full-document end, extend backwards
# over the final ASCII token, then replace that exact UTF-16 range with Q.
click_oracle_point "$SOFT_POINT" "${SOFT_HIT},0" "reverse_insert_focus"
drive shortcut command 125 || blocked "Command+Down was not delivered"
TEXT_LENGTH="$(ofield expected_utf16_length)"
[[ "$(wait_range "$TEXT_LENGTH,0" 25 || true)" == "$TEXT_LENGTH,0" ]] || fail "Command+Down did not place caret at document end"
drive shortcut shift 123 || blocked "Shift+Left #1 was not delivered"
drive shortcut shift 123 || blocked "Shift+Left #2 was not delivered"
drive shortcut shift 123 || blocked "Shift+Left #3 was not delivered"
EXPECTED_SELECTION="$((TEXT_LENGTH - 3)),3"
got="$(wait_range "$EXPECTED_SELECTION" 25 || true)"
[[ "$got" == "$EXPECTED_SELECTION" ]] || fail "reverse selection mismatch expected=$EXPECTED_SELECTION actual=$got"
[[ "$(status_field v)" == "1" && "$(status_field edits)" == "0" ]] || fail "reverse selection wrote owner before replacement"
drive type Q || blocked "replacement character Q was not delivered"
EXPECTED_BYTES="$(printf '%s' "$EXPECTED" | wc -c | tr -d ' ')"
waited=0
while (( waited < 60 )) && [[ "$(status_field v)" != "2" ]]; do sleep 0.25; waited=$((waited + 1)); done
[[ "$(status_field v)" == "2" && "$(status_field edits)" == "1" && "$(status_field bytes)" == "$EXPECTED_BYTES" ]] \
  || fail "reverse replacement owner counters mismatch: $(ax_value range-text-status)"
BODY_VALUE="$(ax_value range-text-body | tr '\r' '\n')"
[[ "$BODY_VALUE" == "$EXPECTED" ]] || fail "AX body differs from frozen expected full owner text"
log "step4 reverse_shift_replace=pass selected=$EXPECTED_SELECTION replacement=Q owner_version=2 edits=1 bytes=$EXPECTED_BYTES ax_owner_text=exact"

# Close only this round's normal app window and compare its own final source
# byte snapshot against the independently frozen expected corpus.
close_result="$(cjgui_ax 10 -e "tell application \"System Events\"
  set p to first process whose unix id is $AX_PID
  try
    click button 1 of window 1 of p
    return \"pressed\"
  on error
    return \"missing\"
  end try
end tell" 2>&1 | tail -1 || true)"
if [[ "$close_result" != "pressed" ]]; then
  window_frame="$(ax_window_frame)"
  [[ -n "$window_frame" && "$window_frame" != "missing" ]] || blocked "round-owned window has no closable frame"
  wx="$(print -r -- "$window_frame" | awk '{print $1}')"; wy="$(print -r -- "$window_frame" | awk '{print $2}')"
  drive click $((wx + 14)) $((wy + 14)) || blocked "could not close the round-owned window"
fi
waited=0; summary_line=""
while (( waited < 90 )); do
  summary_line="$(grep '^RANGE_TEXT_SUMMARY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$summary_line" ]] && break
  sleep 1; waited=$((waited + 1))
done
[[ -n "$summary_line" ]] || fail "owner terminal summary missing after window close"
owner_line="$(grep '^RANGE_TEXT_OWNER_HEX' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
expected_hex="$(printf '%s' "$EXPECTED" | od -An -tx1 | tr -d ' \n')"
[[ "$(field "$owner_line" hex)" == "$expected_hex" && "$(field "$owner_line" bytes)" == "$EXPECTED_BYTES" ]] \
  || fail "closed-window owner bytes differ from fixed complete oracle: $owner_line"
[[ "$(field "$summary_line" version)" == "2" && "$(field "$summary_line" applied)" == "1" && \
   "$(field "$summary_line" rejected)" == "0" && "$(field "$summary_line" leaked_range_events)" == "0" && \
   "$(field "$summary_line" session_accepted)" == "1" ]] \
  || fail "owner settlement mismatch: $summary_line"
log "step5 exact_owner_readback=$owner_line summary=$summary_line"
log "PASS source=range_text_window_app input=CGEvent_synthetic oracle=AppKit_TextKit soft_wrap=pass bidi=pass reverse_selection=pass owner_hex=$expected_hex"
echo "range text window position: PASS soft-wrap+bidi+reverse-selection owner_hex=$expected_hex log=$LOG"
exit 0
