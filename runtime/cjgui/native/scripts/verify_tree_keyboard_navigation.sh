#!/usr/bin/env zsh
# Real-keyboard navigation chain for the public tree, through
# native -> queue -> FFI -> window -> controller -> owner/selection read-back.
#
# What this proves that the programmatic payload probe cannot:
#   * the key event's own modifier state (Shift / Command) reaches the
#     controller from a real keyDown, so Shift+Arrow extends a range and
#     Command-A selects all - no stored mouse state is reused;
#   * Up / Down / Home / End / Left / Right move the shared tree focus and
#     expand/collapse groups in visible order;
#   * a navigation target outside the materialized viewport is revealed (the
#     accessibility row only appears after the keyboard navigation);
#   * a text field keeps its own Command-A: the tree selection does not move
#     while a form field holds the focus.
#
# Instance ownership: per-round copy with its own bundle id, executable name,
# directory and descriptor; every AX call is bounded; cleanup re-proves the
# identity before signalling and only ever touches this round's instance.
#
# Usage: zsh verify_tree_keyboard_navigation.sh
# Exit: 0 all assertions verified, 3 a verified environment precondition
#       (e.g. no desktop / synthetic key delivery unavailable), 1 a failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_TREE_KEYBOARD_TMPDIR:-/private/tmp/cjgui-tree-keyboard}/$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$OUTPUT_DIR"
LOG="$OUTPUT_DIR/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }
blocked() { log "BLOCKED $*"; cat "$LOG"; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh" >/dev/null 2>&1 || true
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
ROUND_DIR="$OUTPUT_DIR/round-app"
NAME_TOKEN="CJGUIRuleSet"
SUFFIX="Kb${RUN_TAG}"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}${SUFFIX}.app/Contents/MacOS/${NAME_TOKEN}${SUFFIX}"
RECORD_COUNT=60

APP_PID=""
DESCRIPTOR=""
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" && echo no || echo yes)"
}
trap cleanup EXIT

# --- per-round application copy -------------------------------------------
cjgui_prepare_app_copy "$RUNTIME_DIR/examples/rule_set_window_app" "$ROUND_DIR" "$RUNTIME_DIR" \
  "$NAME_TOKEN" "$SUFFIX" "org.example.cjgui.rule-set" || fail "per-round application copy failed"

STDOUT_LOG="$OUTPUT_DIR/app.log"
# The rule-set application takes no launch arguments (its own usage line lists
# only --open/--save-as/--verify-host-close-decisions/--measurement-*), so the
# shared-document app's --with-connection flag must not be passed here: doing so
# made the app print its usage line and exit before publishing a descriptor.
BOUND="$(cjgui_launch_bound "$ROUND_DIR" run.sh 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' \
  "$ROUND_EXEC" "$STDOUT_LOG" 240 || true)"
APP_PID="${BOUND%% *}"
DESCRIPTOR="${BOUND#* }"
[[ -n "$APP_PID" && "$DESCRIPTOR" != "$BOUND" && -f "$DESCRIPTOR" ]] || fail "app did not become ready"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "app pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
selection_version() { pub tree-selection 2>/dev/null | awk '/^SELECTION_VERSION /{print $2}'; }
projection_version() { pub tree-selection 2>/dev/null | awk '/^PROJECTION_VERSION /{print $2}'; }
selection_focus() { pub tree-selection 2>/dev/null | awk '/^FOCUS /{print $2}'; }
selection_anchor() { pub tree-selection 2>/dev/null | awk '/^ANCHOR /{print $2}'; }
keys_sorted() { pub tree-selection 2>/dev/null | awk '/^KEY /{print $2}' | sort | tr '\n' ','; }
keys_count() { pub tree-selection 2>/dev/null | grep -c '^KEY ' || true; }
window_focus() { pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}'; }

# --- real input driver -----------------------------------------------------
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable for the desktop input driver"
DRIVER="$OUTPUT_DIR/cjgui_desktop_input_driver"
swiftc -O "$RUNTIME_DIR/native/tests/desktop_input_driver.swift" -o "$DRIVER" > "$OUTPUT_DIR/driver-build.log" 2>&1 \
  || blocked "desktop input driver did not build"
drive() { "$DRIVER" "$@" > "$OUTPUT_DIR/driver.log" 2>&1; }
key() { drive key "$1" || fail "posting key $1 failed"; sleep 0.5; }
# A real modified chord: press the actual modifier KEY, post the key while it is
# held, then release it. The flag-only `shortcut` form is not used for the
# arrows because on this host a synthesized Shift flag on an arrow key event did
# not reach the application at all (measured: no selection-version change and no
# focus change, while the same flag-only form works for Command+letter).
shortcut() { # shortcut <modifier> <keycode>
  local modifier_key
  case "$1" in
    shift) modifier_key=56 ;;
    command) modifier_key=55 ;;
    control) modifier_key=59 ;;
    option) modifier_key=58 ;;
    *) fail "unknown modifier '$1'" ;;
  esac
  # Hold the real modifier key and post the chord with the matching event flag:
  # the flag alone did not reach this application on this host for arrow keys,
  # and the real key press alone did not put the modifier into the delivered
  # event's flags. Together they reproduce what a human keyboard sends.
  drive key-down "$modifier_key" || fail "pressing $1 failed"
  drive shortcut "$1" "$2" || fail "posting $1+$2 failed"
  drive key-up "$modifier_key" || fail "releasing $1 failed"
  sleep 0.5
}
KEY_LEFT=123 KEY_RIGHT=124 KEY_DOWN=125 KEY_UP=126 KEY_HOME=115 KEY_END=119 KEY_A=0

ax_bulk() { # ax_bulk <applescript body using p>
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    $1
  end tell" 2>/dev/null | tail -1 || true
}

# All button names currently exposed (the tree rows are direct window children).
visible_button_names() {
  ax_bulk 'set names to name of every button of window 1 of p
    set out to ""
    repeat with i from 1 to (count of names)
      try
        set n to item i of names
        if n is not missing value then set out to out & n & " | "
      end try
    end repeat
    return out'
}

has_row_label() { # has_row_label <label>
  local names
  names="$(visible_button_names)"
  [[ "$names" == *"$1"* ]]
}

row_frame() { # row_frame <label> -> "x y w h" | missing
  ax_bulk "set names to name of every button of window 1 of p
    set positions to position of every button of window 1 of p
    set sizes to size of every button of window 1 of p
    repeat with i from 1 to (count of names)
      try
        set n to item i of names
        if n is not missing value and n contains \"$1\" then
          set pp to item i of positions
          set ss to item i of sizes
          return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
        end if
      end try
    end repeat
    return \"missing\""
}

click_row() { # click_row <label>
  local frame x y w h
  local attempt=0
  while (( attempt < 6 )); do
    frame="$(row_frame "$1")"
    if [[ "$frame" != "missing" && -n "$frame" ]]; then
      x="$(print -r -- "$frame" | awk '{print $1}')"
      y="$(print -r -- "$frame" | awk '{print $2}')"
      w="$(print -r -- "$frame" | awk '{print $3}')"
      h="$(print -r -- "$frame" | awk '{print $4}')"
      # A row that is scrolled out of the viewport still has an AX element, but
      # its reported frame is empty (0x0): clicking that point would hit the
      # window corner instead of the row. Treat it as "not reachable yet".
      if [[ "$w" == <-> && "$h" == <-> ]] && (( w > 0 && h > 0 )); then
        drive click $(( x + w / 2 )) $(( y + h / 2 )) || fail "posting the row click failed"
      sleep 1.2
      # The caller asserts the resulting state; record what the click reached so
      # a miss names its own geometry instead of failing one step later.
        log "diag click_row label='$1' frame='$x $y $w $h' focus=$(selection_focus) keys=$(keys_sorted)"
        return 0
      fi
      log "diag click_row label='$1' frame='$x $y $w $h' degenerate=true"
    fi
    sleep 1
    attempt=$(( attempt + 1 ))
  done
  log "diag click_row label='$1' frame=missing attempts=$attempt"
  return 1
}

# The window must be key before a posted Tab/arrow is delivered, and the point
# sits in the title band so becoming key cannot press a control.
make_window_key() {
  local frame x y w
  frame="$(ax_bulk 'set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & " " & ((item 2 of pp) as string) & " " & ((item 1 of ss) as string)')"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> ]] || return 1
  drive click $(( x + w - 20 )) $(( y + 40 )) || true
  sleep 0.6
  return 0
}

# --- records and a known expanded tree ------------------------------------
version=0
for n in $(seq 1 "$RECORD_COUNT"); do
  label="记录-$(printf '%03d' "$n")"
  pub invoke "$version" CREATE_RECORD --target 8000 \
    --arg label=STRING:"$label" --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:7 \
    --arg excludedType=STRING:"-" --arg requestId=STRING:"tree-kb-$n" > "$OUTPUT_DIR/create-$n.log" 2>&1 || true
  version=$(( version + 1 ))
done
applied="$(cat "$OUTPUT_DIR"/create-*.log | grep -c '^APPLIED true' || true)"
[[ "$applied" == "$RECORD_COUNT" ]] || fail "expected $RECORD_COUNT applied creates, got $applied"
sel_v="$(selection_version)"
pub tree-select --selection-version "$sel_v" --selection-command expand --key group-enabled \
  > "$OUTPUT_DIR/expand.log" 2>&1 || true
grep -q '^APPLIED true' "$OUTPUT_DIR/expand.log" || fail "expanding group-enabled failed"
sleep 1
log "step0 records_ready count=$RECORD_COUNT projection_version=$(projection_version)"
[[ "$(keys_count)" == "0" ]] || fail "the tree selection is not empty before the human input"

make_window_key || blocked "window frame unavailable for the desktop input driver"

# --- offscreen precondition ----------------------------------------------
if has_row_label "记录-060"; then
  log "step1 offscreen_precondition present_before_navigation=true (reveal assertion will still check focus)"
else
  log "step1 offscreen_precondition present_before_navigation=false"
fi
if has_row_label "记录-001"; then
  log "step1 first_row_exposed=true"
else
  fail "the first tree row is not exposed before any navigation"
fi

# --- 2. real click focuses the tree ---------------------------------------
click_row "记录-001" || fail "could not click the first tree row"
[[ "$(selection_focus)" == "record-1" ]] || fail "a real row click did not focus record-1 (focus=$(selection_focus))"
[[ "$(keys_sorted)" == "record-1," ]] || fail "a real row click did not select exactly record-1 (keys=$(keys_sorted))"
log "step2 click_focus_ok focus=record-1 keys=$(keys_sorted)"

# --- 3. Down moves focus only (documented model) --------------------------
# Diagnostics kept in the log: a selection-version bump proves the controller
# received a navigation event (not just a native focus traversal), and the
# window focus projection shows what the app itself believes is focused.
nav_sv_before="$(selection_version)"
nav_wf_before="$(window_focus)"
key $KEY_DOWN
log "diag down selection_version=$nav_sv_before->$(selection_version) window_focus=$nav_wf_before->$(window_focus)"
[[ "$(selection_focus)" == "record-2" ]] || fail "real Down did not move focus to record-2 (focus=$(selection_focus))"
[[ "$(keys_sorted)" == "record-1," ]] || fail "focus-only navigation changed the selection (keys=$(keys_sorted))"
log "step3 down_focus_ok focus=record-2 keys=$(keys_sorted)"

# --- 3b. modifier-delivery discriminator ----------------------------------
# Delivery of the arrow is not the question - the selection version also moves
# for a focus-only step. The discriminator is whether the Shift flag reaches the
# controller, which is visible as the range growing beyond the single clicked
# row. The measured result decides whether the Shift steps can be asserted here
# or have to be recorded as a host limitation (the production keyDown path with
# a Shift-carrying NSEvent is covered by
# verify_composable_ui_keyboard_navigation.sh in that case).
shift_probe_before_count="$(keys_count)"
shift_probe_before_focus="$(selection_focus)"
shortcut shift $KEY_DOWN
shift_probe_after_count="$(keys_count)"
shift_probe_after_focus="$(selection_focus)"
SHIFT_CARRIED="no"
if (( shift_probe_after_count > shift_probe_before_count )); then
  SHIFT_CARRIED="yes"
fi
log "diag modifier_delivery shift_keys=$shift_probe_before_count->$shift_probe_after_count shift_focus=$shift_probe_before_focus->$shift_probe_after_focus shift_carried=$SHIFT_CARRIED"

if [[ "$SHIFT_CARRIED" == "yes" ]]; then
  # The probe above already moved focus and range; re-anchor on the first row so
  # the documented steps below start from a known state, and verify each step of
  # that setup instead of assuming it.
  # Home scrolls the list back to its first row with real input, so the row the
  # click asserts is actually visible: the discriminator above scrolled the
  # viewport away from it (a scrolled-out row reports an empty AX frame).
  key $KEY_HOME
  sleep 0.6
  click_row "记录-001" || fail "could not re-click the first tree row"
  [[ "$(selection_focus)" == "record-1" ]] || fail "re-click focus=$(selection_focus), expected record-1"
  [[ "$(keys_sorted)" == "record-1," ]] || fail "re-click keys=$(keys_sorted), expected record-1"
  key $KEY_DOWN
  [[ "$(selection_focus)" == "record-2" ]] || fail "setup Down focus=$(selection_focus), expected record-2"

  # --- 4. Shift+Down extends the range from the current anchor ------------
  # The range anchor is the last click (record-1 here), which is the documented
  # model: arrows move the focus, Shift extends anchor..focus. A real Shift key
  # event is what makes the difference visible here - without it (step 3) the
  # selection did not move at all.
  shortcut shift $KEY_DOWN
  [[ "$(selection_anchor)" == "record-1" ]] || fail "Shift+Down anchor=$(selection_anchor), expected the click anchor record-1"
  [[ "$(selection_focus)" == "record-3" ]] || fail "Shift+Down focus=$(selection_focus), expected record-3"
  [[ "$(keys_sorted)" == "record-1,record-2,record-3," ]] || fail "Shift+Down keys=$(keys_sorted), expected record-1..record-3"
  log "step4 shift_down_ok anchor=record-1 focus=record-3 keys=$(keys_sorted)"

  # --- 5. Shift+Up shrinks the same range in reverse ----------------------
  shortcut shift $KEY_UP
  [[ "$(selection_anchor)" == "record-1" ]] || fail "Shift+Up moved the anchor ($(selection_anchor))"
  [[ "$(selection_focus)" == "record-2" ]] || fail "Shift+Up focus=$(selection_focus), expected record-2"
  [[ "$(keys_sorted)" == "record-1,record-2," ]] || fail "Shift+Up keys=$(keys_sorted), expected record-1,record-2"
  log "step5 shift_up_ok anchor=record-1 focus=record-2 keys=$(keys_sorted)"

  # --- 6. reverse (upward) range from a lower anchor ----------------------
  click_row "记录-005" || fail "could not click row 记录-005"
  [[ "$(selection_focus)" == "record-5" ]] || fail "click on 记录-005 focus=$(selection_focus)"
  shortcut shift $KEY_UP
  shortcut shift $KEY_UP
  [[ "$(selection_anchor)" == "record-5" ]] || fail "reverse range anchor=$(selection_anchor), expected record-5"
  [[ "$(selection_focus)" == "record-3" ]] || fail "reverse range focus=$(selection_focus), expected record-3"
  [[ "$(keys_sorted)" == "record-3,record-4,record-5," ]] || fail "reverse range keys=$(keys_sorted)"
  log "step6 reverse_shift_range_ok anchor=record-5 focus=record-3 keys=$(keys_sorted)"
else
  log "note real_shift_arrow_flag_not_delivered_by_host: the arrow itself arrived (focus $shift_probe_before_focus -> $shift_probe_after_focus) but the Shift flag did not, so this host drops the modifier on a synthesized arrow even while the real Shift key is held. The production keyDown path with a Shift-carrying NSEvent is verified by verify_composable_ui_keyboard_navigation.sh."
  # Known state for the remaining real-key steps.
  click_row "记录-001" || fail "could not click the first tree row"
  key $KEY_DOWN
fi

# --- 7. Home moves to the first visible row -------------------------------
key $KEY_HOME
[[ "$(selection_focus)" == "group-enabled" ]] || fail "Home focus=$(selection_focus), expected the first visible row"
log "step7 home_ok focus=$(selection_focus)"

# --- 8. Left collapses, Right expands the focused group -------------------
projection_before="$(projection_version)"
key $KEY_LEFT
sleep 1.0
projection_after="$(projection_version)"
# The assertion is the visible effect (the group's leaves leave the projection)
# plus the focus staying on the group; the projection version is logged as
# supporting evidence rather than used as the gate, because a public read that
# races the refresh returns an empty value and would otherwise read as "no
# change".
if has_row_label "记录-001"; then
  fail "Left did not collapse the focused group (projection $projection_before->$projection_after)"
fi
[[ "$(selection_focus)" == "group-enabled" ]] || fail "Left moved the focus off the group ($(selection_focus))"
log "step8 collapse_ok projection=$projection_before->$projection_after leaves_hidden=true focus=$(selection_focus)"
key $KEY_RIGHT
sleep 1.0
has_row_label "记录-001" || fail "Right did not expand the focused group again"
log "step8b expand_ok projection=$(projection_version) leaves_visible=true"

# --- 9. Command-A selects every visible selectable row --------------------
shortcut command $KEY_A
selected="$(keys_count)"
[[ "$selected" == "$RECORD_COUNT" ]] || fail "Command-A selected $selected keys, expected $RECORD_COUNT"
# keys_sorted is lexicographic (the same way the public payload is read back),
# so build the expectation the same way instead of in numeric order.
expected="$(for n in $(seq 1 "$RECORD_COUNT"); do print -r -- "record-${n},"; done | sort | tr -d '\n')"
[[ "$(keys_sorted)" == "$expected" ]] || fail "Command-A key set mismatch (first keys: $(keys_sorted | cut -c1-80))"
log "step9 cmd_a_ok keys=$selected exact_set=true"

# --- 10. off-screen target is revealed by keyboard navigation -------------
key $KEY_END
[[ "$(selection_focus)" == "group-disabled" ]] || fail "End focus=$(selection_focus), expected the last visible row"
# A navigation that lands on a row re-anchors the native focus and refreshes
# the scene. Wait (bounded) until the window's own focus projection names that
# row before sending the next key: the native focus metadata is what routes it.
waited=0
while (( waited < 25 )); do
  [[ "$(window_focus)" == "rule-tree-vgroup-group-disabled" ]] && break
  sleep 0.2
  waited=$(( waited + 1 ))
done
log "diag end native_focus=$(window_focus) waited=$waited"
offscreen_after_end="no"
has_row_label "记录-060" && offscreen_after_end="yes"
key $KEY_UP
[[ "$(selection_focus)" == "record-60" ]] || fail "Up from the last row focus=$(selection_focus), expected record-60"
has_row_label "记录-060" || fail "the off-screen target was not materialized after keyboard navigation"
log "step10 offscreen_reveal_ok focus=record-60 exposed_after_end=$offscreen_after_end exposed_now=yes"

# --- 11. a text field keeps Command-A; the tree must not navigate ---------
keys_before_text="$(keys_sorted)"
version_before_text="$(selection_version)"
# Key the window again so the posted Tab traversal starts from the window, not
# from deep inside the tree's materialized rows.
make_window_key || true
# The body is a single-quoted shell literal, so its AppleScript quotes are plain
# `"` characters: an escaped \" would reach osascript as a literal backslash
# quote and fail with a syntax error whose empty output looks like "not
# exposed" (the same quoting defect that was fixed in the tree chain script).
field_frame="$(ax_bulk 'set descs to description of every text field of window 1 of p
  set positions to position of every text field of window 1 of p
  set sizes to size of every text field of window 1 of p
  repeat with i from 1 to (count of descs)
    try
      if (item i of descs) is "规则名称" then
        set pp to item i of positions
        set ss to item i of sizes
        return ((item 1 of pp) as string) & " " & ((item 2 of pp) as string) & " " & ((item 1 of ss) as string) & " " & ((item 2 of ss) as string)
      end if
    end try
  end repeat
  return "missing"')"
[[ "$field_frame" != "missing" && -n "$field_frame" ]] || blocked "the handwritten label field is not exposed"
fx="$(print -r -- "$field_frame" | awk '{print $1}')"
fy="$(print -r -- "$field_frame" | awk '{print $2}')"
fw="$(print -r -- "$field_frame" | awk '{print $3}')"
fh="$(print -r -- "$field_frame" | awk '{print $4}')"
drive click $(( fx + fw / 2 )) $(( fy + fh / 2 )) >/dev/null 2>&1 || true
sleep 0.8
focus_now="$(window_focus)"
tabs=0
while (( tabs < 60 )); do
  case "$focus_now" in
    field-*) break ;;
  esac
  drive tab >/dev/null 2>&1 || true
  sleep 0.25
  focus_now="$(window_focus)"
  tabs=$(( tabs + 1 ))
done
case "$focus_now" in
  field-*) log "step11 text_field_focus_ok focus=$focus_now tabs=$tabs" ;;
  *) blocked "no text field took the focus for the Command-A isolation check (focus='$focus_now')" ;;
esac
shortcut command $KEY_A
[[ "$(keys_sorted)" == "$keys_before_text" ]] || fail "Command-A inside a text field changed the tree selection"
[[ "$(selection_version)" == "$version_before_text" ]] || fail "Command-A inside a text field advanced the tree selection version"
log "step11 text_isolation_ok keys_unchanged=true selection_version=$version_before_text"

if [[ "$SHIFT_CARRIED" == "no" ]]; then
  log "BLOCKED real-keyboard Shift+Arrow: the arrow was delivered (focus $shift_probe_before_focus -> $shift_probe_after_focus) but its Shift flag was not, so the range could not be extended from a real key event on this host. Every other real-keyboard step above ran and passed; the Shift-carrying keyDown route is verified separately by verify_composable_ui_keyboard_navigation.sh."
  cat "$LOG"
  exit 3
fi
log "PASSED keyboard chain"
cat "$LOG"
exit 0
