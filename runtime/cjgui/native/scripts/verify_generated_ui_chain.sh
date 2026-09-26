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
# The shared real-input/activation helpers are needed from step12 on (the
# application's own menu/button controls are pressed through them).
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
# Session availability: real-input steps need an ACTIVE desktop session (windows
# addressable). When the machine is at the lock screen the whole real-input part
# is BLOCKED, which is an environment fact rather than a product failure.
source "$SCRIPT_DIR/lib_cjgui_session_guard.sh"

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
  # Drain the client response. Early awk exit can close its stdout and make
  # Python return 120 under pipefail after a successful read.
  pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id {print}'
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
RECORD_ID="$(pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/ && !found {print $2; found=1}')"
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

# --- 7. declared key -> accepted instance projection -------------------------
# A client must be able to address the accepted control by its DECLARED key and
# read the geometry the window really accepted, instead of guessing a control
# from a display caption. The projection covers generated nodes only.
pub generated-instances > "$WORK/instances.txt" 2>&1 || true
grep -q '^KIND GENERATED_UI_INSTANCES' "$WORK/instances.txt" \
  || fail "the accepted-instance projection query failed"
grep -q '^INSTANCE nameFieldAgain ' "$WORK/instances.txt" \
  || fail "the projection is missing the accepted declared key"
grep -q '^INSTANCE nameFieldAgain .*id=[0-9][0-9]* ' "$WORK/instances.txt" \
  || fail "the projection is missing the accepted component identity"
grep -q '^INSTANCE nameFieldAgain .*bounds=[0-9-]*,[0-9-]*,[0-9]*,[0-9]* ' "$WORK/instances.txt" \
  || fail "the projection is missing the accepted geometry"
log "step7 instance_projection_ok keys=$(grep -c '^INSTANCE ' "$WORK/instances.txt")"

# --- 8. the public typed example, from the same public surface ---------------
# The example discovers the published fields, builds a panel, submits it, waits
# for acceptance, checks the accepted structure really is its candidate and
# addresses the accepted instance by declared key. No action/field/resource id
# is hard-coded in it.
python3 "$RUNTIME_DIR/shared_operation_core/example_generated_consumption.py" "$DESCRIPTOR" \
  > "$WORK/public-example.log" 2>&1 || {
  cat "$WORK/public-example.log" >> "$LOG" 2>/dev/null || true
  fail "the public typed example did not pass against the running application"
}
grep -q '^PASSED example consumption' "$WORK/public-example.log" \
  || fail "the public typed example did not report success"
log "step8 public_example_ok $(grep -m1 '^instance ' "$WORK/public-example.log")"

# --- 9. atomic observation seam (snapshot + bounded change cursor) ----------
# The public observation example takes ONE atomic snapshot, then confirms that an
# unchanged round costs one small change read instead of resending the tree. A
# REAL owner draft edit happens between the two phases, so the FIELDS category is
# observed from a real change - not from a synthetic injection.
OBS_STATE="$WORK/observation-state.json"
OBS_EXAMPLE="$RUNTIME_DIR/shared_operation_core/example_generated_observation.py"
python3 "$OBS_EXAMPLE" "$DESCRIPTOR" phase1 "$OBS_STATE" > "$WORK/observation-phase1.log" 2>&1 || {
  cat "$WORK/observation-phase1.log" >> "$LOG" 2>/dev/null || true
  fail "the public observation phase1 did not pass"
}
grep -q '^PASSED observation phase1' "$WORK/observation-phase1.log" \
  || fail "the public observation phase1 did not report success"

DRAFT_OBS_VERSION="$(field_version label)"
[[ -n "$DRAFT_OBS_VERSION" ]] || fail "observation draft version not readable"
pub invoke "$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT --target "$RECORD_ID" \
  --arg fieldId=STRING:label --arg text=STRING:"观测草稿-9" \
  --arg expectedDraftVersion=INTEGER:"$DRAFT_OBS_VERSION" > "$WORK/observation-draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/observation-draft.log" || fail "the observation draft edit failed"

python3 "$OBS_EXAMPLE" "$DESCRIPTOR" phase2 "$OBS_STATE" > "$WORK/observation-phase2.log" 2>&1 || {
  cat "$WORK/observation-phase2.log" >> "$LOG" 2>/dev/null || true
  fail "the public observation phase2 did not pass"
}
grep -q '^PASSED observation phase2' "$WORK/observation-phase2.log" \
  || fail "the public observation phase2 did not report success"
log "step9 observation_ok $(grep -m1 '^snapshot ' "$WORK/observation-phase1.log")"
log "step9 observation_change $(grep -m1 '^changes ' "$WORK/observation-phase2.log")"

# A REAL window resize (Accessibility, the window's own size) between the
# phases: the geometry moves while the structure does not, so the increment must
# report SCENE and re-read only the INSTANCES section.
RESIZE_LOG="$WORK/observation-resize.log"
# The application must have registered its AX window before the resize can
# address it. A fixed sleep raced a busy host and reported
# `window 1 ... 无效的索引 (-1719)` for a healthy window, so the harness waits for
# the window (bounded) and records what it saw instead of treating an unresolved
# address as a product failure.
RESIZE_READY=0
RESIZE_ATTEMPT=0
AX_WINDOW_COUNT=""
while (( RESIZE_ATTEMPT < 20 )); do
  AX_WINDOW_COUNT="$(cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    return (count of windows of p) as string
  end tell" 2>/dev/null | tail -1 || true)"
  if [[ "$AX_WINDOW_COUNT" == <-> ]] && (( AX_WINDOW_COUNT >= 1 )); then
    RESIZE_READY=1
    break
  fi
  activate_app
  sleep 0.5
  RESIZE_ATTEMPT=$(( RESIZE_ATTEMPT + 1 ))
done
log "diag step9 resize_window_ready=$RESIZE_READY attempts=$((RESIZE_ATTEMPT + 1)) count='${AX_WINDOW_COUNT}'"
if (( RESIZE_READY == 1 )); then
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set pos to position of window 1 of p
    set siz to size of window 1 of p
    set size of window 1 of p to {(item 1 of siz) + 120, (item 2 of siz) + 80}
    return ((item 1 of pos) as string) & \" \" & ((item 2 of pos) as string) & \" \" & ((item 1 of siz) as string) & \" \" & ((item 2 of siz) as string)
  end tell" > "$RESIZE_LOG" 2>&1 || true
  sleep 2
  python3 "$OBS_EXAMPLE" "$DESCRIPTOR" phase3 "$OBS_STATE" > "$WORK/observation-phase3.log" 2>&1 || {
    cat "$WORK/observation-phase3.log" >> "$LOG" 2>/dev/null || true
    fail "the public observation phase3 (real resize) did not pass"
  }
  grep -q '^PASSED observation phase3' "$WORK/observation-phase3.log" \
    || fail "the public observation phase3 did not report success"
  log "step9 observation_resize_ok $(grep -m1 '^changes ' "$WORK/observation-phase3.log")"
else
  # The accessibility bridge sees no window for this process on this host right
  # now, so the REAL resize cannot be driven. That is an environment limitation
  # of this segment, recorded as such: it is not replaced by a public write (which
  # would not resize anything) and it does not invalidate the other evidence.
  log "BLOCKED observation_resize_status no AX window for pid=$APP_PID after $((RESIZE_ATTEMPT + 1)) attempts (count='${AX_WINDOW_COUNT}')"
  log "note observation_resize_skipped=true window_resize_evidence=blocked_on_this_host"
fi
if (( RESIZE_READY == 1 )); then
  log "step9 observation_resize $(grep -m1 '^resize ' "$WORK/observation-phase3.log")"
  log "step9 observation_resize_geometry $(grep -m1 '^geometry ' "$WORK/observation-phase3.log")"
fi

# --- 10. two independent clients, one base version --------------------------
# Ownership must be per attempt: the second submission cannot make the first
# look successful. The outcome is reported honestly (either the first was
# superseded before the scene accepted it, or it was accepted and the second was
# refused); the ownership invariants are asserted either way.
python3 "$RUNTIME_DIR/shared_operation_core/example_generated_candidate_race.py" "$DESCRIPTOR" \
  > "$WORK/candidate-race.log" 2>&1 || {
  cat "$WORK/candidate-race.log" >> "$LOG" 2>/dev/null || true
  fail "the two-client candidate ownership race did not pass"
}
grep -q '^PASSED candidate ownership race' "$WORK/candidate-race.log" \
  || fail "the two-client candidate ownership race did not report success"
log "step10 candidate_race $(grep -m1 '^race ' "$WORK/candidate-race.log")"
log "step10 candidate_race_accepted $(grep -m1 '^accepted_token=' "$WORK/candidate-race.log")"

# --- 11. shared image resource through the public surface -------------------
# Discovery publishes the application's logical resource (never a raster path);
# a generated candidate references it by key + exact version; an unknown key and
# a stale version are refused as a WHOLE (the previous interface stays readable);
# the accepted read-back names the resource, not a local path.
pub generated-capabilities > "$WORK/capabilities-images.txt" 2>&1 || true
grep -q '^IMAGE_RESOURCE rule-set-beacon PNG 1 ' "$WORK/capabilities-images.txt" \
  || fail "the capability text does not publish the application image resource"
grep -q 'composable-beacon.png' "$WORK/capabilities-images.txt" \
  && fail "the capability text leaked the application raster path"

cat > "$WORK/image-v1.txt" <<'IMG'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 1
PROPERTY 1 icon contentMode fit
PROPERTY 1 icon fixedWidth 48
PROPERTY 1 icon fixedHeight 48
NODE 1 nameEditor textInput field=label
PROPERTY 1 nameEditor label 规则名称编辑
END
IMG
IMG_VERSION="$(structure_version)"
pub generated-submit --structure-version "$IMG_VERSION" --payload-file "$WORK/image-v1.txt" \
  > "$WORK/image-v1.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/image-v1.log" || fail "the image candidate was not received"
wait_for_structure_version $((IMG_VERSION + 1)) || \
  fail "the image candidate was never scene-accepted (version=$(structure_version))"
pub generated-instances > "$WORK/image-instances.txt" 2>&1 || true
grep -q '^INSTANCE icon ' "$WORK/image-instances.txt" || fail "the accepted image instance is missing"
grep -q 'kind=image' "$WORK/image-instances.txt" || fail "the accepted instance is not an image node"
grep -q 'resource=rule-set-beacon' "$WORK/image-instances.txt" \
  || fail "the accepted instance does not name the logical resource"
grep -q 'resource_version=1' "$WORK/image-instances.txt" \
  || fail "the accepted instance does not name the accepted resource version"
grep -q 'composable-beacon.png' "$WORK/image-instances.txt" \
  && fail "the accepted-instance projection leaked the application raster path"

cat > "$WORK/image-unknown.txt" <<'IMGU'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource not-registered
PROPERTY 1 icon resourceVersion 1
END
IMGU
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/image-unknown.txt" \
  > "$WORK/image-unknown.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/image-unknown.log" || fail "an unknown resource key was accepted"
grep -q 'REASON image_resource_not_registered' "$WORK/image-unknown.log" \
  || fail "the unknown resource key reason is missing"

cat > "$WORK/image-stale.txt" <<'IMGS'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 7
END
IMGS
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/image-stale.txt" \
  > "$WORK/image-stale.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/image-stale.log" || fail "a stale resource version was accepted"
grep -q 'REASON image_resource_version_mismatch' "$WORK/image-stale.log" \
  || fail "the stale resource version reason is missing"
# The rejected candidates did not disturb the accepted interface (the accepted
# image structure is still the one that was committed).
grep -q 'NODE 1 icon image' <(pub generated-structure 2>/dev/null) \
  || fail "the accepted interface was lost after the refused image candidates"
grep -q 'PROPERTY 1 icon resource rule-set-beacon' <(pub generated-structure 2>/dev/null) \
  || fail "the accepted image reference was lost after the refused candidates"
log "step11 image_resource_ok key=rule-set-beacon version=1 readback=resource_only refused=unknown_key+stale_version"

# --- 12. the declaration is the single source of truth ----------------------
# The application owns the raster and the version. An external candidate cannot
# conjure a version that is not declared, and the application's OWN window
# control performs the real swap: after it, discovery publishes v2, the new
# reference is accepted and the withdrawn v1 reference is refused instead of
# silently resolving to the replacement image. The observation reports the
# declaration change as its own resource revision.
snapshot_field() { # snapshot_field <NAME>
  pub generated-snapshot 2>/dev/null | awk -v name="$1" '$1 == name {print $2}'
}
RESOURCE_REV_BEFORE="$(snapshot_field RESOURCE_REVISION)"
[[ -n "$RESOURCE_REV_BEFORE" ]] || fail "the atomic snapshot did not publish a resource revision"

cat > "$WORK/image-v2-before.txt" <<'IMG2'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 2
END
IMG2
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/image-v2-before.txt" \
  > "$WORK/image-v2-before.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/image-v2-before.log" \
  || fail "an undeclared image version was accepted before the application declared it"
grep -q 'REASON image_resource_version_mismatch' "$WORK/image-v2-before.log" \
  || fail "the undeclared image version did not report the version mismatch reason"
log "step12 image_undeclared_version_refused version=2 before_swap=true"

# The real swap: the application's own window control (the 图标 button, which
# runs the window command that redeclares the key at the next version).
# The window must be key/frontmost for its menu bar and controls to be
# reachable through Accessibility.
AX_PID="$APP_PID"
AX_APP_PATH="${ROUND_EXEC%%.app/*}.app"
activate_app
sleep 0.5
# The window inventory is recorded BEFORE the press. Opening a self-drawn window
# and publishing its accessibility children is asynchronous; an empty tree is a
# readiness fact, and waiting for it is not the same as faking the press.
AX_WINDOWS=""
AX_READY_ATTEMPT=0
while (( AX_READY_ATTEMPT < 20 )); do
  AX_WINDOWS="$(real_ax_windows_report "$APP_PID")"
  if print -r -- "$AX_WINDOWS" | grep -q 'elements=[1-9]'; then
    break
  fi
  AX_READY_ATTEMPT=$(( AX_READY_ATTEMPT + 1 ))
  activate_app
  sleep 0.5
done
log "diag step12 ax_windows attempts=$((AX_READY_ATTEMPT + 1)) $(print -r -- "$AX_WINDOWS" | tr '\n' '|')"
# Exact address first: the application publishes the control's own semantic id as
# its accessibility identifier, so the press targets THAT element (PID + window +
# role + full identifier) instead of a caption another control may share. The
# application menu command stays as a logged fallback.
AX_PRESS="$(real_ax_press_identifier "$APP_PID" "toggle-rule-set-beacon")"
AX_PRESS_MODE="exact_identifier"
if [[ "$AX_PRESS" != "identifier_press_sent" ]]; then
  AX_PRESS_MODE="caption_fallback"
  AX_PRESS="$(real_ax_press_application_command "$APP_PID" "切换图标" "图标" || true)"
fi
log "step12 image_swap_control result=$AX_PRESS mode=$AX_PRESS_MODE"
if [[ "$AX_PRESS" != "identifier_press_sent" && "$AX_PRESS" != "menu_press_sent" && "$AX_PRESS" != "window_press_sent" ]]; then
  # Explain the miss from the real accessibility tree instead of guessing: the
  # driver must address the application's own control, and a caption-based lookup
  # is allowed to fail only with the observed element list as evidence.
  log "diag step12 ax_identifiers $(real_ax_dump_identifiers "$APP_PID" 60 | tr '\n' '|')"
  log "diag step12 ax_captions $(real_ax_dump_captions "$APP_PID" 80 | tr '\n' '|')"
  # A LOCKED session (or no console session at all) exposes no application
  # windows anywhere, so a press can never land: that is an environment state,
  # reported as BLOCKED with its own evidence, never as a product failure. An
  # unverifiable session is NOT blocking: the missing control stays a product
  # failure with the session diagnostic attached.
  if real_ax_session_blocking; then
    log "BLOCKED step12 real_input $(real_ax_session_diagnostic)"
    cat "$LOG"
    exit 3
  fi
  log "session_diagnostic step12 $(real_ax_session_diagnostic)"
  fail "the application's own swap control could not be pressed"
fi

SWAPPED=0
waited=0
while (( waited < 20 )); do
  if grep -q '^IMAGE_RESOURCE rule-set-beacon PNG 2 ' <(pub generated-capabilities 2>/dev/null); then
    SWAPPED=1
    break
  fi
  sleep 0.5
  waited=$(( waited + 1 ))
done
(( SWAPPED == 1 )) || fail "the application swap did not redeclare the image resource at version 2"
CAPS_AFTER_SWAP="$(pub generated-capabilities 2>/dev/null)"
grep -q '^IMAGE_RESOURCE rule-set-beacon PNG 2 ' <<< "$CAPS_AFTER_SWAP" \
  || fail "discovery did not publish the swapped version"
grep -q '^IMAGE_RESOURCE rule-set-beacon PNG 1 ' <<< "$CAPS_AFTER_SWAP" \
  && fail "discovery still publishes the withdrawn version"
grep -q 'composable-beacon' <<< "$CAPS_AFTER_SWAP" \
  && fail "the swapped capability text leaked a raster path"
RESOURCE_REV_AFTER="$(snapshot_field RESOURCE_REVISION)"
[[ -n "$RESOURCE_REV_AFTER" ]] || fail "the snapshot lost its resource revision after the swap"
# The resource revision is a DETERMINISTIC FINGERPRINT of the declared table,
# not an ordering counter, so the declaration change must make it DIFFER.
[[ "$RESOURCE_REV_AFTER" != "$RESOURCE_REV_BEFORE" ]] \
  || fail "the declaration change did not change the observed resource revision ($RESOURCE_REV_BEFORE -> $RESOURCE_REV_AFTER)"
log "step12 image_discovery_swapped version=2 resource_revision=${RESOURCE_REV_BEFORE}->${RESOURCE_REV_AFTER} path_leaked=false"

# The accepted scene must KEEP the interface it accepted: the real swap above did
# not resubmit any structure, yet the image instance, its accepted version, the
# sampled resource state and the field editor must all still be addressable.
pub generated-instances > "$WORK/image-after-swap-instances.txt" 2>&1 || true
grep -q '^INSTANCE icon ' "$WORK/image-after-swap-instances.txt" \
  || fail "the real declaration swap emptied the accepted image instance"
grep -q 'resource=rule-set-beacon' "$WORK/image-after-swap-instances.txt" \
  || fail "the accepted image instance lost its logical resource"
grep -q 'resource_version=1' "$WORK/image-after-swap-instances.txt" \
  || fail "the accepted image instance lost the version it was accepted with"
grep -q 'resource=rule-set-beacon resource_version=1 resource_state=-' "$WORK/image-after-swap-instances.txt" \
  && fail "the accepted image instance published no preparation state"
grep -q 'resource=rule-set-beacon resource_version=1 resource_state=' "$WORK/image-after-swap-instances.txt" \
  || fail "the accepted image instance did not publish its preparation state"
grep -q '^INSTANCE nameEditor ' "$WORK/image-after-swap-instances.txt" \
  || fail "the declaration swap removed the accepted editor"
grep -q 'kind=textInput' "$WORK/image-after-swap-instances.txt" \
  || fail "the accepted editor is no longer a text input"
grep -q 'composable-beacon' "$WORK/image-after-swap-instances.txt" \
  && fail "the continuity read-back leaked a raster path"
log "step12 image_swap_continuity_ok accepted_version=1 editor_alive=true state_published=true"

# The withdrawn reference and the replacement, from the SAME public surface.
cat > "$WORK/image-v2-after.txt" <<'IMG3'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 2
PROPERTY 1 icon contentMode fit
PROPERTY 1 icon fixedWidth 48
PROPERTY 1 icon fixedHeight 48
NODE 1 nameEditor textInput field=label
PROPERTY 1 nameEditor label 规则名称编辑
END
IMG3
V2_VERSION="$(structure_version)"
pub generated-submit --structure-version "$V2_VERSION" --payload-file "$WORK/image-v2-after.txt" \
  > "$WORK/image-v2-after.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/image-v2-after.log" || fail "the replacement image version was refused"
wait_for_structure_version $((V2_VERSION + 1)) || fail "the replaced image structure was never scene-accepted"
pub generated-instances > "$WORK/image-v2-instances.txt" 2>&1 || true
grep -q 'resource=rule-set-beacon' "$WORK/image-v2-instances.txt" \
  || fail "the replaced image instance does not name the logical resource"
grep -q 'resource_version=2' "$WORK/image-v2-instances.txt" \
  || fail "the replaced image instance does not name version 2"
grep -q 'composable-beacon' "$WORK/image-v2-instances.txt" \
  && fail "the replaced instance read-back leaked a raster path"
grep -q '^INSTANCE nameEditor ' "$WORK/image-v2-instances.txt" \
  || fail "the v2 replacement removed the accepted editor"
log "step12 image_v2_keeps_editor_ok"

cat > "$WORK/image-v1-after.txt" <<'IMG4'
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 1
END
IMG4
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/image-v1-after.txt" \
  > "$WORK/image-v1-after.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/image-v1-after.log" \
  || fail "the withdrawn image version was still accepted after the swap"
grep -q 'REASON image_resource_version_mismatch' "$WORK/image-v1-after.log" \
  || fail "the withdrawn version did not report the version mismatch reason"
log "step12 image_lifecycle_ok swap=control_ax_press declared_v2 accepted_v2 refused_withdrawn_v1"

# --- 13. real input is addressed by exact accepted identity ------------------
# The shared driver used to type into whatever component the window reported as
# focused (a `component-` PREFIX) and to judge success only from the target
# field, so it wrote the target text into other generated editors first. This
# step is the deterministic counterexample: a TEXT editor sits BEFORE the INTEGER
# target, the TEXT draft must stay byte-identical, and only the target changes.
AX_PID="$APP_PID"
cat > "$WORK/input-identity.txt" <<'S13'
GENERATED_UI_STRUCTURE 1
NODE 0 inputRoot vertical
NODE 1 textEditor textInput field=label
PROPERTY 1 textEditor label 第一编辑器
NODE 1 countEditor integerInput field=retentionCount
PROPERTY 1 countEditor label 保留天数编辑
END
S13
ID_VERSION="$(structure_version)"
pub generated-submit --structure-version "$ID_VERSION" --payload-file "$WORK/input-identity.txt" \
  > "$WORK/input-identity-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/input-identity-submit.log" || fail "the input-identity structure was rejected"
wait_for_structure_version $((ID_VERSION + 1)) || fail "the input-identity structure was never scene-accepted"
grep -q '^INSTANCE textEditor ' <(pub generated-instances 2>/dev/null) || fail "the text editor instance is missing"
grep -q '^INSTANCE countEditor ' <(pub generated-instances 2>/dev/null) || fail "the integer editor instance is missing"

if prepare_desktop_driver; then
  INPUT_IDENTITY_OK=true
  # (a) the TEXT editor is written first, then the INTEGER target.
  if ! real_generated_text_edit input_identity_text "$DESCRIPTOR" label "第一编辑器" "text field" "标识文本-A" textEditor; then
    INPUT_IDENTITY_OK=false
    log "note input_identity_text_not_delivered"
  fi
  if [[ "$INPUT_IDENTITY_OK" == "true" ]]; then
    LABEL_A="$(print -r -- "$(field_draft_hex label)" | hex_to_text)"
    [[ "$LABEL_A" == "标识文本-A" ]] || fail "the first real edit did not reach its own editor ('$LABEL_A')"
    if ! real_generated_text_edit input_identity_count "$DESCRIPTOR" retentionCount "保留天数编辑" "text field" "63" countEditor; then
      INPUT_IDENTITY_OK=false
      log "note input_identity_count_not_delivered"
    fi
    LABEL_AFTER="$(print -r -- "$(field_draft_hex label)" | hex_to_text)"
    COUNT_AFTER="$(print -r -- "$(field_draft_hex retentionCount)" | hex_to_text)"
    [[ "$COUNT_AFTER" == "63" ]] || fail "the integer target is not exactly 63 ('$COUNT_AFTER')"
    [[ "$LABEL_AFTER" == "标识文本-A" ]] \
      || fail "editing the INTEGER target rewrote the TEXT editor ('$LABEL_AFTER')"
    log "step13 input_identity_forward text='$LABEL_AFTER' integer='$COUNT_AFTER' other_field_unchanged=true"
  fi
  # (b) the reverse order: the INTEGER first, then the TEXT editor.
  if [[ "$INPUT_IDENTITY_OK" == "true" ]]; then
    if ! real_generated_text_edit input_identity_count2 "$DESCRIPTOR" retentionCount "保留天数编辑" "text field" "64" countEditor; then
      INPUT_IDENTITY_OK=false
      log "note input_identity_count2_not_delivered"
    fi
    if ! real_generated_text_edit input_identity_text2 "$DESCRIPTOR" label "第一编辑器" "text field" "标识文本-B" textEditor; then
      INPUT_IDENTITY_OK=false
      log "note input_identity_text2_not_delivered"
    fi
    LABEL_B="$(print -r -- "$(field_draft_hex label)" | hex_to_text)"
    COUNT_B="$(print -r -- "$(field_draft_hex retentionCount)" | hex_to_text)"
    [[ "$LABEL_B" == "标识文本-B" ]] || fail "the reverse-order text edit is not exact ('$LABEL_B')"
    [[ "$COUNT_B" == "64" ]] || fail "the reverse-order integer edit was rewritten ('$COUNT_B')"
    log "step13 input_identity_reverse text='$LABEL_B' integer='$COUNT_B' other_field_unchanged=true"
  fi
  # (c) after a genuine reorder the SAME keys are addressed by accepted identity.
  if [[ "$INPUT_IDENTITY_OK" == "true" ]]; then
    cat > "$WORK/input-reorder.txt" <<'S13R'
GENERATED_UI_STRUCTURE 1
NODE 0 inputRoot vertical
NODE 1 countEditor integerInput field=retentionCount
PROPERTY 1 countEditor label 保留天数编辑
NODE 1 textEditor textInput field=label
PROPERTY 1 textEditor label 第一编辑器
END
S13R
    REORDER_VERSION="$(structure_version)"
    pub generated-submit --structure-version "$REORDER_VERSION" --payload-file "$WORK/input-reorder.txt" \
      > "$WORK/input-reorder-submit.log" 2>&1 || true
    grep -q '^APPLIED true' "$WORK/input-reorder-submit.log" || fail "the reordered input structure was rejected"
    wait_for_structure_version $((REORDER_VERSION + 1)) || fail "the reordered input structure was never scene-accepted"
    if ! real_generated_text_edit input_identity_count3 "$DESCRIPTOR" retentionCount "保留天数编辑" "text field" "65" countEditor; then
      INPUT_IDENTITY_OK=false
      log "note input_identity_count3_not_delivered"
    fi
    LABEL_C="$(print -r -- "$(field_draft_hex label)" | hex_to_text)"
    COUNT_C="$(print -r -- "$(field_draft_hex retentionCount)" | hex_to_text)"
    [[ "$COUNT_C" == "65" ]] || fail "the post-reorder integer edit is not exact ('$COUNT_C')"
    [[ "$LABEL_C" == "标识文本-B" ]] || fail "the post-reorder edit rewrote the other editor ('$LABEL_C')"
    log "step13 input_identity_reorder text='$LABEL_C' integer='$COUNT_C' other_field_unchanged=true"
  fi
  if [[ "$INPUT_IDENTITY_OK" != "true" ]]; then
    log "BLOCKED input_identity counterexample not delivered by this host"
  fi
else
  log "note input_identity_skipped reason='${INPUT_BLOCKED:-desktop_driver_unavailable}'"
fi

# --- 13b. the accepted semantic identity IS the AX element address ----------
# The driver located the editor by its exact accepted identity in step13. This
# step proves the accessibility tree publishes that same identity, so the exact
# address exists independently of any caption: the lookup is PID + window + role
# + full identifier, and the frame comes from that element only.
if [[ -z "${DESKTOP_BLOCKED:-}" ]]; then
  AX_INSTANCE_LINE="$(accepted_field_instance_line "$DESCRIPTOR" label textEditor 2>/dev/null || true)"
  AX_SEMANTIC="$(instance_token "$AX_INSTANCE_LINE" semantic)"
  [[ -n "$AX_SEMANTIC" && "$AX_SEMANTIC" != "-" ]] \
    || fail "the accepted instance for the text editor has no semantic identity"
  AX_IDENTIFIERS="$(real_ax_dump_identifiers "$APP_PID" 80)"
  log "diag step13b ax_identifiers $(print -r -- "$AX_IDENTIFIERS" | tr '\n' '|')"
  print -r -- "$AX_IDENTIFIERS" | grep -q "^identifier=${AX_SEMANTIC} " \
    || fail "the accepted identity ${AX_SEMANTIC} is not an accessibility identifier"
  AX_EXACT_FRAME="$(ax_identifier_frame "$AX_SEMANTIC" "text field")"
  [[ "$AX_EXACT_FRAME" != "missing" && -n "$AX_EXACT_FRAME" ]] \
    || fail "the exact identifier ${AX_SEMANTIC} exposed no text-field frame"
  AX_WRONG_FRAME="$(ax_identifier_frame "component-not-accepted-anywhere" "text field")"
  [[ "$AX_WRONG_FRAME" == "missing" ]] \
    || fail "an unaccepted identifier still resolved to a frame ('$AX_WRONG_FRAME')"
  log "step13b ax_exact_address_ok semantic=${AX_SEMANTIC} frame='${AX_EXACT_FRAME}' lookup=pid+window+role+identifier"
fi

# --- 14. the shared named style through the public surface -----------------
# Discovery derives the style from the application's own definition; a generated
# candidate may reference it, and an illegal color or an unknown reference is
# refused as a whole while the accepted interface keeps answering.
pub generated-capabilities > "$WORK/capabilities-styles.txt" 2>&1 || true
grep -q '^STYLE rule_primary_action ' "$WORK/capabilities-styles.txt" \
  || fail "discovery does not publish the application's named style"
grep -q '^STYLE_STATE rule_primary_action normal\[' "$WORK/capabilities-styles.txt" \
  || fail "discovery does not publish the named style's state paint"
grep -q '^STYLE_REVISION ' "$WORK/capabilities-styles.txt" \
  || fail "discovery does not publish a style revision"
STYLE_REV_BEFORE="$(awk '/^STYLE_REVISION /{print $2}' "$WORK/capabilities-styles.txt")"

cat > "$WORK/style-accepted.txt" <<'S14'
GENERATED_UI_STRUCTURE 1
NODE 0 styleRoot vertical
NODE 1 styledAction action action=APPLY_DRAFT
PROPERTY 1 styledAction label 应用
PROPERTY 1 styledAction style rule_primary_action
PROPERTY 1 styledAction background #112233ff
NODE 1 styleEditor textInput field=label
PROPERTY 1 styleEditor label 规则名称编辑
END
S14
STYLE_VERSION="$(structure_version)"
pub generated-submit --structure-version "$STYLE_VERSION" --payload-file "$WORK/style-accepted.txt" \
  > "$WORK/style-accepted.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/style-accepted.log" || fail "the named-style candidate was rejected"
wait_for_structure_version $((STYLE_VERSION + 1)) || fail "the named-style structure was never scene-accepted"
grep -q '^INSTANCE styledAction ' <(pub generated-instances 2>/dev/null) \
  || fail "the styled action instance is missing from the accepted read-back"
grep -q '^INSTANCE styleEditor ' <(pub generated-instances 2>/dev/null) \
  || fail "the named-style candidate removed the accepted editor"

cat > "$WORK/style-unknown.txt" <<'S14U'
GENERATED_UI_STRUCTURE 1
NODE 0 styleRoot vertical
NODE 1 styleEditor textInput field=label
PROPERTY 1 styleEditor label 规则名称编辑
PROPERTY 1 styleEditor style not_registered
END
S14U
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/style-unknown.txt" \
  > "$WORK/style-unknown.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/style-unknown.log" || fail "an unknown style reference was accepted"
grep -q 'REASON style_reference_not_registered' "$WORK/style-unknown.log" \
  || fail "the unknown style reference reason is missing"

cat > "$WORK/style-badcolor.txt" <<'S14C'
GENERATED_UI_STRUCTURE 1
NODE 0 styleRoot vertical
NODE 1 styleEditor textInput field=label
PROPERTY 1 styleEditor label 规则名称编辑
PROPERTY 1 styleEditor border red
END
S14C
pub generated-submit --structure-version "$(structure_version)" --payload-file "$WORK/style-badcolor.txt" \
  > "$WORK/style-badcolor.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/style-badcolor.log" || fail "an illegal color was accepted"
grep -q 'REASON color_value_invalid' "$WORK/style-badcolor.log" \
  || fail "the illegal color reason is missing"
# The refusals did not disturb the accepted interface.
grep -q '^INSTANCE styledAction ' <(pub generated-instances 2>/dev/null) \
  || fail "the accepted styled interface was lost after the refusals"
log "step14 named_style_ok style=rule_primary_action revision=${STYLE_REV_BEFORE} accepted=true refused=unknown_reference+bad_color"

# --- 15. STYLES through the REAL public incremental client ------------------
# A real application operation (the window's own 外观/字体 control) changes the
# named-style definition. The typed public client must then observe a STYLES
# change and re-read the DEFINITIONS section with the concrete new paint - not
# just a revision number, and not through the full snapshot.
STYLE_STATE="$WORK/styles-state.json"
python3 - "$RUNTIME_DIR/shared_operation_core" "$DESCRIPTOR" "$STYLE_STATE" phase1 \
  > "$WORK/styles-phase1.log" 2>&1 <<'PYSTYLE1' || fail "the STYLES baseline phase failed"
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiSession
descriptor, state_path = sys.argv[2], Path(sys.argv[3])
session = GeneratedUiSession.connect(descriptor)
first = session.observe_once()
snapshot = first.snapshot
if snapshot is None:
    print("the first observation was not a snapshot")
    sys.exit(1)
baseline = session.section("STYLES", snapshot.cursor)
if "STYLE rule_primary_action " not in baseline.text or "STYLE_REVISION " not in baseline.text:
    print("the STYLES section did not publish the application style")
    sys.exit(1)
state_path.write_text(json.dumps({
    "stream_epoch": snapshot.stream_epoch,
    "cursor": snapshot.cursor,
    "baseline_text": baseline.text,
}), encoding="utf-8")
print(f"baseline bytes={len(baseline.text)}")
print("PASSED styles phase1")
PYSTYLE1
grep -q '^PASSED styles phase1' "$WORK/styles-phase1.log" || fail "the STYLES baseline did not report success"

# The application's appearance control belongs to the retention tab. Reach it
# through the visible public title before asking AX to press the control.
if [[ -z "${DESKTOP_BLOCKED:-}" ]]; then
  APPEARANCE_TAB_PRESS="$(real_ax_press_identifier "$APP_PID" "rule-detail-tabs-tab-retention")"
  log "step15 retention_tab_press=$APPEARANCE_TAB_PRESS"
  [[ "$APPEARANCE_TAB_PRESS" == "identifier_press_sent" ]] || fail "the retention tab title was not pressable"
  sleep 0.5
fi
if [[ -z "${DESKTOP_BLOCKED:-}" ]] && real_ax_press_button_retry "$APP_PID" "组件：外观/字体"; then
  log "step15 styles_real_control pressed=true"
  sleep 1.0
else
  if real_ax_session_blocking; then
    log "BLOCKED styles_real_control $(real_ax_session_diagnostic)"
    cat "$LOG"
    exit 3
  fi
  fail "the retention page's appearance control could not be pressed (desktop_input=${DESKTOP_BLOCKED:-available})"
fi

python3 - "$RUNTIME_DIR/shared_operation_core" "$DESCRIPTOR" "$STYLE_STATE" phase2 \
  > "$WORK/styles-phase2.log" 2>&1 <<'PYSTYLE2' || fail "the STYLES incremental phase failed"
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiSession
descriptor, state_path = sys.argv[2], Path(sys.argv[3])
state = json.loads(state_path.read_text(encoding="utf-8"))
session = GeneratedUiSession.connect(descriptor)
# The stale-cursor guard first: a section read at an old cursor must never be
# stitched into an older snapshot. The endpoint answers the revision flag with no
# content, and the public client refuses the reply because its cursor moved.
from cjgui_generated_client import GeneratedUiError
try:
    stale = session.section("STYLES", int(state["cursor"]))
except GeneratedUiError as refusal:
    print(f"stale_guard refused_by_client={refusal}")
else:
    if not stale.revision_changed or stale.text.strip() != "":
        print(f"the stale STYLES read was not refused: changed={stale.revision_changed} bytes={len(stale.text)}")
        sys.exit(1)
    print(f"stale_guard revision_changed=true content_bytes=0 cursor={stale.cursor}")
session.seed_cursor(int(state["stream_epoch"]), int(state["cursor"]))
observed = session.observe_once()
if observed.kind != "changes":
    print(f"the definition change was not an increment (kind={observed.kind})")
    sys.exit(1)
categories = [change.category for change in observed.changes.changes]
sections = observed.sections or {}
print(f"styles_change categories={','.join(categories)} sections={','.join(sorted(sections))} "
      f"current={observed.changes.current}")
if "STYLES" not in categories:
    print("the definition change did not report STYLES")
    sys.exit(1)
if "STYLES" not in sections:
    print("the STYLES section was not re-read")
    sys.exit(1)
section_text = sections["STYLES"]
# The typed client strips the SNAPSHOT_STYLE label from each line and joins the
# definitions, so the section body is the directory text itself.
if "STYLE rule_primary_action " not in section_text:
    print("the re-read directory does not name the application style")
    sys.exit(1)
if "STYLE_REVISION " not in section_text:
    print("the re-read directory has no revision line")
    sys.exit(1)


def definition_lines(text):
    """The style DEFINITIONS of the directory, without its revision counter."""
    return [line for line in text.splitlines()
            if line.startswith("STYLE ") and not line.startswith("STYLE_REVISION")]


before = definition_lines(state["baseline_text"])
after = definition_lines(section_text)
if after == before:
    print("the re-read directory changed its revision but not its paint")
    sys.exit(1)
changed = [line for line in after if line not in before]
print(f"paint_changed definitions_before={len(before)} definitions_after={len(after)} changed={len(changed)}")
for line in changed[:4]:
    print(f"changed_style {line}")
print("PASSED styles phase2")
PYSTYLE2
grep -q '^PASSED styles phase2' "$WORK/styles-phase2.log" || fail "the STYLES incremental read did not report success"
log "step15 styles_section_ok $(grep -m1 '^styles_change ' "$WORK/styles-phase2.log")"

# --- 15b. C: the accepted named-style paint is what the screen shows --------
# The scoped handwritten button and the generated action consume the SAME named
# style. This correlates the published base paint with the real composited pixel
# of the handwritten control, read from a bounded region screenshot: an
# observation of the platform's output, not the value the app reported about
# itself.
AX_PID="$APP_PID"
activate_app
sleep 0.5
STYLE_BG="$(pub generated-capabilities 2>/dev/null | awk '/^STYLE rule_primary_action /{for (i = 1; i <= NF; i++) if ($i ~ /^background=/) {sub(/^background=/, "", $i); print $i}}')"
[[ -n "$STYLE_BG" ]] || fail "the accepted named style published no base background"
BEACON_FRAME="$(ax_identifier_frame "toggle-rule-set-beacon" "button")"
if ! frame_is_positive "$BEACON_FRAME"; then
  # Earlier steps revealed editors at the bottom of the same mixed panel, so the
  # header control can be above the fold: reveal it through the SAME public
  # viewport before reading its frame.
  RE_DESCRIPTOR="$DESCRIPTOR"
  BEACON_FRAME="$(real_ax_scroll_reveal "toggle-rule-set-beacon" "button" 6 || true)"
fi
frame_is_positive "$BEACON_FRAME" || fail "the named-style painted control has no pressable frame ('$BEACON_FRAME')"
BX="$(print -r -- "$BEACON_FRAME" | awk '{print $1}')"
BY="$(print -r -- "$BEACON_FRAME" | awk '{print $2}')"
BW="$(print -r -- "$BEACON_FRAME" | awk '{print $3}')"
BH="$(print -r -- "$BEACON_FRAME" | awk '{print $4}')"
# Two bounded samples inside the control, away from the centered caption.
# Sampled at a quarter and three quarters of the width: inside the control's own
# background, away from its centered caption and from the border.
SCREEN_PIXEL_A="$(region_pixel_hex $(( BX + BW / 4 )) $(( BY + BH / 2 )) || true)"
SCREEN_PIXEL_B="$(region_pixel_hex $(( BX + BW * 3 / 4 )) $(( BY + BH / 2 )) || true)"
[[ -n "$SCREEN_PIXEL_A" || -n "$SCREEN_PIXEL_B" ]] \
  || fail "the bounded region screenshot produced no pixel"
if ! python3 - "$STYLE_STATE" "$STYLE_BG" "$SCREEN_PIXEL_A" "$SCREEN_PIXEL_B" <<'PYPAINT'
import json
import re
import sys
state_path, published, observed_a, observed_b = sys.argv[1:5]
state = json.load(open(state_path, encoding="utf-8"))


def rgb(token):
    token = token.lstrip("#")[:6]
    return int(token[0:2], 16), int(token[2:4], 16), int(token[4:6], 16)


def delta(a, b):
    return max(abs(x - y) for x, y in zip(rgb(a), rgb(b)))


match = re.search(r"STYLE rule_primary_action background=(#[0-9a-fA-F]+)", state["baseline_text"])
baseline = match.group(1) if match else ""
candidates = [candidate for candidate in (observed_a, observed_b) if candidate]
if not candidates:
    print("no bounded screenshot pixel was captured")
    sys.exit(1)
best = min(delta(published, candidate) for candidate in candidates)
print(f"published=#{published.lstrip('#')[:6]} observed_a=#{observed_a} observed_b=#{observed_b} "
      f"baseline=#{baseline.lstrip('#')[:6] if baseline else 'none'} best_delta={best}")
# The definition change itself is proven by the STYLES incremental step; this step
# only correlates the ACCEPTED paint with the composited output. The tolerance
# covers color management and edge antialiasing.
if best > 24:
    print("the composited pixel does not match the accepted paint")
    sys.exit(1)
PYPAINT
then
  fail "the composited pixel does not match the accepted named-style paint"
fi
log "step15b named_style_paint_matches_screen published=#$STYLE_BG observed=#$SCREEN_PIXEL_A/#$SCREEN_PIXEL_B method=bounded_region_screenshot tolerance=24"

# --- 15c. C: hover / press / release / leave reach the real paint ----------
# The interaction states of the SAME named style are published, then observed from
# the composited pixel: a state that never paints cannot pass this step.
STYLE_STATE_LINE="$(pub generated-capabilities 2>/dev/null | grep '^STYLE_STATE rule_primary_action ' || true)"
[[ -n "$STYLE_STATE_LINE" ]] || fail "the named style published no interaction states"
read -r NORMAL_BG HOVER_BG PRESSED_BG <<< "$(python3 - "$STYLE_STATE_LINE" <<'PYSTATE'
import re
import sys
line = sys.argv[1]


def state_background(name):
    match = re.search(name + r"\[([^\]]*)\]", line)
    if not match:
        return "-"
    found = re.search(r"background=#([0-9a-fA-F]+)", match.group(1))
    return "#" + found.group(1) if found else "-"


print(state_background("normal"), state_background("hover"), state_background("pressed"))
PYSTATE
)"
[[ "$NORMAL_BG" != "-" && "$HOVER_BG" != "-" && "$PRESSED_BG" != "-" ]] \
  || fail "the named style interaction states are incomplete ('$NORMAL_BG' / '$HOVER_BG' / '$PRESSED_BG')"
[[ "$NORMAL_BG" != "$HOVER_BG" && "$NORMAL_BG" != "$PRESSED_BG" && "$HOVER_BG" != "$PRESSED_BG" ]] \
  || fail "the named style states are not distinguishable, so the observation would be vacuous"
BCX=$(( BX + BW / 2 ))
BCY=$(( BY + BH / 2 ))
SAMPLE_X=$(( BX + 3 ))
SAMPLE_Y=$(( BY + BH / 2 ))
AWAY_X="$BX"
AWAY_Y=$(( BY - 16 ))
drive move "$AWAY_X" "$AWAY_Y"
sleep 0.5
REST_PIXEL="$(region_pixel_hex "$SAMPLE_X" "$SAMPLE_Y" || true)"
drive move "$BCX" "$BCY"
sleep 0.5
HOVER_PIXEL="$(region_pixel_hex "$SAMPLE_X" "$SAMPLE_Y" || true)"
drive press "$BCX" "$BCY"
sleep 0.4
PRESS_PIXEL="$(region_pixel_hex "$SAMPLE_X" "$SAMPLE_Y" || true)"
drive release "$BCX" "$BCY"
sleep 0.4
drive move "$AWAY_X" "$AWAY_Y"
sleep 0.5
LEFT_PIXEL="$(region_pixel_hex "$SAMPLE_X" "$SAMPLE_Y" || true)"
[[ -n "$REST_PIXEL" && -n "$HOVER_PIXEL" && -n "$PRESS_PIXEL" && -n "$LEFT_PIXEL" ]] \
  || fail "a pointer state produced no bounded screenshot pixel"
if ! python3 - "$NORMAL_BG" "$HOVER_BG" "$PRESSED_BG" "$REST_PIXEL" "$HOVER_PIXEL" "$PRESS_PIXEL" "$LEFT_PIXEL" <<'PYHOVER'
import sys
normal, hover, pressed, rest, hover_px, pressed_px, left = sys.argv[1:8]


def rgb(token):
    token = token.lstrip("#")[:6]
    return int(token[0:2], 16), int(token[2:4], 16), int(token[4:6], 16)


def delta(a, b):
    return max(abs(x - y) for x, y in zip(rgb(a), rgb(b)))


checks = (
    ("rest_vs_normal", rest, normal),
    ("hover_vs_hover", hover_px, hover),
    ("pressed_vs_pressed", pressed_px, pressed),
    ("left_vs_normal", left, normal),
)
bad = []
for name, observed, published in checks:
    value = delta(observed, published)
    print(f"{name} observed=#{observed} published=#{published.lstrip('#')[:6]} delta={value}")
    if value > 24:
        bad.append(name)
if bad:
    print("mismatched states: " + ",".join(bad))
    sys.exit(1)
PYHOVER
then
  fail "the real interaction output does not follow the named style's published states"
fi
log "step15c named_style_interaction_paint_ok normal=#$NORMAL_BG hover=#$HOVER_BG pressed=#$PRESSED_BG observed_rest=#$REST_PIXEL observed_hover=#$HOVER_PIXEL observed_pressed=#$PRESS_PIXEL observed_left=#$LEFT_PIXEL method=bounded_region_screenshot tolerance=24"

# --- 16. E: end-to-end cost of scroll, reveal and a local field change -------
# Timed through the SAME public seam an external client uses. The published
# viewport facts give the workload (solves per gesture, bytes of the capability
# catalog), so this is not an offset-assignment cost and no O(1) claim is made.
zmodload zsh/datetime 2>/dev/null || true
AX_PID="$APP_PID"
activate_app
sleep 0.4
viewport_fact() { # viewport_fact <semantic> <field> -> value
  pub window-interaction 2>/dev/null | awk -v id="$1" -v key="$2" '
    $1 == "WINDOW_VIEWPORT" && $2 == id {
      for (i = 3; i <= NF; i++) if ($i ~ ("^" key "=")) { sub("^" key "=", "", $i); print $i }
    }'
}
# ONE MONOTONIC clock in fixed microsecond units. Two earlier defects are fixed
# here at once: the very first form stripped the decimal point of EPOCHREALTIME so
# the unit depended on how many fractional digits the host prints (10 on this
# host), and the second form kept six digits but still read a CALENDAR clock,
# which can step with NTP. CLOCK_MONOTONIC is since boot and stable across
# processes, so stage deltas below are real durations.
now_us() {
  local stamp
  stamp="$(perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC -e 'printf "%d", clock_gettime(CLOCK_MONOTONIC) * 1000000' 2>/dev/null)" || return 1
  if [[ ! "$stamp" == <-> ]]; then
    return 1
  fi
  print -r -- "$stamp"
}
# The clock must ADVANCE over a known interval; a frozen or missing source fails
# here instead of silently producing zero durations.
T_CLOCK_A="$(now_us)" || fail "the monotonic clock is unavailable"
sleep 0.05
T_CLOCK_B="$(now_us)" || fail "the monotonic clock is unavailable"
if (( T_CLOCK_B - T_CLOCK_A < 20000 || T_CLOCK_B - T_CLOCK_A > 5000000 )); then
  fail "the monotonic clock did not advance over a known 50ms interval (delta=$(( T_CLOCK_B - T_CLOCK_A ))us)"
fi
log "diag clock_source=CLOCK_MONOTONIC_us self_check_delta_us=$(( T_CLOCK_B - T_CLOCK_A ))"
RE_DESCRIPTOR="$DESCRIPTOR"
SCROLL_FRAME="$(ax_identifier_frame "rule-set-scroll" "group")"
if ! frame_is_positive "$SCROLL_FRAME"; then
  SCROLL_FRAME="$(real_ax_scroll_reveal "toggle-rule-set-beacon" "button" 6 || true)"
  SCROLL_FRAME="$(ax_identifier_frame "rule-set-scroll" "group")"
fi
frame_is_positive "$SCROLL_FRAME" || fail "the timed scroll could not address the mixed-panel viewport"
SX="$(print -r -- "$SCROLL_FRAME" | awk '{print $1}')"
SY="$(print -r -- "$SCROLL_FRAME" | awk '{print $2}')"
SW="$(print -r -- "$SCROLL_FRAME" | awk '{print $3}')"
SH="$(print -r -- "$SCROLL_FRAME" | awk '{print $4}')"
# A point inside this viewport that no nested list owns.
SCROLL_PROBE_X=$(( SX + 6 ))
SCROLL_PROBE_Y=$(( SY + SH / 2 ))
drive scroll "$SCROLL_PROBE_X" "$SCROLL_PROBE_Y" -4
sleep 0.8
SOLVES_0="$(viewport_fact rule-set-scroll solves)"
OFFSET_0="$(viewport_fact rule-set-scroll accepted)"
CAP_BYTES_0="$(pub generated-capabilities 2>/dev/null | wc -c | tr -d ' ')"
sleep 2
SOLVES_IDLE="$(viewport_fact rule-set-scroll solves)"
OFFSET_IDLE="$(viewport_fact rule-set-scroll accepted)"
[[ "$SOLVES_IDLE" == "$SOLVES_0" && "$OFFSET_IDLE" == "$OFFSET_0" ]] \
  || fail "the idle window kept resolving (solves $SOLVES_0->$SOLVES_IDLE offset $OFFSET_0->$OFFSET_IDLE)"
T_WHEEL_START="$(now_us)"; [[ "$T_WHEEL_START" == <-> ]] || fail "the wheel clock is invalid"
drive scroll "$SCROLL_PROBE_X" "$SCROLL_PROBE_Y" 4
OFFSET_1=""
WHEEL_POLL=0
while (( WHEEL_POLL < 60 )); do
  OFFSET_1="$(viewport_fact rule-set-scroll accepted)"
  [[ -n "$OFFSET_1" && "$OFFSET_1" != "$OFFSET_0" ]] && break
  sleep 0.05
  WHEEL_POLL=$(( WHEEL_POLL + 1 ))
done
T_WHEEL_END="$(now_us)"; [[ "$T_WHEEL_END" == <-> ]] || fail "the wheel clock is invalid"
[[ -n "$OFFSET_1" && "$OFFSET_1" != "$OFFSET_0" ]] || fail "the timed wheel gesture never reached an accepted offset"
WHEEL_MS=$(( (T_WHEEL_END - T_WHEEL_START) / 1000 ))
SOLVES_1="$(viewport_fact rule-set-scroll solves)"
SOLVE_DELTA=$(( SOLVES_1 - SOLVES_0 ))
CAP_BYTES_1="$(pub generated-capabilities 2>/dev/null | wc -c | tr -d ' ')"
[[ "$CAP_BYTES_0" == "$CAP_BYTES_1" ]] \
  || fail "scrolling re-serialized the capability catalog ($CAP_BYTES_0 -> $CAP_BYTES_1)"
# Move back to the top so a generated editor is clipped again, then time a reveal.
drive scroll "$SCROLL_PROBE_X" "$SCROLL_PROBE_Y" 4
drive scroll "$SCROLL_PROBE_X" "$SCROLL_PROBE_Y" 4
sleep 0.8
EDGE_ID="$(pub generated-instances 2>/dev/null | awk '/kind=textInput/ {for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i}}' | tail -1)"
[[ -n "$EDGE_ID" ]] || fail "no generated text-editor identity for the reveal measurement"
T_REVEAL_START="$(now_us)"; [[ "$T_REVEAL_START" == <-> ]] || fail "the E2E clock is invalid"
REVEALED="$(real_ax_scroll_reveal "$EDGE_ID" "text field" 6 || true)"
T_REVEAL_END="$(now_us)"; [[ "$T_REVEAL_END" == <-> ]] || fail "the E2E clock is invalid"
frame_is_positive "$REVEALED" || fail "the timed reveal did not bring $EDGE_ID into view ('$REVEALED')"
REVEAL_MS=$(( (T_REVEAL_END - T_REVEAL_START) / 1000 ))
# A local field change through the real generated editor.
T_FIELD_START="$(now_us)"; [[ "$T_FIELD_START" == <-> ]] || fail "the E2E clock is invalid"
# The ACCEPTED structure at this point is the named-style candidate from step14,
# so the editor is addressed by that structure's own declared key.
real_generated_text_edit e2e_field "$DESCRIPTOR" label "规则名称编辑" "text field" "E2E-字段" styleEditor \
  || fail "the timed field edit was not delivered"
T_FIELD_END="$(now_us)"; [[ "$T_FIELD_END" == <-> ]] || fail "the E2E clock is invalid"
FIELD_MS=$(( (T_FIELD_END - T_FIELD_START) / 1000 ))
log "step16 e2e_costs clock=CLOCK_MONOTONIC_us wheel_ms=$WHEEL_MS solves_per_wheel=$SOLVE_DELTA reveal_ms=$REVEAL_MS reveal_target=$EDGE_ID field_ms=$FIELD_MS idle_stable=true cap_bytes_stable=$CAP_BYTES_0 method=public_seam"

# --- 16b. C1: a GENERATED scroll accepted through the public channel --------
# The structure itself declares the scroll container; the application does not
# wrap it. After acceptance a real wheel gesture moves the viewport WITHOUT
# advancing the business structure version or re-submitting the structure.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 scrollRoot vertical"
  print -r -- "NODE 1 scrollPanel scrollArea"
  print -r -- "PROPERTY 1 scrollPanel offset 0"
  print -r -- "NODE 2 scrollContent vertical"
  for row in {0..13}; do
    print -r -- "NODE 3 row${row} label"
    print -r -- "PROPERTY 3 row${row} text 行${row}"
  done
  print -r -- "END"
} > "$WORK/generated-scroll.txt"
SCROLL_VERSION="$(structure_version)"
pub generated-submit --structure-version "$SCROLL_VERSION" --payload-file "$WORK/generated-scroll.txt" \
  > "$WORK/generated-scroll-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/generated-scroll-submit.log" \
  || fail "the generated scroll structure was rejected"
wait_for_structure_version $(( SCROLL_VERSION + 1 )) \
  || fail "the generated scroll structure was never scene-accepted"
grep -q '^COMPONENT scrollArea ' <(pub generated-capabilities 2>/dev/null) \
  || fail "the public capability read does not publish the generated scroll kind"
SCROLL_SEMANTIC="$(pub generated-instances 2>/dev/null | awk '/kind=scrollArea/ {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}')"
[[ -n "$SCROLL_SEMANTIC" ]] || fail "the accepted generated scroll instance is not published"
AX_PID="$APP_PID"
SCROLL_FRAME="$(ax_identifier_frame "$SCROLL_SEMANTIC" "group")"
frame_is_positive "$SCROLL_FRAME" || fail "the generated scroll instance has no frame ('$SCROLL_FRAME')"
SX="$(print -r -- "$SCROLL_FRAME" | awk '{print $1}')"
SY="$(print -r -- "$SCROLL_FRAME" | awk '{print $2}')"
SW="$(print -r -- "$SCROLL_FRAME" | awk '{print $3}')"
SH="$(print -r -- "$SCROLL_FRAME" | awk '{print $4}')"
viewport_accepted_for() {
  pub window-interaction 2>/dev/null | awk -v id="$1" '$1 == "WINDOW_VIEWPORT" && $2 == id {
    for (i = 3; i <= NF; i++) if ($i ~ /^accepted=/) {sub(/^accepted=/, "", $i); print $i}}'
}
SCROLL_VP_BEFORE="$(viewport_accepted_for "$SCROLL_SEMANTIC")"
SCROLL_STRUCTURE_BEFORE="$(structure_version)"
if [[ -z "$SCROLL_VP_BEFORE" ]]; then
  fail "the generated scroll viewport is not published (semantic=$SCROLL_SEMANTIC)"
fi
SCROLL_ATTEMPT=0
while (( SCROLL_ATTEMPT < 3 )); do
  # A real wheel is only routed into the FRONTMOST window.
  activate_app
  sleep 0.3
  for scroll_direction in -4 4; do
    drive scroll $(( SX + SW / 2 )) $(( SY + SH / 2 )) "$scroll_direction"
    sleep 0.8
    SCROLL_VP_AFTER="$(viewport_accepted_for "$SCROLL_SEMANTIC")"
    [[ -n "$SCROLL_VP_AFTER" && "$SCROLL_VP_AFTER" != "$SCROLL_VP_BEFORE" ]] && break 2
  done
  SCROLL_ATTEMPT=$(( SCROLL_ATTEMPT + 1 ))
done
[[ -n "$SCROLL_VP_AFTER" && "$SCROLL_VP_AFTER" != "$SCROLL_VP_BEFORE" ]] \
  || fail "a real wheel gesture did not move the generated scroll viewport"
[[ "$(structure_version)" == "$SCROLL_STRUCTURE_BEFORE" ]] \
  || fail "scrolling the generated viewport advanced the business structure version"
log "step16b generated_scroll_ok semantic=$SCROLL_SEMANTIC offset=$SCROLL_VP_BEFORE->$SCROLL_VP_AFTER structure_version_stable=$SCROLL_STRUCTURE_BEFORE capability=published"

# --- 16c. C2: a GENERATED split accepted through the public channel ---------
# The structure declares the two-pane split itself (no application wrapper). The
# accepted geometry must come from the DECLARED initial size and both minimums,
# not from a sample's fixed width.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 splitRoot vertical"
  print -r -- "NODE 1 split split"
  print -r -- "PROPERTY 1 split firstSize 180"
  print -r -- "PROPERTY 1 split firstMinimum 80"
  print -r -- "PROPERTY 1 split secondMinimum 90"
  print -r -- "NODE 2 pane0 vertical"
  print -r -- "NODE 3 pane0row label"
  print -r -- "PROPERTY 3 pane0row text 左栏"
  print -r -- "NODE 2 pane1 vertical"
  print -r -- "NODE 3 pane1row label"
  print -r -- "PROPERTY 3 pane1row text 右栏"
  print -r -- "END"
} > "$WORK/generated-split.txt"
SPLIT_VERSION="$(structure_version)"
pub generated-submit --structure-version "$SPLIT_VERSION" --payload-file "$WORK/generated-split.txt" \
  > "$WORK/generated-split-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/generated-split-submit.log" \
  || fail "the generated split structure was rejected"
wait_for_structure_version $(( SPLIT_VERSION + 1 )) \
  || fail "the generated split structure was never scene-accepted"
grep -q '^COMPONENT split ' <(pub generated-capabilities 2>/dev/null) \
  || fail "the public capability read does not publish the generated split kind"
pub generated-structure 2>/dev/null | grep 'NODE 1 split split' >/dev/null \
  || fail "the accepted structure does not carry the declared split node"
SPLIT_INSTANCES="$(pub generated-instances 2>/dev/null)"
PANE0_LINE="$(print -r -- "$SPLIT_INSTANCES" | awk '$2 == "pane0" && !found {print; found=1}')"
PANE1_LINE="$(print -r -- "$SPLIT_INSTANCES" | awk '$2 == "pane1" && !found {print; found=1}')"
[[ -n "$PANE0_LINE" && -n "$PANE1_LINE" ]] || fail "the declared split panes are not published as instances"
PANE0_WIDTH="$(print -r -- "$PANE0_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, parts, ","); print parts[3]}}')"
PANE0_X="$(print -r -- "$PANE0_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, parts, ","); print parts[1]}}')"
PANE1_X="$(print -r -- "$PANE1_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, parts, ","); print parts[1]}}')"
[[ "$PANE0_WIDTH" == <-> && "$PANE0_X" == <-> && "$PANE1_X" == <-> ]] \
  || fail "the split panes published no usable bounds (pane0='$PANE0_LINE')"
(( PANE0_WIDTH == 180 )) \
  || fail "the first pane did not take the DECLARED initial size (width=$PANE0_WIDTH)"
(( PANE1_X > PANE0_X )) || fail "the second pane does not start after the first"
log "diag step16c ax_identifiers $(real_ax_dump_identifiers "$APP_PID" 60 | tr '\n' '|')"
drag_pane_width() {
  print -r -- "$1" | awk -v key="$2" '$2 == key {for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, pp, ","); print pp[3]}}' | head -1
}
drag_pane_x() {
  print -r -- "$1" | awk -v key="$2" '$2 == key {for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, pp, ","); print pp[1]}}' | head -1
}
# --- 16d. C2/D: a REAL divider drag writes the instance size -----------------
# The divider the framework allocated below the split's scope is located by its
# published AX identifier (never by a guessed node id), dragged with real desktop
# input, and the next ACCEPTED projection presents the instance's own view state:
# both panes move while the BUSINESS structure version stays where it was.
DRAG_INSTANCES="$(pub generated-instances 2>/dev/null)"
DRAG_P0_W="$(drag_pane_width "$DRAG_INSTANCES" pane0)"
DRAG_P1_X="$(drag_pane_x "$DRAG_INSTANCES" pane1)"
DRAG_STRUCTURE="$(structure_version)"
[[ "$DRAG_P0_W" == <-> && "$DRAG_P1_X" == <-> ]] || fail "the pre-drag split panes published no readable bounds"
(( DRAG_P0_W == 180 )) || fail "the pre-drag first pane is not the declared size ($DRAG_P0_W)"
DRAG_IDENTIFIER=""
for drag_lookup in 1 2 3; do
  activate_app
  DRAG_IDENTIFIER="$(real_ax_dump_identifiers "$APP_PID" 60 | sed -n 's/^identifier=\(component-[0-9-]*-handle\).*$/\1/p' | head -1)"
  [[ -n "$DRAG_IDENTIFIER" ]] && break
  sleep 0.5
done
[[ -n "$DRAG_IDENTIFIER" ]] || fail "the accepted split published no divider identifier"
DRAG_FRAME="$(ax_identifier_frame "$DRAG_IDENTIFIER" "group" || true)"
frame_is_positive "$DRAG_FRAME" || fail "the divider identifier has no usable frame ('$DRAG_FRAME')"
read -r DRAG_X DRAG_Y DRAG_W DRAG_H <<< "$DRAG_FRAME"
DRAG_FROM_X=$(( DRAG_X + DRAG_W / 2 ))
DRAG_Y_MID=$(( DRAG_Y + DRAG_H / 2 ))
DRAG_TO_X=$(( DRAG_FROM_X + 140 ))
DRAG_P0_W_AFTER=""
DRAG_P1_X_AFTER=""
for drag_attempt in 1 2 3; do
  activate_app
  drive move "$DRAG_FROM_X" "$DRAG_Y_MID"
  sleep 0.2
  drive press "$DRAG_FROM_X" "$DRAG_Y_MID"
  sleep 0.3
  drive move "$DRAG_TO_X" "$DRAG_Y_MID"
  sleep 0.3
  drive release "$DRAG_TO_X" "$DRAG_Y_MID"
  sleep 1.2
  DRAG_AFTER="$(pub generated-instances 2>/dev/null)"
  DRAG_P0_W_AFTER="$(drag_pane_width "$DRAG_AFTER" pane0)"
  DRAG_P1_X_AFTER="$(drag_pane_x "$DRAG_AFTER" pane1)"
  [[ "$DRAG_P0_W_AFTER" == <-> ]] && (( DRAG_P0_W_AFTER > DRAG_P0_W )) && break
done
[[ "$DRAG_P0_W_AFTER" == <-> && "$DRAG_P1_X_AFTER" == <-> ]] \
  || fail "the dragged divider published no readable pane bounds"
(( DRAG_P0_W_AFTER > DRAG_P0_W )) \
  || fail "the real divider drag did not resize the first pane ($DRAG_P0_W -> $DRAG_P0_W_AFTER)"
(( DRAG_P1_X_AFTER > DRAG_P1_X )) \
  || fail "the real divider drag did not move the second pane ($DRAG_P1_X -> $DRAG_P1_X_AFTER)"
[[ "$(structure_version)" == "$DRAG_STRUCTURE" ]] \
  || fail "the divider drag advanced the business structure version"
log "step16d generated_split_drag_ok identifier=$DRAG_IDENTIFIER pane0_width=$DRAG_P0_W->$DRAG_P0_W_AFTER pane1_x=$DRAG_P1_X->$DRAG_P1_X_AFTER structure_version_stable=$DRAG_STRUCTURE"

# --- 16e. C2: a track NARROWER than both minimums still degrades within bounds -
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 narrowRoot vertical"
  print -r -- "NODE 1 narrowSplit split"
  print -r -- "PROPERTY 1 narrowSplit firstSize 700"
  print -r -- "PROPERTY 1 narrowSplit firstMinimum 600"
  print -r -- "PROPERTY 1 narrowSplit secondMinimum 600"
  print -r -- "NODE 2 pane0 vertical"
  print -r -- "NODE 3 pane0row label"
  print -r -- "PROPERTY 3 pane0row text 窄左"
  print -r -- "NODE 2 pane1 vertical"
  print -r -- "NODE 3 pane1row label"
  print -r -- "PROPERTY 3 pane1row text 窄右"
  print -r -- "END"
} > "$WORK/generated-narrow-split.txt"
NARROW_VERSION="$(structure_version)"
pub generated-submit --structure-version "$NARROW_VERSION" --payload-file "$WORK/generated-narrow-split.txt" \
  > "$WORK/generated-narrow-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/generated-narrow-submit.log" \
  || fail "the over-narrow generated split was rejected"
wait_for_structure_version $(( NARROW_VERSION + 1 )) \
  || fail "the over-narrow generated split was never scene-accepted"
NARROW_INSTANCES="$(pub generated-instances 2>/dev/null)"
NARROW0="$(print -r -- "$NARROW_INSTANCES" | awk '$2 == "pane0" && !found {print; found=1}')"
NARROW1="$(print -r -- "$NARROW_INSTANCES" | awk '$2 == "pane1" && !found {print; found=1}')"
[[ -n "$NARROW0" && -n "$NARROW1" ]] || fail "the over-narrow split panes are not published"
read -r N0X N0W <<< "$(print -r -- "$NARROW0" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^bounds=/) {sub(/^bounds=/,"",$i); split($i,pp,","); print pp[1], pp[3]}}')"
read -r N1X N1W <<< "$(print -r -- "$NARROW1" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^bounds=/) {sub(/^bounds=/,"",$i); split($i,pp,","); print pp[1], pp[3]}}')"
[[ "$N0X" == <-> && "$N0W" == <-> && "$N1X" == <-> && "$N1W" == <-> ]] \
  || fail "the over-narrow panes published no usable bounds (pane0='$NARROW0')"
(( N0W >= 0 && N1W >= 0 )) || fail "an over-narrow pane got a negative width ($N0W / $N1W)"
(( N0X + N0W <= N1X + 1 )) || fail "the over-narrow panes overlap ($N0X+$N0W > $N1X)"
log "step16e generated_split_narrow_ok declared_minimums=600+600 pane0_x=$N0X pane0_w=$N0W pane1_x=$N1X pane1_w=$N1W"

log "step16c generated_split_ok declared_first_size=180 pane0_width=$PANE0_WIDTH pane0_x=$PANE0_X pane1_x=$PANE1_X capability=published"

# --- 16f. C3: TWO-WAY keyboard reveal + exact edit inside a generated scroll --
# A generated scroll whose content is far taller than its viewport, with a text
# field at the bottom and another at the top. Tab must reveal the clipped bottom
# field (moving the ACCEPTED offset), the exact typed text must read back, the
# other field must be untouched, Shift-Tab must reveal the top field again, and a
# refused reveal must not fake a negative offset or move anything.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 c3Root vertical"
  print -r -- "NODE 1 c3Scroll scrollArea"
  print -r -- "PROPERTY 1 c3Scroll offset 0"
  print -r -- "NODE 2 c3Stack vertical"
  print -r -- "NODE 3 c3A textInput field=label"
  print -r -- "PROPERTY 3 c3A label 顶部名称"
  for filler in 1 2 3 4; do
    print -r -- "NODE 3 c3Filler${filler} label"
    print -r -- "PROPERTY 3 c3Filler${filler} text 填充${filler}"
    print -r -- "PROPERTY 3 c3Filler${filler} fixedHeight 240"
  done
  print -r -- "NODE 3 c3M integerInput field=retentionCount"
  print -r -- "PROPERTY 3 c3M label 中部计数"
  print -r -- "NODE 3 c3B textInput field=excludedType"
  print -r -- "PROPERTY 3 c3B label 底部类型"
  print -r -- "END"
} > "$WORK/c3-structure.txt"
C3_VERSION="$(structure_version)"
pub generated-submit --structure-version "$C3_VERSION" --payload-file "$WORK/c3-structure.txt" \
  > "$WORK/c3-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/c3-submit.log" \
  || fail "the C3 generated scroll structure was rejected"
wait_for_structure_version $(( C3_VERSION + 1 )) \
  || fail "the C3 structure was never scene-accepted"
C3_INSTANCES="$(pub generated-instances 2>/dev/null)"
C3_SCROLL_SEMANTIC="$(print -r -- "$C3_INSTANCES" | awk '/kind=scrollArea/ {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}')"
C3_A_SEMANTIC="$(print -r -- "$C3_INSTANCES" | awk '$2 == "c3A" {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}')"
C3_B_SEMANTIC="$(print -r -- "$C3_INSTANCES" | awk '$2 == "c3B" {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}')"
C3_M_SEMANTIC="$(print -r -- "$C3_INSTANCES" | awk '$2 == "c3M" {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}')"
[[ -n "$C3_SCROLL_SEMANTIC" && -n "$C3_A_SEMANTIC" && -n "$C3_B_SEMANTIC" && -n "$C3_M_SEMANTIC" ]] \
  || fail "the C3 scroll/fields are not published as instances"
AX_PID="$APP_PID"
c3_bounds() {
  print -r -- "$1" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, pp, ","); print pp[1], pp[2], pp[3], pp[4]}}'
}
c3_instance_line() {
  print -r -- "$1" | awk -v key="$2" '$2 == key && !found {print; found=1}'
}
C3_SCROLL_FRAME="$(ax_identifier_frame "$C3_SCROLL_SEMANTIC" "group")"
frame_is_positive "$C3_SCROLL_FRAME" || fail "the C3 scroll instance has no frame ('$C3_SCROLL_FRAME')"
C3_B_BEFORE="$(ax_identifier_frame "$C3_B_SEMANTIC" "text field")"
C3_B_BEFORE_H="$(print -r -- "$C3_B_BEFORE" | awk '{print $4}')"
[[ "$C3_B_BEFORE_H" == <-> ]] || C3_B_BEFORE_H=0
C3_OFFSET_BEFORE="$(viewport_accepted_for "$C3_SCROLL_SEMANTIC")"
[[ -n "$C3_OFFSET_BEFORE" ]] || fail "the C3 scroll viewport is not published (semantic=$C3_SCROLL_SEMANTIC)"
C3_LABEL_DRAFT_BEFORE="$(field_draft_hex label)"
# Start from a REAL click on the visible top generated field, so the following Tab
# presses walk the generated region's own order (the window has many controls in
# front of it); the reveal under test is still driven by real Tab presses.
C3_A_CLICK_FRAME="$(ax_identifier_frame "$C3_A_SEMANTIC" "text field")"
frame_is_positive "$C3_A_CLICK_FRAME" \
  || fail "the top generated field has no visible frame ('$C3_A_CLICK_FRAME')"
read -r C3_AX C3_AY C3_AW C3_AH <<< "$C3_A_CLICK_FRAME"
activate_app
drive click $(( C3_AX + C3_AW / 2 )) $(( C3_AY + C3_AH / 2 ))
sleep 0.6
C3_OFFSET_FOCUSED="$(viewport_accepted_for "$C3_SCROLL_SEMANTIC")"
C3_FOCUS_AFTER_CLICK="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
C3_VIEWPORTS_BEFORE="$(pub window-interaction 2>/dev/null | awk '$1 == "WINDOW_VIEWPORT" {print $2" "$3" "$4" "$5" "$6}' | tr '\n' '|')"
log "diag step16f focus_click frame='$C3_A_CLICK_FRAME' offset_after_click='${C3_OFFSET_FOCUSED:-}' focus='${C3_FOCUS_AFTER_CLICK:-}' target='$C3_B_SEMANTIC' semantic_a='$C3_A_SEMANTIC' viewports_before='$C3_VIEWPORTS_BEFORE'"
# Real Tab presses until the clipped bottom field is brought into view. The
# ACCEPTED offset is the reveal's own fact: it advances only when the framework
# actually scrolled the shared viewport, and the exact focused identity is read
# from the window's own focus projection.
C3_TABS=0
C3_OFFSET_AFTER="$C3_OFFSET_BEFORE"
C3_FOCUS_TRACE=""
while (( C3_TABS < 60 )); do
  if [[ "$(app_frontmost)" != "true" ]]; then
    activate_app
    sleep 0.3
  fi
  drive tab
  sleep 0.5
  C3_FOCUS="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
  if (( C3_TABS < 10 )); then
    C3_FOCUS_TRACE="${C3_FOCUS_TRACE}${C3_FOCUS:-?}|"
  fi
  C3_OFFSET_NOW="$(viewport_accepted_for "$C3_SCROLL_SEMANTIC")"
  if [[ "$C3_FOCUS" == "$C3_B_SEMANTIC" ]] && [[ "$C3_OFFSET_NOW" == <-> ]] && \
    (( C3_OFFSET_NOW > C3_OFFSET_BEFORE )); then
    C3_OFFSET_AFTER="$C3_OFFSET_NOW"
    break
  fi
  C3_TABS=$(( C3_TABS + 1 ))
done
[[ "$C3_OFFSET_AFTER" == <-> ]] && (( C3_OFFSET_AFTER > C3_OFFSET_BEFORE )) \
  || fail "no real Tab press advanced the generated scroll's accepted offset (trace='$C3_FOCUS_TRACE' target='$C3_B_SEMANTIC')"
[[ "$C3_FOCUS_TRACE" == *"$C3_B_SEMANTIC"* ]] \
  || fail "Tab never focused the exact clipped identity $C3_B_SEMANTIC (trace='$C3_FOCUS_TRACE')"
sleep 1.0
C3_VIEWPORTS_AFTER="$(pub window-interaction 2>/dev/null | awk '$1 == "WINDOW_VIEWPORT" {print $2" "$3" "$4" "$5" "$6}' | tr '\n' '|')"
C3_A_FRAME_AFTER="$(ax_identifier_frame "$C3_A_SEMANTIC" "text field")"
C3_B_FRAME_AFTER="$(ax_identifier_frame "$C3_B_SEMANTIC" "text field")"
C3_INSTANCES_AFTER="$(pub generated-instances 2>/dev/null)"
C3_A_LINE_AFTER="$(print -r -- "$C3_INSTANCES_AFTER" | awk '$2 == "c3A" && !found {print; found=1}')"
C3_B_LINE_AFTER="$(print -r -- "$C3_INSTANCES_AFTER" | awk '$2 == "c3B" && !found {print; found=1}')"
log "diag step16f revealed a_frame_before='$C3_A_CLICK_FRAME' a_frame_after='$C3_A_FRAME_AFTER' b_frame_before='$C3_B_BEFORE' b_frame_after='$C3_B_FRAME_AFTER' a_instance='$C3_A_LINE_AFTER' b_instance='$C3_B_LINE_AFTER' viewports_after='$C3_VIEWPORTS_AFTER'"
# The revealed control's VISIBLE frame, in the one coordinate space that is
# internally consistent: the accepted layout projection. The field must now be
# inside its own scroll container's accepted rect, and the container itself must
# still be a visible instance.
C3_SCROLL_LINE="$(c3_instance_line "$C3_INSTANCES_AFTER" c3Scroll)"
[[ -n "$C3_SCROLL_LINE" ]] || fail "the C3 scroll container is not published as an instance"
read -r C3_SX C3_SY C3_SW C3_SH <<< "$(c3_bounds "$C3_SCROLL_LINE")"
read -r C3_BX C3_BY C3_BW C3_BH <<< "$(c3_bounds "$C3_B_LINE_AFTER")"
[[ "$C3_SW" == <-> && "$C3_SH" == <-> && "$C3_BW" == <-> && "$C3_BH" == <-> ]] \
  || fail "the revealed field/container published no accepted bounds ('$C3_B_LINE_AFTER')"
(( C3_BW > 0 && C3_BH > 0 && C3_SW > 0 && C3_SH > 0 )) \
  || fail "the revealed field or its container has an empty accepted rect (field=$C3_BX,$C3_BY,$C3_BW,$C3_BH container=$C3_SX,$C3_SY,$C3_SW,$C3_SH)"
(( C3_BX >= C3_SX - 1 && C3_BY >= C3_SY - 1 )) \
  || fail "the revealed field starts outside its scroll container (field=$C3_BX,$C3_BY container=$C3_SX,$C3_SY)"
(( C3_BX + C3_BW <= C3_SX + C3_SW + 1 && C3_BY + C3_BH <= C3_SY + C3_SH + 1 )) \
  || fail "the revealed field extends past its scroll container (field=$C3_BX,$C3_BY,$C3_BW,$C3_BH container=$C3_SX,$C3_SY,$C3_SW,$C3_SH)"
print -r -- "$C3_SCROLL_LINE" | grep -q 'visible=1' \
  || fail "the revealed field's scroll container is not a visible accepted instance"
log "diag step16f visible_frame_ok field=$C3_BX,$C3_BY,$C3_BW,$C3_BH container=$C3_SX,$C3_SY,$C3_SW,$C3_SH ax_b_frame='$C3_B_FRAME_AFTER' ax_scroll='$C3_SCROLL_FRAME'"
# The exact typed text must read back through the public field projection, and the
# OTHER field's draft must not move.
C3_TEXT="c3-reveal-bottom"
C3_DRAFT_BEFORE="$(print -r -- "$(field_draft_hex excludedType)" | hex_to_text)"
# A real select-all then type: the field may carry a placeholder draft, and the
# readback must be the EXACT typed text rather than an append.
chord_select_all
drive type "$C3_TEXT"
sleep 1.4
C3_B_DRAFT="$(print -r -- "$(field_draft_hex excludedType)" | hex_to_text)"
[[ "$C3_B_DRAFT" == "$C3_TEXT" ]] \
  || fail "the revealed generated field did not read back the exact text ('$C3_B_DRAFT' before='$C3_DRAFT_BEFORE')"
C3_LABEL_DRAFT_AFTER="$(field_draft_hex label)"
[[ "$C3_LABEL_DRAFT_AFTER" == "$C3_LABEL_DRAFT_BEFORE" ]] \
  || fail "editing the revealed field changed another field ('$C3_LABEL_DRAFT_BEFORE' -> '$C3_LABEL_DRAFT_AFTER')"
# Shift-Tab must walk back: every accepted offset step moves up, the visible
# frame of the identity the upward reveal lands on becomes POSITIVE and inside the
# scroll container, and the walk ends at the exact top identity with offset 0.
C3_SHIFTS=0
C3_OFFSET_BACK="$C3_OFFSET_AFTER"
C3_FOCUS_BACK_TRACE=""
C3_M_FRAME=""
C3_M_SCROLL_FRAME=""
while (( C3_SHIFTS < 40 )); do
  if [[ "$(app_frontmost)" != "true" ]]; then
    activate_app
    sleep 0.3
  fi
  drive shortcut shift 48
  sleep 0.5
  C3_FOCUS_BACK="$(pub window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}')"
  if (( C3_SHIFTS < 10 )); then
    C3_FOCUS_BACK_TRACE="${C3_FOCUS_BACK_TRACE}${C3_FOCUS_BACK:-?}|"
  fi
  C3_OFFSET_NOW="$(viewport_accepted_for "$C3_SCROLL_SEMANTIC")"
  if [[ "$C3_OFFSET_NOW" == <-> ]]; then
    C3_OFFSET_BACK="$C3_OFFSET_NOW"
  fi
  if [[ -z "$C3_M_FRAME" && "$C3_FOCUS_BACK" == "$C3_M_SEMANTIC" ]]; then
    sleep 0.6
    C3_M_FRAME="$(ax_identifier_frame "$C3_M_SEMANTIC" "text field")"
    C3_M_SCROLL_FRAME="$(ax_identifier_frame "$C3_SCROLL_SEMANTIC" "group")"
  fi
  [[ "$C3_OFFSET_BACK" == <-> ]] && (( C3_OFFSET_BACK == 0 )) && break
  C3_SHIFTS=$(( C3_SHIFTS + 1 ))
done
(( C3_OFFSET_BACK < C3_OFFSET_AFTER )) \
  || fail "Shift-Tab never moved the generated scroll back (offset=$C3_OFFSET_BACK)"
[[ "$C3_FOCUS_BACK_TRACE" == *"$C3_A_SEMANTIC"* ]] \
  || fail "Shift-Tab never focused the exact top identity $C3_A_SEMANTIC again (trace='$C3_FOCUS_BACK_TRACE')"
# The UPWARD reveal's visible frame: the identity the reverse walk landed on must
# be a POSITIVE accessibility frame fully inside the scroll container.
frame_is_positive "$C3_M_FRAME" \
  || fail "the upward reveal left the middle identity $C3_M_SEMANTIC clipped ('$C3_M_FRAME')"
print -r -- "$C3_M_FRAME $C3_M_SCROLL_FRAME" | awk '{
  if (NF != 8) exit 1
  fx = $1; fy = $2; fw = $3; fh = $4; cx = $5; cy = $6; cw = $7; ch = $8
  if (fx < cx - 2 || fy < cy - 2) exit 1
  if (fx + fw > cx + cw + 2 || fy + fh > cy + ch + 2) exit 1
  exit 0
}' || fail "the upward-revealed field is not inside its contemporaneous scroll container ('$C3_M_FRAME' vs '$C3_M_SCROLL_FRAME')"
# A REFUSED reveal must not be faked: at the top boundary further Shift-Tabs leave
# the accepted offset exactly at the top instead of inventing a negative one.
C3_OFFSET_TOP="$C3_OFFSET_BACK"
C3_A_TOP_FRAME="$(ax_identifier_frame "$C3_A_SEMANTIC" "text field")"
for c3_top in 1 2 3; do
  drive shortcut shift 48
  sleep 0.3
done
C3_OFFSET_REFUSED="$(viewport_accepted_for "$C3_SCROLL_SEMANTIC")"
C3_A_REFUSED_FRAME="$(ax_identifier_frame "$C3_A_SEMANTIC" "text field")"
(( C3_OFFSET_TOP == 0 )) \
  || fail "reverse reveal did not return to the top of the generated scroll (offset=$C3_OFFSET_TOP)"
[[ "$C3_OFFSET_REFUSED" == "$C3_OFFSET_TOP" ]] \
  || fail "a refused reveal changed the accepted offset ($C3_OFFSET_TOP -> $C3_OFFSET_REFUSED)"
log "diag step16f upward_visible_frame middle='$C3_M_FRAME' container='$C3_SCROLL_FRAME' top_frame='$C3_A_TOP_FRAME' refused_frame='$C3_A_REFUSED_FRAME'"
log "step16f generated_keyboard_reveal_ok semantic=$C3_SCROLL_SEMANTIC target=$C3_B_SEMANTIC offset=$C3_OFFSET_BEFORE->$C3_OFFSET_AFTER tabs=$((C3_TABS + 1)) back_offset=$C3_OFFSET_TOP shifts=$((C3_SHIFTS + 1)) readback='$C3_B_DRAFT' other_field_unchanged=true refused_reveal_not_faked=true visible_frame='$C3_M_FRAME' driver=real_keyboard"

# --- 16h. E: comparable work counters for ONE real operation -----------------
# The SAME window, the SAME accepted structure and the SAME load: a real wheel
# gesture on the generated viewport. Every number below is a real counter the
# framework publishes (viewport solves, native submission version, submitted
# frame index, accepted scene version), not a response length or a script sleep.
progress_counter() {
  pub window-progress 2>/dev/null | awk -v key="$1" '$1 == key {print $2}'
}
viewport_solves_for() {
  pub window-interaction 2>/dev/null | awk -v id="$1" '$1 == "WINDOW_VIEWPORT" && $2 == id {
    for (i = 1; i <= NF; i++) if ($i ~ /^solves=/ && !found) {sub(/^solves=/, "", $i); print $i; found=1}}'
}
C5_SOLVES_BEFORE="$(viewport_solves_for "$C3_SCROLL_SEMANTIC")"
C5_SUBMIT_BEFORE="$(progress_counter WINDOW_NATIVE_SUBMISSION_VERSION)"
C5_FRAME_BEFORE="$(progress_counter WINDOW_SUBMITTED_FRAME_INDEX)"
C5_ACCEPTED_BEFORE="$(progress_counter WINDOW_ACCEPTED_SCENE_VERSION)"
C5_STRUCTURE_BEFORE="$(structure_version)"
[[ "$C5_SOLVES_BEFORE" == <-> && "$C5_SUBMIT_BEFORE" == <-> && "$C5_FRAME_BEFORE" == <-> ]] \
  || fail "the work counters are not readable before the operation (solves=$C5_SOLVES_BEFORE submit=$C5_SUBMIT_BEFORE frame=$C5_FRAME_BEFORE)"
read -r C5X C5Y C5W C5H <<< "$C3_SCROLL_FRAME"
C5_WHEEL_X=$(( C5X + C5W / 2 ))
C5_WHEEL_Y=$(( C5Y + C5H / 2 ))
T_C5_START="$(now_us)"
for c5_try in 1 2 3; do
  activate_app
  sleep 0.3
  drive scroll "$C5_WHEEL_X" "$C5_WHEEL_Y" -4
  sleep 0.8
  C5_SOLVES_AFTER="$(viewport_solves_for "$C3_SCROLL_SEMANTIC")"
  [[ "$C5_SOLVES_AFTER" == <-> ]] && (( C5_SOLVES_AFTER > C5_SOLVES_BEFORE )) && break
done
T_C5_END="$(now_us)"
C5_SUBMIT_AFTER="$(progress_counter WINDOW_NATIVE_SUBMISSION_VERSION)"
C5_FRAME_AFTER="$(progress_counter WINDOW_SUBMITTED_FRAME_INDEX)"
C5_ACCEPTED_AFTER="$(progress_counter WINDOW_ACCEPTED_SCENE_VERSION)"
C5_WHEEL_MS=$(( (T_C5_END - T_C5_START) / 1000 ))
[[ "$C5_SOLVES_AFTER" == <-> ]] && (( C5_SOLVES_AFTER > C5_SOLVES_BEFORE )) \
  || fail "the real wheel did not advance the generated viewport's solve counter ($C5_SOLVES_BEFORE -> ${C5_SOLVES_AFTER:-})"
[[ "$C5_SUBMIT_AFTER" == <-> ]] && (( C5_SUBMIT_AFTER > C5_SUBMIT_BEFORE )) \
  || fail "the accepted viewport move did not reach a native submission ($C5_SUBMIT_BEFORE -> ${C5_SUBMIT_AFTER:-})"
[[ "$C5_FRAME_AFTER" == <-> ]] && (( C5_FRAME_AFTER >= C5_FRAME_BEFORE )) \
  || fail "the submitted frame counter regressed ($C5_FRAME_BEFORE -> ${C5_FRAME_AFTER:-})"
[[ "$C5_ACCEPTED_AFTER" == <-> ]] && (( C5_ACCEPTED_AFTER > C5_ACCEPTED_BEFORE )) \
  || fail "the wheel did not advance the accepted scene version ($C5_ACCEPTED_BEFORE -> ${C5_ACCEPTED_AFTER:-})"
[[ "$(structure_version)" == "$C5_STRUCTURE_BEFORE" ]] \
  || fail "the wheel advanced the business structure version"
log "step16h same_window_work_counters operation=generated_wheel wheel_ms=$C5_WHEEL_MS viewport_solves=$C5_SOLVES_BEFORE->$C5_SOLVES_AFTER native_submission=$C5_SUBMIT_BEFORE->$C5_SUBMIT_AFTER submitted_frame=$C5_FRAME_BEFORE->$C5_FRAME_AFTER accepted_scene=$C5_ACCEPTED_BEFORE->$C5_ACCEPTED_AFTER structure_version_stable=$C5_STRUCTURE_BEFORE clock=CLOCK_MONOTONIC_us"

# --- 16g. D: the accepted identity frame of a GENERATED element paints --------
# A generated leaf declares its own background. The composited pixel is sampled
# INSIDE the frame of that element's accepted identity (never a guessed
# coordinate), so paint output, the published definition and the accepted
# identity are correlated in one real observation.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 c4Root vertical"
  print -r -- "NODE 1 c4Band label"
  print -r -- "PROPERTY 1 c4Band text 生成色带"
  print -r -- "PROPERTY 1 c4Band background #22cc88ff"
  print -r -- "PROPERTY 1 c4Band fixedHeight 96"
  print -r -- "END"
} > "$WORK/c4-paint.txt"
C4_VERSION="$(structure_version)"
pub generated-submit --structure-version "$C4_VERSION" --payload-file "$WORK/c4-paint.txt" \
  > "$WORK/c4-paint-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/c4-paint-submit.log" \
  || fail "the generated paint candidate was rejected"
wait_for_structure_version $(( C4_VERSION + 1 )) \
  || fail "the generated paint candidate was never scene-accepted"
C4_LINE="$(pub generated-instances 2>/dev/null | awk '$2 == "c4Band" {print}')"
[[ -n "$C4_LINE" ]] || fail "the generated paint element is not published as an instance"
print -r -- "$C4_LINE" | grep -q 'visible=1' \
  || fail "the generated paint element is not a visible accepted instance ('$C4_LINE')"
C4_SEMANTIC="$(print -r -- "$C4_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i}}')"
[[ -n "$C4_SEMANTIC" ]] || fail "the generated paint element carries no exact identity"
activate_app
sleep 0.5
C4_FRAME="$(ax_identifier_frame "$C4_SEMANTIC" "static text" || true)"
if ! frame_is_positive "$C4_FRAME"; then
  C4_FRAME="$(ax_identifier_frame "$C4_SEMANTIC" "text" || true)"
fi
if ! frame_is_positive "$C4_FRAME"; then
  C4_FRAME="$(ax_identifier_frame "$C4_SEMANTIC" "UI element" || true)"
fi
frame_is_positive "$C4_FRAME" || fail "the generated paint identity has no frame ('$C4_FRAME')"
read -r C4X C4Y C4W C4H <<< "$C4_FRAME"
C4_PIXEL_A="$(region_pixel_hex $(( C4X + C4W / 4 )) $(( C4Y + C4H / 2 )) || true)"
C4_PIXEL_B="$(region_pixel_hex $(( C4X + C4W * 3 / 4 )) $(( C4Y + C4H / 2 )) || true)"
[[ -n "$C4_PIXEL_A" || -n "$C4_PIXEL_B" ]] \
  || fail "the bounded region screenshot produced no pixel for the generated element"
python3 - "22cc88" "$C4_PIXEL_A" "$C4_PIXEL_B" <<'PYPAINT'
import sys

published, observed_a, observed_b = sys.argv[1:4]


def rgb(token):
    token = token.lstrip("#")[:6]
    return int(token[0:2], 16), int(token[2:4], 16), int(token[4:6], 16)


def delta(a, b):
    return max(abs(x - y) for x, y in zip(rgb(a), rgb(b)))


candidates = [candidate for candidate in (observed_a, observed_b) if candidate]
if not candidates:
    print("no bounded screenshot pixel was captured")
    sys.exit(1)
best_pixel = min(candidates, key=lambda candidate: delta(published, candidate))
best = delta(published, best_pixel)
pr, pg, pb = rgb(published)
or_, og, ob = rgb(best_pixel)
# The dominant channel is chosen by the PUBLISHED definition, and the observed
# pixel must agree with it by a margin larger than any plausible white blend of
# an unrelated colour. The declared paint is correlated with the real composited
# output; the exact delta is logged so a colour-management gap stays visible.
published_dominant = max((pr, "r"), (pg, "g"), (pb, "b"))[1]
observed_channels = {"r": or_, "g": og, "b": ob}
others = [value for name, value in observed_channels.items() if name != published_dominant]
margin = observed_channels[published_dominant] - max(others)
print(f"published=#{published} observed=#{best_pixel} best_delta={best} "
      f"dominant={published_dominant} margin={margin}")
if best > 80:
    print("the composited pixel does not match the generated element's accepted background")
    sys.exit(1)
if margin < 40:
    print("the composited pixel is not in the accepted background's channel family")
    sys.exit(1)
PYPAINT
log "step16g generated_paint_by_identity_ok semantic=$C4_SEMANTIC published=#22cc88 observed=#$C4_PIXEL_A/#$C4_PIXEL_B frame='$C4_FRAME' method=bounded_region_screenshot tolerance=80 family=declared_dominant_channel"

cont_first_pane_width() { # cont_first_pane_width <instances-text> <first-key> -> width
  print -r -- "$1" | awk -v key="$2" '$2 == key {for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/ && !found) {sub(/^bounds=/, "", $i); split($i, pp, ","); print pp[3]; found=1}}'
}
cont_editor_semantic() { # cont_editor_semantic <instances-text> -> exact semantic of contEditor
  print -r -- "$1" | awk '$2 == "contEditor" {for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/ && !found) {sub(/^semantic=/, "", $i); print $i; found=1}}'
}

# --- 16j. C3/C2: drag / legal reorder / style update / resize continuity ------
# One accepted instance must keep its identity, its owner draft and its own split
# size through a REAL divider drag, a legal reorder of the same keys, a legal
# structure update that changes the declared style, and a real window resize (with
# the size clamped inside the new track). No step restarts the application.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 contRoot vertical"
  print -r -- "NODE 1 contSplit split"
  print -r -- "PROPERTY 1 contSplit firstSize 200"
  print -r -- "PROPERTY 1 contSplit firstMinimum 80"
  print -r -- "PROPERTY 1 contSplit secondMinimum 80"
  print -r -- "PROPERTY 1 contSplit fixedHeight 90"
  print -r -- "NODE 2 contPaneA vertical"
  print -r -- "NODE 3 contEditor textInput field=label"
  print -r -- "PROPERTY 3 contEditor label 连续性编辑"
  print -r -- "NODE 2 contPaneB vertical"
  print -r -- "NODE 3 contPaneBLabel label"
  print -r -- "PROPERTY 3 contPaneBLabel text 右栏"
  print -r -- "END"
} > "$WORK/continuity-1.txt"
CONT_VERSION="$(structure_version)"
pub generated-submit --structure-version "$CONT_VERSION" --payload-file "$WORK/continuity-1.txt" \
  > "$WORK/continuity-submit1.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/continuity-submit1.log" || fail "the continuity structure was rejected"
wait_for_structure_version $(( CONT_VERSION + 1 )) || fail "the continuity structure was never scene-accepted"
CONT_INSTANCES="$(pub generated-instances 2>/dev/null)"
CONT_EDITOR_SEM="$(cont_editor_semantic "$CONT_INSTANCES")"
CONT_W0="$(cont_first_pane_width "$CONT_INSTANCES" contPaneA)"
[[ -n "$CONT_EDITOR_SEM" && "$CONT_W0" == <-> ]] || fail "the continuity fixture is not published ($CONT_INSTANCES)"
CONT_DRAFT="连续性-草稿-$(date +%s)"
pub invoke "$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT --target "$RECORD_ID" \
  --arg fieldId=STRING:label --arg text=STRING:"$CONT_DRAFT" \
  --arg expectedDraftVersion=INTEGER:"$(field_version label)" > "$WORK/continuity-draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/continuity-draft.log" || fail "the continuity draft edit was rejected"
[[ "$(print -r -- "$(field_draft_hex label)" | hex_to_text)" == "$CONT_DRAFT" ]] \
  || fail "the continuity draft did not read back"

# 1) A REAL divider drag: the instance resizes, the draft and identity survive.
CONT_STRUCTURE_BEFORE="$(structure_version)"
CONT_DIVIDER=""
for cont_lookup in 1 2 3; do
  activate_app
  CONT_DIVIDER="$(real_ax_dump_identifiers "$APP_PID" 80 | sed -n 's/^identifier=\(component-[0-9-]*-handle\).*$/\1/p' | head -1)"
  [[ -n "$CONT_DIVIDER" ]] && break
  sleep 0.5
done
[[ -n "$CONT_DIVIDER" ]] || fail "the continuity split published no divider identity"
CONT_FRAME="$(ax_identifier_frame "$CONT_DIVIDER" "group" || true)"
frame_is_positive "$CONT_FRAME" || fail "the continuity divider has no usable frame ('$CONT_FRAME')"
read -r CONT_DX CONT_DY CONT_DW CONT_DH <<< "$CONT_FRAME"
CONT_FROM_X=$(( CONT_DX + CONT_DW / 2 ))
CONT_Y=$(( CONT_DY + CONT_DH / 2 ))
CONT_W_AFTER_DRAG=""
for cont_try in 1 2 3; do
  activate_app
  drive move "$CONT_FROM_X" "$CONT_Y"
  sleep 0.2
  drive press "$CONT_FROM_X" "$CONT_Y"
  sleep 0.3
  drive move $(( CONT_FROM_X + 70 )) "$CONT_Y"
  sleep 0.3
  drive release $(( CONT_FROM_X + 70 )) "$CONT_Y"
  sleep 1.2
  CONT_W_AFTER_DRAG="$(cont_first_pane_width "$(pub generated-instances 2>/dev/null)" contPaneA)"
  [[ "$CONT_W_AFTER_DRAG" == <-> ]] && (( CONT_W_AFTER_DRAG > CONT_W0 )) && break
done
[[ "$CONT_W_AFTER_DRAG" == <-> ]] || fail "the continuity drag published no pane width"
(( CONT_W_AFTER_DRAG > CONT_W0 )) \
  || fail "the continuity drag did not resize the first pane ($CONT_W0 -> $CONT_W_AFTER_DRAG)"
[[ "$(structure_version)" == "$CONT_STRUCTURE_BEFORE" ]] \
  || fail "the continuity drag advanced the business structure version"
CONT_DRAFT_AFTER_DRAG="$(print -r -- "$(field_draft_hex label)" | hex_to_text)"
[[ "$CONT_DRAFT_AFTER_DRAG" == "$CONT_DRAFT" ]] \
  || fail "the divider drag changed the owner draft ('$CONT_DRAFT' -> '$CONT_DRAFT_AFTER_DRAG')"
[[ "$(cont_editor_semantic "$(pub generated-instances 2>/dev/null)")" == "$CONT_EDITOR_SEM" ]] \
  || fail "the divider drag changed the editor identity"
log "diag step16j drag pane0_w=$CONT_W0->$CONT_W_AFTER_DRAG draft_kept=true"

# 2) A legal REORDER of the same keys: same instance, same identity, and the split
# keeps the size the person dragged instead of resetting to the declaration.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 contRoot vertical"
  print -r -- "NODE 1 contSplit split"
  print -r -- "PROPERTY 1 contSplit firstSize 200"
  print -r -- "PROPERTY 1 contSplit firstMinimum 80"
  print -r -- "PROPERTY 1 contSplit secondMinimum 80"
  print -r -- "PROPERTY 1 contSplit fixedHeight 90"
  print -r -- "NODE 2 contPaneB vertical"
  print -r -- "NODE 3 contPaneBLabel label"
  print -r -- "PROPERTY 3 contPaneBLabel text 右栏"
  print -r -- "NODE 2 contPaneA vertical"
  print -r -- "NODE 3 contEditor textInput field=label"
  print -r -- "PROPERTY 3 contEditor label 连续性编辑"
  print -r -- "END"
} > "$WORK/continuity-2.txt"
CONT2_VERSION="$(structure_version)"
pub generated-submit --structure-version "$CONT2_VERSION" --payload-file "$WORK/continuity-2.txt" \
  > "$WORK/continuity-submit2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/continuity-submit2.log" || fail "the reordered structure was rejected"
wait_for_structure_version $(( CONT2_VERSION + 1 )) || fail "the reordered structure was never scene-accepted"
CONT2_INSTANCES="$(pub generated-instances 2>/dev/null)"
[[ "$(print -r -- "$(field_draft_hex label)" | hex_to_text)" == "$CONT_DRAFT" ]] \
  || fail "the legal reorder changed the owner draft"
[[ "$(cont_editor_semantic "$CONT2_INSTANCES")" == "$CONT_EDITOR_SEM" ]] \
  || fail "the legal reorder changed the editor identity ($CONT_EDITOR_SEM -> $(cont_editor_semantic "$CONT2_INSTANCES"))"
CONT_FIRST_AFTER_REORDER="$(cont_first_pane_width "$CONT2_INSTANCES" contPaneB)"
[[ "$CONT_FIRST_AFTER_REORDER" == <-> ]] || fail "the reordered split published no first pane width"
(( CONT_FIRST_AFTER_REORDER == CONT_W_AFTER_DRAG )) \
  || fail "the reorder reset the person's split size ($CONT_W_AFTER_DRAG -> $CONT_FIRST_AFTER_REORDER)"
log "diag step16j reorder first_pane_w=$CONT_FIRST_AFTER_REORDER draft_kept=true identity_kept=true"

# 3) A legal structure UPDATE that changes the declared style: identity, draft and
# the person's split size all survive the paint change.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 contRoot vertical"
  print -r -- "NODE 1 contSplit split"
  print -r -- "PROPERTY 1 contSplit firstSize 200"
  print -r -- "PROPERTY 1 contSplit firstMinimum 80"
  print -r -- "PROPERTY 1 contSplit secondMinimum 80"
  print -r -- "PROPERTY 1 contSplit fixedHeight 90"
  print -r -- "PROPERTY 1 contSplit background #334455ff"
  print -r -- "NODE 2 contPaneB vertical"
  print -r -- "NODE 3 contPaneBLabel label"
  print -r -- "PROPERTY 3 contPaneBLabel text 右栏"
  print -r -- "NODE 2 contPaneA vertical"
  print -r -- "NODE 3 contEditor textInput field=label"
  print -r -- "PROPERTY 3 contEditor label 连续性编辑"
  print -r -- "PROPERTY 3 contEditor background #445566ff"
  print -r -- "END"
} > "$WORK/continuity-3.txt"
CONT3_VERSION="$(structure_version)"
pub generated-submit --structure-version "$CONT3_VERSION" --payload-file "$WORK/continuity-3.txt" \
  > "$WORK/continuity-submit3.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/continuity-submit3.log" || fail "the restyled structure was rejected"
wait_for_structure_version $(( CONT3_VERSION + 1 )) || fail "the restyled structure was never scene-accepted"
CONT3_INSTANCES="$(pub generated-instances 2>/dev/null)"
[[ "$(print -r -- "$(field_draft_hex label)" | hex_to_text)" == "$CONT_DRAFT" ]] \
  || fail "the style update changed the owner draft"
[[ "$(cont_editor_semantic "$CONT3_INSTANCES")" == "$CONT_EDITOR_SEM" ]] \
  || fail "the style update changed the editor identity"
CONT_FIRST_AFTER_STYLE="$(cont_first_pane_width "$CONT3_INSTANCES" contPaneB)"
(( CONT_FIRST_AFTER_STYLE == CONT_W_AFTER_DRAG )) \
  || fail "the style update reset the person's split size ($CONT_W_AFTER_DRAG -> $CONT_FIRST_AFTER_STYLE)"
log "diag step16j style_update first_pane_w=$CONT_FIRST_AFTER_STYLE draft_kept=true"

# 4) A REAL window resize: identity and draft survive and the size stays inside the
# new track (bounded, never below the declared minimum, never wider than before).
real_resize_window -220 -140 || true
activate_app
sleep 1.0
CONT4_INSTANCES="$(pub generated-instances 2>/dev/null)"
[[ "$(print -r -- "$(field_draft_hex label)" | hex_to_text)" == "$CONT_DRAFT" ]] \
  || fail "the window resize changed the owner draft"
[[ "$(cont_editor_semantic "$CONT4_INSTANCES")" == "$CONT_EDITOR_SEM" ]] \
  || fail "the window resize changed the editor identity"
CONT_FIRST_AFTER_RESIZE="$(cont_first_pane_width "$CONT4_INSTANCES" contPaneB)"
[[ "$CONT_FIRST_AFTER_RESIZE" == <-> ]] || fail "the resized split published no first pane width"
(( CONT_FIRST_AFTER_RESIZE >= 80 )) \
  || fail "the resized split went below the declared minimum ($CONT_FIRST_AFTER_RESIZE)"
(( CONT_FIRST_AFTER_RESIZE <= CONT_FIRST_AFTER_STYLE )) \
  || fail "the resized split grew past the person's size in a narrower window ($CONT_FIRST_AFTER_STYLE -> $CONT_FIRST_AFTER_RESIZE)"
[[ "$(structure_version)" == "$(( CONT3_VERSION + 1 ))" ]] \
  || fail "the window resize advanced the business structure version"
log "step16j continuity_ok drag_w=$CONT_W0->$CONT_W_AFTER_DRAG reorder_w=$CONT_FIRST_AFTER_REORDER style_w=$CONT_FIRST_AFTER_STYLE resize_w=$CONT_FIRST_AFTER_RESIZE draft=$CONT_DRAFT editor=$CONT_EDITOR_SEM"

# --- 17. A: the REAL window close releases this window's catalog holds ------
# A second launch of the SAME round bundle in its close-decision mode: it accepts
# an image-bearing structure through the public channel, then closes through the
# window's own decision path. The dispose line comes from that real close, not
# from a test calling the release helper.
CLOSE_LOG="$WORK/close-probe.log"
( cd "$ROUND_DIR" && zsh run.sh --verify-host-close-decisions > "$CLOSE_LOG" 2>&1 ) || true
grep -q 'image_holds_before_close=1' "$CLOSE_LOG" \
  || fail "the close probe did not hold a shared image identity (tail: $(tail -2 "$CLOSE_LOG"))"
grep -q 'CJGUI_IMAGE_IDENTITY_DISPOSE leftover_holds=0' "$CLOSE_LOG" \
  || fail "the real window close did not release its shared image identity holds"
grep -q 'CJGUI_RULE_SET_HOST_PROBE rejected_then_accepted_close_cleaned' "$CLOSE_LOG" \
  || fail "the close probe did not complete its close decision path"
log "step17 image_identity_dispose_ok holds_before_close=1 leftover_holds=0 source=real_window_close"

log "PASSED generated-ui chain"
cat "$LOG"
exit 0
