#!/usr/bin/env zsh
# The rule-set consumer's CONVERGED public detail seam, over the app's OWN
# normal window: selection A/B, the public block and the handwritten fields edit
# the SAME owner, external INSTANCE/OWNER reads are scoped by the accepted
# instance table, an external owner write updates both presentations, an
# invalid draft is refused on Apply and editing continues, and one field
# constraint change is refused by UI/catalog/external alike.
set -u
SCRIPT_DIR="${0:A:h}"
RUNTIME_DIR="${CJGUI_SDK_RUNTIME:-${SCRIPT_DIR:h:h}}"
APP_DIR="${CJGUI_RULE_APP_DIR:-$RUNTIME_DIR/examples/rule_set_window_app}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
WORK="${CJGUI_RULE_DETAIL_TMPDIR:-/private/tmp/cjgui-rule-public-detail-$(date +%H%M%S)-$$}"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" | tee -a "$LOG"; }
fail() { log "FAIL $*"; exit 1; }
blocked() { log "BLOCKED $*"; exit 3; }

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh" >/dev/null 2>&1
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
[[ "${LOCK_STATE//[[:space:]]/}" == "Yes" ]] && blocked "session locked"

TAG="Pd$(date +%H%M%S)"
ROUND="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND" "$RUNTIME_DIR" "CJGUIRuleSet" "$TAG" \
  "org.cangjie.cjgui.rule-set.example" || fail "application copy failed"
EXEC="$ROUND/target/release/CJGUIRuleSet${TAG}.app/Contents/MacOS/CJGUIRuleSet${TAG}"
APP_BUNDLE="$ROUND/target/release/CJGUIRuleSet${TAG}.app"
APP_PID=""; DESCRIPTOR=""
cleanup() { [[ -n "${APP_PID:-}" ]] && cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$EXEC" "$ROUND" || true; }
trap cleanup EXIT

cd "$ROUND" || fail "no round dir"
( nohup zsh run.sh --build-only > "$WORK/build.log" 2>&1 ) || fail "build failed: $(tail -3 "$WORK/build.log")"
( nohup zsh run.sh > "$WORK/app.log" 2>&1 & )
DESCRIPTOR="$(cjgui_wait_descriptor "$WORK/app.log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 180)" || \
  fail "no descriptor: $(tail -5 "$WORK/app.log")"
APP_PID="$(pgrep -f "$EXEC" | head -1)"
[[ -n "$APP_PID" ]] || fail "no app process for this round"
pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
ver() { pub get 2>/dev/null | awk '/^VERSION /{print $2}'; }
field_hex() { pub generated-fields 2>/dev/null | awk -v f="FIELD $1 " 'index($0,f)==1 {for(i=1;i<=NF;i++) if($i=="DRAFT_HEX") print $(i+1)}'; }
field_word() { # field_word <fieldId> <WORD>
  pub generated-fields 2>/dev/null | awk -v f="FIELD $1 " -v w="$2" 'index($0,f)==1 {for(i=1;i<=NF;i++) if($i==w) print $(i+1)}'
}
text_of() { print -r -- "$1" | python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("","-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
ax_text() { /private/tmp/r7-ax "$APP_PID" find "$1" 2>/dev/null | sed -n '/value_begin/,/value_end/p' | sed '1d;$d'; }
ax_frame() { /private/tmp/r7-ax "$APP_PID" find "$1" 2>/dev/null | sed -n 's/^frame=//p' | head -1; }
click_field() {
  local f="$(ax_frame "$1")"
  [[ -n "$f" && "$f" != "missing" ]] || return 1
  local x y w h; read -r x y w h <<< "$f"
  "$WORK/left" $(( x + w / 2 )) $(( y + h / 2 ))
  sleep 0.35
}
click_id() { click_field "$1"; }

# --- real input driver + owned bind (target must be frontmost) --------------
DRIVER_SOURCE="${CJGUI_INPUT_DRIVER_SOURCE:-$RUNTIME_DIR/native/tests/desktop_input_driver.swift}"
swiftc -O "$DRIVER_SOURCE" -o "$WORK/driver" > "$WORK/driver-build.log" 2>&1 || \
  blocked "input driver build failed"
cat > "$WORK/left.swift" <<'S'
import CoreGraphics
import Foundation
let a = CommandLine.arguments
let p = CGPoint(x: Double(a[1])!, y: Double(a[2])!)
for t in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
  CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
  usleep(40_000)
}
S
swiftc -O "$WORK/left.swift" -o "$WORK/left" > /dev/null 2>&1 || blocked "click helper build failed"
swiftc -O "/Users/jiangxuanyang/Desktop/Pharos Mark/tools/ax_node_probe.swift" -o /private/tmp/r7-ax > /dev/null 2>&1 || \
  blocked "AX probe build failed"
open "$APP_BUNDLE" > /dev/null 2>&1 || true
sleep 2.0
APP_PID="$(pgrep -f "$EXEC" | head -1)"
osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $APP_PID) to true" > /dev/null 2>&1
sleep 1.2
SCOPE="$WORK/owned-input.json"
python3 - "$APP_PID" "$EXEC" "$SCOPE" <<'PY'
import json, os, sys, uuid
pid, exe, path = sys.argv[1:]
json.dump({"pid": int(pid), "nonce": uuid.uuid4().hex, "executable": exe}, open(path, "w"))
os.chmod(path, 0o600)
PY
export CJGUI_DRIVER_TARGET_PID="$APP_PID" CJGUI_DRIVER_TARGET_FILE="$SCOPE"
"$WORK/driver" bind-target "$SCOPE" > "$WORK/bind.log" 2>&1 || blocked "owned bind failed: $(tail -1 "$WORK/bind.log")"
DRIVER="$WORK/driver"

# --- step1: two records through the public route ---------------------------
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"甲规则" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"pd-a" > "$WORK/create-a.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create-a.log" || fail "create A failed"
pub invoke "$(ver)" CREATE_RECORD --target 8000 --arg label=STRING:"乙规则" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:11 --arg excludedType=STRING:"-" --arg requestId=STRING:"pd-b" > "$WORK/create-b.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create-b.log" || fail "create B failed"
log "step1 created A=1 B=2 selected=[$(text_of "$(field_hex label)")]"

# --- step2: select A; both presentations read A ---------------------------
pub invoke "$(ver)" SELECT_RECORD --target 1 > "$WORK/select-a.log" 2>&1 || true
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "甲规则" ]] || fail "owner projection did not follow A"
click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable"
sleep 0.6
[[ "$(ax_text field-label)" == "甲规则" ]] || fail "handwritten field did not show A"
click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
sleep 0.6
[[ "$(ax_text public-detail-label)" == "甲规则" ]] || fail "public detail did not show A"
log "step2 select_A handwritten+public=[甲规则]"

# --- step3: real key edit through the PUBLIC detail block -----------------
click_field public-detail-label || fail "public detail editor not reachable"
LABEL_VERSION_BEFORE="$(field_word label VERSION)"
"$DRIVER" cmd-key 0 > /dev/null 2>&1 || fail "select-all failed"
# ONE keystroke over the whole selection: one user input must be exactly one
# owner write (the range session rewrites the field once per accepted key).
"$DRIVER" type "改" > /dev/null 2>&1 || fail "typing failed"
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "改" ]] || fail "public edit did not reach the owner: [$(text_of "$(field_hex label)")]"
LABEL_VERSION_AFTER="$(field_word label VERSION)"
(( LABEL_VERSION_AFTER == LABEL_VERSION_BEFORE + 1 )) || \
  fail "one key write advanced the field ${LABEL_VERSION_AFTER} - ${LABEL_VERSION_BEFORE} times"
click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable"
sleep 0.6
[[ "$(ax_text field-label)" == "改" ]] || fail "handwritten presentation did not show the public edit"
log "step3 public_edit owner=[改] handwritten=[改] one_writing"

# --- step4: real key edit through the HANDWRITTEN field ------------------
click_field field-label || fail "handwritten field not reachable"
"$DRIVER" cmd-key 0 > /dev/null 2>&1 || fail "select-all failed"
"$DRIVER" type "手写改" > /dev/null 2>&1 || fail "typing failed"
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "手写改" ]] || fail "handwritten edit did not reach the owner"
click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
sleep 0.6
[[ "$(ax_text public-detail-label)" == "手写改" ]] || fail "public detail did not show the handwritten edit"
log "step4 handwritten_edit owner=[手写改] public=[手写改]"

# --- step5: select B; drafts stay isolated --------------------------------
pub invoke "$(ver)" SELECT_RECORD --target 2 > "$WORK/select-b.log" 2>&1 || true
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "乙规则" ]] || fail "B did not show its own draft"
click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
sleep 0.6
[[ "$(ax_text public-detail-label)" == "乙规则" ]] || fail "public detail did not show B"
pub invoke "$(ver)" SELECT_RECORD --target 1 > /dev/null 2>&1 || true
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "手写改" ]] || fail "A's draft was lost after B"
log "step5 isolation A=[手写改] B=[乙规则]"

# --- step6: scoped external reads use the accepted instance table ----------
cat > "$WORK/structure.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 retentionEdit retentionIntegerEdit
END
S1
SV="$(pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
pub generated-submit --structure-version "$SV" --payload-file "$WORK/structure.txt" > "$WORK/submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit.log" || fail "composite structure not accepted"
sleep 1.0
[[ "$(pub generated-fields --instance retentionEdit 2>/dev/null | grep -c '^FIELD retentionCount ')" == "1" ]] || \
  fail "INSTANCE scoped read is empty"
[[ "$(pub generated-fields --owner 1 2>/dev/null | grep -c '^FIELD retentionCount ')" == "1" ]] || \
  fail "OWNER scoped read is empty"
[[ "$(pub generated-fields --instance nopeX 2>&1 | grep -c 'unknown_instance')" == "1" ]] || fail "unknown instance not refused"
[[ "$(pub generated-fields --owner 999999 2>&1 | grep -c 'unknown_owner')" == "1" ]] || fail "unknown owner not refused"
log "step6 scoped_reads instance=ok owner=ok unknown_refused"

# --- step7: external owner write updates BOTH presentations ---------------
DV="$(field_word label VERSION)"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:label --arg text=STRING:"外改甲" \
  --arg expectedDraftVersion=INTEGER:"$DV" > "$WORK/ext.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/ext.log" || fail "external owner write refused: $(awk '/^REASON /{print $2}' "$WORK/ext.log")"
sleep 1.0
[[ "$(text_of "$(field_hex label)")" == "外改甲" ]] || fail "external write did not reach the owner"
click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
sleep 0.6
[[ "$(ax_text public-detail-label)" == "外改甲" ]] || fail "public detail did not show the external write"
click_id rule-detail-tabs-tab-basic || fail "basic tab unreachable"
sleep 0.6
[[ "$(ax_text field-label)" == "外改甲" ]] || fail "handwritten field did not show the external write"
log "step7 external_write both_presentations=[外改甲]"

# --- step8: an invalid draft is refused on Apply; editing continues --------
# The owner keeps drafts editable and validates at Apply: 0 is stored, Apply
# refuses it by name, the projection then carries the validation message, and a
# corrected value applies without a restart.
VR="$(field_word retentionCount VERSION)"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:retentionCount --arg text=STRING:"0" \
  --arg expectedDraftVersion=INTEGER:"$VR" > "$WORK/invalid.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/invalid.log" || fail "invalid draft was not stored as a draft"
DV="$(field_word label VERSION)"
pub invoke "$(ver)" APPLY_DRAFT --target 1 --arg expectedDraftVersion=INTEGER:"$DV" > "$WORK/apply-invalid.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/apply-invalid.log" || fail "Apply accepted an out-of-range draft"
APPLY_REASON="$(awk '/^REASON /{print $2}' "$WORK/apply-invalid.log")"
[[ "$APPLY_REASON" == "invalid_draft" ]] || fail "unexpected Apply refusal: [$APPLY_REASON]"
# The owner's validation is visible in the SAME projections the presentations read.
ERROR_WORD="$(field_word retentionCount ERROR)"
[[ "$ERROR_WORD" == "retention_count_out_of_range" ]] || fail "owner validation not published: [$ERROR_WORD]"
sleep 0.8
click_id rule-detail-tabs-tab-publicDetail || fail "public detail tab unreachable"
sleep 0.6
PUBLIC_ERROR="$(ax_text public-detail-retentionCount-error)"
[[ "$PUBLIC_ERROR" == *"超出允许范围"* || "$PUBLIC_ERROR" == *"out_of_range"* ]] || \
  fail "public detail did not show the owner validation: [$PUBLIC_ERROR]"
# Correct the value and apply through the ordinary route.
VR="$(field_word retentionCount VERSION)"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:retentionCount --arg text=STRING:"9" \
  --arg expectedDraftVersion=INTEGER:"$VR" > "$WORK/valid.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/valid.log" || fail "corrected draft was refused"
sleep 0.6
DV="$(field_word label VERSION)"
pub invoke "$(ver)" APPLY_DRAFT --target 1 --arg expectedDraftVersion=INTEGER:"$DV" > "$WORK/apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/apply.log" || fail "Apply after the correction failed"
log "step8 invalid_apply_refused reason=[$APPLY_REASON] error_visible=[$PUBLIC_ERROR] corrected_applied"

# --- step8b: designated-object reads/writes (bound non-selected owner) -----
# Two declared instances NAME their owners (`rule<id>`); the accepted table
# binds each to its own record, so an external reader can address A while the
# human keeps B. Reading/writing A must not move B's selection, focus or draft.
cat > "$WORK/two.txt" <<'S2'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 rule1 retentionIntegerEdit
NODE 1 rule2 retentionIntegerEdit
END
S2
SV="$(pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
pub generated-submit --structure-version "$SV" --payload-file "$WORK/two.txt" > "$WORK/submit-two.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-two.log" || fail "two-instance structure not accepted"
sleep 1.0
pub invoke "$(ver)" SELECT_RECORD --target 2 > /dev/null 2>&1 || true
sleep 0.8
A_SCOPED_BEFORE="$(pub generated-fields --instance rule1 2>/dev/null)"
B_BEFORE="$(pub generated-fields 2>/dev/null)"
[[ "$(text_of "$(print -r -- "$A_SCOPED_BEFORE" | awk '/^FIELD label /{for(i=1;i<=NF;i++) if($i=="DRAFT_HEX") print $(i+1)}')")" == "外改甲" ]] || \
  fail "rule1 does not serve A's own draft"
[[ "$(text_of "$(print -r -- "$B_BEFORE" | awk '/^FIELD label /{for(i=1;i<=NF;i++) if($i=="DRAFT_HEX") print $(i+1)}')")" == "乙规则" ]] || \
  fail "selected B projection is not B"
A_VERSION="$(print -r -- "$A_SCOPED_BEFORE" | awk '/^FIELD label /{for(i=1;i<=NF;i++) if($i=="VERSION") print $(i+1)}')"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:label --arg text=STRING:"外改A" \
  --arg expectedDraftVersion=INTEGER:"$A_VERSION" > "$WORK/ext-a.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/ext-a.log" || fail "external write to A refused: $(awk '/^REASON /{print $2}' "$WORK/ext-a.log")"
sleep 0.8
B_AFTER="$(pub generated-fields 2>/dev/null)"
[[ "$B_AFTER" == "$B_BEFORE" ]] || fail "B's projection changed while A was written"
[[ "$(text_of "$(pub generated-fields --instance rule1 2>/dev/null | awk '/^FIELD label /{for(i=1;i<=NF;i++) if($i=="DRAFT_HEX") print $(i+1)}')")" == "外改A" ]] || \
  fail "A's own scoped read did not show the external write"
[[ "$(pub generated-fields --owner 1 2>/dev/null | grep -c '^FIELD label ')" == "1" ]] || fail "owner 1 read empty after write"
[[ "$(pub generated-fields --owner 2 2>/dev/null | grep -c '^FIELD label ')" == "1" ]] || fail "owner 2 read empty"
[[ "$(pub generated-fields --instance noSuchRule 2>&1 | grep -c 'unknown_instance')" == "1" ]] || fail "undeclared key not refused"
[[ "$(pub generated-fields --owner 3 2>&1 | grep -c 'unknown_owner')" == "1" ]] || fail "unbound owner not refused"
# Switching to A shows the external write in the normal projection; B keeps its
# own draft and version for when the human returns to it.
B_VERSION="$(print -r -- "$B_AFTER" | awk '/^FIELD label /{for(i=1;i<=NF;i++) if($i=="VERSION") print $(i+1)}')"
pub invoke "$(ver)" SELECT_RECORD --target 1 > /dev/null 2>&1 || true
sleep 0.6
[[ "$(text_of "$(field_hex label)")" == "外改A" ]] || fail "switching to A did not show its draft"
pub invoke "$(ver)" SELECT_RECORD --target 2 > /dev/null 2>&1 || true
sleep 0.6
[[ "$(field_word label VERSION)" == "$B_VERSION" ]] || fail "B's draft version changed across the A round trip"
log "step8b owner_scope A=[外改A] B_unchanged=[乙规则] focus_selection_version_kept"

# --- step9: a field-constraint change is one definition ------------------
# The catalog publishes the SAME declared bounds the UI and the owner enforce.
cat > "$WORK/constraint.zsh" <<'C'
C
BOUNDS="$(pub generated-capabilities 2>/dev/null | awk '/FIELD retentionCount /{print}')"
log "step9 catalog_bounds=[$BOUNDS]"
[[ -n "$BOUNDS" ]] || fail "catalog did not publish the declared field bounds"
# --- step10: changing ONE declared constraint changes UI, catalog and the
# owner's refusal together (no second copy of the rule).
cjgui_terminate_owned "${APP_PID:-}" "${DESCRIPTOR:-}" "$EXEC" "$ROUND" > /dev/null 2>&1 || true
APP_PID=""
ROUND2="$WORK/round-app-constrained"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND2" "$RUNTIME_DIR" "CJGUIRuleSet" "${TAG}C" \
  "org.cangjie.cjgui.rule-set.example" || fail "constrained copy failed"
EXEC2="$ROUND2/target/release/CJGUIRuleSet${TAG}C.app/Contents/MacOS/CJGUIRuleSet${TAG}C"
APP_BUNDLE2="$ROUND2/target/release/CJGUIRuleSet${TAG}C.app"
( cd "$ROUND2" && nohup zsh run.sh --build-only > "$WORK/build2.log" 2>&1 ) || fail "constrained build failed"
( cd "$ROUND2" && nohup zsh run.sh --retention-range 1 5 > "$WORK/app2.log" 2>&1 & )
DESCRIPTOR="$(cjgui_wait_descriptor "$WORK/app2.log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 180)" || \
  fail "constrained app published no descriptor"
APP_PID="$(pgrep -f "$EXEC2" | head -1)"
[[ -n "$APP_PID" ]] || fail "constrained app process missing"
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"受限" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:4 --arg excludedType=STRING:"-" --arg requestId=STRING:"pd-c" > "$WORK/create-c.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create-c.log" || fail "constrained record creation failed"
BOUNDS2="$(pub generated-capabilities 2>/dev/null | awk '/FIELD retentionCount /{print}')"
[[ "$BOUNDS2" == *"max=5"* ]] || fail "catalog did not follow the declared constraint: [$BOUNDS2]"
VR="$(field_word retentionCount VERSION)"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:retentionCount --arg text=STRING:"9" \
  --arg expectedDraftVersion=INTEGER:"$VR" > "$WORK/out-of-range.log" 2>&1 || true
DV="$(field_word label VERSION)"
pub invoke "$(ver)" APPLY_DRAFT --target 1 --arg expectedDraftVersion=INTEGER:"$DV" > "$WORK/apply2-invalid.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/apply2-invalid.log" || fail "owner accepted a value above the declared bound"
R2="$(awk '/^REASON /{print $2}' "$WORK/apply2-invalid.log")"
[[ "$R2" == "invalid_draft" ]] || fail "unexpected constrained refusal [$R2]"
[[ "$(field_word retentionCount ERROR)" == "retention_count_out_of_range" ]] || fail "range error not published"
VR="$(field_word retentionCount VERSION)"
pub invoke "$(ver)" EDIT_DRAFT_TEXT --target 1 --arg fieldId=STRING:retentionCount --arg text=STRING:"4" \
  --arg expectedDraftVersion=INTEGER:"$VR" > "$WORK/inside-range.log" 2>&1 || true
DV="$(field_word label VERSION)"
pub invoke "$(ver)" APPLY_DRAFT --target 1 --arg expectedDraftVersion=INTEGER:"$DV" > "$WORK/apply2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/apply2.log" || fail "inside-range value was not applied"
log "step10 constraint_change catalog=[max=5] outside_refused reason=[$R2] inside_applied"

# --- step11: a deleted owner is refused by name, never served by another -----
pub invoke "$(ver)" SELECT_RECORD --target 1 > /dev/null 2>&1 || true
sleep 0.4
pub invoke "$(ver)" DELETE_RECORD --target 1 > /dev/null 2>&1 || true
sleep 0.6
[[ "$(pub generated-fields --instance rule1 2>&1 | grep -cE 'unknown_instance|unknown_owner|empty')" == "1" ]] || \
  fail "deleted owner's instance was still served"
[[ "$(pub generated-fields --owner 1 2>&1 | grep -cE 'unknown_owner|unknown_instance|empty')" == "1" ]] || \
  fail "deleted owner was still served"
log "step11 deleted_owner_refused"

log "PASS rule_public_detail_chain"
print -r -- "chain: PASS log=$LOG"
