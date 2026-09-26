#!/usr/bin/env zsh
# Normal rule-set app: CGEvent selection, tab round trip, TextKit replacement.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="${CJGUI_TABS_DESKTOP_TMPDIR:-/private/tmp/cjgui-tabs-desktop}/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

ROUND_DIR="$WORK/round-app"
NAME_TOKEN="CJGUIRuleSet"
BUNDLE_TOKEN="org.cangjie.cjgui.rule-set.example"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Sel${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round app copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}Sel${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}Sel${RUN_TAG}"
APP_PID=""
DESCRIPTOR=""
cleanup() { cjgui_terminate_owned "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || true; }
trap cleanup EXIT
STARTED="$(date +%s)"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$WORK/app.log" 2>&1 & )
DESCRIPTOR="$(cjgui_wait_descriptor "$WORK/app.log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 150 || true)"
[[ -f "$DESCRIPTOR" ]] || fail "no owned descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "no matching process"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "process identity changed"
AX_PID="$APP_PID"
AX_APP_PATH="${ROUND_EXEC%/Contents/MacOS/*}"
pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
owner_version() { pub get | awk '$1 == "VERSION" {print $2}'; }
field_line() { pub generated-fields | awk '$1 == "FIELD" && $2 == "label" {print}'; }
field_version() { field_line | awk '{for (i=1;i<=NF;i++) if ($i == "VERSION") print $(i+1)}'; }
field_text() { field_line | awk '{for (i=1;i<=NF;i++) if ($i == "DRAFT_HEX") print $(i+1)}' | hex_to_text; }
selection() { pub window-interaction | awk '$1 == "WINDOW_SELECTION" && $2 == "field-label" {print $3 " " $4}'; }
focus() { pub window-interaction | awk '$1 == "WINDOW_FOCUS" {print $2}'; }
wait_selection() {
  local wanted="$1" i=0 got=""
  while (( i < 25 )); do
    got="$(selection)"
    [[ "$got" == "$wanted" ]] && return 0
    sleep 0.2
    i=$((i+1))
  done
  log "selection_wait wanted='$wanted' actual='$got' focus='$(focus)'"
  return 1
}
wait_text() {
  local wanted="$1" i=0 got=""
  while (( i < 25 )); do
    got="$(field_text)"
    [[ "$got" == "$wanted" ]] && return 0
    sleep 0.2
    i=$((i+1))
  done
  log "text_wait wanted='$wanted' actual='$got'"
  return 1
}
wait_focus() {
  local wanted="$1" i=0 got=""
  while (( i < 25 )); do
    got="$(focus)"
    [[ "$got" == "$wanted" ]] && return 0
    sleep 0.2
    i=$((i+1))
  done
  log "focus_wait wanted='$wanted' actual='$got'"
  return 1
}
external_edit() {
  local value="$1" result="$WORK/external-edit-$(date +%s%N).log"
  pub invoke "$(owner_version)" EDIT_DRAFT_TEXT --target "$RECORD_ID" \
    --arg fieldId=STRING:label --arg text=STRING:"$value" \
    --arg expectedDraftVersion=INTEGER:"$(field_version)" > "$result" 2>&1 || true
  grep -q '^APPLIED true' "$result" || fail "external owner edit rejected log=$result"
  wait_text "$value" || fail "external owner edit not projected"
}
show_tab() {
  local wanted="$1" result
  result="$(real_ax_press_identifier "$APP_PID" "rule-detail-tabs-tab-$wanted")"
  [[ "$result" == "identifier_press_sent" ]] || fail "tab $wanted press=$result"
  sleep 0.4
}
select_emoji() {
  local frame x y w h
  activate_app
  frame="$(ax_identifier_frame field-label 'text field')"
  frame_is_positive "$frame" || fail "editor not visible frame='$frame'"
  log "frames label='$frame' count='$(ax_identifier_frame field-retentionCount 'text field')' excluded='$(ax_identifier_frame field-excludedType 'text field')' window='$(ax_window_frame)'"
  read -r x y w h <<< "$frame"
  # The application's compressed split can overlap AX rectangles for successive
  # fields; the first visible strip of the label precedes the next editor.
  log "editor_frame='$frame' click=$((x+w/2)),$((y+3)) focus_before=$(focus)"
  drive click $((x+w/2)) $((y+3))
  sleep 0.3
  log "focus_after_click=$(focus) selection_after_click=$(selection)"
  [[ "$(focus)" == "field-label" ]] || fail "CGEvent click reached another control"
  # Move to end in the native editor, then select one grapheme (two UTF-16 units).
  local i=0
  while (( i < 8 )); do drive key 124; i=$((i+1)); done
  drive key 123
  drive shortcut shift 123
  wait_selection '1 3' || fail "CGEvent emoji selection did not project"
}

prepare_desktop_driver || fail "desktop input unavailable reason=$INPUT_BLOCKED"
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"选区往返" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"tabs-selection-$RUN_TAG" \
  > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
RECORD_ID="$(pub get | awk '/FIELD [0-9]+ label STRING/ && !found {print $2; found=1}')"
[[ -n "$RECORD_ID" ]] || fail "created record not readable"
pub invoke "$(owner_version)" SELECT_RECORD --target "$RECORD_ID" > "$WORK/select.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/select.log" || fail "record selection failed"
external_edit '甲😀乙'
show_tab basic
select_emoji
log "selected emoji selection=$(selection) focus=$(focus) owner=$(field_text)"
show_tab retention
show_tab basic
wait_selection '1 3' || fail "selection did not survive tab round trip"
drive type X
wait_text '甲X乙' || fail "native replacement did not reach owner"
log "round_trip selection_restored=true owner=$(field_text) input=CGEvent passed=true"

external_edit '甲😀乙'
select_emoji
show_tab retention
external_edit '甲乙'
show_tab basic
wait_selection '1 2' || fail "hidden owner shrink did not clamp selection"
drive type Y
wait_text '甲Y' || fail "post-shrink replacement did not use current owner text"
log "hidden_shrink clamped_selection=1..2 owner=$(field_text) input=CGEvent passed=true"

# The normal application must route title keys through its key window and
# overlay responder. Arrow keys move title focus without changing the page;
# Return/Space then activate the focused title's accepted page.
show_tab basic
activate_app
HANDLE_FRAME="$(ax_identifier_frame rule-set-content-handle group)"
frame_is_positive "$HANDLE_FRAME" || fail "split handle has no normal-window frame ('$HANDLE_FRAME')"
click_frame_center "$HANDLE_FRAME" || fail "CGEvent split handle click failed"
wait_focus rule-set-content-handle || fail "split handle did not take focus"
drive tab
wait_focus rule-detail-tabs-tab-basic || fail "CGEvent Tab from split handle did not reach the selected title"
drive shortcut shift 48
wait_focus rule-set-content-handle || fail "CGEvent Shift-Tab did not return to split handle"
drive tab
wait_focus rule-detail-tabs-tab-basic || fail "CGEvent Tab did not re-enter the one-stop title group"
log "pure_keyboard_entry from=rule-set-content-handle to=rule-detail-tabs-tab-basic shift_back=true input=CGEvent"
BASIC_TITLE="$(ax_identifier_frame rule-detail-tabs-tab-basic group)"
frame_is_positive "$BASIC_TITLE" || fail "basic title has no normal-window frame ('$BASIC_TITLE')"
click_frame_center "$BASIC_TITLE" || fail "CGEvent title click failed"
wait_focus rule-detail-tabs-tab-basic || fail "title click did not focus the overlay title"
drive key 124
wait_focus rule-detail-tabs-tab-retention || fail "Right did not focus the next title"
frame_is_positive "$(ax_identifier_frame field-label 'text field')" \
  || fail "Right activated the page instead of only moving focus"
if frame_is_positive "$(ax_identifier_frame file-path 'text field')"; then
  fail "Right exposed the retention page before activation"
fi
drive key 36
sleep 0.4
frame_is_positive "$(ax_identifier_frame file-path 'text field')" \
  || fail "Return did not activate the focused retention page"
drive key 123
wait_focus rule-detail-tabs-tab-basic || fail "Left did not focus the previous title"
frame_is_positive "$(ax_identifier_frame file-path 'text field')" \
  || fail "Left activated the page instead of only moving focus"
drive key 49
sleep 0.4
frame_is_positive "$(ax_identifier_frame field-label 'text field')" \
  || fail "Space did not activate the focused basic page"
if frame_is_positive "$(ax_identifier_frame file-path 'text field')"; then
  fail "Space left the retention page active"
fi
TAB_STEPS=0
while (( TAB_STEPS < 8 )) && [[ "$(focus)" != "field-label" ]]; do
  drive tab
  sleep 0.2
  TAB_STEPS=$(( TAB_STEPS + 1 ))
  log "title_keyboard_tab step=$TAB_STEPS focus=$(focus)"
done
[[ "$(focus)" == "field-label" ]] || fail "Tab never entered the active page (steps=$TAB_STEPS focus=$(focus))"
drive shortcut shift 48
sleep 0.3
SHIFT_BACK_FOCUS="$(focus)"
[[ "$SHIFT_BACK_FOCUS" != "field-label" && "$SHIFT_BACK_FOCUS" != "none" ]] \
  || fail "Shift-Tab did not move to the previous focusable control (focus=$SHIFT_BACK_FOCUS)"
drive tab
wait_focus field-label || fail "Tab did not re-enter the page after Shift-Tab"
log "title_keyboard normal_app=true right_focus_only=true return_activated=true left_focus_only=true space_activated=true tab_enter_steps=$TAB_STEPS shift_tab_previous=$SHIFT_BACK_FOCUS tab_reentered=true input=CGEvent"
print -r -- "PASSED tabs desktop selection chain log=$LOG"
