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

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

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
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" && echo no || echo yes)"
  if [[ -n "$RANGE_EXEC" ]]; then
    cjgui_terminate_owned "$RANGE_PID" "${RANGE_DESC:-}" "$RANGE_EXEC" "$RANGE_DIR" || true
    log "cleanup: range instance closed=$(cjgui_pid_owns "$RANGE_PID" "${RANGE_DESC:-}" "$RANGE_EXEC" "$RANGE_DIR" && echo no || echo yes)"
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
grep -q '^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=0 min=1 max=90 callable=1' "$CAPS" || \
  fail "capability description does not publish the declared retention contract"
grep -q '^FIELD label TEXT resource=81001 writer=EDIT_DRAFT_TEXT required=0 min=0 max=0 callable=1' "$CAPS" || \
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
edit_draft_field retentionCount "900" generated-presentation || fail "generated presentation draft was rejected"
APPLY_V6="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V6" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/generated-reject.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/generated-reject.log" || fail "generated presentation bypassed the shared rule"
GENERATED_REASON="$(field_value retentionCount ERROR)"
[[ "$GENERATED_REASON" == "retention_count_out_of_range" ]] || \
  fail "generated presentation reported '$GENERATED_REASON' instead of the shared rule"
[[ "$(APPLIED_RETENTION)" == "45" ]] || fail "generated presentation partially wrote"
edit_draft_field retentionCount "60" generated-valid || fail "valid value through the generated presentation was rejected"
APPLY_V7="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$APPLY_V7" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(record_draft_version)" > "$WORK/generated-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/generated-apply.log" || fail "valid generated-presentation value was not applied"
[[ "$(APPLIED_RETENTION)" == "60" ]] || fail "generated presentation applied value mismatch"
log "step9 two_presentations_one_rule reason=$GENERATED_REASON both=enforced applied=60"

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
grep -q '^FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=0 min=365 max=730 callable=1' "$WORK/range-caps.txt" || \
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

log "PASSED common-definition acceptance (five required items included)"
cat "$LOG"
exit 0
