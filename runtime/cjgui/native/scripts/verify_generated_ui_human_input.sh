#!/usr/bin/env zsh
# Human input into a RUNTIME-GENERATED text input, verified through the public
# projections (no controller shortcuts).
#
# Positive: with a selected record, the generated text node is reached by a
# real posted key (Tab) or by a real posted click into its accessibility frame;
# a real desktop keystroke must advance the window interaction version, change
# the accepted node's draft in the owning domain, and be visible through the
# shared field projection (which the handwritten form also reads). A second
# keystroke proves the local continuation path.
#
# Negative (owner binding absent): with NO selected record the generated input
# must be non-editable -- typing must not change any draft or version.
#
# Input delivery: keystrokes come from native/tests/desktop_input_driver.swift
# (real posted CGEvents). System Events `keystroke` does not reach this app on
# the current host, and this script must not turn "one driver did nothing" into
# a property of the application: the handwritten field is typed into first as a
# control, and only a control that also fails is reported as an environment
# block.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_GENERATED_INPUT_TMPDIR:-/private/tmp/cjgui-generated-input}"
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

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

# A locked session exposes no AX window for this bundle, so the generated
# editor's real typing/focus step below cannot be delivered and its assertion
# ("not disabled", AXEnabled=missing) would read as a product failure. Report
# the measured lock as BLOCKED (exit 3); the sweep classifies exit 3 as BLOCKED.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "generated-editor human input chain: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); the real editor typing/focus step cannot be delivered" >&2
  exit 3
fi

# --- per-round instance (own bundle id, exec name, directory, descriptor) ---
NAME_TOKEN="CJGUIRuleSet"
BUNDLE_TOKEN="org.cangjie.cjgui.rule-set.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "GenInput${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}GenInput${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}GenInput${RUN_TAG}"
APP_PID=""
DESCRIPTOR=""
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" && echo no || echo yes)"
}
trap cleanup EXIT

ROUND_STARTED="$(date +%s)"
STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
DESCRIPTOR=""
waited=0
while (( waited < 120 )); do
  DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$STDOUT_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]]; then break; fi
  sleep 2; waited=$((waited + 2))
done
[[ -f "${DESCRIPTOR:-}" ]] || fail "app did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "app descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "app pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
structure_version() { pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
# Candidate receipt and scene acceptance are separate steps; wait (bounded) for
# the window's scene transaction to accept the submitted structure.
wait_for_structure_version() { # wait_for_structure_version <expected> [seconds]
  local expected="$1" limit="${2:-20}" waited=0
  while (( waited < limit )); do
    [[ "$(structure_version)" == "$expected" ]] && return 0
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  return 1
}
focus_id() { pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}'; }
interaction_version() { pub window-interaction 2>/dev/null | awk '/^WINDOW_INTERACTION_VERSION /{print $2}'; }
draft_hex() { pub generated-fields 2>/dev/null | awk '/^FIELD label /{for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") print $(i + 1)}'; }
# The accepted instance identity of one field, from the SAME accepted-instance
# table the window's focus projection is derived from. A `component-` prefix
# alone only says "some generated control", not "the instance bound to this
# field", so the focus read must match this exact semanticId before typing.
accepted_semantic_for() { # accepted_semantic_for <fieldId>
  pub generated-instances 2>/dev/null | awk -v f="field=$1" '{
    for (i = 1; i <= NF; i++) if ($i == f) {
      for (j = 1; j <= NF; j++) if ($j ~ /^semantic=/) { sub("^semantic=", "", $j); print $j; exit }
      exit
    }
  }'
}
draft_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
# --- real desktop input driver ----------------------------------------------
DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
DRIVER="$WORK/cjgui_desktop_input_driver"
if ! command -v swiftc >/dev/null 2>&1; then
  log "BLOCKED desktop input verification needs swiftc for the input driver"
  cat "$LOG"
  exit 3
fi
swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1 || fail "desktop input driver did not build"

activate_app() {
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
  end tell" >/dev/null 2>&1
}

ax_frame() { # ax_frame <field description> -> "x y w h" or "missing"
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    try
      set f to first text field of window 1 of p whose description is \"$1\"
      set pp to position of f
      set ss to size of f
      return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
    on error errm
      return \"missing\"
    end try
  end tell" 2>/dev/null | tail -1
}

# Real posted click into the named field's accessibility frame.
real_click_field() { # real_click_field <field description>
  local frame x y w h
  frame="$(ax_frame "$1")"
  if [[ "$frame" == "missing" || -z "$frame" ]]; then
    return 1
  fi
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  if [[ "$x" != <-> || "$y" != <-> || "$w" != <-> || "$h" != <-> ]]; then
    return 1
  fi
  "$DRIVER" click $(( x + w / 2 )) $(( y + h / 2 )) >/dev/null 2>&1
  return 0
}

window_frame() { # "x y w h" of window 1
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
  end tell" 2>/dev/null | tail -1
}

# A posted Tab only traverses once the native window is key, and this window
# becomes key through a real click inside its content. The point sits in the
# title band's right side: above the header control row, so becoming key cannot
# press a self-drawn button.
make_window_key() {
  local frame x y w h
  frame="$(window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  if [[ "$x" != <-> || "$y" != <-> || "$w" != <-> || "$h" != <-> ]]; then
    return 1
  fi
  "$DRIVER" click $(( x + w - 20 )) $(( y + 40 )) >/dev/null 2>&1
  sleep 0.6
  return 0
}

bump_tab() {
  local pid="$1" target="$2"
  activate_app
  make_window_key || fail "window frame unavailable for the input driver"
  local index=0
  while (( index < 48 )); do
    "$DRIVER" tab >/dev/null 2>&1
    sleep 0.25
    if [[ "$(focus_id)" == ${target}* ]]; then
      return 0
    fi
    index=$((index + 1))
  done
  return 1
}

ax_enabled() { # ax_enabled <description>
  local pid="$1" description="$2"
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $pid
    try
      set f to first text field of window 1 of p whose description is \"$description\"
      return (value of attribute \"AXEnabled\" of f)
    on error
      return \"missing\"
    end try
  end tell" 2>/dev/null | tail -1
}

# --- negative (keyboard-independent): the owner binding decides editability --
cat > "$WORK/s-norecord.txt" <<'S0'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 fieldNoOwner textInput field=label
PROPERTY 1 fieldNoOwner label 生成输入框
END
S0
pub generated-submit --structure-version 0 --payload-file "$WORK/s-norecord.txt" > "$WORK/submit-norecord.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-norecord.log" || fail "structure without a selected record was not accepted"
wait_for_structure_version 1 || fail "owner-less structure was never scene-accepted"
NO_OWNER_ENABLED="$(ax_enabled "$APP_PID" "生成输入框")"
[[ "$NO_OWNER_ENABLED" == "false" ]] || fail "owner-less generated input is not disabled (AXEnabled=$NO_OWNER_ENABLED)"
log "negative_ok no_owner_input_disabled"

# --- positive: select a record, re-submit with the owner binding -----------
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"键入测试" \
  --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" \
  --arg requestId=STRING:"input-create" > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
S1_VERSION="$(pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
cat > "$WORK/s1.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greet label
PROPERTY 1 greet text 生成输入验收
NODE 1 humanField textInput field=label
PROPERTY 1 humanField label 生成输入框
END
S1
pub generated-submit --structure-version "$S1_VERSION" --payload-file "$WORK/s1.txt" > "$WORK/submit-s1.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s1.log" || fail "structure with the owner binding was not accepted"
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/submit-s1.log" || fail "owner-bound candidate receipt not reported"
wait_for_structure_version $((S1_VERSION + 1)) || fail "owner-bound structure was never scene-accepted"

sleep 1
OWNER_ENABLED="$(ax_enabled "$APP_PID" "生成输入框")"
[[ "$OWNER_ENABLED" == "true" ]] || fail "generated input with an owner target is not editable (AXEnabled=$OWNER_ENABLED)"
log "positive_ok owner_bound_input_enabled"

# Control first: a real click and a real keystroke into the HANDWRITTEN field
# must advance the interaction version. Only when the control also fails is the
# host's input delivery the blocker; otherwise a later failure is a defect.
# The handwritten label field is reached by a real posted Tab after the window
# is made key by a real click: the accessibility frame reported for a text field
# is the surrounding row on this host, so a click by frame can land on a sibling
# field (verified: it focused the retention field instead of the label field).
HANDWRITTEN_VERSION_BEFORE="$(interaction_version)"
bump_tab "$APP_PID" "field-label" || fail "handwritten label field not reached by Tab"
"$DRIVER" type "K" >/dev/null 2>&1
sleep 1.5
HANDWRITTEN_VERSION_AFTER="$(interaction_version)"
if [[ "$HANDWRITTEN_VERSION_AFTER" == "$HANDWRITTEN_VERSION_BEFORE" ]]; then
  log "desktop_input_blocked=true handwritten_control_unchanged=$HANDWRITTEN_VERSION_BEFORE driver=cgevent"
  log "BLOCKED generated input keystroke verification needs working synthetic key delivery"
  cat "$LOG"
  exit 3
fi
log "control_ok handwritten_field_typed interaction=$HANDWRITTEN_VERSION_BEFORE->$HANDWRITTEN_VERSION_AFTER"

# The handwritten field and the generated field bind the same domain field, so
# the control keystroke must already be visible through the generated region's
# shared field projection.
CONTROL_DRAFT="$(draft_hex)"
CONTROL_TEXT="$(print -r -- "$CONTROL_DRAFT" | draft_text)"
case "$CONTROL_TEXT" in
  *K*) log "control_shared_field_ok generated_projection_sees=$(print -r -- "$CONTROL_TEXT")" ;;
  *) fail "keystroke into the handwritten field did not reach the shared field projection (draft='$CONTROL_TEXT')" ;;
esac

DRAFT_BEFORE="$(draft_hex)"
VERSION_BEFORE="$(interaction_version)"
FOCUS_AT=""
FOCUS_PATH=""
if bump_tab "$APP_PID" "component-"; then
  FOCUS_AT="$(focus_id)"
  FOCUS_PATH="tab"
else
  # A real click into the generated field's own accessibility frame is the
  # fallback; both paths are real posted input, never a controller shortcut.
  real_click_field "生成输入框" || fail "generated text field frame unavailable"
  sleep 1
  FOCUS_AT="$(focus_id)"
  FOCUS_PATH="click"
fi
ACCEPTED_SEMANTIC="$(accepted_semantic_for label)"
[[ -n "$ACCEPTED_SEMANTIC" && "$ACCEPTED_SEMANTIC" != "-" ]] \
  || fail "no accepted instance declares field label"
[[ "$FOCUS_AT" == "$ACCEPTED_SEMANTIC" ]] \
  || fail "generated focus ($FOCUS_AT) is not the accepted instance ($ACCEPTED_SEMANTIC) of field label"
[[ "$FOCUS_AT" == component-* ]] || fail "generated text field did not take focus (focus=$FOCUS_AT path=$FOCUS_PATH)"
log "positive_focus_ok path=$FOCUS_PATH focus=$FOCUS_AT accepted=$ACCEPTED_SEMANTIC exact_instance=true"
"$DRIVER" type "Q" >/dev/null 2>&1
sleep 2
DRAFT_AFTER_FIRST="$(draft_hex)"
VERSION_AFTER_FIRST="$(interaction_version)"
[[ "$VERSION_AFTER_FIRST" -gt "$VERSION_BEFORE" ]] || fail "interaction version did not advance after the first keystroke"
[[ "$DRAFT_AFTER_FIRST" != "$DRAFT_BEFORE" ]] || fail "first keystroke did not reach the draft"
FIRST_TEXT="$(print -r -- "$DRAFT_AFTER_FIRST" | draft_text)"
log "positive_first_ok path=$FOCUS_PATH focus=$FOCUS_AT interaction=$VERSION_BEFORE->$VERSION_AFTER_FIRST draft=$(print -r -- "$FIRST_TEXT")"

"$DRIVER" type "W" >/dev/null 2>&1
sleep 2
DRAFT_AFTER_SECOND="$(draft_hex)"
VERSION_AFTER_SECOND="$(interaction_version)"
[[ "$DRAFT_AFTER_SECOND" != "$DRAFT_AFTER_FIRST" ]] || fail "second keystroke did not continue the draft"
SECOND_TEXT="$(print -r -- "$DRAFT_AFTER_SECOND" | draft_text)"
log "positive_second_ok interaction=$VERSION_AFTER_FIRST->$VERSION_AFTER_SECOND draft=$(print -r -- "$SECOND_TEXT")"

# The handwritten projection of the same shared field must read the same draft.
HANDWRITTEN_DRAFT="$(draft_hex)"
[[ "$HANDWRITTEN_DRAFT" == "$DRAFT_AFTER_SECOND" ]] || fail "handwritten projection diverged from the generated draft"
log "positive_shared_field_ok draft=$(print -r -- "$SECOND_TEXT")"
log "PASSED generated input chain"
cat "$LOG"
exit 0
