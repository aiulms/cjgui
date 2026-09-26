#!/usr/bin/env zsh

# E: the FINAL export is consumed from a path that contains SPACES, and the
# EXPORTED consumers really use THIS package's new capabilities:
#
#   * the UI-only tree consumer resolves a named style, a shared image
#     declaration (logical key + exact version) and the window interaction
#     context from the export alone;
#   * the generated second consumer publishes the new dynamic-availability
#     answer (AVAILABLE / REASON_HEX / TARGET / STATE_VERSION), the style
#     directory revision plus its SNAPSHOT_STYLE section, the named style and
#     image declaration in discovery, and the three-fact interaction projection
#     (WINDOW_FOCUS_STATE / WINDOW_FOCUS);
#   * the THIRD consumer (rule domain) builds its application-local native cache
#     from the export and its own suite passes against the EXPORTED framework, so
#     all three consumers are exercised from the export root without a session.
#
# It also re-checks the export fingerprint, that the round copies' dependency
# paths resolve INSIDE the export root, and that the launched processes report
# their runtime/native/dependency/resource origins from the export root (never
# the author checkout).
#
# Usage: verify_exported_new_capabilities.sh [export-root]
#   default: the newest "$CJGUI_PREVIEW_CHAIN_TMPDIR"/cjgui preview */export
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPOSITORY_DIR="$(cd "$RUNTIME_DIR/../.." && pwd)"
EXPORT_PARENT="${CJGUI_PREVIEW_CHAIN_TMPDIR:-/private/tmp/cjgui-preview-chains}"

export_root="${1:-}"
if [[ -z "$export_root" ]]; then
  export_root="$(print -r -- "$EXPORT_PARENT"/cjgui\ preview\ */export(Nom[1]) 2>/dev/null || true)"
fi
if [[ -z "$export_root" || ! -d "$export_root/framework/cjgui/src" ]]; then
  print -u2 "FAIL no export root to consume (pass one explicitly)"
  exit 1
fi
# The deliberate space is what proves the exported package graph never depends
# on shell word splitting.
case "$export_root" in
  *" "*) ;;
  *) print -u2 "FAIL export root does not contain a space: '$export_root'"; exit 1 ;;
esac

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
# The per-round copies keep the SAME nesting depth the preview chain uses: the
# generated round copies rewrite dependency paths relative to themselves, and a
# very deep temporary parent produced escaping paths cjpm cannot resolve.
WORK="${CJGUI_EXPORTED_NEW_CAPABILITIES_TMPDIR:-$EXPORT_PARENT/cjgui preview newcaps $RUN_TAG}"
mkdir -p "$WORK"
FRAMEWORK_FOR_RUN="$export_root/framework/cjgui"
CLIENT="$FRAMEWORK_FOR_RUN/shared_operation_core/client.py"
LOG="$WORK/exported-new-capabilities.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
say() { print -r -- "$*"; log "$*"; }
fail() {
  print -u2 "FAIL $*"
  tail -60 "$LOG" >&2 || true
  exit 1
}

[[ -f "$CLIENT" ]] || fail "the export root does not ship the public client"
[[ -d "$export_root/consumers/tree_outline_consumer" ]] || fail "exported tree consumer missing"
[[ -d "$export_root/consumers/generated_panel_consumer" ]] || fail "exported second consumer missing"

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

TREE_PID=""
PANEL_PID=""
TREE_DIR=""
PANEL_DIR=""
TREE_EXEC=""
PANEL_EXEC=""
TREE_EXEC_NAME=""
PANEL_EXEC_NAME=""
cleanup() {
  if [[ -n "$TREE_EXEC_NAME" && -n "$TREE_DIR" ]]; then
    local tree_now
    tree_now="$(cjgui_unique_round_pid "$TREE_EXEC_NAME" "$TREE_DIR" 2>/dev/null || true)"
    if [[ -n "$tree_now" ]]; then
      cjgui_terminate_owned "$tree_now" "" "$TREE_EXEC_NAME" "$TREE_DIR" || true
    fi
  fi
  if [[ -n "$PANEL_DIR" ]]; then
    local panel_now
    panel_now="$(cjgui_unique_round_pid "$PANEL_EXEC_NAME" "$PANEL_DIR" 2>/dev/null || true)"
    if [[ -n "$panel_now" ]]; then
      cjgui_terminate_owned "$panel_now" "${PANEL_DESCRIPTOR:-}" "$PANEL_EXEC_NAME" "$PANEL_DIR" || true
    fi
  fi
}
trap cleanup EXIT HUP INT TERM

# --- export fingerprint (same checker the export is written with) -----------
FINGERPRINT_REPORT="$(python3 "$SCRIPT_DIR/export_fingerprint.py" \
  "$export_root" "$RUNTIME_DIR" "$REPOSITORY_DIR")" || fail "export fingerprint check failed"
FINGERPRINT_SUMMARY="$(print -r -- "$FINGERPRINT_REPORT" | head -1)"
FINGERPRINT="$(print -r -- "$FINGERPRINT_SUMMARY" | sed -n 's/.*sha256=\([0-9a-f]*\).*/\1/p')"
EXPORTED_FILES="$(print -r -- "$FINGERPRINT_SUMMARY" | sed -n 's/^files=\([0-9]*\).*/\1/p')"
[[ -n "$FINGERPRINT" && -n "$EXPORTED_FILES" ]] || fail "export fingerprint produced no summary"
log "step1 export_fingerprint root_has_spaces=true files=$EXPORTED_FILES sha256=$FINGERPRINT"

assert_export_origins() { # assert_export_origins <stdout-log> <process-name>
  local log_file="$1" name="$2"
  local runtime_origin="$export_root/framework/cjgui"
  local native_origin="$export_root/framework/cjgui/native"
  local resource_origin="$export_root/framework/cjgui/resources/"
  [[ -f "$log_file" ]] || fail "$name has no stdout log"
  grep -qF "source_origin runtime=$runtime_origin native=$native_origin" "$log_file" \
    || fail "$name did not resolve its runtime/native origin inside the export root"
  grep -qF "resource_origin=$resource_origin" "$log_file" \
    || fail "$name did not resolve resources inside the export root"
  if grep -E 'source_origin|resource_origin' "$log_file" | grep -qF "$RUNTIME_DIR"; then
    fail "$name resolved an origin from the author checkout"
  fi
  log "origin_ok process=$name runtime=$runtime_origin resources=$resource_origin"
}

assert_deps_inside_export() { # assert_deps_inside_export <round-dir> <name>
  local dir="$1" name="$2"
  python3 - "$dir/cjpm.toml" "$export_root" "$name" <<'PYDEPS' || fail "$name has a dependency path outside the export root"
import os, re, sys
toml_path, export_root, name = sys.argv[1:4]
text = open(toml_path, encoding="utf-8").read()
section = ""
paths = []
for line in text.splitlines():
    stripped = line.strip()
    if stripped.startswith("["):
        section = stripped
    if section == "[dependencies]":
        paths += re.findall(r'path = "([^"]+)"', line)
root = os.path.realpath(export_root)
for rel in paths:
    resolved = os.path.realpath(os.path.join(os.path.dirname(toml_path), rel))
    if not (resolved == root or resolved.startswith(root + os.sep)):
        print(f"dependency {rel} -> {resolved} escapes the export root", file=sys.stderr)
        sys.exit(1)
print(f"{name} dependency_paths={len(paths)} all_inside_export=true")
PYDEPS
}

# --- 2. the EXPORTED UI-only consumer uses the shared definitions ----------
TREE_DIR="$WORK/tree-round"
cjgui_prepare_app_copy "$export_root/consumers/tree_outline_consumer" "$TREE_DIR" \
  "$FRAMEWORK_FOR_RUN" "CJGUIUiOnlyStarter" "ExportCaps${RUN_TAG}" "org.example.cjgui.ui-only-starter" \
  || fail "per-round copy of the exported tree consumer failed"
TREE_EXEC_NAME="CJGUIUiOnlyStarterExportCaps${RUN_TAG}"
TREE_EXEC="$TREE_DIR/target/release/${TREE_EXEC_NAME}.app/Contents/MacOS/${TREE_EXEC_NAME}"
TREE_LOG="$WORK/tree.log"
( cd "$TREE_DIR" && nohup zsh run.sh > "$TREE_LOG" 2>&1 & )
waited=0
while (( waited < 420 )); do
  TREE_PID="$(cjgui_unique_round_pid "$TREE_EXEC_NAME" "$TREE_DIR" 2>/dev/null || true)"
  if [[ -n "$TREE_PID" ]] && grep -q 'TREE_OUTLINE_CONSUMER_READY' "$TREE_LOG" 2>/dev/null; then
    break
  fi
  sleep 2
  waited=$(( waited + 2 ))
done
[[ -n "$TREE_PID" ]] || fail "the exported UI-only consumer did not start (log=$TREE_LOG)"
cjgui_unique_round_owns "$TREE_PID" "$TREE_EXEC_NAME" "$TREE_DIR" \
  || fail "the tree consumer pid is not this round's instance"
TREE_READY="$(grep 'TREE_OUTLINE_CONSUMER_READY' "$TREE_LOG" | tail -1)"
[[ "$TREE_READY" == *"style="* && "$TREE_READY" == *"image="* && "$TREE_READY" == *"focus="* ]] \
  || fail "the exported UI-only consumer did not consume style/image/interaction context: $TREE_READY"
assert_export_origins "$TREE_LOG" exported_ui_only_tree_consumer
log "step2 exported_ui_only_ok $TREE_READY"
cjgui_terminate_owned "$TREE_PID" "" "$TREE_EXEC_NAME" "$TREE_DIR" || true
stopped=0
for _ in {1..20}; do
  if ! cjgui_unique_round_pid "$TREE_EXEC_NAME" "$TREE_DIR" >/dev/null 2>&1; then
    stopped=1
    break
  fi
  sleep 0.3
done
(( stopped == 1 )) || fail "the exported UI-only consumer did not stop after its exact-identity reclaim"
TREE_PID=""
TREE_DIR=""
log "step2b ui_only_reclaimed pid_absent=true"

# --- 3. the EXPORTED generated consumer publishes the new capabilities ------
PANEL_DIR="$WORK/panel-round"
cjgui_prepare_app_copy "$export_root/consumers/generated_panel_consumer" "$PANEL_DIR" \
  "$FRAMEWORK_FOR_RUN" "CJGUICollaborationStarter" "ExportCaps${RUN_TAG}" \
  "org.example.cjgui.collaboration-starter" \
  || fail "per-round copy of the exported second consumer failed"
assert_deps_inside_export "$PANEL_DIR" exported_second_consumer
PANEL_EXEC_NAME="CJGUICollaborationStarterExportCaps${RUN_TAG}"
PANEL_EXEC="$PANEL_DIR/target/release/${PANEL_EXEC_NAME}.app/Contents/MacOS/${PANEL_EXEC_NAME}"
PANEL_LOG="$WORK/panel.log"
( cd "$PANEL_DIR" && nohup zsh run.sh > "$PANEL_LOG" 2>&1 & )
PANEL_DESCRIPTOR="$(cjgui_wait_descriptor "$PANEL_LOG" 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' 420 || true)"
[[ -n "$PANEL_DESCRIPTOR" && -f "$PANEL_DESCRIPTOR" ]] || fail "the exported second consumer published no descriptor"
PANEL_PID="$(cjgui_descriptor_owner_pid "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" || true)"
[[ -n "$PANEL_PID" ]] || fail "the exported second consumer descriptor has no matching owner"
cjgui_pid_owns "$PANEL_PID" "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" \
  || fail "the exported second consumer pid is not this round's instance"
assert_export_origins "$PANEL_LOG" exported_generated_second_consumer
log "step3 exported_generated_consumer_started pid=$PANEL_PID"

pub() { python3 "$CLIENT" "$PANEL_DESCRIPTOR" "$@"; }

pub generated-capabilities > "$WORK/capabilities.txt" 2>&1 || true
grep -q '^STYLE collaboration_primary_action ' "$WORK/capabilities.txt" \
  || fail "the exported consumer does not publish a named style"
grep -q '^IMAGE_RESOURCE collaboration-beacon ' "$WORK/capabilities.txt" \
  || fail "the exported consumer does not publish its image declaration"

pub generated-snapshot > "$WORK/snapshot.txt" 2>&1 || true
grep -q '^STYLE_REVISION ' "$WORK/snapshot.txt" \
  || fail "the exported snapshot has no STYLE_REVISION"
grep -q '^SNAPSHOT_STYLE ' "$WORK/snapshot.txt" \
  || fail "the exported snapshot ships no SNAPSHOT_STYLE section"
log "step3a exported_style_revision $(grep -m1 '^STYLE_REVISION ' "$WORK/snapshot.txt") snapshot_style=$(grep -c '^SNAPSHOT_STYLE ' "$WORK/snapshot.txt")"

pub generated-fields > "$WORK/fields.txt" 2>&1 || true
grep -q 'AVAILABLE ' "$WORK/fields.txt" || fail "the exported field read publishes no AVAILABLE"
grep -q 'STATE_VERSION ' "$WORK/fields.txt" || fail "the exported field read publishes no STATE_VERSION"
AVAILABILITY_LINE="$(grep -m1 'AVAILABLE ' "$WORK/fields.txt")"
log "step3b exported_availability_ok ${AVAILABILITY_LINE%%DRAFT_HEX*}"
log "step3b exported_availability_targets $(grep -c 'STATE_VERSION ' "$WORK/fields.txt")"

pub window-interaction > "$WORK/interaction.txt" 2>&1 || true
grep -q '^WINDOW_FOCUS_STATE ' "$WORK/interaction.txt" \
  || fail "the exported interaction read publishes no WINDOW_FOCUS_STATE"
grep -q '^WINDOW_FOCUS ' "$WORK/interaction.txt" \
  || fail "the exported interaction read publishes no WINDOW_FOCUS"
grep -q '^WINDOW_SOURCE window_interaction_projection' "$WORK/interaction.txt" \
  || fail "the exported interaction read does not name its accepted-scene projection source"
log "step3c exported_interaction_ok $(grep -m1 '^WINDOW_FOCUS_STATE ' "$WORK/interaction.txt") $(grep -m1 '^WINDOW_FOCUS ' "$WORK/interaction.txt")"

# --- 3d. B3: the RUNNING exported app consumes the two-page workspace --------
# A PUBLIC client (not a probe) submits the "任务"/"备注" workspace description and
# the exported application must accept it and address BOTH pages through the
# public instance read. This is the task-domain counterpart of the rule window's
# real page switch, and it needs no desktop input: it exercises the accepted
# structure and the declared page identities.
pub generated-structure > "$WORK/workspace-before.txt" 2>&1 || true
PANEL_STRUCTURE_VERSION="$(awk '/^STRUCTURE_VERSION /{print $2}' "$WORK/workspace-before.txt" | tail -1)"
[[ "$PANEL_STRUCTURE_VERSION" == <-> ]] \
  || fail "the exported consumer published no numeric structure version"
cat > "$WORK/task-workspace.structure" <<'TASKWS'
GENERATED_UI_STRUCTURE 1
NODE 0 board tabs
PROPERTY 0 board initialPage task
NODE 1 taskPage tabPage
PROPERTY 1 taskPage pageKey task
PROPERTY 1 taskPage pageTitle 任务
NODE 2 titleEditor textInput field=title
PROPERTY 2 titleEditor label 任务标题编辑
NODE 1 notesPage tabPage
PROPERTY 1 notesPage pageKey notes
PROPERTY 1 notesPage pageTitle 备注
NODE 2 notesEditor textInput field=notes
PROPERTY 2 notesEditor label 任务备注编辑
END
TASKWS
pub generated-submit --structure-version "$PANEL_STRUCTURE_VERSION" \
  --payload-file "$WORK/task-workspace.structure" > "$WORK/workspace-submit.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/workspace-submit.txt" \
  || fail "the exported consumer refused the two-page workspace candidate ($(grep -m1 '^REASON ' "$WORK/workspace-submit.txt" || true))"
pub generated-instances > "$WORK/workspace-instances.txt" 2>&1 || true
grep -q '^INSTANCE titleEditor .*field=title' "$WORK/workspace-instances.txt" \
  || fail "the exported consumer did not address the task page's editor after accepting the workspace"
# The HIDDEN page keeps its identity in the accepted structure but is not
# materialized as a control: being hidden must not make it addressable, and it
# must not be dropped from the structure either.
if grep -q '^INSTANCE notesEditor ' "$WORK/workspace-instances.txt"; then
  fail "the hidden notes page was materialized as an addressable control"
fi
grep -q '^SCENE_STATE scene_accepted' "$WORK/workspace-instances.txt" \
  || fail "the exported consumer did not accept the workspace scene"
pub generated-structure > "$WORK/workspace-after.txt" 2>&1 || true
grep -q '^STRUCTURE_VERSION 1' "$WORK/workspace-after.txt" \
  || fail "the accepted workspace structure did not advance to version 1"
grep -q 'board tabs' "$WORK/workspace-after.txt" \
  || fail "the accepted structure does not carry the public tab container"
grep -q 'pageKey task' "$WORK/workspace-after.txt" && grep -q 'pageKey notes' "$WORK/workspace-after.txt" \
  || fail "the accepted structure does not carry both workspace pages"
log "step3d exported_task_workspace_ok version=$PANEL_STRUCTURE_VERSION->1 container=tabs pages=task,notes active_editor=titleEditor hidden_editor_not_materialized=true instances=$(grep -c '^INSTANCE ' "$WORK/workspace-instances.txt") client=public_descriptor"

# --- 4. the THIRD exported consumer builds and consumes from the export alone -
# The rule-domain window is the third exported consumer and the desktop chain is
# the only script that used to touch it, so its export self-sufficiency was never
# checked without a session. Its OWN suite runs in-process windows and exercises
# the public tab workspace, scroll and tree/split paths through the EXPORTED
# framework, so it needs no desktop input. What is pinned here: the copy is
# self-sufficient from the export (every dependency resolves INSIDE the export
# root, never the author checkout) and its suite passes against the exported
# framework.
RULE_DIR="$WORK/rule_set_window_app"
cjgui_prepare_app_copy "$export_root/consumers/rule_set_window_app" "$RULE_DIR" \
  "$FRAMEWORK_FOR_RUN" "CJGUIRuleSet" "Exported${RUN_TAG}" "org.cangjie.cjgui.rule-set.example" \
  || fail "the exported rule consumer could not be prepared from the export root"
RULE_DEP_REPORT="$(python3 - "$RULE_DIR" "$export_root" "$REPOSITORY_DIR" <<'PYRULE'
import os
import sys

dest, export_root, repository = (os.path.realpath(p) for p in sys.argv[1:4])
paths = []
section = ""
for line in open(f"{dest}/cjpm.toml"):
    stripped = line.strip()
    if stripped.startswith("["):
        section = stripped
    if section == "[dependencies]" and 'path = "' in stripped:
        rel = stripped.split('path = "', 1)[1].rsplit('"', 1)[0]
        paths.append(os.path.realpath(os.path.join(dest, rel)))
if not paths:
    print("no dependency paths")
    sys.exit(1)
for real in paths:
    if not (real == export_root or real.startswith(export_root + os.sep)):
        print(f"dependency escapes the export root: {real}")
        sys.exit(1)
    if real == repository or real.startswith(repository + os.sep):
        print(f"dependency resolves to the author checkout: {real}")
        sys.exit(1)
print(f"dependency_paths={len(paths)} all_inside_export=true")
PYRULE
)" || fail "an exported rule dependency does not resolve inside the export root"
RULE_TEST_LOG="$WORK/rule-set-consumer-tests.log"
# The consumer's [ffi.c] names the APPLICATION-local native cache, which the
# framework runner populates. Build that cache from the export with the runner's
# own `--build-only` mode (clang + ar, no launch, no desktop) before the suite.
( cd "$RULE_DIR" && zsh ./run.sh --build-only ) > "$WORK/rule-set-consumer-native.log" 2>&1 \
  || fail "the exported rule consumer could not build its native cache from the export root ($(tail -4 "$WORK/rule-set-consumer-native.log" | tr '\n' ' '))"
[[ -f "$RULE_DIR/.cjgui/native/lib/libcjgui_internal_renderer.a" &&
   -f "$RULE_DIR/.cjgui/native/lib/libcjgui_macos_application_launcher.a" ]] \
  || fail "the exported rule consumer's native cache was not populated inside its copy"
( cd "$RULE_DIR" && cjpm test -j 4 ) > "$RULE_TEST_LOG" 2>&1 \
  || fail "the exported rule consumer's own suite did not pass from the export root ($(tail -4 "$RULE_TEST_LOG" | tr '\n' ' '))"
grep -q 'cjpm test success' "$RULE_TEST_LOG" \
  || fail "the exported rule consumer's suite did not report success"
RULE_TOTAL="$(sed -n 's/^Summary: TOTAL: \([0-9][0-9]*\)$/\1/p' "$RULE_TEST_LOG" | tail -1)"
[[ "$RULE_TOTAL" == <-> ]] \
  || fail "the exported rule consumer published no test summary"
log "step4 exported_rule_consumer_offline_ok tests=$RULE_TOTAL $RULE_DEP_REPORT desktop_input=none"

say "PASSED exported new capabilities root='$export_root' files=$EXPORTED_FILES sha256=$FINGERPRINT"
cat "$LOG"
exit 0
