#!/usr/bin/env zsh
# Human interaction with a RUNTIME-GENERATED action button, verified through
# the public projections only.
#
# The human path for a generated action is an AX press on the generated button:
# the human presses it and the owning domain applies the draft; the public field
# read then shows the applied value. The generated button label is unique so the
# press cannot hit a handwritten button with the same caption. A locked session
# exposes no AX window for this bundle (measured: System Events answers -1719 for
# `window 1`), so the run reports BLOCKED before pressing anything instead of
# recording an undelivered press as a product failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_GENERATED_ACTION_TMPDIR:-/private/tmp/cjgui-generated-action}"
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

# A locked session exposes no AX window for this bundle: System Events answers
# -1719 "invalid index" for `window 1`, so the human press below cannot be
# delivered at all. That is an environment precondition, not a product
# failure, and it is reported as BLOCKED (exit 3) with the measured lock
# evidence; the sweep classifies exit 3 as BLOCKED.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "generated-action human chain: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); System Events cannot address the generated button's window" >&2
  exit 3
fi

# --- per-round instance (own bundle id, exec name, directory, descriptor) ---
NAME_TOKEN="CJGUIRuleSet"
BUNDLE_TOKEN="org.cangjie.cjgui.rule-set.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "GenAction${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}GenAction${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}GenAction${RUN_TAG}"
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
field_value() { # <TAG>
  pub generated-fields 2>/dev/null | awk '/^FIELD label /{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}' tag="$1" \
    || pub generated-fields 2>/dev/null | awk -v tag="$1" '/^FIELD label /{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}'
}
hex_to_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }

# Record + draft that is only applied through the generated button.
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"动作验收" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"act-create" \
  > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
RECORD_ID="$(pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2}' | head -1)"
[[ -n "$RECORD_ID" ]] || fail "created record not visible"
DRAFT_TEXT="生成按钮写入的草稿"
pub invoke 1 EDIT_DRAFT_TEXT --target "$RECORD_ID" --arg fieldId=STRING:label \
  --arg text=STRING:"$DRAFT_TEXT" --arg expectedDraftVersion=INTEGER:0 > "$WORK/draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/draft.log" || fail "draft edit failed"
DRAFT_HEX="$(field_value DRAFT_HEX)"
APPLIED_BEFORE="$(field_value APPLIED_HEX)"
[[ "$DRAFT_HEX" != "$APPLIED_BEFORE" ]] || fail "draft and applied are not separated before the press"

# Generated structure with a UNIQUE action label.
cat > "$WORK/s1.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 humanField textInput field=label
PROPERTY 1 humanField label 生成输入框
NODE 1 pressApply action action=APPLY_DRAFT
PROPERTY 1 pressApply label 生成按钮应用草稿
END
S1
pub generated-submit --structure-version 0 --payload-file "$WORK/s1.txt" > "$WORK/submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit.log" || fail "generated structure candidate was rejected"
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/submit.log" || fail "candidate receipt not reported"
wait_for_structure_version 1 || fail "generated structure was never scene-accepted"

# Human press on the generated button (unique caption, AX action).
osascript -e "tell application \"System Events\"
  set p to first process whose unix id is $APP_PID
  set frontmost of p to true
  perform action \"AXRaise\" of window 1 of p
  click button \"生成按钮应用草稿\" of window 1 of p
end tell" > "$WORK/ax-press.log" 2>&1 || true
sleep 2

APPLIED_AFTER="$(field_value APPLIED_HEX)"
APPLIED_TEXT="$(print -r -- "$APPLIED_AFTER" | hex_to_text)"
[[ "$APPLIED_TEXT" == "$DRAFT_TEXT" ]] || fail "generated action did not apply the draft (applied='$APPLIED_TEXT')"
DRAFT_AFTER="$(field_value DRAFT_HEX)"
[[ "$(print -r -- "$DRAFT_AFTER" | hex_to_text)" == "$DRAFT_TEXT" ]] || fail "draft changed unexpectedly"
log "human_press_ok generated_button_applied applied=$(print -r -- "$APPLIED_TEXT")"
log "PASSED generated-action human chain"
cat "$LOG"
exit 0
