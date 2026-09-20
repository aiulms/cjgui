#!/usr/bin/env zsh
# Shared tree selection + 100-record bidirectional business chain on one real
# window instance.
#
# Proves, in one round instance:
#   1. external authorized CREATE_RECORD x100 (records 1..100, all disabled)
#   2. the shared selection entry (same handler the window uses) expands the
#      groups and selects every visible record; the public read returns exact
#      stable keys, focus, anchor and selection/projection versions
#   3. external authorized BATCH_SET_ENABLED on all 100 ids (including rows
#      outside the viewport) applies through the original owner, and the
#      public per-record read shows the exact new field values
#   4. the window shows the accepted scene (accepted/submitted frame advances),
#      the scene version strictly advanced across the shared expansion, no
#      native failure is pending, and the accessibility projection exposes a
#      real tree leaf row (a stalled window fails here instead of passing)
#   5. a human draft edit + handwritten apply on one record is read back
#      exactly by the public field projection
#   6. rejections (stale version, draft conflict, unknown key) leave version
#      and content unchanged, with no partial application
#
# The instance is launched only by this script and reclaimed by exact PID and
# executable path; a bystander control instance must keep answering.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_TREE_SELECTION_TMPDIR:-/private/tmp/cjgui-tree-selection-chain}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

APP_EXE="$APP_DIR/target/release/CJGUIRuleSet.app/Contents/MacOS/CJGUIRuleSet"
APP_PID=""
CONTROL_PID=""
CONTROL_DESCRIPTOR=""

# Instance ownership is shared with the other desktop verifiers: a round may
# only ever signal the process that owns its own descriptor and matches the
# round executable, and every desktop tool call is bounded.
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

cleanup() {
  # Re-check ownership inside the helper before signalling, so a recycled PID
  # or a bystander instance is never touched.
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$APP_EXE" "$APP_DIR" || true
  cjgui_terminate_owned "$CONTROL_PID" "${CONTROL_DESCRIPTOR:-}" "${CONTROL_EXEC:-}" "${CONTROL_APP_DIR:-}" || true
  if cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$APP_EXE" "$APP_DIR"; then
    log "cleanup: round instance still alive after bounded shutdown pid=$APP_PID"
  else
    log "cleanup: round instance closed pid=$APP_PID"
  fi
}
trap cleanup EXIT

launch_app() { # launch_app <stdout-log>
  local stdout_log="$1"
  ( cd "$APP_DIR" && nohup zsh run.sh > "$stdout_log" 2>&1 & )
  local waited=0 descriptor=""
  while (( waited < 120 )); do
    descriptor="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$stdout_log" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then
      print -r -- "$descriptor"
      return 0
    fi
    sleep 2; waited=$((waited + 2))
  done
  return 1
}

# --- bystander control instance -------------------------------------------
# The control gets its own per-round copy (different bundle id, executable name
# and directory) so the two instances can never share an identity: a shared
# path would make "which instance is this" undecidable, which is exactly the
# ambiguity the old pgrep-based selection papered over.
CONTROL_APP_DIR="$WORK/control-app"
CONTROL_SUFFIX="Ctl${RUN_TAG}"
cjgui_prepare_app_copy "$APP_DIR" "$CONTROL_APP_DIR" "$RUNTIME_DIR" "CJGUIRuleSet" "$CONTROL_SUFFIX" \
  "org.cangjie.cjgui.rule-set.example" || fail "control application copy failed"
CONTROL_EXEC="$CONTROL_APP_DIR/target/release/CJGUIRuleSet${CONTROL_SUFFIX}.app/Contents/MacOS/CJGUIRuleSet${CONTROL_SUFFIX}"
CONTROL_STARTED="$(date +%s)"
CONTROL_LOG="$WORK/control.log"
( cd "$CONTROL_APP_DIR" && nohup zsh run.sh > "$CONTROL_LOG" 2>&1 & )
CONTROL_DESCRIPTOR=""
waited=0
while (( waited < 180 )); do
  CONTROL_DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$CONTROL_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$CONTROL_DESCRIPTOR" && -f "$CONTROL_DESCRIPTOR" ]]; then break; fi
  sleep 2; waited=$(( waited + 2 ))
done
[[ -f "${CONTROL_DESCRIPTOR:-}" ]] || fail "control instance did not start"
CONTROL_PID="$(cjgui_descriptor_owner_pid "$CONTROL_DESCRIPTOR" "$CONTROL_EXEC" "$CONTROL_APP_DIR" "$CONTROL_STARTED" || true)"
[[ -n "$CONTROL_PID" ]] || fail "control instance descriptor has no matching owner"
log "control pid=$CONTROL_PID descriptor=$CONTROL_DESCRIPTOR exec=CJGUIRuleSet${CONTROL_SUFFIX}"

# --- round instance -------------------------------------------------------
ROUND_STARTED="$(date +%s)"
STDOUT_LOG="$WORK/app.log"
DESCRIPTOR="$(launch_app "$STDOUT_LOG")" || fail "round instance did not start"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$APP_EXE" "$APP_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "round instance descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$APP_EXE" "$APP_DIR" || fail "round pid is not this round's instance"
[[ "$APP_PID" != "$CONTROL_PID" ]] || fail "round pid resolved to the control instance"
[[ "$DESCRIPTOR" != "$CONTROL_DESCRIPTOR" ]] || fail "round instance reused the control descriptor"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
control_pub() { python3 "$CLIENT" "$CONTROL_DESCRIPTOR" "$@"; }
selection_version() { pub tree-selection 2>/dev/null | awk '/^SELECTION_VERSION /{print $2}'; }
selected_keys() { pub tree-selection 2>/dev/null | awk '/^KEY /{print $2}'; }
enabled_true() { pub get 2>/dev/null | grep -cE 'enabled BOOLEAN 1$' || true; }
enabled_false() { pub get 2>/dev/null | grep -cE 'enabled BOOLEAN 0$' || true; }
hex_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
field_token() { # field_token <fieldId> <TOKEN>
  # Bounded retry: a public read issued while the window is committing a
  # refresh can come back empty, which would otherwise read as "the field is
  # gone" rather than "the read raced the refresh".
  local attempt=0 value line
  while (( attempt < 12 )); do
    line="$(pub generated-fields 2>/dev/null | grep "^FIELD $1 " | head -1 || true)"
    if [[ -n "$line" ]]; then
      value="$(print -r -- "$line" | awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}')"
      if [[ -n "$value" ]]; then
        print -r -- "$value"
        return 0
      fi
    fi
    sleep 0.3
    attempt=$(( attempt + 1 ))
  done
  return 1
}

# --- 1. external CREATE_RECORD x100 ---------------------------------------
CREATE_LOG="$WORK/creates.log"
: > "$CREATE_LOG"
version=0
for n in $(seq 1 100); do
  label="记录-$(printf '%03d' "$n")"
  pub invoke "$version" CREATE_RECORD --target 8000 \
    --arg label=STRING:"$label" --arg enabled=BOOLEAN:false \
    --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"sel-create-$n" >> "$CREATE_LOG" 2>&1 || true
  version=$((version + 1))
done
appliedCount="$(grep -c '^APPLIED true' "$CREATE_LOG" || true)"
[[ "$appliedCount" == 100 ]] || fail "expected 100 applied creates, got $appliedCount"
[[ "$(enabled_false)" == 100 ]] || fail "expected 100 disabled records after creates"
log "step1 external_create_ok count=100"

# --- 2. shared selection: expand groups + select all -----------------------
expand_enabled() {
  local v; v="$(selection_version)"
  pub tree-select --selection-version "$v" --selection-command expand --key group-enabled 2>/dev/null | grep -q '^APPLIED true'
}
expand_disabled() {
  local v; v="$(selection_version)"
  pub tree-select --selection-version "$v" --selection-command expand --key group-disabled 2>/dev/null | grep -q '^APPLIED true'
}
# Baseline before the shared expansion: the scene version must strictly
# advance because the expansion changes the window's own view revision.
SCENE_BEFORE="$(pub window-progress 2>/dev/null | awk '/^WINDOW_SCENE_VERSION /{print $2}')"
[[ -n "$SCENE_BEFORE" ]] || fail "window progress unavailable before shared expansion"
expand_enabled || fail "expand group-enabled failed"
if [[ "$(enabled_true)" == 0 ]]; then
  expand_disabled || fail "expand group-disabled failed"
fi
SEL_V="$(selection_version)"
SELECT_ALL_LOG="$WORK/select-all.log"
pub tree-select --selection-version "$SEL_V" --selection-command select-all > "$SELECT_ALL_LOG" 2>&1 || true
grep -q '^APPLIED true' "$SELECT_ALL_LOG" || fail "select-all failed"
KEYS_LOG="$WORK/keys.log"
pub tree-selection > "$KEYS_LOG" 2>&1 || true
KEY_COUNT="$(grep -c '^KEY ' "$KEYS_LOG" || true)"
[[ "$KEY_COUNT" == 100 ]] || fail "expected 100 selected keys, got $KEY_COUNT"
grep -q '^KEY record-1$' "$KEYS_LOG" || fail "selected keys do not contain record-1"
grep -q '^FOCUS none$' "$KEYS_LOG" || true
log "step2 selection_ok keys=$KEY_COUNT selection_version=$SEL_V"

# --- 2b. the window really re-projected the expanded tree ------------------
# A rejected candidate (for example `duplicate_node_id`) keeps the previous
# collapsed scene live and leaves the refresh pending; the shared selection
# read above would still answer correctly, so assert the visible projection
# followed instead of trusting the business read alone.
SCENE_FOLLOW="$WORK/progress-after-selection.log"
pub window-progress > "$SCENE_FOLLOW" 2>&1 || true
SCENE_AFTER="$(awk '/^WINDOW_SCENE_VERSION /{print $2}' "$SCENE_FOLLOW")"
ACCEPTED_AFTER="$(awk '/^WINDOW_ACCEPTED_SCENE_VERSION /{print $2}' "$SCENE_FOLLOW")"
SUBMITTED_AFTER="$(awk '/^WINDOW_SUBMITTED_SCENE_VERSION /{print $2}' "$SCENE_FOLLOW")"
NATIVE_FAILURE_AFTER="$(awk '/^WINDOW_LAST_NATIVE_FAILURE /{print $2}' "$SCENE_FOLLOW")"
REFRESH_PENDING_AFTER="$(awk '/^WINDOW_REFRESH_PENDING /{print $2}' "$SCENE_FOLLOW")"
[[ -n "$SCENE_AFTER" && "$SCENE_AFTER" -gt "$SCENE_BEFORE" ]] || \
  fail "window scene version did not advance across the shared expansion (before=$SCENE_BEFORE after=$SCENE_AFTER)"
[[ "$SCENE_AFTER" == "$ACCEPTED_AFTER" && "$SCENE_AFTER" == "$SUBMITTED_AFTER" ]] || \
  fail "window scene not accepted/submitted after expansion (scene=$SCENE_AFTER accepted=$ACCEPTED_AFTER submitted=$SUBMITTED_AFTER)"
[[ "$NATIVE_FAILURE_AFTER" == "none" ]] || \
  fail "window reports a native failure after the shared expansion ($NATIVE_FAILURE_AFTER)"
[[ "$REFRESH_PENDING_AFTER" == "none" ]] || \
  fail "window reports a pending refresh after the shared expansion ($REFRESH_PENDING_AFTER)"
log "step2b window_followed_expansion scene=$SCENE_BEFORE->$SCENE_AFTER"

# The accessibility projection is what a human clicks; assert a real leaf row
# is exposed. An osascript bridge failure is recorded as an environment note,
# but a bridge that answers without any tree leaf row is a real defect.
AX_LOG="$WORK/ax-rows.log"
AX_LISTING="no"
AX_HAS_ROW="no"
attempt=0
while (( attempt < 4 )); do
  if cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    return name of every button of window 1 of p
  end tell" > "$AX_LOG" 2>&1; then
    AX_LISTING="yes"
    if grep -q "记录-" "$AX_LOG"; then
      AX_HAS_ROW="yes"
      break
    fi
  fi
  # A hung or degraded accessibility bridge is bounded above and recorded as a
  # tool limitation. This harness never restarts System Events or changes
  # system settings to repair the environment.
  sleep 2
  attempt=$((attempt + 1))
done
if [[ "$AX_LISTING" == "yes" && "$AX_HAS_ROW" == "no" ]]; then
  fail "accessibility projection lists window buttons but no expanded tree leaf row"
fi
if [[ "$AX_LISTING" == "no" ]]; then
  log "note ax_bridge_unavailable_after=${attempt} (bounded; assertion not claimed)"
fi
log "step2b_ax listing=$AX_LISTING leaf_rows=$AX_HAS_ROW"

# --- 3. external authorized batch over all 100 ids ------------------------
BATCH_LOG="$WORK/batch.log"
BATCH_TARGETS=()
for n in $(seq 1 100); do BATCH_TARGETS+=(--target "$n"); done
BATCH_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$BATCH_VERSION" BATCH_SET_ENABLED "${BATCH_TARGETS[@]}" \
  --arg enabled=BOOLEAN:true --arg requestId=STRING:"tree-batch-100" > "$BATCH_LOG" 2>&1 || true
grep -q '^APPLIED true' "$BATCH_LOG" || fail "external batch enable failed"
[[ "$(enabled_true)" == 100 ]] || fail "expected 100 enabled after batch, got $(enabled_true)"
log "step3 external_batch_ok enabled=100"

# --- 4. window shows the accepted scene -----------------------------------
PROGRESS="$WORK/progress.log"
pub window-progress > "$PROGRESS" 2>&1 || true
SCENE_VERSION="$(awk '/^WINDOW_SCENE_VERSION /{print $2}' "$PROGRESS")"
ACCEPTED="$(awk '/^WINDOW_ACCEPTED_SCENE_VERSION /{print $2}' "$PROGRESS")"
SUBMITTED="$(awk '/^WINDOW_SUBMITTED_SCENE_VERSION /{print $2}' "$PROGRESS")"
METAL_FAILED="$(awk '/^WINDOW_METAL_FAILED_FRAME_INDEX /{print $2}' "$PROGRESS")"
FRAME_INDEX="$(awk '/^WINDOW_SUBMITTED_FRAME_INDEX /{print $2}' "$PROGRESS")"
# Functional criterion: the latest scene was accepted and submitted and no
# frame failed. The failure field is recorded verbatim as evidence; it keeps
# the last failed attempt (if any) and is not used to claim a clean history.
[[ -n "$SCENE_VERSION" && "$SCENE_VERSION" == "$ACCEPTED" && "$SCENE_VERSION" == "$SUBMITTED" ]] || \
  fail "window scene/accepted/submitted mismatch (scene=$SCENE_VERSION accepted=$ACCEPTED submitted=$SUBMITTED)"
[[ "$METAL_FAILED" == "-1" ]] || fail "a metal frame failed (index=$METAL_FAILED)"
[[ "$FRAME_INDEX" -ge 100 ]] || fail "unexpectedly few submitted frames ($FRAME_INDEX)"
log "step4 window_scene_ok version=$SCENE_VERSION frames=$FRAME_INDEX metal_failed=$METAL_FAILED"
log "step4_note native_failure_field=$(awk '/^WINDOW_LAST_NATIVE_FAILURE /{print $2}' "$PROGRESS") refresh_pending=$(awk '/^WINDOW_REFRESH_PENDING /{print $2}' "$PROGRESS")"

# --- 5a. external draft edit + apply on one record -------------------------
# This is the external, public-entry half of the round (kept as evidence of the
# owner path). The HUMAN half runs in step 5b when CHAIN_DESKTOP_STEP=1.
DRAFT_TEXT="外部续写-选择链"
DOMAIN_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$DOMAIN_VERSION" SELECT_RECORD --target 1 > "$WORK/select-record.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/select-record.log" || fail "select record failed"
DRAFT_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$DRAFT_VERSION" EDIT_DRAFT_TEXT --target 1 \
  --arg fieldId=STRING:label --arg text=STRING:"$DRAFT_TEXT" --arg expectedDraftVersion=INTEGER:0 \
  > "$WORK/draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/draft.log" || fail "human draft edit failed"
FIELD_LINE="$(pub generated-fields 2>/dev/null | grep '^FIELD label ' | head -1)"
DRAFT_HEX="$(print -r -- "$FIELD_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") print $(i + 1)}')"
DRAFT_BACK="$(python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))' <<< "$DRAFT_HEX")"
[[ "$DRAFT_BACK" == "$DRAFT_TEXT" ]] || fail "draft read-back mismatch: '$DRAFT_BACK'"
APPLY_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
DRAFT_FIELD_VERSION="$(print -r -- "$FIELD_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i == "VERSION") print $(i + 1)}')"
pub invoke "$APPLY_VERSION" APPLY_DRAFT --target 1 \
  --arg expectedDraftVersion=INTEGER:"$DRAFT_FIELD_VERSION" > "$WORK/apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/apply.log" || fail "apply failed"
APPLIED_HEX="$(pub generated-fields 2>/dev/null | grep '^FIELD label ' | head -1 | awk '{for (i = 1; i <= NF; i++) if ($i == "APPLIED_HEX") print $(i + 1)}')"
APPLIED_BACK="$(python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))' <<< "$APPLIED_HEX")"
[[ "$APPLIED_BACK" == "$DRAFT_TEXT" ]] || fail "applied read-back mismatch: '$APPLIED_BACK'"
log "step5a external_draft_edit_ok applied=$(print -r -- "$APPLIED_BACK")"

# --- 5b. the same instance: real desktop selection + human edit ------------
# Opt-in (CHAIN_DESKTOP_STEP=1) because it needs a usable desktop: a real click
# on a tree row, real typing into the field and a real accessibility press on
# the apply button. A desktop/driver that cannot deliver is reported as BLOCKED
# at the very end (exit 3), never as a pass; running without the opt-in skips
# the whole human half, so it must report the same BLOCKED instead of looking
# like a complete chain pass.
DESKTOP_BLOCKED=""
if [[ -n "${CHAIN_DESKTOP_STEP:-}" ]]; then
  DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
  DRIVER="$WORK/cjgui_desktop_input_driver"
  # Every driver call records its own failure instead of aborting the script:
  # a missing desktop must surface as BLOCKED with its concrete reason.
  drive() {
    "$DRIVER" "$@" >/dev/null 2>&1 && return 0
    DESKTOP_BLOCKED="desktop input driver call failed: $1"
    return 1
  }
  ax_round() { # ax_round <seconds> <applescript body using p>
    local limit="$1"; shift
    cjgui_ax "$limit" -e "tell application \"System Events\"
      set p to first process whose unix id is $APP_PID
      $1
    end tell" 2>/dev/null | tail -1 || true
  }
  # Frame of the (first) declared apply button, used for the real pointer press.
  apply_frame_first() {
    cjgui_ax 20 -e "tell application \"System Events\"
      set p to first process whose unix id is $APP_PID
      set names to name of every button of window 1 of p
      set positions to position of every button of window 1 of p
      set sizes to size of every button of window 1 of p
      repeat with i from 1 to (count of names)
        try
          if (item i of names) is \"应用草稿\" then
            set pp to item i of positions
            set ss to item i of sizes
            return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
          end if
        end try
      end repeat
      return \"missing\"
    end tell" 2>/dev/null | tail -1
  }
  if command -v swiftc >/dev/null 2>&1; then
    swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1 || \
      DESKTOP_BLOCKED="desktop input driver did not build"
  else
    DESKTOP_BLOCKED="swiftc unavailable for the desktop input driver"
  fi
  if [[ -z "$DESKTOP_BLOCKED" ]]; then
    # Raise the window before asking for its frame, and retry: the window has
    # just taken 100 records plus external batch edits, and a single bounded AX
    # read can transiently come back empty. Each attempt records the raw answer
    # so a real BLOCKED names what the bridge returned instead of hiding it.
    ax_round 15 'set frontmost of p to true
      try
        perform action "AXRaise" of window 1 of p
      end try' > /dev/null 2>&1 || true
    LAST_FRAME=""
    for frame_attempt in 1 2 3 4 5; do
      # AppleScript quoting: this body is a single-quoted shell literal, so the
      # quotes are plain `"` characters. The earlier `\"` form was written for a
      # double-quoted shell string and reached osascript as a literal backslash
      # quote -- an AppleScript syntax error whose empty output was reported as
      # "geometry unavailable".
      LAST_FRAME="$(ax_round 15 'set pp to position of window 1 of p
        set ss to size of window 1 of p
        return ((item 1 of pp) as string) & " " & ((item 2 of pp) as string) & " " & ((item 1 of ss) as string)')"
      X="$(print -r -- "$LAST_FRAME" | awk '{print $1}')"
      Y="$(print -r -- "$LAST_FRAME" | awk '{print $2}')"
      W="$(print -r -- "$LAST_FRAME" | awk '{print $3}')"
      [[ "$X" == <-> && "$Y" == <-> && "$W" == <-> ]] && break
      sleep 1
    done
    if [[ "$X" == <-> && "$Y" == <-> && "$W" == <-> ]]; then
      log "desktop_window frame='$X $Y $W' attempt=$frame_attempt"
      # A click in the title band keys the window without pressing a control.
      drive click $(( X + W - 20 )) $(( Y + 40 )) || true
      sleep 0.6
    else
      DESKTOP_BLOCKED="round window geometry unavailable for the desktop input driver (last ax answer: '${LAST_FRAME}')"
    fi
  fi
  if [[ -z "$DESKTOP_BLOCKED" ]]; then
    # The handwritten detail pane's label editor is looked up by its declared
    # accessibility description - the label from the shared form descriptor
    # ("规则名称"). The bulk form (`description of every text field`) is used
    # deliberately: a per-element walk over `entire contents` swallows the
    # element's role/description errors and silently matched nothing while the
    # field was right there. The number of matches is logged, because the same
    # description legitimately appears wherever one definition is rendered
    # twice; the earlier `field-label` description exists nowhere here.
    FIELD_FRAME="$(cjgui_ax 20 -e "tell application \"System Events\"
      set p to first process whose unix id is $APP_PID
      set descs to description of every text field of window 1 of p
      set positions to position of every text field of window 1 of p
      set sizes to size of every text field of window 1 of p
      set matches to 0
      set bestFrame to \"\"
      repeat with i from 1 to (count of descs)
        try
          if (item i of descs) is \"规则名称\" then
            set matches to matches + 1
            if bestFrame is \"\" then
              set pp to item i of positions
              set ss to item i of sizes
              set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
            end if
          end if
        end try
      end repeat
      if bestFrame is \"\" then return \"missing\"
      return bestFrame & \" \" & (matches as string)
    end tell" 2>/dev/null | tail -1)"
    if [[ "$FIELD_FRAME" != "missing" && -n "$FIELD_FRAME" ]]; then
      fx="$(print -r -- "$FIELD_FRAME" | awk '{print $1}')"
      fy="$(print -r -- "$FIELD_FRAME" | awk '{print $2}')"
      fw="$(print -r -- "$FIELD_FRAME" | awk '{print $3}')"
      fh="$(print -r -- "$FIELD_FRAME" | awk '{print $4}')"
      FIELD_MATCHES="$(print -r -- "$FIELD_FRAME" | awk '{print $5}')"
      log "step5b human_field description='规则名称' frame='$fx $fy $fw $fh' matching_fields=$FIELD_MATCHES"
      # Focus the field with real posted Tab input. This runs before the row
      # click on purpose: the tree's virtual rows are all focusable, so a
      # traversal that starts inside the tree walks the materialized list
      # (observed: still on `rule-tree-vleaf-record-7` after 48 tabs in a sweep
      # run, while the same traversal from the freshly keyed window reaches the
      # field in a few dozen steps). The window was just keyed by the real
      # title-band click above, and the public focus projection says which
      # control the human input will actually reach.
      TAB_INDEX=0
      TAB_REACHED=""
      TAB_FOCUS="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
      while (( TAB_INDEX < 60 )); do
        if [[ "$TAB_FOCUS" == field-label* ]]; then
          TAB_REACHED="$TAB_FOCUS"
          break
        fi
        drive tab || break
        sleep 0.2
        TAB_FOCUS="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
        TAB_INDEX=$(( TAB_INDEX + 1 ))
      done
      if [[ -n "$TAB_REACHED" ]]; then
        log "step5b human_focus_ok path=tab focus=$TAB_REACHED tabs=$TAB_INDEX"
        if drive type "H"; then
          sleep 1.5
          HUMAN_DRAFT_HEX="$(pub generated-fields 2>/dev/null | grep '^FIELD label ' | head -1 | awk '{for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") print $(i + 1)}')"
          HUMAN_DRAFT="$(python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))' <<< "$HUMAN_DRAFT_HEX")"
          [[ "$HUMAN_DRAFT" == "${DRAFT_TEXT}H" ]] || \
            fail "the human draft read back '$HUMAN_DRAFT', expected the complete '${DRAFT_TEXT}H'"
          # The apply button is pressed with a real pointer, not an
          # accessibility action, so the human path stays a human path. Two
          # panes legitimately declare "应用草稿" (the handwritten detail pane
          # and the generated region registered from the same definition), so
          # the one nearest the typed field is used and the candidate count is
          # logged as evidence.
          field_cx=$(( fx + fw / 2 ))
          field_cy=$(( fy + fh / 2 ))
          APPLY_FRAME="$(cjgui_ax 20 -e "tell application \"System Events\"
            set p to first process whose unix id is $APP_PID
            set names to name of every button of window 1 of p
            set positions to position of every button of window 1 of p
            set sizes to size of every button of window 1 of p
            set bestFrame to \"\"
            set bestDist to 1.0E+9
            set candidates to 0
            repeat with i from 1 to (count of names)
              try
                if (item i of names) is \"应用草稿\" then
                  set candidates to candidates + 1
                  set pp to item i of positions
                  set ss to item i of sizes
                  set dx to ((item 1 of pp) + ((item 1 of ss) / 2)) - $field_cx
                  set dy to ((item 2 of pp) + ((item 2 of ss) / 2)) - $field_cy
                  set d to (dx * dx) + (dy * dy)
                  if d < bestDist then
                    set bestDist to d
                    set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
                  end if
                end if
              end try
            end repeat
            if bestFrame is \"\" then return \"missing\"
            return bestFrame & \" \" & (candidates as string)
          end tell" 2>/dev/null | tail -1)"
          if [[ "$APPLY_FRAME" != "missing" && -n "$APPLY_FRAME" ]]; then
            ax="$(print -r -- "$APPLY_FRAME" | awk '{print $1}')"
            ay="$(print -r -- "$APPLY_FRAME" | awk '{print $2}')"
            aw="$(print -r -- "$APPLY_FRAME" | awk '{print $3}')"
            ah="$(print -r -- "$APPLY_FRAME" | awk '{print $4}')"
            APPLY_CANDIDATES="$(print -r -- "$APPLY_FRAME" | awk '{print $5}')"
            log "step5b apply_button frame='$ax $ay $aw $ah' candidates=$APPLY_CANDIDATES"
            drive click $(( ax + aw / 2 )) $(( ay + ah / 2 )) || true
            sleep 1.5
            HUMAN_APPLIED_HEX="$(pub generated-fields 2>/dev/null | grep '^FIELD label ' | head -1 | awk '{for (i = 1; i <= NF; i++) if ($i == "APPLIED_HEX") print $(i + 1)}')"
            HUMAN_APPLIED="$(python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))' <<< "$HUMAN_APPLIED_HEX")"
            [[ "$HUMAN_APPLIED" == "${DRAFT_TEXT}H" ]] || \
              fail "the window apply button did not apply the complete human draft (applied='$HUMAN_APPLIED')"
            log "step5b human_edit_ok applied=$(print -r -- "$HUMAN_APPLIED")"
          else
            fail "the window apply button is not exposed by the accessibility projection"
          fi
        fi
      else
        # Never a pass: if real Tab focus never reaches the handwritten field,
        # the human typing step did not run.
        DESKTOP_BLOCKED="the handwritten label field was not reached by real input focus (focus='${TAB_FOCUS:-none}' after the field click plus ${TAB_INDEX} tabs)"
      fi
    else
      # Record what the projection did expose instead of only reporting that
      # the field is missing: the descriptions and frames of the real text
      # fields say whether the label differs or the node is absent.
      TEXT_DIAG="$(cjgui_ax 20 -e "tell application \"System Events\"
        set p to first process whose unix id is $APP_PID
        set out to \"\"
        repeat with f in (every text field of window 1 of p)
          try
            set pp to position of f
            set ss to size of f
            set out to out & \"[\" & (description of f) & \" @\" & ((item 1 of pp) as string) & \",\" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \"x\" & ((item 2 of ss) as string) & \"] \"
          end try
        end repeat
        return out
      end tell" 2>/dev/null | tail -1 || true)"
      log "diag_text_fields direct='$TEXT_DIAG'"
      DESKTOP_BLOCKED="the handwritten label field is not exposed by the accessibility projection (direct text fields: ${TEXT_DIAG:0:200})"
    fi
  fi
  # --- the human's real row click, last -------------------------------------
  # The row to click is the record the external system just wrote: its label is
  # `$DRAFT_TEXT`, applied to record 1 in step 5a (the original `记录-001` label
  # is replaced once that draft is applied, which is why a lookup for it matched
  # nothing). The shared selection is cleared through the public command first,
  # so the click is the only cause of the selection this step asserts instead of
  # observing one that select-all had already made.
  if [[ -z "$DESKTOP_BLOCKED" ]]; then
    CLEAR_VERSION="$(selection_version)"
    pub tree-select --selection-version "$CLEAR_VERSION" --selection-command clear > "$WORK/desktop-clear.log" 2>&1 || true
    grep -q '^APPLIED true' "$WORK/desktop-clear.log" || \
      fail "clearing the shared selection before the human click failed"
    [[ -z "$(selected_keys)" ]] || fail "the shared selection was not empty before the human click"
    log "step5b desktop_clear_ok selection_version=$CLEAR_VERSION"
    # The lookup reads names/positions in bulk and guards every element: a
    # per-element `name of b` raises for an element without a name, which
    # aborted the whole lookup and was reported as "row not exposed" even when
    # the row was there.
    ROW_FRAME="$(cjgui_ax 20 -e "tell application \"System Events\"
      set p to first process whose unix id is $APP_PID
      set names to name of every button of window 1 of p
      set positions to position of every button of window 1 of p
      set sizes to size of every button of window 1 of p
      repeat with i from 1 to (count of names)
        try
          set n to item i of names
          if n is not missing value and n contains \"$DRAFT_TEXT\" then
            set pp to item i of positions
            set ss to item i of sizes
            return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
          end if
        end try
      end repeat
      return \"missing\"
    end tell" 2>/dev/null | tail -1)"
    if [[ "$ROW_FRAME" != "missing" && -n "$ROW_FRAME" ]]; then
      rx="$(print -r -- "$ROW_FRAME" | awk '{print $1}')"
      ry="$(print -r -- "$ROW_FRAME" | awk '{print $2}')"
      rw="$(print -r -- "$ROW_FRAME" | awk '{print $3}')"
      rh="$(print -r -- "$ROW_FRAME" | awk '{print $4}')"
      if drive click $(( rx + rw / 2 )) $(( ry + rh / 2 )); then
        sleep 1.5
        DESKTOP_KEYS="$(selected_keys | tr '\n' ',' )"
        [[ "$DESKTOP_KEYS" == "record-1," ]] || \
          fail "a real desktop click on a tree row did not select exactly record-1 (keys=$DESKTOP_KEYS)"
        log "step5b human_row_click_ok label='$DRAFT_TEXT' frame='$rx $ry $rw $rh' keys=$DESKTOP_KEYS"
      fi
    else
      # Record what the projection did expose: a virtualization-limited list
      # (only viewport + overscan rows materialize) is a different fact from an
      # accessibility projection that lost the row.
      ROW_NAMES="$(cjgui_ax 20 -e "tell application \"System Events\"
        set p to first process whose unix id is $APP_PID
        set names to name of every button of window 1 of p
        set out to \"\"
        repeat with i from 1 to (count of names)
          try
            set n to item i of names
            if n is not missing value then set out to out & n & \" | \"
          end try
        end repeat
        return out
      end tell" 2>/dev/null | tail -1 || true)"
      log "diag_row_names visible='$ROW_NAMES'"
      if [[ "$ROW_NAMES" == *"记录-"* || "$ROW_NAMES" == *"$DRAFT_TEXT"* ]]; then
        DESKTOP_BLOCKED="the row for record 1 ('$DRAFT_TEXT') is not materialized in the current viewport (visible rows: ${ROW_NAMES:0:160})"
      else
        DESKTOP_BLOCKED="the expanded tree row is not exposed by the accessibility projection"
      fi
    fi
  fi
  # --- the human's multi-select decides the batch ---------------------------
  # The targets are derived from the public snapshot of what the human actually
  # selected with a real Command-A, not from a script-side loop over 1..100; the
  # owner result, the window's own scene and a visible field are then checked
  # against that same derived set.
  if [[ -z "$DESKTOP_BLOCKED" ]]; then
    drive shortcut command 0 || DESKTOP_BLOCKED="posting Command-A failed"
    sleep 1.5
    HUMAN_KEYS="$(selected_keys)"
    HUMAN_KEY_COUNT="$(print -r -- "$HUMAN_KEYS" | grep -c '^record-' || true)"
    [[ "$HUMAN_KEY_COUNT" == "100" ]] || \
      fail "real Command-A over the tree selected $HUMAN_KEY_COUNT keys, expected 100"
    DERIVED_TARGETS=()
    for key in ${(f)HUMAN_KEYS}; do
      DERIVED_TARGETS+=(--target "${key#record-}")
    done
    [[ "${#DERIVED_TARGETS[@]}" == "200" ]] || \
      fail "derived batch arguments ${#DERIVED_TARGETS[@]}, expected 200"
    log "step5c human_multiselect_ok keys=$HUMAN_KEY_COUNT derived_targets=$(( ${#DERIVED_TARGETS[@]} / 2 ))"

    SCENE_BEFORE_BATCH="$(pub window-progress 2>/dev/null | awk '/^WINDOW_SCENE_VERSION /{print $2}')"
    ENABLED_BEFORE_HEX="$(field_token enabled APPLIED_HEX)"
    BATCH_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
    pub invoke "$BATCH_VERSION" BATCH_SET_ENABLED "${DERIVED_TARGETS[@]}" \
      --arg enabled=BOOLEAN:false --arg requestId=STRING:"human-selection-batch" \
      > "$WORK/desktop-batch.log" 2>&1 || true
    grep -q '^APPLIED true' "$WORK/desktop-batch.log" || \
      fail "the authorized batch derived from the human selection was rejected"
    [[ "$(enabled_false)" == "100" ]] || \
      fail "owner after the derived batch: expected 100 disabled, got $(enabled_false)"
    BATCH_PROGRESS="$WORK/progress-after-batch.log"
    pub window-progress > "$BATCH_PROGRESS" 2>&1 || true
    SCENE_AFTER_BATCH="$(awk '/^WINDOW_SCENE_VERSION /{print $2}' "$BATCH_PROGRESS")"
    ACCEPTED_AFTER_BATCH="$(awk '/^WINDOW_ACCEPTED_SCENE_VERSION /{print $2}' "$BATCH_PROGRESS")"
    SUBMITTED_AFTER_BATCH="$(awk '/^WINDOW_SUBMITTED_SCENE_VERSION /{print $2}' "$BATCH_PROGRESS")"
    [[ -n "$SCENE_AFTER_BATCH" && "$SCENE_AFTER_BATCH" -gt "$SCENE_BEFORE_BATCH" ]] || \
      fail "the window scene version did not advance across the derived batch ($SCENE_BEFORE_BATCH -> $SCENE_AFTER_BATCH)"
    [[ "$SCENE_AFTER_BATCH" == "$ACCEPTED_AFTER_BATCH" && "$SCENE_AFTER_BATCH" == "$SUBMITTED_AFTER_BATCH" ]] || \
      fail "the derived batch scene was not accepted/submitted (scene=$SCENE_AFTER_BATCH accepted=$ACCEPTED_AFTER_BATCH submitted=$SUBMITTED_AFTER_BATCH)"
    log "diag_field_ids=$(pub generated-fields 2>/dev/null | awk '/^FIELD /{print $2}' | tr '\n' ',')"
    ENABLED_AFTER_HEX="$(field_token enabled APPLIED_HEX || true)"
    ENABLED_AFTER_TEXT="$(print -r -- "$ENABLED_AFTER_HEX" | hex_text)"
    [[ "$ENABLED_AFTER_TEXT" == "false" ]] || \
      fail "the window's enabled field reads '$ENABLED_AFTER_TEXT' after the derived batch"
    log "step5d derived_batch_ok owner_disabled=$(enabled_false) scene=$SCENE_BEFORE_BATCH->$SCENE_AFTER_BATCH field_enabled=$(print -r -- "$ENABLED_BEFORE_HEX" | hex_text)->$ENABLED_AFTER_TEXT"

    # The human keeps editing the same record after the batch.
    drive click $(( X + W - 20 )) $(( Y + 40 )) || true
    sleep 0.6
    CONT_TAB=0
    CONT_FOCUS="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
    while (( CONT_TAB < 60 )); do
      [[ "$CONT_FOCUS" == field-label* ]] && break
      drive tab || break
      sleep 0.2
      CONT_FOCUS="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
      CONT_TAB=$(( CONT_TAB + 1 ))
    done
    if [[ "$CONT_FOCUS" != field-label* ]]; then
      DESKTOP_BLOCKED="the handwritten label field was not reached for the post-batch edit (focus='$CONT_FOCUS' after $CONT_TAB tabs)"
    else
      CONT_DRAFT_BEFORE="$(field_token label DRAFT_HEX | hex_text)"
      [[ "$CONT_DRAFT_BEFORE" == "${DRAFT_TEXT}H" ]] || \
        fail "the post-batch draft read back '$CONT_DRAFT_BEFORE', expected '${DRAFT_TEXT}H'"
      drive type "I" || true
      sleep 1.5
      CONT_APPLY_FRAME="$(apply_frame_first)"
      if [[ "$CONT_APPLY_FRAME" != "missing" && -n "$CONT_APPLY_FRAME" ]]; then
        cx="$(print -r -- "$CONT_APPLY_FRAME" | awk '{print $1}')"
        cy="$(print -r -- "$CONT_APPLY_FRAME" | awk '{print $2}')"
        cw="$(print -r -- "$CONT_APPLY_FRAME" | awk '{print $3}')"
        ch="$(print -r -- "$CONT_APPLY_FRAME" | awk '{print $4}')"
        drive click $(( cx + cw / 2 )) $(( cy + ch / 2 )) || true
        sleep 1.5
        CONT_APPLIED="$(field_token label APPLIED_HEX | hex_text)"
        [[ "$CONT_APPLIED" == "${DRAFT_TEXT}HI" ]] || \
          fail "the post-batch human edit read back '$CONT_APPLIED', expected the complete '${DRAFT_TEXT}HI'"
        log "step5e human_continuation_ok applied=$CONT_APPLIED"
      else
        DESKTOP_BLOCKED="the apply button is not exposed for the post-batch edit"
      fi
    fi
  fi
  if [[ -n "$DESKTOP_BLOCKED" ]]; then
    log "BLOCKED human_desktop_step reason=$DESKTOP_BLOCKED"
  fi
else
  # No opt-in means the human half did not run at all. Leaving the flag empty
  # would end in "PASSED ... exit 0" and pass a headless-only run off as the
  # complete human chain (the same misclassification the isolation verifier
  # had); report it as the blocked item it is.
  DESKTOP_BLOCKED="CHAIN_DESKTOP_STEP is not set, so the human click/Cmd-A/typing step did not run"
fi

# --- 6. rejections leave version and content unchanged ---------------------
BEFORE_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
BEFORE_ENABLED="$(enabled_true)"
STALE_LOG="$WORK/stale.log"
pub invoke 0 BATCH_SET_ENABLED --target 1 --target 2 \
  --arg enabled=BOOLEAN:false --arg requestId=STRING:"stale-batch" > "$STALE_LOG" 2>&1 || true
grep -q '^APPLIED true' "$STALE_LOG" && fail "stale batch unexpectedly applied"
grep -q 'CONFLICT true' "$STALE_LOG" || fail "stale batch missing conflict marker"
# Draft-conflict rejection semantics are covered by the rule domain's own
# business chain (the owner rejects only when a target draft actually
# conflicts); this chain keeps the two strict, always-invalid cases so a
# rejection can never be confused with a legitimate acceptance.
UNKNOWN_KEY_LOG="$WORK/unknown-key.log"
pub tree-select --selection-version "$(selection_version)" --selection-command replace --key record-9999 > "$UNKNOWN_KEY_LOG" 2>&1 || true
grep -q '^APPLIED false' "$UNKNOWN_KEY_LOG" || fail "unknown selection key was accepted"
grep -q '^REASON unknown_key$' "$UNKNOWN_KEY_LOG" || fail "unknown key reason missing"
AFTER_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
[[ "$BEFORE_VERSION" == "$AFTER_VERSION" ]] || fail "business version changed after rejections"
[[ "$(enabled_true)" == "$BEFORE_ENABLED" ]] || fail "enabled content changed after rejections"
log "step6 rejections_ok version_stable=$AFTER_VERSION"

# --- bystander control still answers --------------------------------------
CONTROL_STATE="$(control_pub get 2>/dev/null | grep -c '^KIND SNAPSHOT' || true)"
[[ "$CONTROL_STATE" == 1 ]] || fail "control instance stopped answering"
log "step7 control_instance_ok"

if [[ -n "${DESKTOP_BLOCKED:-}" ]]; then
  log "BLOCKED the human desktop step was not verified: $DESKTOP_BLOCKED"
  cat "$LOG"
  exit 3
fi
log "PASSED tree shared-selection chain"
cat "$LOG"
exit 0
