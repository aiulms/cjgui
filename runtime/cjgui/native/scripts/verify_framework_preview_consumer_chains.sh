#!/usr/bin/env zsh
# Final export consumption: build and RUN the consumers that ship inside a
# fresh framework export whose path contains spaces, with no author-directory
# or environment override.
#
# What this proves:
#   * the exported tree builds from the export root alone (each consumer's
#     dependency paths are relative to the export, not to the author's tree);
#   * EVERY process that participates - the UI-only tree consumer, the derived
#     per-round tree-interaction copy, the rule generated consumer and the
#     second generated consumer - resolves its runtime, native sources,
#     dependencies and resources inside the export root, and never falls back
#     to the author checkout;
#   * both runtime-generated-UI consumers answer the public capability /
#     structure / submit / field-readback entry points from that export;
#   * the generated editors of both consumers are driven by the same REAL
#     desktop input driver the interaction verifiers use (posted click / typed
#     Unicode / boolean press), parameterized to the exported instance, and the
#     effect is read back exactly through the public owner projection;
#   * every instance is a per-round copy identified by its own descriptor and
#     executable path, and is reclaimed at the end of the round.
#
# Public invoke is still used for the EXTERNAL actions (record create/select,
# APPLY_DRAFT, SET_TITLE/SET_MARKED when the desktop input itself is blocked)
# and for exact read-backs; it is not accepted as evidence for the generated
# control input segments.
#
# Desktop input is bounded. If the session is locked, the driver cannot be
# built, or posted input is not delivered, the affected segment is reported
# BLOCKED with the measured condition and the script exits 3 - the origin and
# structure guarantees above are still verified headlessly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLIENT=""  # resolved from the export root once it exists
EXPORT_PARENT="${CJGUI_PREVIEW_CHAIN_TMPDIR:-/private/tmp/cjgui-preview-chains}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
# The export path deliberately contains spaces: the exported package graph must
# not depend on shell word splitting.
WORK="$EXPORT_PARENT/cjgui preview ${RUN_TAG}"
# The export root is parameterized (default keeps the deliberate space) so the
# same chain can be pointed at any export without editing the script.
export_root="${CJGUI_FRAMEWORK_PREVIEW_EXPORT_ROOT:-$WORK/export}"
mkdir -p "$WORK"
# Author-directory source overrides are cleared explicitly before anything is
# exported or launched: the exported tree must be consumed from its own sources,
# never silently fall back to the author checkout.
CLEARED_OVERRIDES=""
for name in CJGUI_NATIVE_SOURCE_DIR CJGUI_FRAMEWORK_SOURCE_DIR CJGUI_PREVIEW_SOURCE_DIR; do
  if [[ -n "${(P)name:-}" ]]; then
    CLEARED_OVERRIDES="${CLEARED_OVERRIDES}${name}=${(P)name} "
    unset "$name"
  fi
done
export CLEARED_OVERRIDES
LOG="$WORK/chains.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

typeset -a ROUND_PIDS ROUND_DIRS ROUND_EXECS ROUND_DESCS
# Candidate identity is recorded BEFORE each launch: a process that starts but
# dies/answers the ready+ownership handshake incorrectly would otherwise never
# reach register_round and leak. Cleanup re-resolves the PID from this identity
# (exec path/name + this round's directory) and re-proves ownership before
# signalling - never a generic pkill and never a user instance.
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
register_candidate() { # register_candidate <exec-path-or-name> <round-dir> [descriptor]
  CANDIDATE_EXECS+=("$1"); CANDIDATE_DIRS+=("$2"); CANDIDATE_DESCS+=("${3:-}")
}
cleanup() {
  # zsh arrays are 1-based; leave no gap when no instance was registered.
  if (( ${#ROUND_PIDS} > 0 )); then
    local index=1
    while (( index <= ${#ROUND_PIDS} )); do
      cjgui_terminate_owned "${ROUND_PIDS[index]}" "${ROUND_DESCS[index]}" "${ROUND_EXECS[index]}" \
        "${ROUND_DIRS[index]}" || true
      index=$(( index + 1 ))
    done
  fi
  # Reclaim anything that started but never reached the ready/ownership
  # handshake, from the identity registered before launch. The shared helper is
  # the same code the pre-registration negative control exercises.
  cjgui_reclaim_candidates log
}
trap cleanup EXIT

# --- 1. export into the spaced path ----------------------------------------
# A caller that already produced (and completed) this export root can reuse it
# instead of re-exporting; the byte-identity comparison below still proves the
# reused root carries THIS author source, so a stale root cannot pass.
if [[ "${CJGUI_PREVIEW_CHAIN_REUSE_EXPORT:-0}" == "1" ]]; then
  log "step1 export_reused=true root='$export_root' reason=CJGUI_PREVIEW_CHAIN_REUSE_EXPORT"
else
  log "step1 exporting to: $export_root"
  zsh "$RUNTIME_DIR/scripts/export_framework_preview.sh" "$export_root" >> "$LOG" 2>&1 \
    || fail "export failed"
fi
[[ -d "$export_root/framework/cjgui/src" ]] || fail "exported framework sources missing"
[[ -d "$export_root/consumers" ]] || fail "exported consumers missing"
CLIENT="$export_root/framework/cjgui/shared_operation_core/client.py"
[[ -f "$CLIENT" ]] || fail "exported client missing"
log "step1 export_ok root_has_spaces=true client_source=export cleared_overrides='${CLEARED_OVERRIDES:-none}'"

# The export must really be THIS source. ONE explicit list (shared with the
# fast, GUI-free check `verify_export_fingerprint.sh`) drives the per-file
# comparison, the per-file hash and the aggregate fingerprint, so the recorded
# file count is exactly the number of hashed inputs and no subset can be reported
# as "the whole SDK fingerprint".
REPOSITORY_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"
EXPORT_FINGERPRINT_REPORT="$(python3 "$SCRIPT_DIR/export_fingerprint.py" \
  "$export_root" "$RUNTIME_DIR" "$REPOSITORY_ROOT")" || fail "export source fingerprint check failed"
EXPORT_FINGERPRINT_SUMMARY="$(print -r -- "$EXPORT_FINGERPRINT_REPORT" | head -1)"
EXPORTED_SOURCE_COUNT="$(print -r -- "$EXPORT_FINGERPRINT_SUMMARY" | sed -n 's/^files=\([0-9]*\).*/\1/p')"
EXPORT_FINGERPRINT="$(print -r -- "$EXPORT_FINGERPRINT_SUMMARY" | sed -n 's/.*sha256=\([0-9a-f]*\).*/\1/p')"
[[ -n "$EXPORTED_SOURCE_COUNT" && "$EXPORTED_SOURCE_COUNT" -gt 0 ]] || fail "no exported sources were compared"
# The per-file hash lines are evidence, not noise: the aggregate above is
# computed from exactly these inputs.
print -r -- "$EXPORT_FINGERPRINT_REPORT" | tail -n +2 >> "$LOG"
log "step1b source_fingerprint_match $EXPORT_FINGERPRINT_SUMMARY"

# Every launched process must report origins inside the export root. The check
# is per process, covers runtime/native/dependencies/resources, and records one
# evidence line so a reader can see which process resolved which origin.
assert_export_origins() { # assert_export_origins <stdout-log> <process-name>
  local log_file="$1" name="$2"
  local runtime_origin="$export_root/framework/cjgui"
  local native_origin="$export_root/framework/cjgui/native"
  local dep_origin="$export_root/framework/cjgui"
  local core_origin="$export_root/framework/cjgui/shared_operation_core"
  local resource_origin="$export_root/framework/cjgui/resources/"
  [[ -f "$log_file" ]] || fail "$name has no stdout log ($log_file)"
  grep -qF "source_origin runtime=$runtime_origin native=$native_origin dependency_cjgui=$dep_origin dependency_core=$core_origin" "$log_file" \
    || fail "$name did not resolve runtime/native/dependency origins inside the export root"
  grep -qF "resource_origin=$resource_origin" "$log_file" \
    || fail "$name did not resolve resources inside the export root"
  # No process in this acceptance may resolve anything from the author checkout.
  if [[ "$export_root" != "$RUNTIME_DIR"* ]] && \
     grep -E 'source_origin|resource_origin' "$log_file" | grep -qF "$RUNTIME_DIR"; then
    fail "$name resolved an origin from the author tree ($RUNTIME_DIR)"
  fi
  log "origin_ok process=$name runtime=$runtime_origin native=$native_origin deps=$dep_origin resources=$resource_origin"
}

FRAMEWORK_FOR_RUN="$export_root/framework/cjgui"

# --- helpers ---------------------------------------------------------------
prepare_consumer() { # prepare_consumer <name> <name-token> <bundle-token> <suffix>
  local name="$1" token="$2" bundle="$3" suffix="$4"
  local src="$export_root/consumers/$name" dir="$WORK/$name-round"
  [[ -d "$src" ]] || fail "exported consumer $name missing"
  cjgui_prepare_app_copy "$src" "$dir" "$FRAMEWORK_FOR_RUN" "$token" "$suffix" "$bundle" \
    || fail "per-round copy of $name failed"
  print -r -- "$dir"
}

# Every instance this round starts is registered so the single exit trap can
# reclaim exactly those processes (identity re-checked per instance).
register_round() { # register_round <pid> <descriptor> <exec> <dir>
  ROUND_PIDS+=("$1"); ROUND_DESCS+=("$2"); ROUND_EXECS+=("$3"); ROUND_DIRS+=("$4")
}

# --- real desktop input into the EXPORTED generated controls ----------------
# The driver build, the AX frame walk and the bounded type/owner-readback loop
# now live in lib_cjgui_desktop_input.sh, so this script and the
# common-definition acceptance exercise the SAME implementation instead of two
# drifting copies. AX_PID selects the round process and CLIENT is the exported
# public client, so no author-runtime seam is introduced.
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

prepare_desktop_driver || true

# A per-round consumer build that fails to compile is reported as such instead
# of as "did not start": a concurrent source change can land a file the export
# whitelist does not copy yet, and the compiler error inside the exported tree
# is the actionable evidence.
build_failure_hint() { # build_failure_hint <stdout-log>
  grep -qE 'failed to compile package|Error: cjpm build failed|cjpm did not publish executable' "$1" 2>/dev/null
}

# --- 2. UI-only tree consumer: build + run + own projection -----------------
TREE_DIR="$(prepare_consumer tree_outline_consumer "CJGUIUiOnlyStarter" \
  "org.example.cjgui.ui-only-starter" "TreeChain${RUN_TAG}")"
TREE_EXEC_NAME="CJGUIUiOnlyStarterTreeChain${RUN_TAG}"
TREE_STDOUT="$WORK/tree-outline.log"
ROUND_STARTED="$(date +%s)"
register_candidate "$TREE_EXEC_NAME" "$TREE_DIR"  # no descriptor: identity is the round-unique exec name + dir
( cd "$TREE_DIR" && nohup zsh run.sh > "$TREE_STDOUT" 2>&1 & )
TREE_PID=""
waited=0
while (( waited < 200 )); do
  TREE_PID="$(cjgui_unique_round_pid "$TREE_EXEC_NAME" "$TREE_DIR" || true)"
  if [[ -n "$TREE_PID" ]] && grep -q 'TREE_OUTLINE_CONSUMER_READY' "$TREE_STDOUT" 2>/dev/null; then
    break
  fi
  sleep 2
  waited=$(( waited + 2 ))
done
if [[ -z "$TREE_PID" ]]; then
  if build_failure_hint "$TREE_STDOUT"; then
    tail -8 "$TREE_STDOUT" >> "$LOG" 2>/dev/null || true
    fail "exported UI-only tree consumer did not build (exported tree does not compile)"
  fi
  fail "exported UI-only tree consumer did not start"
fi
cjgui_unique_round_owns "$TREE_PID" "$TREE_EXEC_NAME" "$TREE_DIR" || fail "tree consumer pid is not this round's instance"
TREE_READY_LINE="$(grep 'TREE_OUTLINE_CONSUMER_READY' "$TREE_STDOUT" | tail -1)"
TREE_ROWS="$(print -r -- "$TREE_READY_LINE" | sed -n 's/.*rows=\([0-9]*\).*/\1/p')"
[[ -n "$TREE_ROWS" && "$TREE_ROWS" -gt 0 ]] || fail "tree consumer published no rows ($TREE_READY_LINE)"
register_round "$TREE_PID" "" "$TREE_EXEC_NAME" "$TREE_DIR"
assert_export_origins "$TREE_STDOUT" ui_only_tree_consumer
log "step2 ui_only_tree_consumer_started pid=$TREE_PID rows=$TREE_ROWS source=export"

# --- 2b. the exported UI-only tree actually navigates ---------------------
# The exported consumer ships its controller, so this round adds a driver in the
# SAME package (the application entry is renamed so there is exactly one main)
# and drives expansion, keyboard navigation, Shift ranges, select-all and
# collapse/expand through the controller's real event entry.
CHAIN_DIR="$WORK/tree-interaction-round"
cp -R "$TREE_DIR" "$CHAIN_DIR"
rm -rf "$CHAIN_DIR/target" "$CHAIN_DIR/.cjgui"
python3 - "$CHAIN_DIR" "$RUNTIME_DIR" <<'PYCHAIN'
import os
import shutil
import sys
round_dir, runtime = sys.argv[1:3]
main_path = os.path.join(round_dir, "src", "main.cj")
text = open(main_path, encoding="utf-8").read()
# The consumer's entry is declared without the `func` keyword, so the rename
# has to add it: a bare `consumerAppMain(): Int64` is not a declaration.
assert "main(): Int64 {" in text
assert "func main(): Int64 {" not in text
text = text.replace("main(): Int64 {", "func consumerAppMain(): Int64 {", 1)
open(main_path, "w", encoding="utf-8").write(text)
shutil.copy(os.path.join(runtime, "examples", "tree_outline_consumer", "export_check",
                         "export_interaction_check.cj"),
            os.path.join(round_dir, "src", "export_interaction_check.cj"))
PYCHAIN
CHAIN_EXEC_NAME="CJGUIUiOnlyStarterChain${RUN_TAG}"
python3 - "$CHAIN_DIR" "$RUN_TAG" <<'PYCHAIN2'
import os
import sys
round_dir, tag = sys.argv[1:3]
launcher = os.path.join(round_dir, "cjgui_macos_app.sh")
text = open(launcher, encoding="utf-8").read()
text = text.replace("CJGUIUiOnlyStarter", "CJGUIUiOnlyStarterChain" + tag)
text = text.replace("org.example.cjgui.ui-only-starter", "org.example.cjgui.ui-only-starter.chain." + tag)
open(launcher, "w", encoding="utf-8").write(text)
PYCHAIN2
CHAIN_EXEC="$CHAIN_DIR/target/release/${CHAIN_EXEC_NAME}.app/Contents/MacOS/${CHAIN_EXEC_NAME}"
CHAIN_LOG="$WORK/tree-interaction.log"
# The per-round launcher hardcodes the directory it was created for, so this
# copy gets its own launcher instead of inheriting one that points back at the
# unmodified round directory. It must launch through the EXPORT root's own
# framework scripts: the author path here made the derived navigation copy
# resolve runtime/native/resources from the author checkout even though its
# dependencies pointed at the export.
cat > "$CHAIN_DIR/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$FRAMEWORK_FOR_RUN/scripts/run_macos_application.sh" "$CHAIN_DIR/cjgui_macos_app.sh" "\$@"
RUNSH
chmod +x "$CHAIN_DIR/run.sh"
register_candidate "$CHAIN_EXEC" "$CHAIN_DIR"  # derived navigation copy, same identity rule
( cd "$CHAIN_DIR" && nohup zsh "$CHAIN_DIR/run.sh" > "$CHAIN_LOG" 2>&1 & )
CHAIN_PID=""
waited=0
while (( waited < 180 )); do
  # The driver prints its last line and exits, so completion is the marker; the
  # identity is only needed while the instance is still alive.
  if grep -q 'EXPORT_TREE_CHAIN window ' "$CHAIN_LOG" 2>/dev/null; then break; fi
  if [[ -z "$CHAIN_PID" ]]; then
    CHAIN_PID="$(cjgui_unique_round_pid "$CHAIN_EXEC_NAME" "$CHAIN_DIR" || true)"
    # Register as soon as the instance is identified: a chain that fails before
    # its completion marker must still leave nothing running.
    if [[ -n "$CHAIN_PID" ]]; then
      register_round "$CHAIN_PID" "" "$CHAIN_EXEC" "$CHAIN_DIR"
    fi
  fi
  sleep 2
  waited=$(( waited + 2 ))
done
if ! grep -q 'EXPORT_TREE_CHAIN window ' "$CHAIN_LOG" 2>/dev/null; then
  tail -20 "$CHAIN_LOG" >> "$LOG" 2>/dev/null || true
  fail "exported UI-only tree interaction chain did not complete"
fi
assert_export_origins "$CHAIN_LOG" tree_interaction_derived_copy
grep -q '^EXPORT_TREE_CHAIN ready rows=2' "$CHAIN_LOG" || fail "exported tree did not start collapsed with 2 rows"
grep -q '^EXPORT_TREE_CHAIN expanded .* rows=14' "$CHAIN_LOG" || fail "exported tree did not expand to 14 rows"
grep -qE '^EXPORT_TREE_CHAIN down focus=[^ ]+ anchor=[^ ]* keys= rows=14 selected=0' "$CHAIN_LOG" || \
  fail "exported tree keyboard down did not move the focus without selecting"
grep -qE '^EXPORT_TREE_CHAIN shift_down focus=[^ ]+ anchor=[^ ]+ keys=[^ ]+, rows=14 selected=2' "$CHAIN_LOG" || \
  fail "exported tree Shift+Down did not extend a two-row range with exact keys"
grep -q '^EXPORT_TREE_CHAIN select_all .*keys=.* rows=14 selected=8' "$CHAIN_LOG" || \
  fail "exported tree select-all did not select every selectable row with exact keys"
grep -q '^EXPORT_TREE_CHAIN collapse rows_expanded=14 rows_collapsed=8 rows_reexpanded=14' "$CHAIN_LOG" || \
  fail "exported tree left/right did not collapse and expand the focused group"
grep -q 'EXPORT_TREE_CHAIN window .*failure=none' "$CHAIN_LOG" || \
  fail "exported tree window reported a native failure"
log "step2b ui_only_tree_interaction_ok focus_shift_range=true select_all=8 collapse_expand=true"

# --- 3. rule generated consumer: public capability/structure/submit ---------
RULE_DIR="$(prepare_consumer rule_set_window_app "CJGUIRuleSet" \
  "org.cangjie.cjgui.rule-set.example" "Export${RUN_TAG}")"
RULE_EXEC="$RULE_DIR/target/release/CJGUIRuleSetExport${RUN_TAG}.app/Contents/MacOS/CJGUIRuleSetExport${RUN_TAG}"
RULE_STDOUT="$WORK/rule-window.log"
register_candidate "$RULE_EXEC" "$RULE_DIR"  # descriptor is recorded after the handshake
( cd "$RULE_DIR" && nohup zsh run.sh > "$RULE_STDOUT" 2>&1 & )
RULE_DESCRIPTOR=""
waited=0
while (( waited < 200 )); do
  RULE_DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$RULE_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$RULE_DESCRIPTOR" && -f "$RULE_DESCRIPTOR" ]]; then break; fi
  sleep 2
  waited=$(( waited + 2 ))
done
if [[ ! -f "${RULE_DESCRIPTOR:-}" ]]; then
  if build_failure_hint "$RULE_STDOUT"; then
    tail -8 "$RULE_STDOUT" >> "$LOG" 2>/dev/null || true
    fail "exported rule window did not build (exported tree does not compile)"
  fi
  fail "exported rule window did not publish a descriptor"
fi
RULE_PID="$(cjgui_descriptor_owner_pid "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" "$ROUND_STARTED" || true)"
[[ -n "$RULE_PID" ]] || fail "exported rule window descriptor has no matching owner"
cjgui_pid_owns "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" || fail "rule window pid is not this round's instance"
register_round "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR"
rule_pub() { python3 "$CLIENT" "$RULE_DESCRIPTOR" "$@"; }
assert_export_origins "$RULE_STDOUT" rule_generated_consumer
rule_field_token() { # rule_field_token <fieldId> <TOKEN>
  local attempt=0 line value
  # Bounded retry: a read issued while the window commits a refresh can come
  # back empty, and an empty draft version would be sent as 0.
  while (( attempt < 12 )); do
    line="$(rule_pub generated-fields 2>/dev/null | grep "^FIELD $1 " | head -1 || true)"
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
rule_draft_version() { rule_field_token label VERSION; }
# The generated editors bind to the selected record, so the export chain first
# creates and selects one through the public entry points. These are EXTERNAL
# actions; the control edits below are real desktop input.
rule_pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"导出消费记录" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"export-rule-1" \
  > "$WORK/rule-create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-create.log" || fail "exported rule consumer could not create a record"
RULE_RECORD_ID="$(rule_pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2; exit}')"
[[ -n "$RULE_RECORD_ID" ]] || fail "exported rule consumer did not publish the created record id"
rule_pub invoke 1 SELECT_RECORD --target "$RULE_RECORD_ID" > "$WORK/rule-select.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-select.log" || fail "exported rule consumer could not select the record"
log "step2d exported_rule_record_ok id=$RULE_RECORD_ID"
rule_pub generated-capabilities > "$WORK/rule-capabilities.txt" 2>&1 || true
grep -q '^KIND GENERATED_UI_CAPABILITIES' "$WORK/rule-capabilities.txt" \
  || fail "exported rule consumer did not answer the capability query"
grep -q '^FIELD label' "$WORK/rule-capabilities.txt" || fail "exported rule catalog missing the shared field"
# S1 through the public submit entry: declares the generated text editor and the
# generated boolean editor with their accessibility labels so the real desktop
# driver can reach them.
# The declared retention maximum comes from the same capability payload the
# external query already reads; the composite's preset caption is its OWN
# declared property, so the real click below is unambiguous.
RULE_RETENTION_MAX="$(rule_pub generated-capabilities 2>/dev/null \
  | grep -m1 '^FIELD retentionCount ' | sed -n 's/.* max=\([0-9]*\).*/\1/p')"
[[ -n "$RULE_RETENTION_MAX" ]] || fail "rule consumer did not publish the retention bound"
cat > "$WORK/rule-s1.txt" <<RS1
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greeting label
PROPERTY 1 greeting text 导出消费：编辑规则名称
NODE 1 nameField textInput field=label
PROPERTY 1 nameField label 规则名称编辑
NODE 1 enabledEditor booleanInput field=enabled
PROPERTY 1 enabledEditor label 启用状态编辑
NODE 1 retentionEdit retentionIntegerEdit
PROPERTY 1 retentionEdit presetLabel 导出预设${RULE_RETENTION_MAX}
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
END
RS1
# The public capability query must publish the application's own composite kind.
rule_pub generated-capabilities 2>/dev/null | grep -q '^COMPONENT retentionIntegerEdit ' \
  || fail "the exported rule consumer did not publish the composite kind"
log "step3cap rule_composite_published kind=retentionIntegerEdit retention_max=$RULE_RETENTION_MAX"
rule_pub generated-submit --structure-version 0 --payload-file "$WORK/rule-s1.txt" > "$WORK/rule-submit.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/rule-submit.txt" || fail "exported rule consumer rejected the candidate"
waited=0
RULE_VERSION=""
while (( waited < 40 )); do
  RULE_VERSION="$(rule_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  [[ "$RULE_VERSION" == "1" ]] && break
  sleep 0.5
  waited=$(( waited + 1 ))
done
[[ "$RULE_VERSION" == "1" ]] || fail "exported rule consumer never scene-accepted the structure"
rule_pub generated-structure 2>/dev/null | grep -q 'NODE 1 nameField textInput field=label' \
  || fail "exported rule consumer accepted structure missing the field binding"
rule_pub generated-fields 2>/dev/null | grep -q '^FIELD label ' || fail "exported rule consumer field readback missing"
rule_pub generated-structure 2>/dev/null | grep -q 'NODE 1 retentionEdit retentionIntegerEdit' \
  || fail "exported rule consumer accepted structure missing the composite instance"

# --- 3a. REAL generated-control input #1 (text) -----------------------------
AX_PID="$RULE_PID"
RULE_TEXT_ONE="export-rule-edit-one"
RULE_INPUT_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_text_one "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_ONE"; then
    log "step3a rule_control_text_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RULE_TEXT_ONE' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_generated_text_input_not_delivered"
    RULE_INPUT_FALLBACK="public_invoke"
    log "BLOCKED rule_generated_text_edit reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$RULE_TEXT_ONE' focus='$(window_focus_for "$RULE_DESCRIPTOR")'"
  fi
else
  RULE_INPUT_FALLBACK="public_invoke"
  log "note rule_generated_text_edit skipped input_blocked=$INPUT_BLOCKED fallback=$RULE_INPUT_FALLBACK"
fi
if [[ -n "$RULE_INPUT_FALLBACK" ]]; then
  # The EXTERNAL edit keeps the rest of the round's semantics verifiable; it is
  # recorded as a fallback and never replaces the control-input evidence.
  rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
    --target "$RULE_RECORD_ID" --arg fieldId=STRING:label --arg text=STRING:"$RULE_TEXT_ONE" \
    --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-edit-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/rule-edit-fallback.log" || fail "exported rule public fallback edit was rejected"
  log "note rule_text_edit_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(rule_field_token label DRAFT_HEX | hex_to_text)" == "$RULE_TEXT_ONE" ]] || \
  fail "exported rule draft read-back mismatch after the control edit"

# --- 3b. REAL generated-control input #1 (boolean toggle) -------------------
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_boolean_toggle rule_bool_one "$RULE_DESCRIPTOR" enabled "启用状态编辑" checkbox; then
    assert_boolean_flip "rule generated boolean"
    log "step3b rule_control_boolean_toggle mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_generated_boolean_input_not_delivered"
    log "BLOCKED rule_generated_boolean_toggle reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_BOOLEAN \
    --target "$RULE_RECORD_ID" --arg fieldId=STRING:enabled --arg value=BOOLEAN:false \
    --arg expectedDraftVersion=INTEGER:"$(rule_field_token enabled VERSION)" > "$WORK/rule-bool-fallback.log" 2>&1 || true
  log "note rule_boolean_edit_fallback=public_invoke control_input_unverified=true"
fi

# --- 3e/3f. the APPLICATION COMPOSITE participates in the real chain ---------
# The composite instance was submitted through the public structure channel and
# is now edited with real desktop input, exactly like a built-in editor.
RULE_COMPOSITE_TEXT="45"
RULE_COMPOSITE_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_composite_retention "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "$RULE_COMPOSITE_TEXT"; then
    log "step3e rule_composite_integer_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RULE_COMPOSITE_TEXT' kind=retentionIntegerEdit input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_composite_integer_input_not_delivered"
    RULE_COMPOSITE_FALLBACK="public_invoke"
    log "FAIL_CANDIDATE rule_composite_integer_edit reason=not_delivered before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  RULE_COMPOSITE_FALLBACK="public_invoke"
  log "note rule_composite_integer_edit skipped input_blocked=$INPUT_BLOCKED"
fi
if [[ -n "$RULE_COMPOSITE_FALLBACK" ]]; then
  rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
    --target "$RULE_RECORD_ID" --arg fieldId=STRING:retentionCount --arg text=STRING:"$RULE_COMPOSITE_TEXT" \
    --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-composite-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/rule-composite-fallback.log" || fail "exported rule composite fallback edit was rejected"
  log "note rule_composite_integer_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "$RULE_COMPOSITE_TEXT" ]] || \
  fail "the composite editor did not write the shared retention draft"

# A real press on the composite's own preset button: it resolves to the same
# field edit with the DECLARED constant, so the value comes from the app's one
# configuration rather than from a duplicated limit in this script.
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_ax_press_button "$RULE_PID" "导出预设${RULE_RETENTION_MAX}"; then
    log "step3f rule_composite_preset_click label='导出预设${RULE_RETENTION_MAX}' target=$RULE_RETENTION_MAX input=real_desktop_control driver=ax"
  else
    INPUT_BLOCKED="rule_composite_preset_not_delivered"
    log "FAIL_CANDIDATE rule_composite_preset_click label='导出预设${RULE_RETENTION_MAX}'"
  fi
fi
[[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "$RULE_RETENTION_MAX" ]] || \
  fail "the composite preset press did not write the declared maximum"
# The declared maximum is inside the declared range, so the owner applies it.
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" APPLY_DRAFT --target "$RULE_RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-composite-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-composite-apply.log" || fail "the composite preset draft was not applied"
[[ "$(rule_field_token retentionCount APPLIED_HEX | hex_to_text)" == "$RULE_RETENTION_MAX" ]] || \
  fail "the applied composite preset value mismatch"
log "step3ef rule_composite_chain_ok kind=retentionIntegerEdit typed=$RULE_COMPOSITE_TEXT preset=$RULE_RETENTION_MAX applied=true"

# Same key, different position: the accepted editors keep their identity and the
# still-pending draft continues through them.
cat > "$WORK/rule-s2.txt" <<RS2
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionEdit retentionIntegerEdit
PROPERTY 1 retentionEdit presetLabel 导出预设${RULE_RETENTION_MAX}
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
NODE 1 enabledEditor booleanInput field=enabled
PROPERTY 1 enabledEditor label 启用状态编辑
NODE 1 greeting label
PROPERTY 1 greeting text 导出消费：重排后继续编辑
NODE 1 nameField textInput field=label
PROPERTY 1 nameField label 规则名称编辑
END
RS2
rule_pub generated-submit --structure-version "$RULE_VERSION" --payload-file "$WORK/rule-s2.txt" > "$WORK/rule-submit2.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/rule-submit2.txt" || fail "exported rule consumer rejected the reordered structure"
waited=0
while (( waited < 40 )); do
  RULE_VERSION2="$(rule_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  [[ "$RULE_VERSION2" == "2" ]] && break
  sleep 0.5
  waited=$(( waited + 1 ))
done
[[ "${RULE_VERSION2:-}" == "2" ]] || fail "exported rule consumer never scene-accepted the reordered structure"

# --- 3c. REAL generated-control input #2 (continue editing after S2) --------
RULE_TEXT_TWO="export-rule-edit-two"
RULE_INPUT_FALLBACK2=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_text_two "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_TWO"; then
    log "step3c rule_control_text_edit_after_s2 mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RULE_TEXT_TWO' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_generated_text_input_not_delivered_after_s2"
    RULE_INPUT_FALLBACK2="public_invoke"
    log "BLOCKED rule_generated_text_edit_after_s2 reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$RULE_TEXT_TWO'"
  fi
else
  RULE_INPUT_FALLBACK2="public_invoke"
  log "note rule_generated_text_edit_after_s2 skipped input_blocked=$INPUT_BLOCKED fallback=$RULE_INPUT_FALLBACK2"
fi
if [[ -n "$RULE_INPUT_FALLBACK2" ]]; then
  rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
    --target "$RULE_RECORD_ID" --arg fieldId=STRING:label --arg text=STRING:"$RULE_TEXT_TWO" \
    --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-edit2-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/rule-edit2-fallback.log" || fail "exported rule public fallback edit after S2 was rejected"
  log "note rule_text_edit_after_s2_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(rule_field_token label DRAFT_HEX | hex_to_text)" == "$RULE_TEXT_TWO" ]] || \
  fail "exported rule draft read-back after the reorder mismatch"

# The composite instance survived the reorder with its identity: a real edit
# through it still writes the shared field.
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_composite_after_s2 "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "50"; then
    log "step3g rule_composite_after_reorder mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_composite_after_s2_not_delivered"
    log "FAIL_CANDIDATE rule_composite_after_reorder"
  fi
fi
[[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "50" ]] || \
  fail "the composite editor stopped working after the reorder"

# The continued draft then applies through the same owner operation (EXTERNAL
# action), and the applied value is read back exactly.
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" APPLY_DRAFT --target "$RULE_RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-apply.log" || fail "exported rule generated editor apply was rejected"
[[ "$(rule_field_token label APPLIED_HEX | hex_to_text)" == "$RULE_TEXT_TWO" ]] || \
  fail "exported rule applied value read-back mismatch"

# An illegal candidate keeps the accepted structure and its editors usable.
cat > "$WORK/rule-illegal.txt" <<'RIL'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 dup textInput field=label
NODE 1 dup textInput field=label
END
RIL
rule_pub generated-submit --structure-version "$RULE_VERSION2" --payload-file "$WORK/rule-illegal.txt" > "$WORK/rule-illegal.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED false' "$WORK/rule-illegal.log" || fail "exported rule consumer accepted an illegal candidate"
[[ "$(rule_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')" == "2" ]] || \
  fail "exported rule consumer changed its accepted structure after a rejected candidate"
[[ "$(rule_field_token label DRAFT_HEX | hex_to_text)" == "$RULE_TEXT_TWO" ]] || \
  fail "exported rule editors stopped being readable after a rejected candidate"

# --- 3d. REAL generated-control input #3: the OLD interface is operating ----
RULE_TEXT_THREE="export-rule-edit-three"
RULE_INPUT_FALLBACK3=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_text_three "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_THREE"; then
    log "step3d rule_control_text_edit_after_rejection mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RULE_TEXT_THREE' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_generated_text_input_not_delivered_after_rejection"
    RULE_INPUT_FALLBACK3="public_invoke"
    log "BLOCKED rule_generated_text_edit_after_rejection reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$RULE_TEXT_THREE'"
  fi
else
  RULE_INPUT_FALLBACK3="public_invoke"
  log "note rule_generated_text_edit_after_rejection skipped input_blocked=$INPUT_BLOCKED fallback=$RULE_INPUT_FALLBACK3"
fi
if [[ -n "$RULE_INPUT_FALLBACK3" ]]; then
  rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
    --target "$RULE_RECORD_ID" --arg fieldId=STRING:label --arg text=STRING:"$RULE_TEXT_THREE" \
    --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-edit3-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/rule-edit3-fallback.log" || fail "exported rule public fallback edit after rejection was rejected"
  log "note rule_text_edit_after_rejection_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(rule_field_token label DRAFT_HEX | hex_to_text)" == "$RULE_TEXT_THREE" ]] || \
  fail "exported rule old interface was not operable after the rejected candidate"

# The OLD composite interface is still operable after the rejected candidate.
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_composite_after_reject "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "55"; then
    log "step3h rule_composite_after_rejection mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_composite_after_rejection_not_delivered"
    log "FAIL_CANDIDATE rule_composite_after_rejection"
  fi
fi
[[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "55" ]] || \
  fail "the composite editor stopped being operable after a rejected candidate"
if [[ -n "$RULE_INPUT_FALLBACK" || -n "$RULE_INPUT_FALLBACK2" || -n "$RULE_INPUT_FALLBACK3" ]]; then
  log "step3 exported_rule_generated_chain_ok version=$RULE_VERSION s2=$RULE_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=blocked"
else
  log "step3 exported_rule_generated_chain_ok version=$RULE_VERSION s2=$RULE_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=real_desktop"
fi

# --- 4. second generated consumer: public capability/structure/submit -------
PANEL_DIR="$(prepare_consumer generated_panel_consumer "CJGUICollaborationStarter" \
  "org.example.cjgui.collaboration-starter" "Export${RUN_TAG}")"
PANEL_EXEC="$PANEL_DIR/target/release/CJGUICollaborationStarterExport${RUN_TAG}.app/Contents/MacOS/CJGUICollaborationStarterExport${RUN_TAG}"
PANEL_STDOUT="$WORK/panel.log"
register_candidate "$PANEL_EXEC" "$PANEL_DIR"  # descriptor is recorded after the handshake
( cd "$PANEL_DIR" && nohup zsh run.sh > "$PANEL_STDOUT" 2>&1 & )
PANEL_DESCRIPTOR=""
waited=0
while (( waited < 200 )); do
  PANEL_DESCRIPTOR="$(grep 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' "$PANEL_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$PANEL_DESCRIPTOR" && -f "$PANEL_DESCRIPTOR" ]]; then break; fi
  sleep 2
  waited=$(( waited + 2 ))
done
if [[ ! -f "${PANEL_DESCRIPTOR:-}" ]]; then
  if build_failure_hint "$PANEL_STDOUT"; then
    tail -8 "$PANEL_STDOUT" >> "$LOG" 2>/dev/null || true
    fail "exported second consumer did not build (exported tree does not compile)"
  fi
  fail "exported second consumer did not publish a descriptor"
fi
PANEL_PID="$(cjgui_descriptor_owner_pid "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" "$ROUND_STARTED" || true)"
[[ -n "$PANEL_PID" ]] || fail "exported second consumer descriptor has no matching owner"
cjgui_pid_owns "$PANEL_PID" "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" || fail "second consumer pid is not this round's instance"
register_round "$PANEL_PID" "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR"
panel_pub() { python3 "$CLIENT" "$PANEL_DESCRIPTOR" "$@"; }
assert_export_origins "$PANEL_STDOUT" second_generated_consumer
panel_field_token() { # panel_field_token <fieldId> <TOKEN>
  panel_pub generated-fields 2>/dev/null | grep "^FIELD $1 " | head -1 |
    awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}'
}
panel_pub generated-capabilities > "$WORK/panel-capabilities.txt" 2>&1 || true
grep -q '^KIND GENERATED_UI_CAPABILITIES' "$WORK/panel-capabilities.txt" \
  || fail "exported second consumer did not answer the capability query"
grep -q '^FIELD title' "$WORK/panel-capabilities.txt" || fail "second consumer definition-derived field missing"
cat > "$WORK/panel-s1.txt" <<'PS1'
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
NODE 1 card taskEditCard
PROPERTY 1 card caption 导出任务编辑卡
NODE 1 toggleBtn action action=TOGGLE_MARKED
PROPERTY 1 toggleBtn label 切换提交状态
END
PS1
panel_pub generated-submit --structure-version 0 --payload-file "$WORK/panel-s1.txt" > "$WORK/panel-submit.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-submit.txt" || fail "exported second consumer rejected the candidate"
waited=0
PANEL_VERSION=""
while (( waited < 40 )); do
  PANEL_VERSION="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  [[ "$PANEL_VERSION" == "1" ]] && break
  sleep 0.5
  waited=$(( waited + 1 ))
done
[[ "$PANEL_VERSION" == "1" ]] || fail "exported second consumer never scene-accepted the structure"
panel_pub generated-structure 2>/dev/null | grep -q 'NODE 1 markedEditor booleanInput field=marked' \
  || fail "exported second consumer accepted structure missing the boolean editor"
panel_pub generated-fields 2>/dev/null | grep -q '^FIELD marked ' || fail "second consumer boolean field readback missing"
# The public capability query publishes the second application composite too.
panel_pub generated-capabilities 2>/dev/null | grep -q '^COMPONENT taskEditCard ' \
  || fail "the exported second consumer did not publish the composite kind"
panel_pub generated-structure 2>/dev/null | grep -q 'NODE 1 card taskEditCard' \
  || fail "the exported second consumer accepted structure missing the card"
log "step4cap panel_composite_published kind=taskEditCard"

# --- 4a. REAL generated-control input #1: type into the generated text editor
AX_PID="$PANEL_PID"
PANEL_TEXT_ONE="export-panel-title-one"
PANEL_INPUT_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_text_one "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_ONE"; then
    log "step4a panel_control_text_edit mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$PANEL_TEXT_ONE' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_generated_text_input_not_delivered"
    PANEL_INPUT_FALLBACK="public_invoke"
    log "BLOCKED panel_generated_text_edit reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$PANEL_TEXT_ONE'"
  fi
else
  PANEL_INPUT_FALLBACK="public_invoke"
  log "note panel_generated_text_edit skipped input_blocked=$INPUT_BLOCKED fallback=$PANEL_INPUT_FALLBACK"
fi
if [[ -n "$PANEL_INPUT_FALLBACK" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_TITLE --target 8101 \
    --arg title=STRING:"$PANEL_TEXT_ONE" > "$WORK/panel-edit-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/panel-edit-fallback.log" || fail "exported second consumer public fallback title write was rejected"
  log "note panel_text_edit_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(panel_field_token title APPLIED_HEX | hex_to_text)" == "$PANEL_TEXT_ONE" ]] || \
  fail "exported second consumer title read-back mismatch after the control edit"

# Same key in a different position: the editors keep working. This runs BEFORE
# the generated boolean editor marks the task submitted: the exported domain
# freezes the title once it is submitted (SET_TITLE -> title_frozen_after_submit),
# so the "continue editing" step must happen while the editor is still callable.
cat > "$WORK/panel-s2.txt" <<'PS2'
GENERATED_UI_STRUCTURE 1
NODE 0 board horizontal
NODE 1 card taskEditCard
PROPERTY 1 card caption 导出任务编辑卡
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
END
PS2
# --- 4f. REAL input through the APPLICATION COMPOSITE's own editor ----------
# The card instance came from the public structure channel; its notes editor is
# now driven with real desktop input and read back from the owner.
PANEL_CARD_NOTES="export-card-notes-one"
PANEL_CARD_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_card_notes "$PANEL_DESCRIPTOR" notes "备注" "text field" "$PANEL_CARD_NOTES"; then
    log "step4f panel_composite_notes_edit mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' kind=taskEditCard input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_composite_notes_not_delivered"
    PANEL_CARD_FALLBACK="public_invoke"
    log "FAIL_CANDIDATE panel_composite_notes_edit reason=not_delivered before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  PANEL_CARD_FALLBACK="public_invoke"
  log "note panel_composite_notes_edit skipped input_blocked=$INPUT_BLOCKED"
fi
if [[ -n "$PANEL_CARD_FALLBACK" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_NOTES --target 8101 \
    --arg notes=STRING:"$PANEL_CARD_NOTES" > "$WORK/panel-card-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/panel-card-fallback.log" || fail "exported second consumer card fallback write was rejected"
  log "note panel_composite_notes_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(panel_field_token notes APPLIED_HEX | hex_to_text)" == "$PANEL_CARD_NOTES" ]] || \
  fail "the card's notes editor did not write the owner field"
log "step4f panel_composite_chain_ok kind=taskEditCard field=notes readback=true"

panel_pub generated-submit --structure-version "$PANEL_VERSION" --payload-file "$WORK/panel-s2.txt" > "$WORK/panel-submit2.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-submit2.txt" || fail "exported second consumer rejected the reordered structure"
waited=0
while (( waited < 40 )); do
  PANEL_VERSION2="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  [[ "$PANEL_VERSION2" == "2" ]] && break
  sleep 0.5
  waited=$(( waited + 1 ))
done
[[ "${PANEL_VERSION2:-}" == "2" ]] || fail "exported second consumer never scene-accepted the reordered structure"

# --- 4b. REAL generated-control input #2: continue editing after S2 ---------
PANEL_TEXT_TWO="export-panel-title-two"
PANEL_INPUT_FALLBACK2=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_text_two "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_TWO"; then
    log "step4b panel_control_text_edit_after_s2 mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$PANEL_TEXT_TWO' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_generated_text_input_not_delivered_after_s2"
    PANEL_INPUT_FALLBACK2="public_invoke"
    log "BLOCKED panel_generated_text_edit_after_s2 reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$PANEL_TEXT_TWO'"
  fi
else
  PANEL_INPUT_FALLBACK2="public_invoke"
  log "note panel_generated_text_edit_after_s2 skipped input_blocked=$INPUT_BLOCKED fallback=$PANEL_INPUT_FALLBACK2"
fi
if [[ -n "$PANEL_INPUT_FALLBACK2" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_TITLE --target 8101 \
    --arg title=STRING:"$PANEL_TEXT_TWO" > "$WORK/panel-edit2-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/panel-edit2-fallback.log" || fail "exported second consumer public fallback title write after S2 was rejected"
  log "note panel_text_edit_after_s2_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(panel_field_token title APPLIED_HEX | hex_to_text)" == "$PANEL_TEXT_TWO" ]] || \
  fail "exported second consumer read-back after the reorder mismatch"

# --- 4c. REAL generated-control input #3: press the generated boolean editor -
# This is the same generated boolean control the task board uses to submit; the
# press must reach the owner as a real event, not as a public invoke.
PANEL_INPUT_FALLBACK3=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_boolean_toggle panel_bool_submit "$PANEL_DESCRIPTOR" marked "提交状态编辑" checkbox; then
    assert_boolean_flip "panel generated boolean"
    log "step4c panel_control_boolean_toggle mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_generated_boolean_input_not_delivered"
    PANEL_INPUT_FALLBACK3="public_invoke"
    log "BLOCKED panel_generated_boolean_toggle reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  PANEL_INPUT_FALLBACK3="public_invoke"
  log "note panel_generated_boolean_toggle skipped input_blocked=$INPUT_BLOCKED fallback=$PANEL_INPUT_FALLBACK3"
fi
if [[ -n "$PANEL_INPUT_FALLBACK3" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_MARKED --target 8101 \
    --arg marked=BOOLEAN:true > "$WORK/panel-bool-fallback.log" 2>&1 || true
  log "note panel_boolean_edit_fallback=public_invoke control_input_unverified=true"
fi
# The boolean editor's field is readable through the same projection.
[[ "$(panel_field_token marked APPLIED_HEX | hex_to_text)" != "" ]] || \
  fail "exported second consumer boolean field read-back is empty"

# An illegal candidate keeps the accepted structure and its editors usable.
cat > "$WORK/panel-illegal.txt" <<'PIL'
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 dup textInput field=title
NODE 1 dup textInput field=title
END
PIL
panel_pub generated-submit --structure-version "$PANEL_VERSION2" --payload-file "$WORK/panel-illegal.txt" > "$WORK/panel-illegal.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED false' "$WORK/panel-illegal.log" || fail "exported second consumer accepted an illegal candidate"
[[ "$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')" == "2" ]] || \
  fail "exported second consumer changed its accepted structure after a rejected candidate"
[[ "$(panel_field_token title APPLIED_HEX | hex_to_text)" == "$PANEL_TEXT_TWO" ]] || \
  fail "exported second consumer editors stopped being readable after a rejected candidate"

# --- 4d. REAL generated-control input #4: the OLD interface is operating -----
# After the rejected candidate the same generated controls still take real
# input: the boolean press un-submits (which the exported domain exposes as the
# recovery condition), and the title editor is then operable again.
PANEL_INPUT_FALLBACK4=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_boolean_toggle panel_bool_after_rejection "$PANEL_DESCRIPTOR" marked "提交状态编辑" checkbox; then
    assert_boolean_flip "panel generated boolean after rejection"
    log "step4d panel_control_boolean_after_rejection mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_generated_boolean_input_not_delivered_after_rejection"
    PANEL_INPUT_FALLBACK4="public_invoke"
    log "BLOCKED panel_generated_boolean_after_rejection reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  PANEL_INPUT_FALLBACK4="public_invoke"
  log "note panel_generated_boolean_after_rejection skipped input_blocked=$INPUT_BLOCKED fallback=$PANEL_INPUT_FALLBACK4"
fi
if [[ -n "$PANEL_INPUT_FALLBACK4" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_MARKED --target 8101 \
    --arg marked=BOOLEAN:false > "$WORK/panel-bool2-fallback.log" 2>&1 || true
  log "note panel_boolean_after_rejection_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(panel_field_token title APPLIED_HEX | hex_to_text)" == "$PANEL_TEXT_TWO" ]] || \
  fail "exported second consumer title changed while only a boolean was pressed"

PANEL_TEXT_THREE="export-panel-title-three"
PANEL_INPUT_FALLBACK5=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_text_three "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_THREE"; then
    log "step4e panel_control_text_edit_after_rejection mode='$REAL_EDIT_MODE' frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$PANEL_TEXT_THREE' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="panel_generated_text_input_not_delivered_after_rejection"
    PANEL_INPUT_FALLBACK5="public_invoke"
    log "BLOCKED panel_generated_text_edit_after_rejection reason=not_delivered before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$PANEL_TEXT_THREE'"
  fi
else
  PANEL_INPUT_FALLBACK5="public_invoke"
  log "note panel_generated_text_edit_after_rejection skipped input_blocked=$INPUT_BLOCKED fallback=$PANEL_INPUT_FALLBACK5"
fi
if [[ -n "$PANEL_INPUT_FALLBACK5" ]]; then
  panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_TITLE --target 8101 \
    --arg title=STRING:"$PANEL_TEXT_THREE" > "$WORK/panel-edit3-fallback.log" 2>&1 || true
  grep -q '^APPLIED true' "$WORK/panel-edit3-fallback.log" || fail "exported second consumer public fallback title write after rejection was rejected"
  log "note panel_text_edit_after_rejection_fallback=public_invoke control_input_unverified=true"
fi
[[ "$(panel_field_token title APPLIED_HEX | hex_to_text)" == "$PANEL_TEXT_THREE" ]] || \
  fail "exported second consumer old interface was not operable after the rejected candidate"
if [[ -n "$PANEL_INPUT_FALLBACK" || -n "$PANEL_INPUT_FALLBACK2" || -n "$PANEL_INPUT_FALLBACK3" || -n "$PANEL_INPUT_FALLBACK4" || -n "$PANEL_INPUT_FALLBACK5" ]]; then
  log "step4 exported_second_generated_chain_ok version=$PANEL_VERSION s2=$PANEL_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=blocked"
else
  log "step4 exported_second_generated_chain_ok version=$PANEL_VERSION s2=$PANEL_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=real_desktop"
fi

if [[ -n "$INPUT_BLOCKED" ]]; then
  log "BLOCKED exported_consumer_chains input_segments_unverified reason=$INPUT_BLOCKED"
  log "PASSED_HEADLESS origin_and_structure_chain root='$export_root'"
  cat "$LOG"
  exit 3
fi
log "PASSED exported consumer chains root='$export_root'"
cat "$LOG"
exit 0
