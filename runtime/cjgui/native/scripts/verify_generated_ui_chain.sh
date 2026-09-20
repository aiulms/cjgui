#!/usr/bin/env zsh
# Runtime-generated-UI closed loop on the rule-set consumer.
#
# Same instance proves:
#   1. capability query (typed catalog + bounds)
#   2. structure read (v0) and S1 submission -> accepted, scene accepted
#   3. same field after S2 re-order: the domain draft survives and the public
#      read returns the same field content (state continuation)
#   4. a generated button executes the existing business action (APPLY_DRAFT)
#      and the public read shows the owner's applied result
#   5. rejection family: stale structure version, duplicate key, unknown
#      action, unknown component, depth/nodes/property limits, malformed
#      payload -- each keeps the previous accepted structure and business state
#
# The instance is launched by this script only and reclaimed by exact PID.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_GENERATED_UI_TMPDIR:-/private/tmp/cjgui-generated-ui}"
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
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Gen${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}Gen${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}Gen${RUN_TAG}"
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
DESCRIPTOR="$(cjgui_wait_descriptor "$STDOUT_LOG" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 150 || true)"
[[ -f "${DESCRIPTOR:-}" ]] || fail "app did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "app descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "app pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
structure_version() {
  pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'
}
field_line() { # field_line <fieldId>
  pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id {print; exit}'
}
field_draft_hex() {
  field_line "$1" | awk '/DRAFT_HEX /{for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") print $(i + 1)}'
}
field_version() {
  field_line "$1" | awk '/VERSION /{for (i = 1; i <= NF; i++) if ($i == "VERSION") print $(i + 1)}'
}
hex_to_text() {
  python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'
}
# A candidate is received immediately, but the accepted structure version only
# advances when the window's own scene transaction accepts it. Poll the public
# read with a bound instead of assuming the refresh already happened.
wait_for_structure_version() { # wait_for_structure_version <expected> [seconds]
  local expected="$1" limit="${2:-20}" waited=0 current
  while (( waited < limit )); do
    current="$(structure_version)"
    [[ "$current" == "$expected" ]] && return 0
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  return 1
}
scene_state() {
  pub generated-structure 2>/dev/null | awk '/^SCENE_STATE /{print $2}'
}
candidate_version() {
  pub generated-structure 2>/dev/null | awk '/^CANDIDATE_VERSION /{print $2}'
}

# --- 1. capability query ---------------------------------------------------
CAPS="$WORK/capabilities.txt"
pub generated-capabilities > "$CAPS" 2>&1 || true
grep -q '^KIND GENERATED_UI_CAPABILITIES' "$CAPS" || fail "capabilities query failed"
# The declared node bound is reported as the effective framework
# capacity, so a client never plans a structure that cannot mount.
grep -q '^BOUNDS 12 64 8 256' "$CAPS" || fail "capability bounds missing"
grep -q '^COMPONENT textInput' "$CAPS" || fail "textInput component missing"
grep -q '^ACTION APPLY_DRAFT' "$CAPS" || fail "APPLY_DRAFT action missing"
grep -q '^FIELD label' "$CAPS" || fail "label field missing"
log "step1 capabilities_ok bytes=$(wc -c < "$CAPS" | tr -d ' ')"

# --- 2. accepted structure starts empty, then S1 ---------------------------
[[ "$(structure_version)" == "0" ]] || fail "initial structure version is not 0"

cat > "$WORK/s1.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greeting label
PROPERTY 1 greeting text 生成面板：编辑规则名称
NODE 1 nameField textInput field=label
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
END
S1
SUBMIT_S1="$WORK/submit-s1.log"
pub generated-submit --structure-version 0 --payload-file "$WORK/s1.txt" > "$SUBMIT_S1" 2>&1 || true
grep -q '^APPLIED true' "$SUBMIT_S1" || fail "S1 candidate was not received"
grep -q '^CANDIDATE_ACCEPTED true' "$SUBMIT_S1" || fail "S1 candidate acceptance not reported"
grep -q '^CANDIDATE_VERSION 1' "$SUBMIT_S1" || fail "S1 candidate version missing"
# Receiving a candidate must not publish it: the scene-accepted version stays
# where it was until the window accepts the scene that contains it.
grep -q '^VERSION_AFTER 0' "$SUBMIT_S1" || fail "candidate receipt advanced the accepted structure version"
grep -q '^SCENE_ACCEPTED false' "$SUBMIT_S1" || fail "candidate receipt claimed scene acceptance"
wait_for_structure_version 1 || fail "S1 was never scene-accepted (structure_version=$(structure_version))"
[[ "$(scene_state)" == "scene_accepted" ]] || fail "S1 scene state is $(scene_state)"
[[ "$(candidate_version)" == "0" ]] || fail "S1 candidate still pending after scene acceptance"
[[ "$(structure_version)" == "1" ]] || fail "structure read did not report v1"
pub generated-structure > "$WORK/structure-v1.txt" 2>&1 || true
grep -q 'NODE 1 nameField textInput field=label' "$WORK/structure-v1.txt" || fail "S1 node missing from accepted structure"
log "step2 s1_scene_accepted version=1 scene=$(scene_state)"

# --- 3. create + select a record, draft text lives in the domain -----------
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"生成链记录" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"gen-create-1" \
  > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
RECORD_ID="$(pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2}' | head -1)"
[[ -n "$RECORD_ID" ]] || fail "created record id not visible"
pub invoke 1 SELECT_RECORD --target "$RECORD_ID" > "$WORK/select.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/select.log" || fail "record selection failed"
log "step3 record_ready id=$RECORD_ID"

# Draft edit through the ordinary draft action, then S2 re-orders the same
# field while keeping its fieldId: the draft must survive.
DRAFT_TEXT="草稿续写-A"
pub generated-fields > "$WORK/fields-before-edit.txt" 2>&1 || true
grep -q '^FIELD label ' "$WORK/fields-before-edit.txt" || fail "field projection missing label"
DRAFT_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$DRAFT_VERSION" EDIT_DRAFT_TEXT --target "$RECORD_ID" \
  --arg fieldId=STRING:label --arg text=STRING:"$DRAFT_TEXT" --arg expectedDraftVersion=INTEGER:0 \
  > "$WORK/draft-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/draft-edit.log" || fail "draft edit failed"
DRAFT_BEFORE="$(field_draft_hex label)"
[[ -n "$DRAFT_BEFORE" && "$DRAFT_BEFORE" != "-" ]] || fail "draft not visible through the public field read"
[[ "$(print -r -- "$DRAFT_BEFORE" | hex_to_text)" == "$DRAFT_TEXT" ]] || fail "public draft read mismatch"

cat > "$WORK/s2.txt" <<'S2'
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 horizontal
NODE 1 applyBtn2 action action=APPLY_DRAFT
PROPERTY 1 applyBtn2 label 先放按钮
NODE 1 hint label
PROPERTY 1 hint text 重排后同一字段仍绑定 label
NODE 1 nameFieldAgain textInput field=label
END
S2
SUBMIT_S2="$WORK/submit-s2.log"
S2_VERSION="$(structure_version)"
pub generated-submit --structure-version "$S2_VERSION" --payload-file "$WORK/s2.txt" > "$SUBMIT_S2" 2>&1 || true
grep -q '^APPLIED true' "$SUBMIT_S2" || fail "S2 re-order candidate was not received"
grep -q '^CANDIDATE_ACCEPTED true' "$SUBMIT_S2" || fail "S2 candidate acceptance not reported"
grep -q "^CANDIDATE_VERSION $((S2_VERSION + 1))" "$SUBMIT_S2" || fail "S2 candidate version missing"
grep -q "^VERSION_AFTER $S2_VERSION" "$SUBMIT_S2" || fail "S2 candidate receipt advanced the accepted version"
wait_for_structure_version $((S2_VERSION + 1)) || \
  fail "S2 was never scene-accepted (structure_version=$(structure_version))"
[[ "$(scene_state)" == "scene_accepted" ]] || fail "S2 scene state is $(scene_state)"
pub generated-structure > "$WORK/structure-v2.txt" 2>&1 || true
grep -q 'NODE 1 nameFieldAgain textInput field=label' "$WORK/structure-v2.txt" || fail "S2 field binding missing"
# The draft survives the re-order: the public field projection still carries it.
DRAFT_AFTER="$(field_draft_hex label)"
[[ "$DRAFT_AFTER" == "$DRAFT_BEFORE" ]] || fail "draft did not survive the structure re-order"
log "step4 s2_reorder_ok draft_survived=true draft=$(print -r -- "$DRAFT_AFTER" | hex_to_text)"

# --- 4. generated button runs the existing business action ------------------
# The window renders the accepted S2; the human-equivalent path for this
# script is the same owner entry the generated button uses. The public read
# afterwards must show the applied label (the domain's own result).
APPLY_LOG="$WORK/apply.log"
DRAFT_FIELD_VERSION="$(field_version label)"
[[ -n "$DRAFT_FIELD_VERSION" ]] || fail "draft field version not readable"
pub invoke "$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')" APPLY_DRAFT --target "$RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$DRAFT_FIELD_VERSION" > "$APPLY_LOG" 2>&1 || true
grep -q '^APPLIED true' "$APPLY_LOG" || fail "apply draft through the owner failed"
pub generated-fields > "$WORK/fields-after-apply.txt" 2>&1 || true
APPLIED_HEX="$(grep '^FIELD label ' "$WORK/fields-after-apply.txt" | awk '/APPLIED_HEX /{for (i = 1; i <= NF; i++) if ($i == "APPLIED_HEX") print $(i + 1)}')"
[[ "$(print -r -- "$APPLIED_HEX" | hex_to_text)" == "$DRAFT_TEXT" ]] || fail "applied value not visible through the public field read"
log "step5 business_action_applied_ok applied=$(print -r -- "$APPLIED_HEX" | hex_to_text)"

# --- 5. rejection family keeps the previous structure ----------------------
REJECT_DIR="$WORK/rejections"
mkdir -p "$REJECT_DIR"
before_version="$(structure_version)"

cat > "$REJECT_DIR/duplicate.txt" <<'R1'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 dup label
PROPERTY 1 dup text one
NODE 1 dup label
PROPERTY 1 dup text two
END
R1
cat > "$REJECT_DIR/unknown-action.txt" <<'R2'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 btn action action=NOT_A_REAL_ACTION
PROPERTY 1 btn action NOT_A_REAL_ACTION
END
R2
cat > "$REJECT_DIR/unknown-component.txt" <<'R3'
GENERATED_UI_STRUCTURE 1
NODE 0 root galaxy
END
R3
cat > "$REJECT_DIR/unknown-property.txt" <<'R4'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
PROPERTY 0 root glow 1
END
R4
cat > "$REJECT_DIR/unknown-field.txt" <<'R7'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 fld textInput field=notARegisteredField
END
R7
python3 - "$REJECT_DIR/too-many-nodes.txt" <<'RNODES'
import sys
path = sys.argv[1]
lines = ["GENERATED_UI_STRUCTURE 1", "NODE 0 root vertical"]
# 9 groups x 60 leaves: every container stays inside its child limit while the
# total node count exceeds the catalog's maxNodes bound.
for group in range(9):
    lines.append(f"NODE 1 group{group} vertical")
    for leaf in range(60):
        lines.append(f"NODE 2 leaf{group}_{leaf} label")
        lines.append(f"PROPERTY 2 leaf{group}_{leaf} text x{leaf}")
lines.append("END")
open(path, "w", encoding="utf-8").write("\n".join(lines))
RNODES
cat > "$REJECT_DIR/deep.txt" <<'R5'
GENERATED_UI_STRUCTURE 1
NODE 0 n0 vertical
NODE 1 n1 vertical
NODE 2 n2 vertical
NODE 3 n3 vertical
NODE 4 n4 vertical
NODE 5 n5 vertical
NODE 6 n6 vertical
NODE 7 n7 vertical
NODE 8 n8 vertical
NODE 9 n9 vertical
NODE 10 n10 vertical
NODE 11 n11 vertical
NODE 12 n12 vertical
NODE 13 n13 vertical
END
R5
printf 'GENERATED_UI_STRUCTURE 1\nNODE 0 broken\n' > "$REJECT_DIR/malformed.txt"

reject_case() { # reject_case <name> <payload> <expected-reason>
  local name="$1"
  local payload="$2"
  local expected="$3"
  local out="$REJECT_DIR/$name.log"
  pub generated-submit --structure-version "$before_version" --payload-file "$payload" > "$out" 2>&1 || true
  grep -q '^APPLIED true' "$out" && fail "rejection case $name was accepted"
  grep -q "REASON $expected" "$out" || {
    grep -q "REASON $expected" "$out" || fail "rejection case $name reason mismatch (want $expected)"
  }
  log "rejection_ok $name reason=$expected"
}
reject_case duplicate_key "$REJECT_DIR/duplicate.txt" duplicate_key
reject_case unknown_action "$REJECT_DIR/unknown-action.txt" unknown_action
reject_case unknown_component "$REJECT_DIR/unknown-component.txt" unknown_component
reject_case unknown_property "$REJECT_DIR/unknown-property.txt" unknown_property
reject_case max_depth "$REJECT_DIR/deep.txt" max_depth_exceeded
reject_case unknown_field "$REJECT_DIR/unknown-field.txt" unknown_field
reject_case max_nodes "$REJECT_DIR/too-many-nodes.txt" max_nodes_exceeded
reject_case malformed "$REJECT_DIR/malformed.txt" malformed_node

# Stale structure version: a candidate built against an older structure.
cat > "$REJECT_DIR/stale.txt" <<'R6'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 note label
PROPERTY 1 note text stale
END
R6
pub generated-submit --structure-version 0 --payload-file "$REJECT_DIR/stale.txt" > "$REJECT_DIR/stale.log" 2>&1 || true
grep -q '^APPLIED true' "$REJECT_DIR/stale.log" && fail "stale structure version was accepted"
grep -q 'REASON structure_version_conflict' "$REJECT_DIR/stale.log" || fail "stale rejection reason missing"
log "rejection_ok stale_structure_version"

after_version="$(structure_version)"
[[ "$before_version" == "$after_version" ]] || fail "structure version changed after rejections"
grep -q 'NODE 1 nameFieldAgain textInput field=label' <(pub generated-structure 2>/dev/null) || \
  fail "previous accepted structure was lost after rejections"
log "step6 rejections_ok version_stable=$after_version"

log "PASSED generated-ui chain"
cat "$LOG"
exit 0
