#!/usr/bin/env zsh
# Final export consumption: build and RUN the consumers that ship inside a
# fresh framework export whose path contains spaces, with no author-directory
# or environment override.
#
# What this proves:
#   * the exported tree builds from the export root alone (each consumer's
#     dependency paths are relative to the export, not to the author's tree);
#   * the UI-only tree consumer runs and publishes its own row projection;
#   * both runtime-generated-UI consumers answer the public capability /
#     structure / submit / field-readback entry points from that export;
#   * every instance is a per-round copy identified by its own descriptor and
#     executable path, and is reclaimed at the end of the round.
#
# Desktop-only input (real clicks/typing) is not claimed here; the interaction
# verifiers cover that separately and report their own BLOCKED state.
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
cleanup() {
  # zsh arrays are 1-based; leave no gap when no instance was registered.
  if (( ${#ROUND_PIDS} == 0 )); then
    return 0
  fi
  local index=1
  while (( index <= ${#ROUND_PIDS} )); do
    cjgui_terminate_owned "${ROUND_PIDS[index]}" "${ROUND_DESCS[index]}" "${ROUND_EXECS[index]}" \
      "${ROUND_DIRS[index]}" || true
    index=$(( index + 1 ))
  done
}
trap cleanup EXIT

# --- 1. export into the spaced path ----------------------------------------
log "step1 exporting to: $export_root"
zsh "$RUNTIME_DIR/scripts/export_framework_preview.sh" "$export_root" >> "$LOG" 2>&1 \
  || fail "export failed"
[[ -d "$export_root/framework/cjgui/src" ]] || fail "exported framework sources missing"
[[ -d "$export_root/consumers" ]] || fail "exported consumers missing"
CLIENT="$export_root/framework/cjgui/shared_operation_core/client.py"
[[ -f "$CLIENT" ]] || fail "exported client missing"
log "step1 export_ok root_has_spaces=true client_source=export cleared_overrides='${CLEARED_OVERRIDES:-none}'"

# The export must really be THIS source: every exported framework source file is
# compared with the author copy, and the combined fingerprint is recorded.
EXPORTED_SOURCE_COUNT=0
for file in "$export_root"/framework/cjgui/src/*.cj; do
  base="$(basename "$file")"
  [[ -f "$RUNTIME_DIR/src/$base" ]] || fail "exported source $base has no author original"
  cmp -s "$file" "$RUNTIME_DIR/src/$base" || fail "exported $base differs from the author source"
  EXPORTED_SOURCE_COUNT=$(( EXPORTED_SOURCE_COUNT + 1 ))
done
for file in "$export_root"/framework/cjgui/native/cjgui_internal_renderer.m; do
  base="$(basename "$file")"
  cmp -s "$file" "$RUNTIME_DIR/native/$base" || fail "exported native $base differs from the author source"
  EXPORTED_SOURCE_COUNT=$(( EXPORTED_SOURCE_COUNT + 1 ))
done
for file in "$export_root"/framework/cjgui/shared_operation_core/src/*.cj; do
  base="$(basename "$file")"
  cmp -s "$file" "$RUNTIME_DIR/shared_operation_core/src/$base" ||     fail "exported shared-core $base differs from the author source"
  EXPORTED_SOURCE_COUNT=$(( EXPORTED_SOURCE_COUNT + 1 ))
done
[[ "$EXPORTED_SOURCE_COUNT" -gt 0 ]] || fail "no exported sources were compared"
EXPORT_FINGERPRINT="$(cat "$export_root"/framework/cjgui/src/*.cj "$export_root"/framework/cjgui/native/cjgui_internal_renderer.m | shasum -a 256 | awk '{print $1}')"
log "step1b source_fingerprint_match files=$EXPORTED_SOURCE_COUNT sha256=$EXPORT_FINGERPRINT"

# Every launched consumer must report origins inside the export root.
assert_export_origins() { # assert_export_origins <log> <consumer>
  local log_file="$1" consumer="$2"
  grep -q "source_origin runtime=$export_root/framework/cjgui" "$log_file" || \
    fail "$consumer did not resolve its runtime from the export root"
  grep -q "native=$export_root/framework/cjgui/native" "$log_file" || \
    fail "$consumer did not resolve native sources from the export root"
  grep -q "dependency_cjgui=$export_root/framework/cjgui" "$log_file" || \
    fail "$consumer did not resolve the cjgui package from the export root"
  if grep -q "$RUNTIME_DIR/native" "$log_file"; then
    fail "$consumer resolved native sources from the author tree"
  fi
  log "step1c origins_ok consumer=$consumer source=export no_author_path=true"
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

# --- 2. UI-only tree consumer: build + run + own projection -----------------
TREE_DIR="$(prepare_consumer tree_outline_consumer "CJGUIUiOnlyStarter" \
  "org.example.cjgui.ui-only-starter" "TreeChain${RUN_TAG}")"
TREE_EXEC_NAME="CJGUIUiOnlyStarterTreeChain${RUN_TAG}"
TREE_STDOUT="$WORK/tree-outline.log"
ROUND_STARTED="$(date +%s)"
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
[[ -n "$TREE_PID" ]] || fail "exported UI-only tree consumer did not start"
cjgui_unique_round_owns "$TREE_PID" "$TREE_EXEC_NAME" "$TREE_DIR" || fail "tree consumer pid is not this round's instance"
TREE_READY_LINE="$(grep 'TREE_OUTLINE_CONSUMER_READY' "$TREE_STDOUT" | tail -1)"
TREE_ROWS="$(print -r -- "$TREE_READY_LINE" | sed -n 's/.*rows=\([0-9]*\).*/\1/p')"
[[ -n "$TREE_ROWS" && "$TREE_ROWS" -gt 0 ]] || fail "tree consumer published no rows ($TREE_READY_LINE)"
register_round "$TREE_PID" "" "$TREE_EXEC_NAME" "$TREE_DIR"
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
# unmodified round directory.
cat > "$CHAIN_DIR/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$RUNTIME_DIR/scripts/run_macos_application.sh" "$CHAIN_DIR/cjgui_macos_app.sh" "\$@"
RUNSH
chmod +x "$CHAIN_DIR/run.sh"
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
( cd "$RULE_DIR" && nohup zsh run.sh > "$RULE_STDOUT" 2>&1 & )
RULE_DESCRIPTOR=""
waited=0
while (( waited < 200 )); do
  RULE_DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$RULE_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$RULE_DESCRIPTOR" && -f "$RULE_DESCRIPTOR" ]]; then break; fi
  sleep 2
  waited=$(( waited + 2 ))
done
[[ -f "${RULE_DESCRIPTOR:-}" ]] || fail "exported rule window did not publish a descriptor"
RULE_PID="$(cjgui_descriptor_owner_pid "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" "$ROUND_STARTED" || true)"
[[ -n "$RULE_PID" ]] || fail "exported rule window descriptor has no matching owner"
cjgui_pid_owns "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" || fail "rule window pid is not this round's instance"
register_round "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR"
rule_pub() { python3 "$CLIENT" "$RULE_DESCRIPTOR" "$@"; }
assert_export_origins "$RULE_STDOUT" rule_generated_consumer
hex_text_local() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
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
# creates and selects one through the public entry points.
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
cat > "$WORK/rule-s1.txt" <<'RS1'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greeting label
PROPERTY 1 greeting text 导出消费：编辑规则名称
NODE 1 nameField textInput field=label
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
END
RS1
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
# The generated editor writes through the operation the shared definition
# declares, and the public readback is exact - not a substring.
RULE_EDIT_TEXT="导出消费编辑"
RULE_DRAFT_VERSION="$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
rule_pub invoke "$RULE_DRAFT_VERSION" EDIT_DRAFT_TEXT --target "$RULE_RECORD_ID" \
  --arg fieldId=STRING:label --arg text=STRING:"$RULE_EDIT_TEXT" --arg expectedDraftVersion=INTEGER:0 \
  > "$WORK/rule-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-edit.log" || fail "exported rule generated editor write was rejected"
[[ "$(rule_field_token label DRAFT_HEX | hex_text_local)" == "$RULE_EDIT_TEXT" ]] || \
  fail "exported rule generated editor draft read-back mismatch"
# Same key, different position: the accepted editor keeps its identity and the
# still-pending draft continues through it (the draft version advances per edit,
# so the reorder must not reset it).
cat > "$WORK/rule-s2.txt" <<'RS2'
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
NODE 1 greeting label
PROPERTY 1 greeting text 导出消费：重排后继续编辑
NODE 1 nameField textInput field=label
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
RULE_EDIT2_TEXT="导出消费编辑二"
RULE_DRAFT2_VERSION="$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
RULE_FIELD_VERSION2="$(rule_draft_version)"
log "diag rule_edit2_expected_draft=$RULE_FIELD_VERSION2"
rule_pub invoke "$RULE_DRAFT2_VERSION" EDIT_DRAFT_TEXT --target "$RULE_RECORD_ID" \
  --arg fieldId=STRING:label --arg text=STRING:"$RULE_EDIT2_TEXT" \
  --arg expectedDraftVersion=INTEGER:"$RULE_FIELD_VERSION2" > "$WORK/rule-edit2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-edit2.log" || fail "exported rule editor stopped accepting input after the reorder"
[[ "$(rule_field_token label DRAFT_HEX | hex_text_local)" == "$RULE_EDIT2_TEXT" ]] || \
  fail "exported rule draft read-back after the reorder mismatch"

# The continued draft then applies through the same owner operation, and the
# applied value is read back exactly.
RULE_APPLY_VERSION="$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
RULE_FIELD_VERSION3="$(rule_draft_version)"
log "diag rule_apply_expected_draft=$RULE_FIELD_VERSION3"
rule_pub invoke "$RULE_APPLY_VERSION" APPLY_DRAFT --target "$RULE_RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$RULE_FIELD_VERSION3" > "$WORK/rule-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-apply.log" || fail "exported rule generated editor apply was rejected"
[[ "$(rule_field_token label APPLIED_HEX | hex_text_local)" == "$RULE_EDIT2_TEXT" ]] || \
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
[[ "$(rule_field_token label DRAFT_HEX | hex_text_local)" == "$RULE_EDIT2_TEXT" ]] || \
  fail "exported rule editors stopped being readable after a rejected candidate"
log "step3 exported_rule_generated_chain_ok version=$RULE_VERSION s2=$RULE_VERSION2 edit_readback=true rejected_candidate_kept_old=true"

# --- 4. second generated consumer: public capability/structure/submit -------
PANEL_DIR="$(prepare_consumer generated_panel_consumer "CJGUICollaborationStarter" \
  "org.example.cjgui.collaboration-starter" "Export${RUN_TAG}")"
PANEL_EXEC="$PANEL_DIR/target/release/CJGUICollaborationStarterExport${RUN_TAG}.app/Contents/MacOS/CJGUICollaborationStarterExport${RUN_TAG}"
PANEL_STDOUT="$WORK/panel.log"
( cd "$PANEL_DIR" && nohup zsh run.sh > "$PANEL_STDOUT" 2>&1 & )
PANEL_DESCRIPTOR=""
waited=0
while (( waited < 200 )); do
  PANEL_DESCRIPTOR="$(grep 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' "$PANEL_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$PANEL_DESCRIPTOR" && -f "$PANEL_DESCRIPTOR" ]]; then break; fi
  sleep 2
  waited=$(( waited + 2 ))
done
[[ -f "${PANEL_DESCRIPTOR:-}" ]] || fail "exported second consumer did not publish a descriptor"
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
# The generated text editor writes through this consumer's own owner operation
# (SET_TITLE) and the public readback is the complete value.
PANEL_TEXT="导出消费标题"
PANEL_DOMAIN_VERSION="$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
panel_pub invoke "$PANEL_DOMAIN_VERSION" SET_TITLE --target 8101 --arg title=STRING:"$PANEL_TEXT" \
  > "$WORK/panel-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/panel-edit.log" || fail "exported second consumer generated editor write was rejected"
[[ "$(panel_field_token title APPLIED_HEX | hex_text_local)" == "$PANEL_TEXT" ]] || \
  fail "exported second consumer title read-back mismatch"

# Same key in a different position: the editors keep working.
cat > "$WORK/panel-s2.txt" <<'PS2'
GENERATED_UI_STRUCTURE 1
NODE 0 board horizontal
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
END
PS2
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
PANEL_TEXT2="导出消费标题二"
PANEL_DOMAIN_VERSION2="$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
panel_pub invoke "$PANEL_DOMAIN_VERSION2" SET_TITLE --target 8101 --arg title=STRING:"$PANEL_TEXT2" \
  > "$WORK/panel-edit2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/panel-edit2.log" || fail "exported second consumer owner stopped accepting writes after the reorder"
[[ "$(panel_field_token title APPLIED_HEX | hex_text_local)" == "$PANEL_TEXT2" ]] || \
  fail "exported second consumer read-back after the reorder mismatch"
# The boolean editor's field is readable through the same projection.
[[ "$(panel_field_token marked APPLIED_HEX | hex_text_local)" != "" ]] || \
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
[[ "$(panel_field_token title APPLIED_HEX | hex_text_local)" == "$PANEL_TEXT2" ]] || \
  fail "exported second consumer editors stopped being readable after a rejected candidate"
log "step4 exported_second_generated_chain_ok version=$PANEL_VERSION s2=$PANEL_VERSION2 edit_readback=true rejected_candidate_kept_old=true"

log "PASSED exported consumer chains root='$export_root'"
cat "$LOG"
exit 0
