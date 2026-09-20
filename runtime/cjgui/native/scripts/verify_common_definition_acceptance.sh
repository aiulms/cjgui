#!/usr/bin/env zsh
# Common-definition acceptance on the rule-set consumer, verified through the
# public connection only.
#
# 1. one field definition serves the handwritten binding, the external query
#    and the generated region (same field id + same field resource)
# 2. the registered catalog bounds are the SAME description the validator
#    enforces (a declared property limit rejects an over-limit candidate)
# 3. a conditional state change invalidates an older request (structure CAS and
#    business CAS both reject stale expectations)
# 4. draft and applied values stay separate while the draft is unapplied
# 5. two compatible presentations (handwritten form + generated region) read
#    the same live field projection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_COMMON_DEFINITION_TMPDIR:-/private/tmp/cjgui-common-definition}"
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
# Desktop-input outcome for the final exit classification (see the tail):
# INPUT_BLOCKED is reserved for a proven environment/tool limitation, while
# INPUT_FAILED means a real control input was not delivered and the fallback
# was used. The inject hook exists only for the bounded negative controls in
# verify_common_definition_acceptance_exit_paths.sh.
INPUT_FAILED=""
INJECT="${CJGUI_ACCEPTANCE_INJECT:-none}"

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
# Real desktop input helpers (driver build, AX frame walk, bounded type +
# owner read-back). Defined AFTER WORK/CLIENT/RUNTIME_DIR below, so the driver
# preparation call sits with the launched instance.
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

# --- per-round instance (own bundle id, exec name, directory, descriptor) ---
NAME_TOKEN="CJGUIRuleSet"
BUNDLE_TOKEN="org.cangjie.cjgui.rule-set.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "CommonDef${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}CommonDef${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}CommonDef${RUN_TAG}"
APP_PID=""
DESCRIPTOR=""
# The boundary-change round is a second own instance with its own identity.
RANGE_PID=""
RANGE_DESC=""
RANGE_EXEC=""
RANGE_DIR=""
# Dedicated boundary comparisons (1..365 / 1..730) are further own instances.
typeset -a EXTRA_PIDS EXTRA_DESCS EXTRA_EXECS EXTRA_DIRS
EXTRA_PIDS=(); EXTRA_DESCS=(); EXTRA_EXECS=(); EXTRA_DIRS=()
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" && echo no || echo yes)"
  if [[ -n "$RANGE_EXEC" ]]; then
    cjgui_terminate_owned "$RANGE_PID" "${RANGE_DESC:-}" "$RANGE_EXEC" "$RANGE_DIR" || true
    log "cleanup: range instance closed=$(cjgui_pid_owns "$RANGE_PID" "${RANGE_DESC:-}" "$RANGE_EXEC" "$RANGE_DIR" && echo no || echo yes)"
  fi
  if (( ${#EXTRA_PIDS} > 0 )); then
    local index=1
    while (( index <= ${#EXTRA_PIDS} )); do
      cjgui_terminate_owned "${EXTRA_PIDS[index]}" "${EXTRA_DESCS[index]:-}" "${EXTRA_EXECS[index]}" "${EXTRA_DIRS[index]}" || true
      log "cleanup: boundary config instance closed=$(cjgui_pid_owns "${EXTRA_PIDS[index]}" "${EXTRA_DESCS[index]:-}" "${EXTRA_EXECS[index]}" "${EXTRA_DIRS[index]}" && echo no || echo yes)"
      index=$(( index + 1 ))
    done
  fi
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

# Real desktop input is prepared against the running instance. When the session
# is locked (or swiftc is missing) the driver is reported BLOCKED and only the
# generated-presentation segments fall back to the public invoke, which is
# recorded as `control_input_unverified` instead of passed off as control input.
prepare_desktop_driver || true
# Negative-control injection (only used by the exit-path verification script):
# `fail` proves an assertion failure propagates as exit 1, `blocked` proves a
# proven environment limitation propagates as exit 3 after the semantic segments
# still run.
if [[ "$INJECT" == "fail" ]]; then
  fail "injected assertion failure (negative control: expected exit 1)"
fi
if [[ "$INJECT" == "blocked" ]]; then
  INPUT_BLOCKED="session_locked (injected negative control: expected exit 3)"
  log "inject blocked_path reason='$INPUT_BLOCKED'"
fi
if [[ "$INJECT" == "undelivered" ]]; then
  INPUT_FAILED="injected_control_input_not_delivered (negative control: expected exit 1)"
  log "inject undelivered_path reason='$INPUT_FAILED'"
fi

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
field_line() { pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id {print; exit}'; }
field_value() { # field_value <fieldId> <TAG>
  field_line "$1" | awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}'
}
hex_to_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }

hex_to_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
structure_version() { pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
# A candidate is received immediately; the accepted version advances only when
# the window's scene transaction accepts it.
wait_for_structure_version() { # wait_for_structure_version <expected> [seconds]
  local expected="$1" limit="${2:-20}" waited=0
  while (( waited < limit )); do
    [[ "$(structure_version)" == "$expected" ]] && return 0
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  return 1
}

# --- 1. capability catalog declares the field and the bounds ---------------
CAPS="$WORK/capabilities.txt"
pub generated-capabilities > "$CAPS" 2>&1 || true
# The description publishes the whole field contract, not only the name: the
# retired `FIELD <id>`-only form is asserted as its current contract instead.
grep -q '^FIELD label TEXT resource=81001 writer=EDIT_DRAFT_TEXT' "$CAPS" || \
  fail "capability catalog does not declare the shared field contract"
grep -q '^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT' "$CAPS" || \
  fail "capability catalog does not declare the retention field contract"
grep -q '^BOUNDS ' "$CAPS" || fail "capability catalog does not declare bounds"
log "step1 field_declared_once field=label"

# --- 2. the declared bound is the enforced bound ---------------------------
BOUNDS_MAX_LEN="$(grep '^PROPERTY textInput label STRING' "$CAPS" | awk '{for (i = 1; i <= NF; i++) if ($i == "STRING") print $(i + 2)}')"
[[ -n "$BOUNDS_MAX_LEN" ]] || fail "textInput label property spec missing"
cat > "$WORK/over-limit.txt" <<'OVER'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 fld textInput field=label
PROPERTY 1 fld label 这是一个超过声明上限的标签属性值它必须在同一个目录描述的校验下被拒绝而不是被截断或静默接受即使界面其余部分完全合法也要保持旧界面可用状态继续提供正常服务并且方便后续继续使用这个结构提交必须明确失败并给出具体字段位置与原因以便调用方修正
END
OVER
pub generated-submit --structure-version 0 --payload-file "$WORK/over-limit.txt" > "$WORK/over-limit.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/over-limit.log" || fail "over-limit property was accepted"
grep -q 'REASON property_too_long' "$WORK/over-limit.log" || fail "over-limit rejection reason missing"
log "step2 declared_bound_enforced maxLength=$BOUNDS_MAX_LEN reason=property_too_long"

# --- structure + draft state ------------------------------------------------
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"共同定义" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"cd-create" \
  > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
RECORD_ID="$(pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2}' | head -1)"
[[ -n "$RECORD_ID" ]] || fail "created record not visible"

# --- 4. draft and applied stay separate ------------------------------------
pub invoke 1 EDIT_DRAFT_TEXT --target "$RECORD_ID" --arg fieldId=STRING:label \
  --arg text=STRING:"草稿未应用" --arg expectedDraftVersion=INTEGER:0 > "$WORK/draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/draft.log" || fail "draft edit failed"
DRAFT_HEX="$(field_value label DRAFT_HEX)"
APPLIED_HEX="$(field_value label APPLIED_HEX)"
[[ "$DRAFT_HEX" != "$APPLIED_HEX" ]] || fail "draft and applied are not separated"
[[ "$(print -r -- "$DRAFT_HEX" | hex_to_text)" == "草稿未应用" ]] || fail "draft read-back mismatch"
log "step4 draft_applied_separated draft=$(print -r -- "$DRAFT_HEX" | hex_to_text) applied=$(print -r -- "$APPLIED_HEX" | hex_to_text)"

# --- 5. the generated region reads the same live projection ----------------
cat > "$WORK/s1.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 sharedField textInput field=label
PROPERTY 1 sharedField label 生成输入框
NODE 1 apply action action=APPLY_DRAFT
PROPERTY 1 apply label 生成应用草稿
END
S1
pub generated-submit --structure-version 0 --payload-file "$WORK/s1.txt" > "$WORK/submit-s1.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s1.log" || fail "generated structure binding the shared field was rejected"
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/submit-s1.log" || fail "candidate receipt was not reported"
wait_for_structure_version 1 || fail "the shared-field structure was never scene-accepted"
DRAFT_AFTER_STRUCTURE="$(field_value label DRAFT_HEX)"
[[ "$DRAFT_AFTER_STRUCTURE" == "$DRAFT_HEX" ]] || fail "the shared field projection changed when the generated region appeared"
log "step5 shared_field_one_projection draft=$(print -r -- "$DRAFT_AFTER_STRUCTURE" | hex_to_text)"

# --- 3. stale expectations are rejected after the state changed ------------
STRUCTURE_VERSION="$(structure_version)"
cat > "$WORK/s2.txt" <<'S2'
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 horizontal
NODE 1 sharedField2 textInput field=label
PROPERTY 1 sharedField2 label 重排后的同一字段
END
S2
pub generated-submit --structure-version "$STRUCTURE_VERSION" --payload-file "$WORK/s2.txt" > "$WORK/submit-s2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s2.log" || fail "re-ordered structure was rejected"
wait_for_structure_version $((STRUCTURE_VERSION + 1)) || fail "re-ordered structure was never scene-accepted"
# A candidate built against the now-obsolete version is refused.
pub generated-submit --structure-version "$STRUCTURE_VERSION" --payload-file "$WORK/s2.txt" > "$WORK/stale-structure.log" 2>&1 || true
grep -q 'REASON structure_version_conflict' "$WORK/stale-structure.log" || fail "stale structure version was not rejected"
BUSINESS_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
DRAFT_FIELD_VERSION="$(field_line label | awk '{for (i = 1; i <= NF; i++) if ($i == "VERSION") print $(i + 1)}')"
pub invoke "$BUSINESS_VERSION" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$DRAFT_FIELD_VERSION" > "$WORK/apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/apply.log" || fail "apply failed"
pub invoke "$BUSINESS_VERSION" SET_SPLIT_SIZE --target 8000 --arg value=INTEGER:300 > "$WORK/stale-business.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/stale-business.log" && fail "stale business request was accepted"
log "step3 stale_rejected structure=structure_version_conflict business=conflict"

# The applied field now equals the draft: one owner, three readers.
APPLIED_AFTER="$(field_value label APPLIED_HEX)"
[[ "$(print -r -- "$APPLIED_AFTER" | hex_to_text)" == "草稿未应用" ]] || fail "applied value after apply mismatch"
log "step_all applied=$(print -r -- "$APPLIED_AFTER" | hex_to_text)"
# --- 6. the external query publishes the declared field contract ----------
# An outside caller must be able to read the business type, the shared resource,
# the declared constraints and the owner operation - not just a field name.
grep -q '^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=0 min=1 max=90 maxlen=0 callable=1' "$CAPS" || \
  fail "capability description does not publish the declared retention contract"
grep -q '^FIELD label TEXT resource=81001 writer=EDIT_DRAFT_TEXT required=0 min=0 max=0 maxlen=0 callable=1' "$CAPS" || \
  fail "capability description does not publish the label contract"
log "step6 field_contract_published retention=INTEGER/81003/EDIT_DRAFT_TEXT/1..90 label=TEXT/81001"

# --- 7. a runtime business condition refuses the whole write --------------
# A valid label draft plus an out-of-range retention draft: the apply is refused
# with the field's own reason and NOTHING is written, then the fix applies both.
EDIT_SEQ=0
record_draft_version() { field_value label VERSION; }
edit_draft_field() { # edit_draft_field <fieldId> <text> <label>
  local fieldId="$1" text="$2" tag="$3" v
  EDIT_SEQ=$(( EDIT_SEQ + 1 ))
  v="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
  pub invoke "$v" EDIT_DRAFT_TEXT --target "$RECORD_ID" --arg fieldId=STRING:"$fieldId" \
    --arg text=STRING:"$text" --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" \
    > "$WORK/edit-$EDIT_SEQ-$tag.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/edit-$EDIT_SEQ-$tag.log"
}
APPLIED_RETENTION() { field_value retentionCount APPLIED_HEX | hex_to_text; }
rename_draft() { field_value label DRAFT_HEX | hex_to_text; }
retention_draft() { field_value retentionCount DRAFT_HEX | hex_to_text; }

edit_draft_field label "整体拒绝验证" label || fail "valid label draft was rejected"
edit_draft_field retentionCount "100" retention || fail "out-of-range retention draft was rejected as a draft"
APPLY_V="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/reject-apply.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/reject-apply.log" || fail "an invalid draft was applied"
grep -q 'REASON invalid_draft' "$WORK/reject-apply.log" || fail "invalid draft reason missing"
[[ "$(field_value retentionCount ERROR)" == "retention_count_out_of_range" ]] || \
  fail "the refused field did not report its business reason"
# No partial write: neither field changed, and the drafts are still there.
[[ "$(print -r -- "$(field_value label APPLIED_HEX)" | hex_to_text)" == "草稿未应用" ]] || \
  fail "a refused apply partially wrote the valid field"
[[ "$(APPLIED_RETENTION)" == "7" ]] || fail "a refused apply changed the retention value"
[[ "$(rename_draft)" == "整体拒绝验证" ]] || fail "the refused draft was lost"
log "step7 business_rejection_ok reason=retention_count_out_of_range partial_write=false"

# Recovery: fixing the business condition applies both fields through one owner.
edit_draft_field retentionCount "30" retention-fix || fail "in-range retention draft was rejected"
APPLY_V2="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V2" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/recover-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/recover-apply.log" || fail "the recovered draft was not applied"
[[ "$(print -r -- "$(field_value label APPLIED_HEX)" | hex_to_text)" == "整体拒绝验证" ]] || \
  fail "recovered label value mismatch"
[[ "$(APPLIED_RETENTION)" == "30" ]] || fail "recovered retention value mismatch"
log "step7b business_recovery_ok applied_label=true applied_retention=30"

# --- 8. integer drafts: empty, transient, cancel, then apply --------------
# Empty required value: refused with its own reason, nothing written.
edit_draft_field retentionCount "" retention-empty || fail "empty retention draft was refused as a draft"
APPLY_V3="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V3" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/empty-apply.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/empty-apply.log" || fail "an empty required integer was applied"
[[ "$(field_value retentionCount ERROR)" == "retention_count_required" ]] || \
  fail "empty integer did not report retention_count_required"
[[ "$(APPLIED_RETENTION)" == "30" ]] || fail "empty integer changed the applied value"

# A partially typed number is a legal transient draft: kept, applied value
# unchanged, and refused at apply time with its own reason.
edit_draft_field retentionCount "12a" retention-transient || fail "transient numeric draft was rejected"
[[ "$(retention_draft)" == "12a" ]] || fail "transient numeric draft was not kept"
[[ "$(APPLIED_RETENTION)" == "30" ]] || fail "transient numeric draft changed the applied value"
APPLY_V4="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V4" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/transient-apply.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/transient-apply.log" || fail "a transient integer was applied"
[[ "$(field_value retentionCount ERROR)" == "retention_count_invalid" ]] || \
  fail "transient integer did not report retention_count_invalid"
[[ "$(retention_draft)" == "12a" ]] || fail "transient draft was lost by the refused apply"
log "step8 integer_transient_ok draft=12a applied=30 reason=retention_count_invalid"

# Cancel restores the applied value, and a completed value applies normally.
CANCEL_V="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$CANCEL_V" CANCEL_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/cancel.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/cancel.log" || fail "draft cancel failed"
[[ "$(retention_draft)" == "30" ]] || fail "cancel did not restore the applied value"
edit_draft_field retentionCount "45" retention-final || fail "completed integer draft was rejected"
APPLY_V5="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V5" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/final-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/final-apply.log" || fail "completed integer draft was not applied"
[[ "$(APPLIED_RETENTION)" == "45" ]] || fail "completed integer value mismatch"
log "step8b integer_cancel_and_apply_ok cancel_restores=30 applied=45"

# --- 9. two compatible presentations share one rule -----------------------
# The same retention field is presented by the handwritten form and by a
# generated integer editor. The out-of-range rejection must be the SAME rule and
# the same reason through both, and a valid value through the generated
# presentation must be readable through the handwritten projection.
cat > "$WORK/retention-s1.txt" <<'RET'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionField integerInput field=retentionCount
PROPERTY 1 retentionField label 保留天数编辑
NODE 1 apply action action=APPLY_DRAFT
PROPERTY 1 apply label 应用草稿
END
RET
STRUCTURE_VERSION_NOW="$(structure_version)"
pub generated-submit --structure-version "$STRUCTURE_VERSION_NOW" --payload-file "$WORK/retention-s1.txt" \
  > "$WORK/retention-submit.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/retention-submit.log" || \
  fail "the generated integer presentation of the shared field was rejected"
wait_for_structure_version $((STRUCTURE_VERSION_NOW + 1)) || fail "the integer presentation was never scene-accepted"
# The write is a REAL desktop control event on the generated integer editor, not
# a public connection shortcut: a human edit into the generated presentation and
# an external apply must be refused by the SAME rule with the SAME reason.
AX_PID="$APP_PID"
GENERATED_INPUT_FALLBACK=""
GENERATED_VALID_FALLBACK=""
HANDWRITTEN_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if real_generated_text_edit generated_reject "$DESCRIPTOR" retentionCount "保留天数编辑" "text field" "900"; then
    log "step9a generated_control_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target=900 input=real_desktop_control driver=cgevent"
  else
    INPUT_FAILED="generated_integer_input_not_delivered"
    GENERATED_INPUT_FALLBACK="public_invoke"
    log "FAIL_CANDIDATE generated_control_edit reason=not_delivered before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}' focus='$(window_focus_for "$DESCRIPTOR")'"
  fi
else
  GENERATED_INPUT_FALLBACK="public_invoke"
  log "note generated_control_edit skipped input_blocked=$INPUT_BLOCKED input_failed=$INPUT_FAILED fallback=$GENERATED_INPUT_FALLBACK"
fi
if [[ -n "$GENERATED_INPUT_FALLBACK" ]]; then
  # Keeps the rest of the round's semantics verifiable; it is recorded as a
  # fallback and never replaces the control-input evidence.
  edit_draft_field retentionCount "900" generated-presentation || fail "generated presentation draft was rejected"
  log "note generated_control_edit_fallback=public_invoke control_input_unverified=true"
fi
# Either way the out-of-range value must be present as a DRAFT: the rule bites at
# apply time, so the control must not silently clamp or refuse the typing.
[[ "$(retention_draft)" == "900" ]] || \
  fail "generated presentation did not reach the shared draft ('$(retention_draft)')"
APPLY_V6="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V6" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/generated-reject.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/generated-reject.log" || fail "generated presentation bypassed the shared rule"
GENERATED_REASON="$(field_value retentionCount ERROR)"
[[ "$GENERATED_REASON" == "retention_count_out_of_range" ]] || \
  fail "generated presentation reported '$GENERATED_REASON' instead of the shared rule"
[[ "$(APPLIED_RETENTION)" == "45" ]] || fail "generated presentation partially wrote"
# The HANDWRITTEN presentation of the same field, driven by the same real desktop
# input helper: it waits for the window's own `field-<fieldId>` focus, so the walk
# can never type into a different handwritten field. A different out-of-range
# value must produce the SAME rule reason, which is what "two compatible
# presentations share one rule" means.
HANDWRITTEN_REASON=""
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if real_focus_text_edit handwritten_reject "$DESCRIPTOR" retentionCount "field-retentionCount" "888"; then
    log "step9c handwritten_control_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target=888 input=real_desktop_control driver=cgevent"
  else
    INPUT_FAILED="handwritten_input_not_delivered"
    HANDWRITTEN_FALLBACK="public_invoke"
    log "FAIL_CANDIDATE handwritten_control_edit reason=not_delivered before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}' focus='$(window_focus_for "$DESCRIPTOR")'"
  fi
else
  HANDWRITTEN_FALLBACK="public_invoke"
  log "note handwritten_control_edit skipped input_blocked=$INPUT_BLOCKED input_failed=$INPUT_FAILED fallback=$HANDWRITTEN_FALLBACK"
fi
if [[ -n "$HANDWRITTEN_FALLBACK" ]]; then
  edit_draft_field retentionCount "888" handwritten-presentation || fail "handwritten presentation draft was rejected"
  log "note handwritten_control_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(retention_draft)" == "888" ]] || \
  fail "handwritten presentation did not reach the shared draft ('$(retention_draft)')"
APPLY_VH="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_VH" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/handwritten-reject.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/handwritten-reject.log" || fail "handwritten presentation bypassed the shared rule"
HANDWRITTEN_REASON="$(field_value retentionCount ERROR)"
[[ "$HANDWRITTEN_REASON" == "$GENERATED_REASON" ]] || \
  fail "the two presentations reported different reasons ('$HANDWRITTEN_REASON' vs '$GENERATED_REASON')"
[[ "$(APPLIED_RETENTION)" == "45" ]] || fail "handwritten presentation partially wrote"
log "step9d two_presentations_same_reason reason=$HANDWRITTEN_REASON handwritten=888 generated=900"
# Recovery through the same real control.
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if real_generated_text_edit generated_valid "$DESCRIPTOR" retentionCount "保留天数编辑" "text field" "60"; then
    log "step9b generated_control_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target=60 input=real_desktop_control driver=cgevent"
  else
    INPUT_FAILED="generated_integer_valid_input_not_delivered"
    GENERATED_VALID_FALLBACK="public_invoke"
    log "FAIL_CANDIDATE generated_valid_control_edit reason=not_delivered before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  GENERATED_VALID_FALLBACK="public_invoke"
  log "note generated_valid_control_edit skipped input_blocked=$INPUT_BLOCKED fallback=$GENERATED_VALID_FALLBACK"
fi
if [[ -n "$GENERATED_VALID_FALLBACK" ]]; then
  edit_draft_field retentionCount "60" generated-valid || fail "valid value through the generated presentation was rejected"
  log "note generated_valid_control_fallback=public_invoke control_input_unverified=true"
fi
APPLY_V7="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V7" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/generated-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/generated-apply.log" || fail "valid generated-presentation value was not applied"
[[ "$(APPLIED_RETENTION)" == "60" ]] || fail "generated presentation applied value mismatch"
# --- 9e/9f. the composite preset button, clicked for real in BOTH regions ----
# The caption/value come from the app's ONE preset configuration, derived from
# the declared bounds: nothing is copied into this script.
# The declared bounds are read from the capability payload captured at step 1
# (the same single declaration the owner enforces), not re-queried mid-flight.
RETENTION_CAP="$(grep -m1 '^FIELD retentionCount ' "$CAPS" || true)"
RETENTION_MIN="$(print -r -- "$RETENTION_CAP" | sed -n 's/.* min=\([0-9]*\).*/\1/p')"
RETENTION_MAX="$(print -r -- "$RETENTION_CAP" | sed -n 's/.* max=\([0-9]*\).*/\1/p')"
[[ -n "$RETENTION_MAX" ]] || fail "the declared retention maximum is not published"
PRESET_LABEL="设为 ${RETENTION_MAX}"
PRESET_APPLIED_BEFORE="$(APPLIED_RETENTION)"

# 9e. Handwritten region: the composite editor lives in the record edit dialog,
# so the dialog is opened with a real press on the window's own "编辑草稿"
# control first (the selected record is the one this round created).
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if ! real_ax_press_button "$APP_PID" "编辑草稿"; then
    INPUT_FAILED="handwritten_edit_dialog_not_opened"
    log "FAIL_CANDIDATE handwritten_edit_dialog_open"
  fi
fi
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if real_ax_press_button "$APP_PID" "$PRESET_LABEL"; then
    log "step9e handwritten_preset_click label='$PRESET_LABEL' input=real_desktop_control driver=ax"
  else
    INPUT_FAILED="handwritten_preset_click_not_delivered"
    log "FAIL_CANDIDATE handwritten_preset_click label='$PRESET_LABEL'"
  fi
fi
[[ "$(retention_draft)" == "$RETENTION_MAX" ]] || \
  fail "the handwritten preset click did not write the declared maximum ('$(retention_draft)' vs '$RETENTION_MAX')"
APPLY_PRESET="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_PRESET" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/preset-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/preset-apply.log" || fail "the preset draft was not applied"
[[ "$(APPLIED_RETENTION)" == "$RETENTION_MAX" ]] || fail "the applied preset value mismatch"

# 9f. Generated region: submit a candidate that presents the SAME composite kind
# (only its caption differs, from a declared property, so the AX match is
# unambiguous) and click that preset button for real.
cat > "$WORK/retention-preset-s1.txt" <<RETPRESET
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 presetField retentionIntegerEdit
PROPERTY 1 presetField presetLabel 生成预设${RETENTION_MAX}
END
RETPRESET
STRUCTURE_VERSION_PRESET="$(structure_version)"
pub generated-submit --structure-version "$STRUCTURE_VERSION_PRESET" \
  --payload-file "$WORK/retention-preset-s1.txt" > "$WORK/retention-preset-submit.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/retention-preset-submit.log" || \
  fail "the generated composite presentation was rejected"
wait_for_structure_version $((STRUCTURE_VERSION_PRESET + 1)) || \
  fail "the composite presentation was never scene-accepted"
if [[ -z "$INPUT_BLOCKED" && -z "$INPUT_FAILED" ]]; then
  if real_ax_press_button "$APP_PID" "生成预设${RETENTION_MAX}"; then
    log "step9f generated_preset_click label='生成预设${RETENTION_MAX}' input=real_desktop_control driver=ax"
  else
    INPUT_FAILED="generated_preset_click_not_delivered"
    log "FAIL_CANDIDATE generated_preset_click"
  fi
fi
[[ "$(retention_draft)" == "$RETENTION_MAX" ]] || \
  fail "the generated preset click did not write the declared maximum ('$(retention_draft)')"
log "step9ef composite_preset_ok handwritten=clicked generated=clicked value=$RETENTION_MAX min=$RETENTION_MIN applied_before=$PRESET_APPLIED_BEFORE"

GENERATED_CONTROL_INPUT="real_desktop"
if [[ -n "$GENERATED_INPUT_FALLBACK" || -n "$GENERATED_VALID_FALLBACK" || -n "$HANDWRITTEN_FALLBACK" ]]; then
  GENERATED_CONTROL_INPUT="blocked"
fi
log "step9 two_presentations_one_rule reason=$GENERATED_REASON handwritten_reason=$HANDWRITTEN_REASON both=enforced applied=60 control_input=$GENERATED_CONTROL_INPUT handwritten_control=$([[ -z "$HANDWRITTEN_FALLBACK" ]] && echo real_desktop || echo blocked)"

# --- 10. the declared boundary can be re-declared, and all three entries move
RANGE_DIR="$WORK/round-range"
cjgui_prepare_app_copy "$APP_DIR" "$RANGE_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Range${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "boundary-change round copy failed"
RANGE_EXEC="$RANGE_DIR/target/release/${NAME_TOKEN}Range${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}Range${RUN_TAG}"
RANGE_STDOUT="$WORK/range-app.log"
( cd "$RANGE_DIR" && nohup zsh run.sh --retention-range 365 730 > "$RANGE_STDOUT" 2>&1 & )
RANGE_DESC=""
waited=0
while (( waited < 150 )); do
  RANGE_DESC="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$RANGE_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$RANGE_DESC" && -f "$RANGE_DESC" ]]; then break; fi
  sleep 2; waited=$(( waited + 2 ))
done
[[ -f "${RANGE_DESC:-}" ]] || fail "boundary-change instance did not publish a descriptor"
RANGE_PID="$(cjgui_descriptor_owner_pid "$RANGE_DESC" "$RANGE_EXEC" "$RANGE_DIR" "$(date +%s)" || true)"
[[ -n "$RANGE_PID" ]] || RANGE_PID="$(cjgui_descriptor_owner_pid "$RANGE_DESC" "$RANGE_EXEC" "$RANGE_DIR" || true)"
[[ -n "$RANGE_PID" ]] || fail "boundary-change descriptor has no matching owner"
cjgui_pid_owns "$RANGE_PID" "$RANGE_DESC" "$RANGE_EXEC" "$RANGE_DIR" || fail "range pid is not this round's instance"
range_pub() { python3 "$CLIENT" "$RANGE_DESC" "$@"; }
range_pub generated-capabilities > "$WORK/range-caps.txt" 2>&1 || true
grep -q '^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=0 min=365 max=730 maxlen=0 callable=1' "$WORK/range-caps.txt" || \
  fail "the re-declared boundary was not published (external query entry)"
# The owner follows the same declaration: a value outside it is refused at
# creation, a value inside it is created.
range_pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"边界外" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:100 --arg excludedType=STRING:"-" --arg requestId=STRING:"range-out" \
  > "$WORK/range-create-out.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/range-create-out.log" || fail "the owner accepted a value outside the re-declared boundary"
grep -q 'REASON invalid_rule' "$WORK/range-create-out.log" || fail "out-of-boundary creation reason missing"
range_pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"边界内" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:500 --arg excludedType=STRING:"-" --arg requestId=STRING:"range-in" \
  > "$WORK/range-create-in.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/range-create-in.log" || fail "the owner refused a value inside the re-declared boundary"
RANGE_RECORD_ID="$(range_pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2; exit}')"
[[ -n "$RANGE_RECORD_ID" ]] || fail "boundary-change record not visible"
range_pub invoke 1 SELECT_RECORD --target "$RANGE_RECORD_ID" > "$WORK/range-select.log" 2>&1 || true
RANGE_DRAFT_V="$(range_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
range_pub invoke "$RANGE_DRAFT_V" EDIT_DRAFT_TEXT --target "$RANGE_RECORD_ID" --arg fieldId=STRING:retentionCount \
  --arg text=STRING:"600" --arg expectedDraftVersion=INTEGER:0 > "$WORK/range-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/range-edit.log" || fail "draft edit in the boundary-change round failed"
RANGE_APPLY_V="$(range_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
RANGE_FIELD_V="$(range_pub generated-fields 2>/dev/null | grep '^FIELD retentionCount ' | head -1 | awk '{for (i = 1; i <= NF; i++) if ($i == "VERSION") print $(i + 1)}')"
range_pub invoke "$RANGE_APPLY_V" APPLY_DRAFT --target "$RANGE_RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$RANGE_FIELD_V" > "$WORK/range-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/range-apply.log" || fail "in-boundary apply failed in the boundary-change round"
log "step10 redeclared_boundary_ok external_query=365..730 owner_refuses_outside=true owner_accepts_inside=true"

# --- 11. dedicated boundary comparison: 1..365 versus 1..730 --------------
# `--retention-range MIN MAX` is a STARTUP declaration (a re-declaration when the
# instance is relaunched). This step compares two startup declarations of the
# same application and states that mode explicitly; this app exposes no runtime
# range-update entry, so it is not presented as a dynamic update.
launchBoundaryConfig() { # launchBoundaryConfig <min> <max> <label>
  local min="$1" max="$2" label="$3"
  local dir="$WORK/round-range-$label"
  local execp="$dir/target/release/${NAME_TOKEN}R${label}${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}R${label}${RUN_TAG}"
  local stdout="$WORK/range-$label-app.log"
  cjgui_prepare_app_copy "$APP_DIR" "$dir" "$RUNTIME_DIR" "$NAME_TOKEN" "R${label}${RUN_TAG}" "$BUNDLE_TOKEN" \
    || fail "boundary config copy failed ($label)"
  ( cd "$dir" && nohup zsh run.sh --retention-range "$min" "$max" > "$stdout" 2>&1 & )
  CFG_DESC=""
  local waited=0
  while (( waited < 150 )); do
    CFG_DESC="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$stdout" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$CFG_DESC" && -f "$CFG_DESC" ]]; then break; fi
    sleep 2; waited=$(( waited + 2 ))
  done
  [[ -f "${CFG_DESC:-}" ]] || fail "boundary config $label did not publish a descriptor"
  CFG_PID="$(cjgui_descriptor_owner_pid "$CFG_DESC" "$execp" "$dir" || true)"
  [[ -n "$CFG_PID" ]] || fail "boundary config $label descriptor has no matching owner"
  cjgui_pid_owns "$CFG_PID" "$CFG_DESC" "$execp" "$dir" || fail "boundary config $label pid is not this round's instance"
  EXTRA_PIDS+=("$CFG_PID"); EXTRA_DESCS+=("$CFG_DESC"); EXTRA_EXECS+=("$execp"); EXTRA_DIRS+=("$dir")
}

# Three entries against ONE declaration: external query, owner creation, draft
# apply. `accept366` is true only for the 1..730 declaration; 731 must always be
# refused.
checkBoundaryConfig() { # checkBoundaryConfig <min> <max> <label> <accept366>
  local min="$1" max="$2" label="$3" accept366="$4"
  launchBoundaryConfig "$min" "$max" "$label"
  python3 "$CLIENT" "$CFG_DESC" generated-capabilities > "$WORK/caps-$label.txt" 2>&1 || true
  grep -q "^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=0 min=$min max=$max maxlen=0 callable=1" \
    "$WORK/caps-$label.txt" || fail "declared boundary $min..$max was not published (external query entry)"
  # Draft entry first, so this record is the first visible one and the draft/apply
  # check below cannot accidentally target the 366 record.
  python3 "$CLIENT" "$CFG_DESC" invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"草稿项" \
    --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:100 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"b-$label-draft" > "$WORK/create-$label-draft.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/create-$label-draft.log" || fail "in-range creation failed in 1..$max"
  local rid
  rid="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2; exit}')"
  [[ -n "$rid" ]] || fail "boundary config $label: no visible record"
  # Owner creation entry. Every invoke carries the owner's CURRENT version, so a
  # refusal can only be the business boundary - never a stale-version conflict.
  local vnow
  vnow="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/^VERSION /{print $2}')"
  python3 "$CLIENT" "$CFG_DESC" invoke "$vnow" CREATE_RECORD --target 8000 --arg label=STRING:"边界366" \
    --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:366 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"b-$label-366" > "$WORK/create-$label-366.log" 2>&1 || true
  local created366=false
  grep -q '^APPLIED true' "$WORK/create-$label-366.log" && created366=true
  [[ "$created366" == "$accept366" ]] || fail "1..$max creation of 366 was created=$created366 expected=$accept366"
  grep -q '^CONFLICT true' "$WORK/create-$label-366.log" && fail "1..$max 366 attempt was a version conflict, not a boundary verdict"
  if [[ "$created366" == "false" ]]; then
    grep -q '^REASON invalid_rule' "$WORK/create-$label-366.log" || \
      fail "1..$max refused 366 without the boundary reason"
  fi
  vnow="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/^VERSION /{print $2}')"
  python3 "$CLIENT" "$CFG_DESC" invoke "$vnow" CREATE_RECORD --target 8000 --arg label=STRING:"边界731" \
    --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:731 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"b-$label-731" > "$WORK/create-$label-731.log" 2>&1 || true
  grep -q '^APPLIED false' "$WORK/create-$label-731.log" || fail "1..$max accepted 731"
  grep -q '^REASON invalid_rule' "$WORK/create-$label-731.log" || fail "1..$max refused 731 without the boundary reason"
  grep -q '^CONFLICT true' "$WORK/create-$label-731.log" && fail "1..$max 731 attempt was a version conflict, not a boundary verdict"
  # Draft/apply entry. The record is selected with the CURRENT version so the
  # field read below really belongs to it.
  local v
  v="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/^VERSION /{print $2}')"
  python3 "$CLIENT" "$CFG_DESC" invoke "$v" SELECT_RECORD --target "$rid" > "$WORK/sel-$label.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/sel-$label.log" || fail "boundary config $label: selecting the draft record failed"
  v="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/^VERSION /{print $2}')"
  python3 "$CLIENT" "$CFG_DESC" invoke "$v" EDIT_DRAFT_TEXT --target "$rid" --arg fieldId=STRING:retentionCount \
    --arg text=STRING:"366" --arg expectedDraftVersion=INTEGER:0 > "$WORK/edit-$label.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/edit-$label.log" || fail "draft 366 edit failed in 1..$max"
  v="$(python3 "$CLIENT" "$CFG_DESC" get 2>/dev/null | awk '/^VERSION /{print $2}')"
  local fv
  fv="$(python3 "$CLIENT" "$CFG_DESC" generated-fields 2>/dev/null | grep '^FIELD retentionCount ' | head -1 | awk '{for (i = 1; i <= NF; i++) if ($i == "VERSION") print $(i + 1)}')"
  python3 "$CLIENT" "$CFG_DESC" invoke "$v" APPLY_DRAFT --target "$rid" \
    --arg expectedDraftVersion=INTEGER:"$fv" > "$WORK/apply-$label.log" 2>&1 || true
  local applied366=false
  grep -q '^APPLIED true' "$WORK/apply-$label.log" && applied366=true
  grep -q '^CONFLICT true' "$WORK/apply-$label.log" && fail "1..$max draft/apply of 366 was a stale-draft conflict, not a rule verdict"
  [[ "$applied366" == "$accept366" ]] || fail "1..$max draft/apply of 366 applied=$applied366 expected=$accept366"
  local draftReason="none"
  if [[ "$applied366" == "false" ]]; then
    # The refusal is the draft-validation verdict; the SHARED business rule
    # reason is what the field projection publishes for the same field.
    grep -q '^REASON invalid_draft' "$WORK/apply-$label.log" || \
      fail "1..$max refused the 366 draft without the draft-validation verdict"
    draftReason="$(python3 "$CLIENT" "$CFG_DESC" generated-fields 2>/dev/null | grep '^FIELD retentionCount ' | head -1 | \
      awk '{for (i = 1; i <= NF; i++) if ($i == "ERROR") print $(i + 1)}')"
    [[ "$draftReason" == "retention_count_out_of_range" ]] || \
      fail "1..$max draft refusal reason was '$draftReason', not the shared rule"
  fi
  log "step11 boundary_ok declared=$min..$max external_query=$min..$max create_366=$created366 create_731=false draft366_applied=$applied366 draft_rule_reason=$draftReason"
}

CFG_DESC=""
CFG_PID=""
checkBoundaryConfig 1 365 Low false
checkBoundaryConfig 1 730 High true
log "step11 redeclaration_mode=startup_flag(--retention-range) dynamic_update_entry=none"

# --- exit classification -----------------------------------------------------
# The independent semantic segments above stay valid even when desktop input
# could not run, but the script's own exit code must reflect what really
# happened instead of always reporting PASS:
#   * a real desktop input that was not delivered, or a failed assertion, is a
#     FAIL - the fallback public invoke keeps the rest of the round verifiable
#     but cannot stand in for the control-input evidence;
#   * only a proven environment/tool limitation (locked session, no swiftc,
#     driver that cannot be built) is BLOCKED (exit 3), the same classification
#     the exported consumer chains use.
if [[ -n "$INPUT_FAILED" ]]; then
  log "FAIL desktop_control_input_not_delivered detail=$INPUT_FAILED"
  cat "$LOG"
  exit 1
fi
if [[ -n "$INPUT_BLOCKED" ]]; then
  log "BLOCKED desktop_input reason=$INPUT_BLOCKED semantic_segments_above=valid (environment/tool limitation, not a CJGUI result)"
  cat "$LOG"
  exit 3
fi
log "PASSED common-definition acceptance (five required items included)"
cat "$LOG"
exit 0
