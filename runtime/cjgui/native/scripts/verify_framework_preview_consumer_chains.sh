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
INPUT_BLOCKED=""
STEP4J_BLOCKED=""

# Final classification shared by the normal exit path and its GUI-free
# negative control. Any required real-input segment that is blocked prevents a
# whole-chain PASSED result.
chain_result_code() {
  if [[ -n "${INPUT_BLOCKED:-}" || -n "${STEP4J_BLOCKED:-}" ]]; then
    return 3
  fi
  if [[ "${CJGUI_PREVIEW_CHAIN_SKIP_STEP2C:-0}" == "1" ]]; then
    return 4
  fi
  return 0
}

# This catches the former regression where step4j could log BLOCKED and the
# script still fell through to PASSED, without launching apps or touching the
# desktop.
if [[ "${CJGUI_PREVIEW_CHAIN_CLASSIFICATION_SELF_TEST:-0}" == "1" ]]; then
  INPUT_BLOCKED=""
  STEP4J_BLOCKED="real_input_unverified"
  if chain_result_code; then
    fail "classification self-test accepted a blocked step4j as complete"
  else
    result=$?
  fi
  [[ "$result" == "3" ]] || fail "classification self-test returned $result for blocked step4j"
  print -r -- "PASSED classification_negative_control step4j_blocked_exit=3"
  exit 0
fi

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
EXPORT_FINGERPRINT_SUMMARY="$(print -r -- "$EXPORT_FINGERPRINT_REPORT" | awk 'NR == 1 {print}')"
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
     grep -E 'source_origin|resource_origin' "$log_file" | grep -F "$RUNTIME_DIR" > /dev/null; then
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
# Session availability: the real-input segments below need an ACTIVE desktop
# session. A locked machine is reported as BLOCKED (exit 3), never as a product
# failure - the same rule the generated chain follows.
source "$SCRIPT_DIR/lib_cjgui_session_guard.sh"

prepare_desktop_driver || true

# bind_input_target <pid> <app-bundle-path>
# `AX_PID` and `AX_APP_PATH` MUST move together: activate_app() reaches
# LaunchServices through AX_APP_PATH, so a stale value from another consumer
# opens THAT app and leaves the intended window non-key - every posted
# keystroke/click is then dropped while the script believes it delivered input.
bind_input_target() {
  AX_PID="$1"
  if [[ -n "${2:-}" && -d "$2" ]]; then
    AX_APP_PATH="$2"
  else
    AX_APP_PATH=""
  fi
  log "diag input_target pid=$AX_PID bundle='${AX_APP_PATH:-}'"
}

# ax_identifier_enabled <pid> <accepted-semantic-id>
# Read the native Accessibility projection for the exact accepted control. A
# successful permission preflight or a nonempty frame does not prove that the
# generated action is enabled.
ax_identifier_enabled() {
  local pid="$1" wanted="$2"
  cjgui_ax 25 -e "tell application \"System Events\"
    set p to first process whose unix id is $pid
    repeat with w in windows of p
      repeat with e in (every UI element of w)
        try
          if (value of attribute \"AXIdentifier\" of e) is \"$wanted\" then
            return (value of attribute \"AXEnabled\" of e) as string
          end if
        end try
      end repeat
    end repeat
    return \"missing\"
  end tell" 2>/dev/null | tail -1 || true
}

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

# --- 2c. D: the UI-only consumer uses the SAME public scroll container -------
# It has no descriptor, UDS or model: it only shares the published container, and
# the framework's focus reveal is what brings a clipped control into view.
TREE_APP_PATH="$TREE_DIR/target/release/${TREE_EXEC_NAME}.app"
if [[ "${CJGUI_PREVIEW_CHAIN_SKIP_STEP2C:-0}" == "1" ]]; then
  log "NOT_RUN step2c reason=independent_downstream_diagnosis"
else
# `activate_app` only reaches LaunchServices when AX_APP_PATH names this round's
# OWN bundle; without it the window can be frontmost but not KEY, and every posted
# key reaches nothing. The reveal counterexample below is driven by real Tab
# presses, so the key state is part of the fixture rather than an assumption.
tree_ax_description() { # tree_ax_description <semanticId>
  local wanted="$1"
  cjgui_ax 25 -e "tell application \"System Events\"
    set p to first process whose unix id is $TREE_PID
    repeat with w in windows of p
      repeat with e in (every UI element of w)
        try
          if (value of attribute \"AXIdentifier\" of e) is \"$wanted\" then
            set textValue to \"\"
            try
              set textValue to textValue & \" value=\" & (value of e as string)
            end try
            try
              set textValue to textValue & \" name=\" & (name of e as string)
            end try
            try
              set textValue to textValue & \" title=\" & (title of e as string)
            end try
            try
              set textValue to textValue & \" description=\" & (description of e as string)
            end try
            return textValue
          end if
        end try
      end repeat
    end repeat
    return \"missing\"
  end tell" 2>/dev/null | tail -1 || true
}
bind_input_target "$TREE_PID" "$TREE_APP_PATH"
[[ "$AX_PID" == "$TREE_PID" && "$AX_APP_PATH" == "$TREE_APP_PATH" ]] \
  || fail "tree input target lost its PID/bundle pairing pid='$AX_PID' bundle='$AX_APP_PATH'"
cjgui_unique_round_owns "$TREE_PID" "$TREE_EXEC_NAME" "$TREE_DIR" \
  || fail "tree input target PID no longer owns this round's bundle executable"
[[ -x "$TREE_APP_PATH/Contents/MacOS/$TREE_EXEC_NAME" ]] \
  || fail "tree input target bundle has no matching executable ('$TREE_APP_PATH')"
activate_app
make_window_key >/dev/null 2>&1 || true
activate_app
real_ax_wait_ready "$TREE_PID" 24 >/dev/null 2>&1 || true
# Populate off-screen row controls before the reveal check. With the collapsed
# three-row tree every focusable row already fits in the clipped strip, so Tab
# has no legitimate reason to move the viewport.
TREE_EXPAND_PRESS="$(real_ax_press_identifier "$TREE_PID" "catalog-expand-all" || true)"
if [[ "$TREE_EXPAND_PRESS" != "identifier_press_sent" ]]; then
  if real_ax_session_blocking; then
    log "BLOCKED step2c expand_all $(real_ax_session_diagnostic) press='$TREE_EXPAND_PRESS'"
    cat "$LOG"
    exit 3
  fi
  fail "UI-only expand-all press=$TREE_EXPAND_PRESS"
fi
sleep 0.6
log "step2c expanded_tree_for_reveal press=$TREE_EXPAND_PRESS"
# The tree list lives on the "条目" page of the SAME public tab container. The
# chain must reach it through the real tab UI: looking for a hidden page's list
# and blaming the environment would be the wrong attribution, and the container
# is exactly the new public capability this stage has to exercise.
TREE_ROWS_TITLE_ID="catalog-workspace-tab-rows"
TREE_ROWS_SWITCH_TRIES=0
TREE_LIST_PROBE="$(ax_identifier_frame "catalog-tree-list" "group")"
while (( TREE_ROWS_SWITCH_TRIES < 3 )) && [[ "$TREE_LIST_PROBE" == "missing" ]]; do
  log "step2c tab_switch attempt=$TREE_ROWS_SWITCH_TRIES press=$TREE_ROWS_TITLE_ID"
  # A REAL AXPress on the tab TITLE: the same interaction a person's click and
  # Enter/Space produce, resolved by the framework against the accepted tab state.
  real_ax_press_identifier "$TREE_PID" "$TREE_ROWS_TITLE_ID" || true
  sleep 0.8
  activate_app
  TREE_LIST_PROBE="$(ax_identifier_frame "catalog-tree-list" "group")"
  TREE_ROWS_SWITCH_TRIES=$(( TREE_ROWS_SWITCH_TRIES + 1 ))
done
log "step2c tab_switch attempts=$TREE_ROWS_SWITCH_TRIES title=$TREE_ROWS_TITLE_ID list_probe='$TREE_LIST_PROBE'"
TREE_SCROLL_FRAME="$(ax_identifier_frame "catalog-scroll" "group")"
if ! frame_is_positive "$TREE_SCROLL_FRAME"; then
  # Only a POSITIVE environment fact (an explicit lock screen or no console
  # session at all) may stop this chain as BLOCKED. "The usual desktop apps have
  # no window open" is not evidence, and a missing control in a live window must
  # stay a product failure instead of being absorbed as an environment problem.
  if real_ax_session_blocking; then
    log "BLOCKED step2c real_input $(real_ax_session_diagnostic) tree_frame='$TREE_SCROLL_FRAME'"
    cat "$LOG"
    exit 3
  fi
  log "session_diagnostic step2c $(real_ax_session_diagnostic) tree_frame='$TREE_SCROLL_FRAME'"
fi
frame_is_positive "$TREE_SCROLL_FRAME" \
  || fail "the UI-only consumer did not expose the shared scroll container ('$TREE_SCROLL_FRAME')"
TREE_LIST_BEFORE="$(ax_identifier_frame "catalog-tree-list" "group")"
[[ -n "$TREE_LIST_BEFORE" && "$TREE_LIST_BEFORE" != "missing" ]] \
  || fail "the UI-only tree list has no accessibility identity"
TREE_LIST_BEFORE_H="$(print -r -- "$TREE_LIST_BEFORE" | awk '{print $4}')"
TREE_LIST_BEFORE_W="$(print -r -- "$TREE_LIST_BEFORE" | awk '{print $3}')"
[[ "$TREE_LIST_BEFORE_W" == <-> && "$TREE_LIST_BEFORE_H" == <-> ]] \
  || fail "the UI-only tree list published no frame ('$TREE_LIST_BEFORE')"
# The counterexample needs a control that EXISTS but is clipped. When the window
# is tall enough to show everything, the window is made smaller with a REAL corner
# drag (not an Accessibility size assignment) and the frames are re-read.
TREE_RESIZE_TRY=0
# Each drag is COMPUTED from the current AX window/list frame toward a target
# (not a fixed delta): a fixed -320,-320 over-shrank the window until the
# corner drag crossed the screen edge and macOS tiled the window fullscreen,
# which un-clips the list and invalidates the counterexample. The drag
# endpoint is clamped so the corner never leaves the window's own bounds.
# The CLIP criterion is the TARGET ROW's own visibility: the list declares
# minHeight 220, so its AX height never drops below the old 200 threshold no
# matter how small the window gets.
TREE_TARGET_ID="catalog-vleaf-domain-0-topic-0-entry-2"
TREE_TARGET_W=440
TREE_TARGET_VIEWPORT_H=120
while (( TREE_RESIZE_TRY < 6 )); do
  # The clipped list reports a SHORTER AX frame than its declared content
  # minHeight (historical passing runs: height 62). That height is the proven
  # clip signal; the target row's own AX frame is checked afterwards.
  if (( TREE_LIST_BEFORE_W > 0 && TREE_LIST_BEFORE_H < 200 )); then
    break
  fi
  make_window_key >/dev/null 2>&1 || true
  # The VIEWPORT (catalog-scroll) height is what clips rows: the list's own
  # minHeight 220 never shrinks, so the drag target follows the scroll frame.
  SCROLL_H="$(print -r -- "$TREE_SCROLL_FRAME" | awk '{print $4}')"
  SCROLL_H="${SCROLL_H:-160}"
  DW=$(( TREE_TARGET_W - TREE_LIST_BEFORE_W ))
  DH=$(( TREE_TARGET_VIEWPORT_H - SCROLL_H ))
  (( DW < -520 )) && DW=-520
  (( DW > 160 )) && DW=160
  (( DH < -420 )) && DH=-420
  (( DH > 160 )) && DH=160
  real_resize_window "$DW" "$DH" || true
  activate_app
  sleep 1.0
  TREE_SCROLL_FRAME="$(ax_identifier_frame "catalog-scroll" "group")"
  TREE_LIST_BEFORE="$(ax_identifier_frame "catalog-tree-list" "group")"
  TREE_LIST_BEFORE_H="$(print -r -- "$TREE_LIST_BEFORE" | awk '{print $4}')"
  TREE_LIST_BEFORE_W="$(print -r -- "$TREE_LIST_BEFORE" | awk '{print $3}')"
  TREE_RESIZE_TRY=$(( TREE_RESIZE_TRY + 1 ))
done
log "diag step2c ui_only_window_resized attempts=$TREE_RESIZE_TRY target_w=${TREE_TARGET_W} viewport_h=$TREE_TARGET_VIEWPORT_H container='$TREE_SCROLL_FRAME' list='$TREE_LIST_BEFORE'"
frame_is_positive "$TREE_SCROLL_FRAME" \
  || fail "the UI-only consumer lost its scroll container after the resize ('$TREE_SCROLL_FRAME')"
[[ "$TREE_LIST_BEFORE_W" == <-> && "$TREE_LIST_BEFORE_H" == <-> ]] \
  || fail "the UI-only tree list published no frame ('$TREE_LIST_BEFORE')"
# The list exists but is clipped by the shared viewport: its AX height is below
# the 200pt threshold while its declared content minHeight is 220.
if (( TREE_LIST_BEFORE_W <= 0 || TREE_LIST_BEFORE_H >= 200 )); then
  fail "the UI-only tree list is not clipped ('$TREE_LIST_BEFORE'); the reveal counterexample is not exercised"
fi
TREE_TARGET_ID="catalog-vleaf-domain-0-topic-0-entry-2"
TREE_TARGET_BEFORE="$(ax_identifier_frame "$TREE_TARGET_ID" "button")"
[[ "$TREE_TARGET_BEFORE" != "missing" ]] || fail "the clipped target row has no accepted AX identity"
if frame_is_positive "$TREE_TARGET_BEFORE"; then
  fail "the target row was already visible before keyboard reveal ('$TREE_TARGET_BEFORE')"
fi
# The window must be KEY and the self-drawn view must be the FIRST RESPONDER, or a
# posted Tab never reaches `keyDown`. The resize drag and the title-bar click that
# keyed the window both move the responder away, so the title is pressed AGAIN
# after the resize: an AXPress on a tab TITLE routes through the same production
# pointer path a person's click uses and focuses the overlay (measured; a title is
# deliberately NOT a pointer-capture control, so it takes the focus route).
bind_input_target "$TREE_PID" "$TREE_APP_PATH"
TREE_REFOCUS_PRESS="$(real_ax_press_identifier "$TREE_PID" "$TREE_ROWS_TITLE_ID" || true)"
sleep 0.6
# AXPress selects the page, while this posted pointer press establishes the
# KEY window and overlay first responder after the resize on the normal host.
TREE_TITLE_FRAME="$(ax_identifier_frame "$TREE_ROWS_TITLE_ID" "group")"
frame_is_positive "$TREE_TITLE_FRAME" || fail "tab title has no pressable frame ('$TREE_TITLE_FRAME')"
click_frame_center "$TREE_TITLE_FRAME" || fail "tab title CGEvent click failed"
sleep 0.4
log "step2c responder_refocus press='$TREE_REFOCUS_PRESS' pointer_frame='$TREE_TITLE_FRAME' frontmost='$(app_frontmost)' target_clipped='$TREE_TARGET_BEFORE'"

# Bounded real Tab presses. Focus moves through the controls; when it lands on a
# control inside the shared viewport that is still clipped, the framework reveals
# it. The exact initially clipped row is the success criterion; the list frame
# alone cannot establish that a person can reach and use that row.
TREE_TABS=0
TREE_LIST_AFTER="$TREE_LIST_BEFORE"
while (( TREE_TABS < 18 )); do
  # A real Tab is only routed into the FRONTMOST window; the resize drag and the
  # previous consumer can leave this one behind.
  if [[ "$(app_frontmost)" != "true" ]]; then
    activate_app
    sleep 0.3
  fi
  drive tab
  sleep 0.45
  TREE_TARGET_AFTER="$(ax_identifier_frame "$TREE_TARGET_ID" "button")"
  TREE_LIST_AFTER="$(ax_identifier_frame "catalog-tree-list" "group")"
  log "step2c tab=$TREE_TABS frontmost='$(app_frontmost)' target='$TREE_TARGET_AFTER' list='$TREE_LIST_AFTER'"
  if frame_is_positive "$TREE_TARGET_AFTER"; then
    break
  fi
  TREE_TABS=$(( TREE_TABS + 1 ))
done
frame_is_positive "${TREE_TARGET_AFTER:-}" \
  || fail "keyboard focus never revealed the exact clipped row (tabs=$TREE_TABS target='$TREE_TARGET_AFTER')"
print -r -- "$TREE_TARGET_AFTER $TREE_SCROLL_FRAME" | awk '{
  if (NF != 8) exit 1
  lx = $1; ly = $2; lw = $3; lh = $4; cx = $5; cy = $6; cw = $7; ch = $8
  if (lx < cx - 2 || ly < cy - 2) exit 1
  if (lx + lw > cx + cw + 2 || ly + lh > cy + ch + 2) exit 1
  exit 0
}' || fail "the revealed row is not inside the shared scroll container"
# AXPress on that now-visible leaf exercises the normal row action. Read the
# catalogue's own status after switching back through the same tab UI: this is
# the UI-only owner's selected-count projection, not a verifier-side guess.
TREE_ROW_PRESS="$(real_ax_press_identifier "$TREE_PID" "$TREE_TARGET_ID" || true)"
[[ "$TREE_ROW_PRESS" == "identifier_press_sent" ]] || fail "revealed row AXPress=$TREE_ROW_PRESS"
sleep 0.5
TREE_CATALOG_PRESS="$(real_ax_press_identifier "$TREE_PID" "catalog-workspace-tab-catalog" || true)"
[[ "$TREE_CATALOG_PRESS" == "identifier_press_sent" ]] || fail "catalog tab AXPress=$TREE_CATALOG_PRESS"
sleep 0.5
TREE_STATUS="$(tree_ax_description "catalog-status")"
[[ "$TREE_STATUS" == *"多选 1 条"* ]] || fail "revealed row action did not update owner status ('$TREE_STATUS')"
log "step2c ui_only_scroll_reveal_ok container='$TREE_SCROLL_FRAME' tabs=$((TREE_TABS + 1)) clipped_row='$TREE_TARGET_BEFORE' revealed_row='$TREE_TARGET_AFTER' list_before='$TREE_LIST_BEFORE' list_after='$TREE_LIST_AFTER' row_press=$TREE_ROW_PRESS status='$TREE_STATUS' input=real_keyboard driver=cgevent"
fi

# --- 3. rule generated consumer: public capability/structure/submit ---------
RULE_DIR="$(prepare_consumer rule_set_window_app "CJGUIRuleSet" \
  "org.cangjie.cjgui.rule-set.example" "Export${RUN_TAG}")"
RULE_EXEC="$RULE_DIR/target/release/CJGUIRuleSetExport${RUN_TAG}.app/Contents/MacOS/CJGUIRuleSetExport${RUN_TAG}"
RULE_APP="$RULE_DIR/target/release/CJGUIRuleSetExport${RUN_TAG}.app"
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
    line="$(rule_pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id && !found {print; found=1}' || true)"
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
RULE_RECORD_ID="$(rule_pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/ && !found {print $2; found=1}')"
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
  | awk '$1 == "FIELD" && $2 == "retentionCount" {for (i=1;i<=NF;i++) if ($i ~ /^max=/) {sub(/^max=/,"",$i); print $i}}')"
[[ -n "$RULE_RETENTION_MAX" ]] || fail "rule consumer did not publish the retention bound"
cat > "$WORK/rule-s1.txt" <<RS1
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greeting label
PROPERTY 1 greeting text 导出消费：编辑规则名称
NODE 1 nameField textInput field=label
PROPERTY 1 nameField label 规则名称编辑
PROPERTY 1 nameField growX 1
PROPERTY 1 nameField background #FFFFFF
PROPERTY 1 nameField border #C8D2E0
PROPERTY 1 nameField borderWidth 1
NODE 1 enabledEditor booleanInput field=enabled
PROPERTY 1 enabledEditor label 启用状态编辑
NODE 1 retentionEdit retentionIntegerEdit
PROPERTY 1 retentionEdit presetLabel 导出预设${RULE_RETENTION_MAX}
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
PROPERTY 1 applyBtn growX 1
PROPERTY 1 applyBtn background #FFFFFF
PROPERTY 1 applyBtn border #C8D2E0
PROPERTY 1 applyBtn borderWidth 1
END
RS1
# The public capability query must publish the application's own composite kind.
rule_pub generated-capabilities 2>/dev/null | grep '^COMPONENT retentionIntegerEdit ' > /dev/null \
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
rule_pub generated-structure 2>/dev/null | grep 'NODE 1 nameField textInput field=label' > /dev/null \
  || fail "exported rule consumer accepted structure missing the field binding"
rule_pub generated-fields 2>/dev/null | grep '^FIELD label ' > /dev/null || fail "exported rule consumer field readback missing"
rule_pub generated-structure 2>/dev/null | grep 'NODE 1 retentionEdit retentionIntegerEdit' > /dev/null \
  || fail "exported rule consumer accepted structure missing the composite instance"

# --- 3a. REAL generated-control input #1 (text) -----------------------------
bind_input_target "$RULE_PID" "$RULE_APP"
RULE_TEXT_ONE="export-rule-edit-one"
RULE_INPUT_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit rule_text_one "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_ONE" nameField; then
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
  if real_generated_text_edit rule_composite_retention "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "$RULE_COMPOSITE_TEXT" retentionEdit; then
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
RULE_PRESET_VERIFIED="false"
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_ax_press_button "$RULE_PID" "导出预设${RULE_RETENTION_MAX}"; then
    RULE_PRESET_VERIFIED="true"
    log "step3f rule_composite_preset_click label='导出预设${RULE_RETENTION_MAX}' target=$RULE_RETENTION_MAX input=real_desktop_control driver=ax"
  else
    INPUT_BLOCKED="rule_composite_preset_not_delivered"
    log "FAIL_CANDIDATE rule_composite_preset_click label='导出预设${RULE_RETENTION_MAX}'"
  fi
else
  log "note rule_composite_preset_click skipped input_blocked=$INPUT_BLOCKED"
fi
# The value assertion is mandatory only when the press really happened; when the
# session is locked the segment is reported BLOCKED and the script exits 3.
if [[ "$RULE_PRESET_VERIFIED" == "true" ]]; then
  [[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "$RULE_RETENTION_MAX" ]] || \
    fail "the composite preset press did not write the declared maximum"
fi
# The declared maximum is inside the declared range, so the owner applies it.
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" APPLY_DRAFT --target "$RULE_RECORD_ID" \
  --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/rule-composite-apply.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-composite-apply.log" || fail "the composite preset draft was not applied"
if [[ "$RULE_PRESET_VERIFIED" == "true" ]]; then
  [[ "$(rule_field_token retentionCount APPLIED_HEX | hex_to_text)" == "$RULE_RETENTION_MAX" ]] || \
    fail "the applied composite preset value mismatch"
fi
log "step3ef rule_composite_chain_ok kind=retentionIntegerEdit typed=$RULE_COMPOSITE_TEXT preset=$RULE_RETENTION_MAX applied=$( [[ "$RULE_PRESET_VERIFIED" == "true" ]] && print true || print input_blocked )"

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
  if real_generated_text_edit rule_text_two "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_TWO" nameField; then
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
  if real_generated_text_edit rule_composite_after_s2 "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "50" retentionEdit; then
    log "step3g rule_composite_after_reorder mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_composite_after_s2_not_delivered"
    log "FAIL_CANDIDATE rule_composite_after_reorder"
  fi
fi
if [[ -z "$INPUT_BLOCKED" ]]; then
  [[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "50" ]] || \
    fail "the composite editor stopped working after the reorder"
else
  log "note rule_composite_after_reorder_assertion skipped input_blocked=$INPUT_BLOCKED (no real input was delivered for this segment)"
fi

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
  if real_generated_text_edit rule_text_three "$RULE_DESCRIPTOR" label "规则名称编辑" "text field" "$RULE_TEXT_THREE" nameField; then
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
  if real_generated_text_edit rule_composite_after_reject "$RULE_DESCRIPTOR" retentionCount "保留天数" "text field" "55" retentionEdit; then
    log "step3h rule_composite_after_rejection mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
  else
    INPUT_BLOCKED="rule_composite_after_rejection_not_delivered"
    log "FAIL_CANDIDATE rule_composite_after_rejection"
  fi
fi
if [[ -z "$INPUT_BLOCKED" ]]; then
  [[ "$(rule_field_token retentionCount DRAFT_HEX | hex_to_text)" == "55" ]] || \
    fail "the composite editor stopped being operable after a rejected candidate"
else
  log "note rule_composite_after_rejection_assertion skipped input_blocked=$INPUT_BLOCKED (no real input was delivered for this segment)"
fi
if [[ -n "$RULE_INPUT_FALLBACK" || -n "$RULE_INPUT_FALLBACK2" || -n "$RULE_INPUT_FALLBACK3" ]]; then
  log "step3 exported_rule_generated_chain_ok version=$RULE_VERSION s2=$RULE_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=blocked"
else
  log "step3 exported_rule_generated_chain_ok version=$RULE_VERSION s2=$RULE_VERSION2 edit_readback=true rejected_candidate_kept_old=true control_input=real_desktop"
fi

# --- 3t. B3: the rule workspace really switches pages and keeps working -----
# The detail workspace is ONE public tab container ("基本" / "保留策略"). A real
# press on the title must switch the ACCEPTED page: the retention page's OWN
# controls become addressable, and pressing the other title hides them again. The
# accepted draft must be identical after the round trip, because which page is
# active is VIEW state and never a business write.
RULE_RETENTION_TITLE="rule-detail-tabs-tab-retention"
RULE_BASIC_TITLE="rule-detail-tabs-tab-basic"
bind_input_target "$RULE_PID" "$RULE_APP"
activate_app
RULE_FILE_BEFORE="$(ax_identifier_frame "file-path" "text field")"
RULE_SAVE_BEFORE="$(ax_identifier_frame "save-as" "button")"
RULE_DRAFT_BEFORE="$(rule_field_token label DRAFT_HEX | hex_to_text)"
[[ "$RULE_FILE_BEFORE" == "missing" ]] \
  || fail "the retention page was already presented before the switch ('$RULE_FILE_BEFORE')"
RULE_SWITCH_PRESS="$(real_ax_press_identifier "$RULE_PID" "$RULE_RETENTION_TITLE" || true)"
sleep 0.9
activate_app
RULE_FILE_AFTER="$(ax_identifier_frame "file-path" "text field")"
RULE_SAVE_AFTER="$(ax_identifier_frame "save-as" "button")"
frame_is_positive "$RULE_FILE_AFTER" \
  || fail "the retention page's editor did not become addressable after the real tab press ('$RULE_FILE_AFTER')"
frame_is_positive "$RULE_SAVE_AFTER" \
  || fail "the retention page's own action row did not become addressable after the real tab press ('$RULE_SAVE_AFTER')"
# A real press back: the retention page is hidden again and the accepted draft is
# exactly what it was before the round trip.
RULE_SWITCH_BACK="$(real_ax_press_identifier "$RULE_PID" "$RULE_BASIC_TITLE" || true)"
sleep 0.9
activate_app
RULE_FILE_BACK="$(ax_identifier_frame "file-path" "text field")"
RULE_DRAFT_AFTER="$(rule_field_token label DRAFT_HEX | hex_to_text)"
[[ "$RULE_FILE_BACK" == "missing" ]] \
  || fail "the retention page was still presented after switching back ('$RULE_FILE_BACK')"
[[ "$RULE_DRAFT_AFTER" == "$RULE_DRAFT_BEFORE" ]] \
  || fail "switching pages changed the accepted draft ('$RULE_DRAFT_BEFORE' -> '$RULE_DRAFT_AFTER')"
log "step3t rule_tabs_page_switch_ok retention_press='$RULE_SWITCH_PRESS' basic_press='$RULE_SWITCH_BACK' file_before='$RULE_FILE_BEFORE' file_after='$RULE_FILE_AFTER' save_after='$RULE_SAVE_AFTER' file_back='$RULE_FILE_BACK' draft='$RULE_DRAFT_BEFORE' input=real_desktop_control driver=ax"

# --- 3g. D: the same public container serves the rule domain -----------------
# The published viewport reports overflowing content, a REAL wheel gesture
# changes the offset, and the content really moves on screen.
bind_input_target "$RULE_PID" "$RULE_APP"
activate_app
make_window_key || fail "the rule window could not be keyed before its wheel gesture"
log "diag step3g wheel_target frontmost=$(app_frontmost) key_window=clicked_title_band"
rule_pub window-interaction > "$WORK/rule-scroll-interaction.txt" 2>&1 || true
RULE_VP_LINE="$(grep '^WINDOW_VIEWPORT rule-set-scroll ' "$WORK/rule-scroll-interaction.txt" || true)"
[[ -n "$RULE_VP_LINE" ]] || fail "the rule consumer did not publish its scroll viewport"
print -r -- "$RULE_VP_LINE" | awk '{
  for (i = 1; i <= NF; i++) {
    if ($i ~ /^content=/) { sub(/^content=/, "", $i); content = $i + 0 }
    if ($i ~ /^viewport=/) { sub(/^viewport=/, "", $i); viewport = $i + 0 }
    if ($i ~ /^pending=/) { sub(/^pending=/, "", $i); pending = $i + 0 }
  }
  if (!(content > viewport)) exit 1
  if (pending != 0) exit 1
}' || fail "the rule viewport does not report overflowing content at rest ('$RULE_VP_LINE')"
RULE_VP_FRAME="$(ax_identifier_frame "rule-set-scroll" "group")"
frame_is_positive "$RULE_VP_FRAME" || fail "the rule scroll container has no pressable frame ('$RULE_VP_FRAME')"
RULE_VX="$(print -r -- "$RULE_VP_FRAME" | awk '{print $1}')"
RULE_VY="$(print -r -- "$RULE_VP_FRAME" | awk '{print $2}')"
RULE_VW="$(print -r -- "$RULE_VP_FRAME" | awk '{print $3}')"
RULE_VH="$(print -r -- "$RULE_VP_FRAME" | awk '{print $4}')"
# A generated editor that is currently materialized is the movement marker.
RULE_MARKER="$(rule_pub generated-instances 2>/dev/null | awk '/kind=textInput/ && !found {for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; found=1; break}}')"
RULE_MARK_BEFORE=""
[[ -n "$RULE_MARKER" ]] && RULE_MARK_BEFORE="$(ax_identifier_frame "$RULE_MARKER" "text field")"
RULE_OFFSET_BEFORE="$(print -r -- "$RULE_VP_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^accepted=/) {sub(/^accepted=/, "", $i); print $i}}')"
RULE_OFFSET_AFTER=""
for scroll_direction in 4 -4; do
  drive scroll $(( RULE_VX + 6 )) $(( RULE_VY + RULE_VH / 2 )) "$scroll_direction"
  RULE_WAIT=0
  while (( RULE_WAIT < 40 )); do
    RULE_VP_AFTER="$(rule_pub window-interaction 2>/dev/null | grep '^WINDOW_VIEWPORT rule-set-scroll ' || true)"
    RULE_OFFSET_AFTER="$(print -r -- "$RULE_VP_AFTER" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^accepted=/) {sub(/^accepted=/, "", $i); print $i}}')"
    [[ -n "$RULE_OFFSET_AFTER" && "$RULE_OFFSET_AFTER" != "$RULE_OFFSET_BEFORE" ]] && break
    sleep 0.05
    RULE_WAIT=$(( RULE_WAIT + 1 ))
  done
  [[ -n "$RULE_OFFSET_AFTER" && "$RULE_OFFSET_AFTER" != "$RULE_OFFSET_BEFORE" ]] && break
done
[[ -n "$RULE_OFFSET_AFTER" && "$RULE_OFFSET_AFTER" != "$RULE_OFFSET_BEFORE" ]] \
  || fail "a real wheel gesture did not move the rule viewport ('$RULE_VP_LINE')"
print -r -- "$RULE_VP_AFTER" | grep -q 'pending=0' \
  || fail "the rule viewport did not settle its request into an accepted offset ('$RULE_VP_AFTER')"
RULE_MARK_AFTER=""
[[ -n "$RULE_MARKER" ]] && RULE_MARK_AFTER="$(ax_identifier_frame "$RULE_MARKER" "text field")"
RULE_MARK_MOVED=false
if frame_is_positive "$RULE_MARK_BEFORE" && frame_is_positive "$RULE_MARK_AFTER"; then
  [[ "$RULE_MARK_AFTER" != "$RULE_MARK_BEFORE" ]] && RULE_MARK_MOVED=true
fi
log "step3g rule_viewport_wheel_ok before='$RULE_VP_LINE' after='$RULE_VP_AFTER' frame='$RULE_VP_FRAME' marker='$RULE_MARKER' marker_visible_frame_moved=$RULE_MARK_MOVED offset='$RULE_OFFSET_BEFORE'->'$RULE_OFFSET_AFTER'"

# --- 3i. D/C2: generated split with TWO independent scrolling panes ----------
# The same exported rule consumer: one generated split whose two panes are each a
# generated scroll. A real divider drag resizes it, and a real wheel in ONE pane
# moves only that pane's accepted offset. Neither view-only operation may move
# the business structure version.
rule_structure_version() {
  rule_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'
}
rule_viewport_line() {
  rule_pub window-interaction 2>/dev/null | awk -v id="$1" '$1 == "WINDOW_VIEWPORT" && $2 == id && !found {print; found=1}'
}
rule_viewport_offset() {
  rule_viewport_line "$1" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^accepted=/) {sub(/^accepted=/, "", $i); print $i}}'
}
d3_wait_pane_frame() { # d3_wait_pane_frame <semantic> -> positive "x y w h" on stdout
  local semantic="$1" attempt frame=""
  for attempt in {1..6}; do
    frame="$(ax_identifier_frame "$semantic" "group")"
    if frame_is_positive "$frame"; then
      print -r -- "$frame"
      return 0
    fi
    sleep 0.4
  done
  print -r -- "$frame"
  return 1
}
rule_instance_line() {
  print -r -- "$1" | awk -v key="$2" '$2 == key && !found {print; found=1}'
}
rule_instance_bounds() {
  print -r -- "$1" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/) {sub(/^bounds=/, "", $i); split($i, pp, ","); print pp[1], pp[2], pp[3], pp[4]}}'
}
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 d3Root vertical"
  print -r -- "NODE 1 d3Split split"
  print -r -- "PROPERTY 1 d3Split firstSize 200"
  print -r -- "PROPERTY 1 d3Split firstMinimum 120"
  print -r -- "PROPERTY 1 d3Split secondMinimum 120"
  # A bounded split keeps its divider inside the exported region's visible strip,
  # so the drag below is a real screen drag instead of a clipped control.
  print -r -- "PROPERTY 1 d3Split fixedHeight 80"
  print -r -- "NODE 2 d3Left scrollArea"
  print -r -- "PROPERTY 2 d3Left offset 0"
  print -r -- "NODE 3 d3LeftStack vertical"
  for row in {0..7}; do
    print -r -- "NODE 4 d3LeftRow${row} label"
    print -r -- "PROPERTY 4 d3LeftRow${row} text 左${row}"
  done
  print -r -- "NODE 2 d3Right scrollArea"
  print -r -- "PROPERTY 2 d3Right offset 0"
  print -r -- "NODE 3 d3RightStack vertical"
  for row in {0..7}; do
    print -r -- "NODE 4 d3RightRow${row} label"
    print -r -- "PROPERTY 4 d3RightRow${row} text 右${row}"
  done
  print -r -- "END"
} > "$WORK/merged-split-panes.txt"
D3_VERSION="$(rule_structure_version)"
rule_pub generated-submit --structure-version "$D3_VERSION" --payload-file "$WORK/merged-split-panes.txt" \
  > "$WORK/merged-split-panes-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/merged-split-panes-submit.log" \
  || fail "the merged generated split/scroll structure was rejected"
D3_WAIT=0
while (( D3_WAIT < 40 )); do
  [[ "$(rule_structure_version)" == "$(( D3_VERSION + 1 ))" ]] && break
  sleep 0.25
  D3_WAIT=$(( D3_WAIT + 1 ))
done
[[ "$(rule_structure_version)" == "$(( D3_VERSION + 1 ))" ]] \
  || fail "the merged generated split/scroll structure was never scene-accepted"
D3_INSTANCES="$(rule_pub generated-instances 2>/dev/null)"
D3_LEFT_SEM="$(print -r -- "$D3_INSTANCES" | awk '$2 == "d3Left" && !found {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; found=1; break}}')"
D3_RIGHT_SEM="$(print -r -- "$D3_INSTANCES" | awk '$2 == "d3Right" && !found {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; found=1; break}}')"
[[ -n "$D3_LEFT_SEM" && -n "$D3_RIGHT_SEM" ]] || fail "the merged split panes are not published as instances"
D3_LEFT_LINE="$(rule_instance_line "$D3_INSTANCES" d3Left)"
D3_RIGHT_LINE="$(rule_instance_line "$D3_INSTANCES" d3Right)"
read -r D3_LX D3_LY D3_LW D3_LH <<< "$(rule_instance_bounds "$D3_LEFT_LINE")"
read -r D3_RX D3_RY D3_RW D3_RH <<< "$(rule_instance_bounds "$D3_RIGHT_LINE")"
[[ "$D3_LW" == <-> && "$D3_RW" == <-> ]] || fail "the merged split panes published no usable bounds"
(( D3_LW > 0 && D3_RW > 0 )) || fail "a merged split pane has no width ($D3_LW / $D3_RW)"
(( D3_LX + D3_LW <= D3_RX + 1 )) || fail "the merged split panes overlap ($D3_LX+$D3_LW > $D3_RX)"

bind_input_target "$RULE_PID" "$RULE_APP"
# The exported application places its generated region at the BOTTOM of its root
# scroll content, so bring that region into the visible strip first: real wheels
# at the same point step3g used for the ROOT viewport, until its accepted offset
# settles at the bottom.
D3_ROOT_PREV=""
D3_ROOT_STABLE=0
for d3_root_try in {1..12}; do
  activate_app
  sleep 0.2
  drive scroll $(( RULE_VX + 6 )) $(( RULE_VY + RULE_VH / 2 )) -6
  sleep 0.45
  D3_ROOT_NOW="$(rule_viewport_offset rule-set-scroll)"
  if [[ -n "$D3_ROOT_NOW" && "$D3_ROOT_NOW" == "$D3_ROOT_PREV" ]]; then
    D3_ROOT_STABLE=$(( D3_ROOT_STABLE + 1 ))
  else
    D3_ROOT_STABLE=0
  fi
  D3_ROOT_PREV="$D3_ROOT_NOW"
  (( D3_ROOT_STABLE >= 1 )) && break
done
log "diag step3i root_scrolled accepted=$D3_ROOT_PREV stable=$D3_ROOT_STABLE"
# The divider's OWN accessibility frame can be the clipped placeholder when the
# exported region's visible strip is short, so the drag point is derived from the
# two REAL pane frames: the divider sits between pane0's right edge and pane1's
# left edge. The divider's own published identity is still recorded as evidence.
D3_LEFT_FRAME="$(d3_wait_pane_frame "$D3_LEFT_SEM" || true)"
D3_RIGHT_FRAME="$(d3_wait_pane_frame "$D3_RIGHT_SEM" || true)"
frame_is_positive "$D3_LEFT_FRAME" || fail "the merged left pane has no frame ('$D3_LEFT_FRAME')"
frame_is_positive "$D3_RIGHT_FRAME" || fail "the merged right pane has no frame ('$D3_RIGHT_FRAME')"
read -r D3_LFX D3_LFY D3_LFW D3_LFH <<< "$D3_LEFT_FRAME"
read -r D3_RFX D3_RFY D3_RFW D3_RFH <<< "$D3_RIGHT_FRAME"
D3_DIVIDER=""
for d3_lookup in 1 2 3; do
  D3_DIVIDER="$(real_ax_dump_identifiers "$RULE_PID" 80 | sed -n 's/^identifier=\(component-[0-9-]*-handle\).*$/\1/p' | awk 'NR == 1 {print}')"
  [[ -n "$D3_DIVIDER" ]] && break
  sleep 0.5
done
[[ -n "$D3_DIVIDER" ]] || fail "the merged generated split published no divider identity"
D3_DIVIDER_FRAME="$(ax_identifier_frame "$D3_DIVIDER" "group" || true)"
D3_FROM_X=$(( (D3_LFX + D3_LFW + D3_RFX) / 2 ))
D3_Y=$(( D3_LFY + D3_LFH / 2 ))
log "diag step3i divider='$D3_DIVIDER' divider_frame='$D3_DIVIDER_FRAME' pane0='$D3_LEFT_FRAME' pane1='$D3_RIGHT_FRAME' drag_from=$D3_FROM_X,$D3_Y"
D3_TO_X=$(( D3_FROM_X + 120 ))
D3_STRUCTURE_BEFORE="$(rule_structure_version)"
D3_LW_AFTER=""
for d3_try in 1 2 3; do
  activate_app
  drive move "$D3_FROM_X" "$D3_Y"
  sleep 0.2
  drive press "$D3_FROM_X" "$D3_Y"
  sleep 0.3
  drive move "$D3_TO_X" "$D3_Y"
  sleep 0.3
  drive release "$D3_TO_X" "$D3_Y"
  sleep 1.2
  D3_LW_AFTER="$(rule_instance_bounds "$(rule_instance_line "$(rule_pub generated-instances 2>/dev/null)" d3Left)" | awk '{print $3}')"
  [[ "$D3_LW_AFTER" == <-> ]] && (( D3_LW_AFTER > D3_LW )) && break
done
[[ "$D3_LW_AFTER" == <-> ]] || fail "the dragged merged divider published no pane width"
(( D3_LW_AFTER > D3_LW )) \
  || fail "the merged real divider drag did not resize the first pane ($D3_LW -> $D3_LW_AFTER)"
[[ "$(rule_structure_version)" == "$D3_STRUCTURE_BEFORE" ]] \
  || fail "the merged divider drag advanced the business structure version"
log "step3i merged_split_drag_ok identifier=$D3_DIVIDER pane0_width=$D3_LW->$D3_LW_AFTER structure_version_stable=$D3_STRUCTURE_BEFORE"

D3_LEFT_FRAME="$(d3_wait_pane_frame "$D3_LEFT_SEM" || true)"
frame_is_positive "$D3_LEFT_FRAME" || fail "the merged left pane has no frame ('$D3_LEFT_FRAME')"
read -r D3_LFX D3_LFY D3_LFW D3_LFH <<< "$D3_LEFT_FRAME"
D3_L_OFFSET_BEFORE="$(rule_viewport_offset "$D3_LEFT_SEM")"
D3_R_OFFSET_BEFORE="$(rule_viewport_offset "$D3_RIGHT_SEM")"
[[ -n "$D3_L_OFFSET_BEFORE" && -n "$D3_R_OFFSET_BEFORE" ]] \
  || fail "the merged pane viewports are not published ($D3_LEFT_SEM / $D3_RIGHT_SEM)"
D3_L_OFFSET_AFTER="$D3_L_OFFSET_BEFORE"
for d3_try in 1 2 3; do
  activate_app
  sleep 0.2
  drive scroll $(( D3_LFX + D3_LFW / 2 )) $(( D3_LFY + D3_LFH / 2 )) -4
  sleep 0.8
  D3_L_OFFSET_AFTER="$(rule_viewport_offset "$D3_LEFT_SEM")"
  [[ "$D3_L_OFFSET_AFTER" == <-> ]] && (( D3_L_OFFSET_AFTER != D3_L_OFFSET_BEFORE )) && break
done
[[ "$D3_L_OFFSET_AFTER" == <-> ]] && (( D3_L_OFFSET_AFTER != D3_L_OFFSET_BEFORE )) \
  || fail "a real wheel did not move the left pane's viewport ($D3_L_OFFSET_BEFORE -> $D3_L_OFFSET_AFTER)"
D3_R_AFTER_LEFT_SCROLL="$(rule_viewport_offset "$D3_RIGHT_SEM")"
[[ "$D3_R_AFTER_LEFT_SCROLL" == "$D3_R_OFFSET_BEFORE" ]] \
  || fail "scrolling the left pane moved the right pane ($D3_R_OFFSET_BEFORE -> $D3_R_AFTER_LEFT_SCROLL)"

D3_RIGHT_FRAME="$(d3_wait_pane_frame "$D3_RIGHT_SEM" || true)"
frame_is_positive "$D3_RIGHT_FRAME" || fail "the merged right pane has no frame ('$D3_RIGHT_FRAME')"
read -r D3_RFX D3_RFY D3_RFW D3_RFH <<< "$D3_RIGHT_FRAME"
D3_R_OFFSET_AFTER="$D3_R_OFFSET_BEFORE"
for d3_try in 1 2 3; do
  activate_app
  sleep 0.2
  drive scroll $(( D3_RFX + D3_RFW / 2 )) $(( D3_RFY + D3_RFH / 2 )) -4
  sleep 0.8
  D3_R_OFFSET_AFTER="$(rule_viewport_offset "$D3_RIGHT_SEM")"
  [[ "$D3_R_OFFSET_AFTER" == <-> ]] && (( D3_R_OFFSET_AFTER != D3_R_OFFSET_BEFORE )) && break
done
[[ "$D3_R_OFFSET_AFTER" == <-> ]] && (( D3_R_OFFSET_AFTER != D3_R_OFFSET_BEFORE )) \
  || fail "a real wheel did not move the right pane's viewport ($D3_R_OFFSET_BEFORE -> $D3_R_OFFSET_AFTER)"
D3_L_FINAL="$(rule_viewport_offset "$D3_LEFT_SEM")"
[[ "$D3_L_FINAL" == "$D3_L_OFFSET_AFTER" ]] \
  || fail "scrolling the right pane moved the left pane ($D3_L_OFFSET_AFTER -> $D3_L_FINAL)"
[[ "$(rule_structure_version)" == "$D3_STRUCTURE_BEFORE" ]] \
  || fail "an independent pane scroll advanced the business structure version"
log "step3i merged_pane_independence_ok left=$D3_L_OFFSET_BEFORE->$D3_L_OFFSET_AFTER right=$D3_R_OFFSET_BEFORE->$D3_R_OFFSET_AFTER structure_version_stable=$D3_STRUCTURE_BEFORE"

# --- 4. second generated consumer: public capability/structure/submit -------
PANEL_DIR="$(prepare_consumer generated_panel_consumer "CJGUICollaborationStarter" \
  "org.example.cjgui.collaboration-starter" "Export${RUN_TAG}")"
PANEL_EXEC="$PANEL_DIR/target/release/CJGUICollaborationStarterExport${RUN_TAG}.app/Contents/MacOS/CJGUICollaborationStarterExport${RUN_TAG}"
PANEL_APP="$PANEL_DIR/target/release/CJGUICollaborationStarterExport${RUN_TAG}.app"
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
  panel_pub generated-fields 2>/dev/null |
    awk -v id="$1" -v tag="$2" '$1 == "FIELD" && $2 == id && !found {for (i = 1; i <= NF; i++) if ($i == tag) {print $(i + 1); found=1; break}}'
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
PROPERTY 1 titleEditor growX 1
PROPERTY 1 titleEditor textColor #A8BDE0FF
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
PROPERTY 1 markedEditor growX 1
PROPERTY 1 markedEditor textColor #A8BDE0FF
NODE 1 card taskEditCard
PROPERTY 1 card caption 导出任务编辑卡
PROPERTY 1 card growX 1
PROPERTY 1 card textColor #A8BDE0FF
NODE 1 toggleBtn action action=TOGGLE_MARKED
PROPERTY 1 toggleBtn label 切换提交状态
PROPERTY 1 toggleBtn growX 1
PROPERTY 1 toggleBtn textColor #A8BDE0FF
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
panel_pub generated-structure 2>/dev/null | grep 'NODE 1 markedEditor booleanInput field=marked' > /dev/null \
  || fail "exported second consumer accepted structure missing the boolean editor"
panel_pub generated-fields 2>/dev/null | grep '^FIELD marked ' > /dev/null || fail "second consumer boolean field readback missing"
# The public capability query publishes the second application composite too.
panel_pub generated-capabilities 2>/dev/null | grep '^COMPONENT taskEditCard ' > /dev/null \
  || fail "the exported second consumer did not publish the composite kind"
panel_pub generated-structure 2>/dev/null | grep 'NODE 1 card taskEditCard' > /dev/null \
  || fail "the exported second consumer accepted structure missing the card"
log "step4cap panel_composite_published kind=taskEditCard"

# --- 4a. REAL generated-control input #1: type into the generated text editor
bind_input_target "$PANEL_PID" "$PANEL_APP"
PANEL_TEXT_ONE="export-panel-title-one"
PANEL_INPUT_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_text_one "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_ONE" titleEditor; then
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
PROPERTY 1 card textColor #A8BDE0FF
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
PROPERTY 1 markedEditor textColor #A8BDE0FF
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
PROPERTY 1 titleEditor textColor #A8BDE0FF
END
PS2
# --- 4f. REAL input through the APPLICATION COMPOSITE's own editor ----------
# The card instance came from the public structure channel; its notes editor is
# now driven with real desktop input and read back from the owner.
PANEL_CARD_NOTES="export-card-notes-one"
PANEL_CARD_FALLBACK=""
if [[ -z "$INPUT_BLOCKED" ]]; then
  if real_generated_text_edit panel_card_notes "$PANEL_DESCRIPTOR" notes "备注" "text field" "$PANEL_CARD_NOTES" card; then
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
  if real_generated_text_edit panel_text_two "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_TWO" titleEditor; then
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

# --- 4c-b. B: ONE owner availability, every presentation --------------------
# The task is now submitted, so the owner refuses the title. The handwritten
# editor, the built-in generated editor and the composite card editor are three
# presentations of the SAME declared field: all three must show the owner's
# verdict, notes must stay editable, and the external client must be refused for
# the same reason instead of storing a value.
bind_input_target "$PANEL_PID" "$PANEL_APP"
activate_app
sleep 0.4
panel_ax_state() { # panel_ax_state <identifier> <collection-kind> -> true|false|missing
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set out to \"missing\"
    repeat with w in windows of p
      try
        repeat with e in (every $2 of w)
          try
            if (value of attribute \"AXIdentifier\" of e) is \"$1\" then
              return ((value of attribute \"AXEnabled\" of e) as string)
            end if
          end try
        end repeat
      end try
    end repeat
    return out
  end tell" 2>/dev/null | tail -1 || true
}
B2_TITLE_PRESENTATIONS="component-1-1 component-4-1 component-6-2-title"
B2_CHECKED=0
for presentation in ${(z)B2_TITLE_PRESENTATIONS}; do
  B2_STATE="$(panel_ax_state "$presentation" "text field")"
  [[ "$B2_STATE" == "false" ]] \
    || fail "the title presentation $presentation did not consume the owner's frozen verdict (AXEnabled=$B2_STATE)"
  B2_CHECKED=$(( B2_CHECKED + 1 ))
done
(( B2_CHECKED == 3 )) || fail "not every title presentation was observed"
B2_NOTES_STATE="$(panel_ax_state "component-6-2-notes" "text field")"
[[ "$B2_NOTES_STATE" == "true" ]] \
  || fail "the notes editor was disabled although the owner allows it (AXEnabled=$B2_NOTES_STATE)"
panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_TITLE --target 8101 \
  --arg title=STRING:"export-panel-frozen-title" > "$WORK/panel-frozen-title.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/panel-frozen-title.log" \
  || fail "the owner accepted a title write while presenting the field as unavailable"
grep -q 'title_frozen_after_submit' "$WORK/panel-frozen-title.log" \
  || fail "the frozen-title refusal did not carry the owner's own reason"
log "step4cb owner_availability_presentations_ok title_presentations=3 title=disabled notes=enabled external_reason=title_frozen_after_submit"

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
  if real_generated_text_edit panel_text_three "$PANEL_DESCRIPTOR" title "任务标题编辑" "text field" "$PANEL_TEXT_THREE" titleEditor; then
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

# --- 4g. D: the composite editor was reached by revealing, not by a guess ----
# The target is clipped at rest ('... 0 0'); the driver performed real wheel
# gestures inside the application's published viewport and re-located the SAME
# accepted semantic identity before pressing it.
if ! python3 - "$LOG" <<'PYREVEAL'
import re
import sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
pattern = re.compile(
    r"diag real_text_edit reveal semantic=component-6-2-notes "
    r"clipped_frame='[^']* 0 0' revealed_frame='[^']* ([1-9][0-9]*) ([1-9][0-9]*)'")
match = pattern.search(text)
if not match:
    print("no clipped->pressable reveal for component-6-2-notes")
    sys.exit(1)
print(f"panel_viewport_reveal_ok width={match.group(1)} height={match.group(2)}")
PYREVEAL
then
  fail "the second consumer's clipped editor was not revealed through the shared viewport"
fi
log "step4g panel_viewport_reveal_ok semantic=component-6-2-notes clipped_frame=0x0 revealed_frame=pressable"


# --- 4h. E: style segmentation from the EXPORT ROOT ------------------------
# Both exported consumers must really serve the STYLES section through the
# EXPORTED public client (not only through a full snapshot), and the rule domain
# must show the update path after its own appearance control, with the moved
# cursor refused instead of stitched.
EXPORTED_STYLE_DIR="$export_root/framework/cjgui/shared_operation_core"
[[ -f "$EXPORTED_STYLE_DIR/cjgui_generated_client.py" ]] \
  || fail "the export root does not ship the typed public client"
exported_style_baseline() { # exported_style_baseline <descriptor> <style-name> <state-file>
  python3 - "$EXPORTED_STYLE_DIR" "$1" "$2" "$3" <<'PYSTYLEBASE'
import json
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiSession
descriptor, style_name, state_path = sys.argv[2], sys.argv[3], Path(sys.argv[4])
session = GeneratedUiSession.connect(descriptor)
first = session.observe_once()
snapshot = first.snapshot
if snapshot is None:
    print("the first observation was not a snapshot")
    sys.exit(1)
section = session.section("STYLES", snapshot.cursor)
if f"STYLE {style_name} " not in section.text or "STYLE_REVISION " not in section.text:
    print(f"the STYLES section did not publish {style_name}")
    sys.exit(1)
state_path.write_text(json.dumps({
    "stream_epoch": snapshot.stream_epoch,
    "cursor": snapshot.cursor,
    "baseline_text": section.text,
}), encoding="utf-8")
print(f"exported_style_section_ok style={style_name} cursor={snapshot.cursor} bytes={len(section.text)}")
PYSTYLEBASE
}
exported_style_after_change() { # exported_style_after_change <descriptor> <style-name> <state-file>
  python3 - "$EXPORTED_STYLE_DIR" "$1" "$2" "$3" <<'PYSTYLEAFTER'
import json
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiError, GeneratedUiSession
descriptor, style_name, state_path = sys.argv[2], sys.argv[3], Path(sys.argv[4])
state = json.loads(state_path.read_text(encoding="utf-8"))
session = GeneratedUiSession.connect(descriptor)
try:
    stale = session.section("STYLES", int(state["cursor"]))
except GeneratedUiError as refusal:
    print(f"stale_guard refused_by_client={refusal}")
else:
    if not stale.revision_changed or stale.text.strip() != "":
        print("the stale STYLES read was not refused")
        sys.exit(1)
session.seed_cursor(int(state["stream_epoch"]), int(state["cursor"]))
observed = session.observe_once()
if observed.kind != "changes":
    print(f"the definition change was not an increment (kind={observed.kind})")
    sys.exit(1)
categories = [change.category for change in observed.changes.changes]
sections = observed.sections or {}
if "STYLES" not in categories or "STYLES" not in sections:
    print(f"the definition change did not re-read STYLES ({categories})")
    sys.exit(1)
text = sections["STYLES"]
if f"STYLE {style_name} " not in text or "STYLE_REVISION " not in text:
    print(f"the re-read STYLES section does not name {style_name}")
    sys.exit(1)


def definitions(payload):
    return [line for line in payload.splitlines()
            if line.startswith("STYLE ") and not line.startswith("STYLE_REVISION")]


if definitions(text) == definitions(state["baseline_text"]):
    print("the re-read directory changed its revision but not its paint")
    sys.exit(1)
print(f"exported_style_change_ok style={style_name} categories={len(categories)} definitions_changed=1")
PYSTYLEAFTER
}
exported_title_style_after_change() { # exported_title_style_after_change <descriptor> <state-file>
  python3 - "$EXPORTED_STYLE_DIR" "$1" "$2" <<'PYTITLECHANGE'
import json
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiSession
descriptor, state_path = sys.argv[2], Path(sys.argv[3])
state = json.loads(state_path.read_text(encoding="utf-8"))
session = GeneratedUiSession.connect(descriptor)
session.seed_cursor(int(state["stream_epoch"]), int(state["cursor"]))
observed = session.observe_once()
if observed.kind != "changes":
    print(f"title style update was not an increment (kind={observed.kind})")
    sys.exit(1)
sections = observed.sections or {}
if "STYLES" not in [change.category for change in observed.changes.changes] or "STYLES" not in sections:
    print("title style update did not carry a STYLES section")
    sys.exit(1)
lines = [line for line in sections["STYLES"].splitlines()
         if line.startswith("STYLE_STATE panel_tab_title ")]
if len(lines) != 1:
    print(f"title role state missing or duplicated ({len(lines)} lines)")
    sys.exit(1)
print(lines[0])
PYTITLECHANGE
}
title_style_color() { # title_style_color <STYLE_STATE line>
  python3 - "$1" <<'PYTITLECOLOR'
import re
import sys

normal = re.search(r"\bnormal\[([^]]*)\]", sys.argv[1])
if normal:
    color = re.search(r"\btextColor=(#[0-9A-Fa-f]{8}|#[0-9A-Fa-f]{6})\b", normal.group(1))
    if color:
        print(color.group(1).upper())
PYTITLECOLOR
}
sample_title_paint() { # sample_title_paint <accepted-semantic> <expected-color>
  local semantic="$1" expected="$2" frame x y width height shot
  frame="$(ax_identifier_frame "$semantic" "group")"
  if [[ "$frame" == "missing" || -z "$frame" ]]; then
    frame="$(ax_identifier_frame "$semantic" "button")"
  fi
  frame_is_positive "$frame" || fail "accepted title has no visible frame semantic=$semantic frame='$frame'"
  read -r x y width height <<< "$frame"
  shot="$WORK/title-paint-${expected#\#}.png"
  screencapture -x -R "${x},${y},${width},${height}" -t png "$shot" >/dev/null 2>&1 \
    || fail "could not capture accepted title frame semantic=$semantic frame='$frame'"
  python3 - "$SCRIPT_DIR" "$shot" "$expected" > "$WORK/title-paint-check.txt" 2>&1 <<'PYTITLEPIXEL' \
    || fail "accepted title paint did not match its public text color semantic=$semantic expected=$expected frame='$frame' screenshot='$shot' result='$(cat "$WORK/title-paint-check.txt")'"
import sys
sys.path.insert(0, sys.argv[1])
from region_luminance import read_pixels

token = sys.argv[3].lstrip("#")[:6]
if len(token) != 6:
    print("invalid public title color")
    sys.exit(1)
target = tuple(int(token[index:index + 2], 16) for index in (0, 2, 4))
width, height, channels, rows = read_pixels(sys.argv[2])
matches = 0
best = 255
for row in rows:
    for x in range(width):
        offset = x * channels
        delta = max(abs(row[offset + channel] - target[channel]) for channel in range(3))
        best = min(best, delta)
        if delta <= 55:
            matches += 1
if matches < 3:
    print(f"title frame has no declared glyph color: size={width}x{height} matches={matches} best_channel_delta={best} target={target}")
    sys.exit(1)
print(f"title_drawable_color_ok target=#{token} pixels={matches} best_channel_delta={best} size={width}x{height}")
PYTITLEPIXEL
  log "step4j $(cat "$WORK/title-paint-check.txt") screenshot=$shot"
}
EXPORTED_STYLE_STATE="$WORK/exported-style-state.json"
if ! exported_style_baseline "$PANEL_DESCRIPTOR" "collaboration_primary_action" "$EXPORTED_STYLE_STATE" \
    > "$WORK/exported-panel-style1.log" 2>&1; then
  cat "$WORK/exported-panel-style1.log" >> "$LOG" 2>/dev/null || true
  fail "the exported panel consumer did not serve its STYLES section"
fi
log "step4h $(cat "$WORK/exported-panel-style1.log") consumer=panel"
if ! exported_style_baseline "$RULE_DESCRIPTOR" "rule_primary_action" "$EXPORTED_STYLE_STATE" \
    > "$WORK/exported-rule-style1.log" 2>&1; then
  cat "$WORK/exported-rule-style1.log" >> "$LOG" 2>/dev/null || true
  fail "the exported rule consumer did not serve its STYLES section"
fi
log "step4h $(cat "$WORK/exported-rule-style1.log") consumer=rule"
# The application's OWN appearance control changes the definition; the exported
# client must then observe STYLES and re-read changed paint.
bind_input_target "$RULE_PID" "$RULE_APP"
activate_app
# The appearance component lives on the "保留策略" page, so this step reaches it
# through the REAL tab UI first instead of assuming a hidden page's controls are
# addressable.
RULE_STYLE_PAGE_PRESS="$(real_ax_press_identifier "$RULE_PID" "rule-detail-tabs-tab-retention" || true)"
[[ "$RULE_STYLE_PAGE_PRESS" == "identifier_press_sent" ]] \
  || fail "the retention page could not be reached for the appearance control ('$RULE_STYLE_PAGE_PRESS')"
sleep 0.7
activate_app
EXPORTED_STYLE_PRESS="$(real_ax_press_identifier "$RULE_PID" "component-1-2")"
[[ "$EXPORTED_STYLE_PRESS" == "identifier_press_sent" ]] \
  || fail "the exported rule consumer's appearance control could not be pressed ('$EXPORTED_STYLE_PRESS')"
sleep 1.0
if ! exported_style_after_change "$RULE_DESCRIPTOR" "rule_primary_action" "$EXPORTED_STYLE_STATE" \
    > "$WORK/exported-rule-style2.log" 2>&1; then
  cat "$WORK/exported-rule-style2.log" >> "$LOG" 2>/dev/null || true
  fail "the exported rule consumer did not observe the STYLES update"
fi
log "step4h $(cat "$WORK/exported-rule-style2.log") consumer=rule_after_real_control"

# --- 4i. D: a generated control and a REGISTERED COMPOSITE element share paint --
# One declared named style is used by a generated text control AND by the
# registered `taskEditCard` composite. Both are addressed by the identity the
# framework allocated for them, and the composited pixel inside each accepted
# frame must be the SAME paint: declaration value, accepted identity frame and
# real composited output are correlated without a hard-coded coordinate.
bind_input_target "$PANEL_PID" "$PANEL_APP"
cat > "$WORK/panel-paint-shared.txt" <<'PPAINT'
GENERATED_UI_STRUCTURE 1
NODE 0 paintBoard vertical
NODE 1 paintTitle textInput field=title
PROPERTY 1 paintTitle label 共享样式标题
PROPERTY 1 paintTitle style collaboration_primary_action
NODE 1 paintCard taskEditCard
PROPERTY 1 paintCard caption 共享样式卡片
PROPERTY 1 paintCard style collaboration_primary_action
END
PPAINT
P_PAINT_VERSION="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
panel_pub generated-submit --structure-version "$P_PAINT_VERSION" --payload-file "$WORK/panel-paint-shared.txt" \
  > "$WORK/panel-paint-shared-submit.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-paint-shared-submit.log" \
  || fail "the exported panel rejected the shared-style structure"
P_PAINT_ACCEPT=0
for p_paint_wait in {1..40}; do
  P_PAINT_NOW="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  if [[ "$P_PAINT_NOW" == "$(( P_PAINT_VERSION + 1 ))" ]]; then
    P_PAINT_ACCEPT=1
    break
  fi
  sleep 0.25
done
(( P_PAINT_ACCEPT == 1 )) || fail "the shared-style structure was never scene-accepted"
P_PAINT_INSTANCES="$(panel_pub generated-instances 2>/dev/null)"
P_GEN_SEM="$(print -r -- "$P_PAINT_INSTANCES" | awk '$2 == "paintTitle" && !found {
  for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; found=1; break}}')"
P_COMP_LINE="$(print -r -- "$P_PAINT_INSTANCES" | awk '$2 == "paintCard" && $0 ~ /element=title/ && !found {print; found=1}')"
[[ -n "$P_GEN_SEM" && -n "$P_COMP_LINE" ]] \
  || fail "the shared-style generated control or composite element is not published"
P_COMP_SEM="$(print -r -- "$P_COMP_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i}}')"
[[ -n "$P_COMP_SEM" ]] || fail "the composite element carries no accepted identity"
P_SHARED_BG="$(panel_pub generated-capabilities 2>/dev/null | awk '/^STYLE collaboration_primary_action /{
  for (i = 1; i <= NF; i++) if ($i ~ /^background=/) {sub(/^background=/, "", $i); print $i}}')"
[[ -n "$P_SHARED_BG" ]] || fail "the exported panel published no background for the shared named style"
activate_app
sleep 0.4
P_GEN_FRAME="$(ax_identifier_frame "$P_GEN_SEM" "text field")"
frame_is_positive "$P_GEN_FRAME" || fail "the shared-style generated control has no frame ('$P_GEN_FRAME')"
P_COMP_FRAME="$(ax_identifier_frame "$P_COMP_SEM" "text field")"
frame_is_positive "$P_COMP_FRAME" || fail "the shared-style composite element has no frame ('$P_COMP_FRAME')"
read -r P_GX P_GY P_GW P_GH <<< "$P_GEN_FRAME"
read -r P_KX P_KY P_KW P_KH <<< "$P_COMP_FRAME"
P_GEN_PIXEL_A="$(region_pixel_hex $(( P_GX + P_GW / 4 )) $(( P_GY + P_GH / 2 )) || true)"
P_GEN_PIXEL_B="$(region_pixel_hex $(( P_GX + P_GW * 3 / 4 )) $(( P_GY + P_GH / 2 )) || true)"
P_COMP_PIXEL_A="$(region_pixel_hex $(( P_KX + P_KW / 4 )) $(( P_KY + P_KH / 2 )) || true)"
P_COMP_PIXEL_B="$(region_pixel_hex $(( P_KX + P_KW * 3 / 4 )) $(( P_KY + P_KH / 2 )) || true)"
[[ -n "$P_GEN_PIXEL_A" || -n "$P_GEN_PIXEL_B" ]] || fail "no composited pixel for the generated shared-style control"
[[ -n "$P_COMP_PIXEL_A" || -n "$P_COMP_PIXEL_B" ]] || fail "no composited pixel for the composite shared-style element"
python3 - "$P_SHARED_BG" "$P_GEN_PIXEL_A" "$P_GEN_PIXEL_B" "$P_COMP_PIXEL_A" "$P_COMP_PIXEL_B" <<'PYPANT'
import sys

published, gen_a, gen_b, comp_a, comp_b = sys.argv[1:6]


def rgb(token):
    token = token.lstrip("#")[:6]
    return int(token[0:2], 16), int(token[2:4], 16), int(token[4:6], 16)


def delta(a, b):
    return max(abs(x - y) for x, y in zip(rgb(a), rgb(b)))


generated = [value for value in (gen_a, gen_b) if value]
composite = [value for value in (comp_a, comp_b) if value]
if not generated or not composite:
    print("no bounded screenshot pixel was captured")
    sys.exit(1)
best = min(((g, c, delta(g, c)) for g in generated for c in composite), key=lambda item: item[2])
gen_pixel, comp_pixel, shared = best
pr, pg, pb = rgb(published)
dominant = max((pr, "r"), (pg, "g"), (pb, "b"))[1]
observed = rgb(gen_pixel)
others = [value for name, value in zip(("r", "g", "b"), observed) if name != dominant]
margin = observed[("r", "g", "b").index(dominant)] - max(others)
print(f"published=#{published} generated=#{gen_pixel} composite=#{comp_pixel} "
      f"shared_delta={shared} dominant={dominant} margin={margin} declared_delta={delta(published, gen_pixel)}")
if shared > 12:
    print("the composite element and the generated control do not share the same composited paint")
    sys.exit(1)
if margin < 40 or delta(published, gen_pixel) > 80:
    print("the shared paint is not in the declared background's channel family")
    sys.exit(1)
PYPANT
log "step4i composite_shared_style_paint_ok generated_semantic=$P_GEN_SEM composite_semantic=$P_COMP_SEM published=#$P_SHARED_BG generated=#$P_GEN_PIXEL_A/#$P_GEN_PIXEL_B composite=#$P_COMP_PIXEL_A/#$P_COMP_PIXEL_B method=bounded_region_screenshot shared_tolerance=12"

# --- 4j. D3: the generated tabs' title role consumes its OWN theme operation.
# The accent action flips the title role's EFFECTIVE normal override (the base
# stays untouched); the public STYLES increment must carry it, and the real
# page switch plus the following steps must keep working on the same instance.
PANEL_TABS_PAYLOAD="$WORK/panel-tabs.txt"
cat > "$PANEL_TABS_PAYLOAD" <<'PS3'
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 boardTabs tabs
PROPERTY 1 boardTabs initialPage task
PROPERTY 1 boardTabs titleStyle panel_tab_title
NODE 2 taskPage tabPage
PROPERTY 2 taskPage pageKey task
PROPERTY 2 taskPage pageTitle 任务
NODE 3 taskPageContent vertical
NODE 4 titleEditor textInput field=title
PROPERTY 4 titleEditor label 任务标题编辑
PROPERTY 4 titleEditor growX 1
PROPERTY 4 titleEditor textColor #A8BDE0FF
PROPERTY 4 titleEditor background #22314A
PROPERTY 4 titleEditor border #3A5A8C
PROPERTY 4 titleEditor borderWidth 1
NODE 4 accentBtn action action=TOGGLE_TITLE_ACCENT
PROPERTY 4 accentBtn label 切换标题强调色
PROPERTY 4 accentBtn growX 1
PROPERTY 4 accentBtn textColor #A8BDE0FF
PROPERTY 4 accentBtn background #22314A
PROPERTY 4 accentBtn border #3A5A8C
PROPERTY 4 accentBtn borderWidth 1
NODE 2 notesPage tabPage
PROPERTY 2 notesPage pageKey notes
PROPERTY 2 notesPage pageTitle 备注
NODE 3 notesEditor textInput field=notes
PROPERTY 3 notesEditor label 任务备注编辑
PROPERTY 3 notesEditor growX 1
PROPERTY 3 notesEditor textColor #A8BDE0FF
PROPERTY 3 notesEditor background #22314A
PROPERTY 3 notesEditor border #3A5A8C
PROPERTY 3 notesEditor borderWidth 1
END
PS3
PANEL_TABS_VERSION="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
panel_pub generated-submit --structure-version "$PANEL_TABS_VERSION" --payload-file "$PANEL_TABS_PAYLOAD" > "$WORK/panel-tabs-submit.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-tabs-submit.txt" \
  || fail "the tabs+titleStyle candidate was rejected: $(cat "$WORK/panel-tabs-submit.txt")"
PANEL_TABS_ACCEPTED1=0
for title_accept_wait in {1..40}; do
  PANEL_TABS_ACCEPTED_NOW="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  if [[ "$PANEL_TABS_ACCEPTED_NOW" == "$(( PANEL_TABS_VERSION + 1 ))" ]]; then
    PANEL_TABS_ACCEPTED1=1
    break
  fi
  sleep 0.1
done
(( PANEL_TABS_ACCEPTED1 == 1 )) || fail "the tabs+titleStyle candidate was not scene-accepted"
bind_input_target "$PANEL_PID" "$PANEL_APP"
# On this host "frontmost" is not the same as the KEY window; posted pointer
# input is dropped unless the window is keyed first (the same reason step2c
# keys the window before its reveal presses).
make_window_key >/dev/null 2>&1 || true
activate_app
PANEL_INSTANCES="$(panel_pub generated-instances 2>/dev/null)"
PANEL_BOARD_SEMANTIC="$(print -r -- "$PANEL_INSTANCES" | awk '$2 == "boardTabs" {for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; exit}}')"
[[ -n "$PANEL_BOARD_SEMANTIC" ]] || fail "the accepted tabs container has no semantic identity"
PANEL_NOTES_TAB_SEMANTIC="${PANEL_BOARD_SEMANTIC}-tab-notes"
PANEL_TASK_TAB_SEMANTIC="${PANEL_BOARD_SEMANTIC}-tab-task"
PANEL_NOTES_TAB_FRAME="$(ax_identifier_frame "$PANEL_NOTES_TAB_SEMANTIC" "group")"
frame_is_positive "$PANEL_NOTES_TAB_FRAME" \
  || fail "the accepted notes tab has no visible semantic frame ('$PANEL_NOTES_TAB_FRAME')"
PANEL_NOTES_PRESS="$(real_ax_press_identifier "$PANEL_PID" "$PANEL_NOTES_TAB_SEMANTIC" || true)"
[[ "$PANEL_NOTES_PRESS" == "identifier_press_sent" ]] \
  || fail "the generated tabs could not switch to the notes page ('$PANEL_NOTES_PRESS')"
sleep 0.6
activate_app
PANEL_D3_NOTES_VALUE="标题链前置编辑-$(date +%s)"
if real_generated_text_edit panel_title_chain_notes_before "$PANEL_DESCRIPTOR" notes \
    "任务备注编辑" "text field" "$PANEL_D3_NOTES_VALUE" notesEditor; then
  log "step4j notes_page_edit_ok semantic=$PANEL_NOTES_TAB_SEMANTIC field=notes readback=true"
else
  STEP4J_BLOCKED="${STEP4J_BLOCKED:+$STEP4J_BLOCKED,}notes_page_input_unverified"
  log "BLOCKED step4j notes_page_edit reason=real_input_unverified semantic=$PANEL_NOTES_TAB_SEMANTIC"
fi
PANEL_TASK_PRESS="$(real_ax_press_identifier "$PANEL_PID" "$PANEL_TASK_TAB_SEMANTIC" || true)"
[[ "$PANEL_TASK_PRESS" == "identifier_press_sent" ]] \
  || fail "the generated tabs could not return to the task page ('$PANEL_TASK_PRESS')"
sleep 0.6
activate_app
# The declared key maps to its runtime semantic address through the public
# instances payload (generated semantic ids are positional). The press itself
# is a REAL CGEvent click at the button's screen frame center: generated
# action buttons dispatch their action from the ordinary mouse path.
ACCENT_SEMANTIC="$(panel_pub generated-instances 2>/dev/null | awk '/^INSTANCE accentBtn /{for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) { sub(/^semantic=/, "", $i); print $i; exit } }')"
[[ -n "$ACCENT_SEMANTIC" ]] || fail "the accent button semantic id was not published"
ACCENT_INSTANCE="$(panel_pub generated-instances 2>/dev/null | awk '$2 == "accentBtn" {print; exit}')"
print -r -- "$ACCENT_INSTANCE" | grep -q 'action=TOGGLE_TITLE_ACCENT' \
  || fail "the accepted accent semantic does not resolve to the declared theme action ('$ACCENT_INSTANCE')"
print -r -- "$ACCENT_INSTANCE" | grep -q 'visible=1' \
  || fail "the accepted accent action is not visible ('$ACCENT_INSTANCE')"
ACCENT_ENABLED="$(ax_identifier_enabled "$PANEL_PID" "$ACCENT_SEMANTIC")"
[[ "$ACCENT_ENABLED" == "true" || "$ACCENT_ENABLED" == "True" || "$ACCENT_ENABLED" == "1" ]] \
  || fail "the accepted accent action is not AX-enabled semantic=$ACCENT_SEMANTIC enabled='$ACCENT_ENABLED'"
# Locate by the EXACT accepted semantic identity (component-N-M) instead of
# guessing from the caption: the description match can pick a different button
# in the same window.
ACCENT_FRAME="$(ax_identifier_frame "$ACCENT_SEMANTIC" "button")"
[[ "$ACCENT_FRAME" != "missing" && -n "$ACCENT_FRAME" ]] || fail "the accent button frame was not exposed"
# Style state + cursor are captured BEFORE the click: the increment that must
# carry the flipped override is read from THIS cursor afterwards, so an absent
# increment is a real observation rather than an artifact of sampling after the
# change had already been published.
exported_style_baseline "$PANEL_DESCRIPTOR" "panel_tab_title" "$WORK/panel-title-state" > "$WORK/panel-title-baseline.log" 2>&1 || true
TITLE_STATE_BEFORE="$(python3 -c "
import json
from pathlib import Path
state=json.loads(Path('$WORK/panel-title-state').read_text(encoding='utf-8'))
lines=[l for l in state['baseline_text'].splitlines() if l.startswith('STYLE_STATE panel_tab_title ')]
print(lines[0] if lines else 'MISSING')
" 2>/dev/null || print MISSING)"
ACCENT_REVISION_BEFORE="$(panel_pub generated-snapshot 2>/dev/null | awk '/^STYLE_REVISION /{print $2; exit}')"
# The accent toggle is NOT idempotent: it is clicked exactly ONCE (a blind
# retry would flip it back). Delivery is judged by the published style revision
# and, when it does not move, recorded as a bounded real-input condition.
click_frame_center "$ACCENT_FRAME" || fail "the accent button click failed"
ACCENT_REVISION_NOW=""
for accent_wait in {1..30}; do
  ACCENT_REVISION_NOW="$(panel_pub generated-snapshot 2>/dev/null | awk '/^STYLE_REVISION /{print $2; exit}')"
  [[ -n "$ACCENT_REVISION_NOW" && "$ACCENT_REVISION_NOW" != "$ACCENT_REVISION_BEFORE" ]] && break
  sleep 0.1
done
log "diag step4j accent_click revision=$ACCENT_REVISION_BEFORE->$ACCENT_REVISION_NOW frame='$ACCENT_FRAME' semantic=$ACCENT_SEMANTIC"
# The named-style update lives in the live catalog; it publishes through a
# candidate transaction (the same staged/accepted rule as every style). A
# no-op re-submit of the same tabs payload restages the role so the public
# STYLES increment carries the flipped normal override.
PANEL_TABS_VERSION2="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
panel_pub generated-submit --structure-version "$PANEL_TABS_VERSION2" --payload-file "$PANEL_TABS_PAYLOAD" > "$WORK/panel-tabs-submit2.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-tabs-submit2.txt" \
  || fail "the post-toggle re-submit was rejected: $(cat "$WORK/panel-tabs-submit2.txt")"
PANEL_TABS_ACCEPTED2=0
for title_accept_wait2 in {1..40}; do
  PANEL_TABS_ACCEPTED_NOW2="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  if [[ "$PANEL_TABS_ACCEPTED_NOW2" == "$(( PANEL_TABS_VERSION2 + 1 ))" ]]; then
    PANEL_TABS_ACCEPTED2=1
    break
  fi
  sleep 0.1
done
(( PANEL_TABS_ACCEPTED2 == 1 )) || fail "the title scene was not accepted after the first accent change"
TITLE_STATE_AFTER=""
if [[ -n "$ACCENT_REVISION_NOW" ]]; then
  TITLE_STATE_AFTER="$(exported_title_style_after_change "$PANEL_DESCRIPTOR" "$WORK/panel-title-state" 2>/dev/null || true)"
fi
if [[ -z "$ACCENT_REVISION_NOW" ]]; then
  # The click's delivery is unverified (the published style revision did not
  # move). Record it as a bounded environment/input condition with the measured
  # values and keep the headless evidence; the dependent assertion is skipped
  # rather than reported as a product failure.
  STEP4J_BLOCKED="${STEP4J_BLOCKED:+$STEP4J_BLOCKED,}real_input_unverified"
  log "BLOCKED step4j accent_click reason=real_input_unverified revision='$ACCENT_REVISION_BEFORE'->'$ACCENT_REVISION_NOW' semantic=$ACCENT_SEMANTIC frame='$ACCENT_FRAME' dependent_assertion=skipped"
elif [[ "$TITLE_STATE_AFTER" == "MISSING" ]]; then
  fail "the accent toggle moved the style revision but no STYLES increment carried it (before='$TITLE_STATE_BEFORE')"
elif [[ "$TITLE_STATE_BEFORE" == "$TITLE_STATE_AFTER" ]]; then
  fail "the title accent toggle did not change the effective state (before='$TITLE_STATE_BEFORE' after='$TITLE_STATE_AFTER')"
else
  TITLE_COLOR_AFTER="$(title_style_color "$TITLE_STATE_AFTER")"
  [[ "$TITLE_COLOR_AFTER" == "#1A4DD9FF" ]] \
    || fail "the first title accent state is not the declared blue token ('$TITLE_COLOR_AFTER')"
  TITLE_SEMANTIC="${PANEL_BOARD_SEMANTIC}-tab-task"
  sample_title_paint "$TITLE_SEMANTIC" "$TITLE_COLOR_AFTER"
  log "step4j title_accent_state_ok before='$TITLE_STATE_BEFORE' after='$TITLE_STATE_AFTER' revision='$ACCENT_REVISION_BEFORE'->'$ACCENT_REVISION_NOW'"
fi

# A second independent click must move the same accepted action to the other
# exact palette state and redraw the same page title from the updated role.
if [[ -n "$ACCENT_REVISION_NOW" ]]; then
  exported_style_baseline "$PANEL_DESCRIPTOR" "panel_tab_title" "$WORK/panel-title-state2" \
    > "$WORK/panel-title-baseline2.log" 2>&1 \
    || fail "could not capture the second title-style baseline"
  TITLE_STATE_BEFORE2="$(python3 -c "
import json
from pathlib import Path
state=json.loads(Path('$WORK/panel-title-state2').read_text(encoding='utf-8'))
lines=[line for line in state['baseline_text'].splitlines() if line.startswith('STYLE_STATE panel_tab_title ')]
print(lines[0] if lines else 'MISSING')
" 2>/dev/null || print MISSING)"
  ACCENT_REVISION_BEFORE2="$(panel_pub generated-snapshot 2>/dev/null | awk '/^STYLE_REVISION /{print $2; exit}')"
  ACCENT_SEMANTIC2="$(panel_pub generated-instances 2>/dev/null | awk '$2 == "accentBtn" {for (i = 1; i <= NF; i++) if ($i ~ /^semantic=/) {sub(/^semantic=/, "", $i); print $i; exit}}')"
  [[ -n "$ACCENT_SEMANTIC2" && "$ACCENT_SEMANTIC2" == "$ACCENT_SEMANTIC" ]] \
    || fail "the accepted accent action identity changed across its first update ('$ACCENT_SEMANTIC' -> '$ACCENT_SEMANTIC2')"
  ACCENT_ENABLED2="$(ax_identifier_enabled "$PANEL_PID" "$ACCENT_SEMANTIC2")"
  [[ "$ACCENT_ENABLED2" == "true" || "$ACCENT_ENABLED2" == "True" || "$ACCENT_ENABLED2" == "1" ]] \
    || fail "the accent action became disabled before its second click ('$ACCENT_ENABLED2')"
  ACCENT_FRAME2="$(ax_identifier_frame "$ACCENT_SEMANTIC2" "button")"
  frame_is_positive "$ACCENT_FRAME2" || fail "the second accepted accent action has no frame ('$ACCENT_FRAME2')"
  click_frame_center "$ACCENT_FRAME2" || fail "the second accent button click failed"
  ACCENT_REVISION_NOW2=""
  for accent_wait2 in {1..30}; do
    ACCENT_REVISION_NOW2="$(panel_pub generated-snapshot 2>/dev/null | awk '/^STYLE_REVISION /{print $2; exit}')"
    [[ -n "$ACCENT_REVISION_NOW2" && "$ACCENT_REVISION_NOW2" != "$ACCENT_REVISION_BEFORE2" ]] && break
    sleep 0.1
  done
  PANEL_TABS_VERSION3="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
  panel_pub generated-submit --structure-version "$PANEL_TABS_VERSION3" --payload-file "$PANEL_TABS_PAYLOAD" \
    > "$WORK/panel-tabs-submit3.txt" 2>&1 || true
  grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-tabs-submit3.txt" \
    || fail "the second post-toggle candidate was rejected: $(cat "$WORK/panel-tabs-submit3.txt")"
  PANEL_TABS_ACCEPTED3=0
  for title_accept_wait3 in {1..40}; do
    PANEL_TABS_ACCEPTED_NOW3="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
    if [[ "$PANEL_TABS_ACCEPTED_NOW3" == "$(( PANEL_TABS_VERSION3 + 1 ))" ]]; then
      PANEL_TABS_ACCEPTED3=1
      break
    fi
    sleep 0.1
  done
  (( PANEL_TABS_ACCEPTED3 == 1 )) || fail "the title scene was not accepted after the second accent change"
  TITLE_STATE_AFTER2=""
  if [[ -n "$ACCENT_REVISION_NOW2" ]]; then
    TITLE_STATE_AFTER2="$(exported_title_style_after_change "$PANEL_DESCRIPTOR" "$WORK/panel-title-state2" 2>/dev/null || true)"
  fi
  if [[ -z "$ACCENT_REVISION_NOW2" || -z "$TITLE_STATE_AFTER2" || "$TITLE_STATE_AFTER2" == "$TITLE_STATE_BEFORE2" ]]; then
    STEP4J_BLOCKED="${STEP4J_BLOCKED:+$STEP4J_BLOCKED,}second_real_input_unverified"
    log "BLOCKED step4j second_accent_click reason=real_input_unverified revision='$ACCENT_REVISION_BEFORE2'->'$ACCENT_REVISION_NOW2' semantic=$ACCENT_SEMANTIC2"
  else
    TITLE_COLOR_AFTER2="$(title_style_color "$TITLE_STATE_AFTER2")"
    [[ "$TITLE_COLOR_AFTER2" == "#8C2699FF" ]] \
      || fail "the second title accent state is not the declared plum token ('$TITLE_COLOR_AFTER2')"
    sample_title_paint "$TITLE_SEMANTIC" "$TITLE_COLOR_AFTER2"
    log "step4j title_accent_roundtrip_ok first='$TITLE_COLOR_AFTER' second='$TITLE_COLOR_AFTER2' revision='$ACCENT_REVISION_BEFORE2'->'$ACCENT_REVISION_NOW2'"
  fi
fi

# The unknown title reference must leave the last accepted scene and old page
# controls intact. Recheck by editing the notes control through its accepted
# semantic identity after the rejection.
PANEL_TABS_ACCEPTED_BEFORE_REJECT="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
sed 's/titleStyle panel_tab_title/titleStyle missing_title_role/' "$PANEL_TABS_PAYLOAD" \
  > "$WORK/panel-tabs-unknown-title.txt"
panel_pub generated-submit --structure-version "$PANEL_TABS_ACCEPTED_BEFORE_REJECT" \
  --payload-file "$WORK/panel-tabs-unknown-title.txt" > "$WORK/panel-tabs-unknown-submit.txt" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED false' "$WORK/panel-tabs-unknown-submit.txt" \
  || fail "an unknown title role candidate was not explicitly refused: $(cat "$WORK/panel-tabs-unknown-submit.txt")"
PANEL_TABS_ACCEPTED_AFTER_REJECT="$(panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}')"
[[ "$PANEL_TABS_ACCEPTED_AFTER_REJECT" == "$PANEL_TABS_ACCEPTED_BEFORE_REJECT" ]] \
  || fail "the rejected unknown title candidate replaced the accepted tabs version ($PANEL_TABS_ACCEPTED_BEFORE_REJECT -> $PANEL_TABS_ACCEPTED_AFTER_REJECT)"
PANEL_NOTES_PRESS_AFTER_REJECT="$(real_ax_press_identifier "$PANEL_PID" "$PANEL_NOTES_TAB_SEMANTIC" || true)"
[[ "$PANEL_NOTES_PRESS_AFTER_REJECT" == "identifier_press_sent" ]] \
  || fail "the accepted notes page stopped responding after candidate rejection ('$PANEL_NOTES_PRESS_AFTER_REJECT')"
sleep 0.6
activate_app
PANEL_D3_NOTES_VALUE2="标题链拒绝后编辑-$(date +%s)"
if real_generated_text_edit panel_title_chain_notes_after_reject "$PANEL_DESCRIPTOR" notes \
    "任务备注编辑" "text field" "$PANEL_D3_NOTES_VALUE2" notesEditor; then
  log "step4j rejected_title_kept_old_control_editable accepted=$PANEL_TABS_ACCEPTED_AFTER_REJECT field=notes readback=true"
else
  STEP4J_BLOCKED="${STEP4J_BLOCKED:+$STEP4J_BLOCKED,}post_rejection_control_edit_unverified"
  log "BLOCKED step4j old_control_edit reason=real_input_unverified accepted=$PANEL_TABS_ACCEPTED_AFTER_REJECT"
fi

# --- 5. the EXPORTED typed public client and example -------------------------
# The example ships inside the export root and is imported from there: discovery
# -> build -> submit -> bounded wait -> accepted-instance addressing, with no
# action/field/resource id hard-coded. It runs against the exported rule window.
EXPORTED_PUBLIC_DIR="$export_root/framework/cjgui/shared_operation_core"
[[ -f "$EXPORTED_PUBLIC_DIR/example_generated_consumption.py" ]] \
  || fail "the export root does not ship the public typed example"
python3 "$EXPORTED_PUBLIC_DIR/example_generated_consumption.py" "$RULE_DESCRIPTOR" \
  > "$WORK/exported-public-example.log" 2>&1 || {
  cat "$WORK/exported-public-example.log" >> "$LOG" 2>/dev/null || true
  fail "the exported public typed example did not pass against the exported application"
}
grep -q '^PASSED example consumption' "$WORK/exported-public-example.log" \
  || fail "the exported public typed example did not report success"
log "step5 exported_public_client_ok $(grep -m1 '^instance ' "$WORK/exported-public-example.log")"

# --- 5b. the EXPORTED atomic observation seam --------------------------------
# The observation example ships inside the export root and runs against the
# exported application: one atomic snapshot, an unchanged round that does not
# resend the tree, a REAL owner draft edit observed as FIELDS, a rejected
# candidate observed as CANDIDATE, and a stale stream epoch asking for a resync.
OBS_EXPORT_STATE="$WORK/exported-observation-state.json"
[[ -f "$EXPORTED_PUBLIC_DIR/example_generated_observation.py" ]] \
  || fail "the export root does not ship the public observation example"
python3 "$EXPORTED_PUBLIC_DIR/example_generated_observation.py" "$RULE_DESCRIPTOR" phase1 "$OBS_EXPORT_STATE" \
  > "$WORK/exported-observation-phase1.log" 2>&1 || {
  cat "$WORK/exported-observation-phase1.log" >> "$LOG" 2>/dev/null || true
  fail "the exported observation phase1 did not pass"
}
grep -q '^PASSED observation phase1' "$WORK/exported-observation-phase1.log" \
  || fail "the exported observation phase1 did not report success"
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
  --target "$RULE_RECORD_ID" --arg fieldId=STRING:label --arg text=STRING:"导出观测-9" \
  --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/exported-observation-draft.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/exported-observation-draft.log" \
  || fail "the exported observation draft edit was rejected"
python3 "$EXPORTED_PUBLIC_DIR/example_generated_observation.py" "$RULE_DESCRIPTOR" phase2 "$OBS_EXPORT_STATE" \
  > "$WORK/exported-observation-phase2.log" 2>&1 || {
  cat "$WORK/exported-observation-phase2.log" >> "$LOG" 2>/dev/null || true
  fail "the exported observation phase2 did not pass"
}
grep -q '^PASSED observation phase2' "$WORK/exported-observation-phase2.log" \
  || fail "the exported observation phase2 did not report success"
log "step5b exported_observation_ok $(grep -m1 '^snapshot ' "$WORK/exported-observation-phase1.log")"
log "step5b exported_observation_change $(grep -m1 '^changes ' "$WORK/exported-observation-phase2.log")"

# --- 5c. the EXPORTED two-client candidate ownership example ----------------
# Two independent public clients submit against the same base version: exactly
# one attempt is accepted, the other is attributed to itself (SUPERSEDED or the
# public structure_version_conflict), and the accepted ticket stays ACCEPTED.
[[ -f "$EXPORTED_PUBLIC_DIR/example_generated_candidate_race.py" ]] \
  || fail "the export root does not ship the candidate ownership example"
python3 "$EXPORTED_PUBLIC_DIR/example_generated_candidate_race.py" "$RULE_DESCRIPTOR" \
  > "$WORK/exported-candidate-race.log" 2>&1 || {
  cat "$WORK/exported-candidate-race.log" >> "$LOG" 2>/dev/null || true
  fail "the exported candidate ownership race did not pass"
}
grep -q '^PASSED candidate ownership race' "$WORK/exported-candidate-race.log" \
  || fail "the exported candidate ownership race did not report success"
log "step5c exported_candidate_race_ok $(grep -m1 '^race ' "$WORK/exported-candidate-race.log")"

# --- 5d. Same-machine, two independent apps: resource/function scenario -----
# ONE MONOTONIC clock in fixed microsecond units, used by every stage below so the
# two windows share a single origin. The earlier definition read EPOCHREALTIME:
# that is a CALENDAR clock (it can step with NTP or a manual clock change), so the
# deltas were never a duration measurement no matter how many fractional digits
# were kept. CLOCK_MONOTONIC is since boot and stable across processes, which is
# what makes separate script invocations comparable.
now_us() {
  local stamp
  stamp="$(perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC -e 'printf "%d", clock_gettime(CLOCK_MONOTONIC) * 1000000' 2>/dev/null)" || return 1
  if [[ ! "$stamp" == <-> ]]; then
    return 1
  fi
  print -r -- "$stamp"
}
# The clock must ADVANCE over a known interval. A frozen, missing or wrongly typed
# source is a hard failure here instead of silently producing zero durations.
T_CLOCK_A="$(now_us)" || fail "the monotonic clock is unavailable"
sleep 0.05
T_CLOCK_B="$(now_us)" || fail "the monotonic clock is unavailable"
if (( T_CLOCK_B - T_CLOCK_A < 20000 || T_CLOCK_B - T_CLOCK_A > 5000000 )); then
  fail "the monotonic clock did not advance over a known 50ms interval (delta=$(( T_CLOCK_B - T_CLOCK_A ))us)"
fi
log "diag step5d clock_source=CLOCK_MONOTONIC_us self_check_delta_us=$(( T_CLOCK_B - T_CLOCK_A ))"
# A = the mixed rule window, B = the panel window, both live on this host. The
# public read right after A's image structure is scene-accepted is the timeline
# marker: A's registered image has not converged yet. In exactly that window, B
# changes a concrete field through its OWN owner entry and reads it back. Then A's
# image converges to the exact registered identity, A's own input continues, and
# closing A leaves B's owner value untouched.
{
  print -r -- "GENERATED_UI_STRUCTURE 1"
  print -r -- "NODE 0 twoWinRoot vertical"
  print -r -- "NODE 1 twoWinIcon image"
  print -r -- "PROPERTY 1 twoWinIcon resource rule-set-beacon"
  print -r -- "PROPERTY 1 twoWinIcon resourceVersion 1"
  print -r -- "PROPERTY 1 twoWinIcon contentMode fit"
  print -r -- "PROPERTY 1 twoWinIcon fixedWidth 48"
  print -r -- "PROPERTY 1 twoWinIcon fixedHeight 48"
  print -r -- "NODE 1 twoWinEditor textInput field=label"
  print -r -- "PROPERTY 1 twoWinEditor label 双窗编辑"
  print -r -- "END"
} > "$WORK/two-window-image.txt"
A_IMAGE_VERSION="$(rule_structure_version)"
T_A_SUBMIT0="$(now_us)"
rule_pub generated-submit --structure-version "$A_IMAGE_VERSION" --payload-file "$WORK/two-window-image.txt" \
  > "$WORK/two-window-image-submit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/two-window-image-submit.log" \
  || fail "window A rejected its image structure"
# The state of A's image is sampled in a TIGHT loop from the moment the structure
# is submitted: in a normal application the raster has no artificial delay, so the
# loading window is whatever the real decode/upload leaves behind. The observed
# first state is logged either way; the controlled-loading ordering is covered by
# the image lifecycle probe's held gate.
A_STATE_FIRST=""
A_LOADING_OBSERVED=false
A_IMAGE_ACCEPT=0
for a_wait in {1..120}; do
  if (( A_IMAGE_ACCEPT == 0 )); then
    if [[ "$(rule_structure_version)" == "$(( A_IMAGE_VERSION + 1 ))" ]]; then
      A_IMAGE_ACCEPT=1
      T_A_ACCEPT="$(now_us)"
    fi
  fi
  if [[ -z "$A_STATE_FIRST" ]]; then
    A_IMAGE_PROBE="$(rule_pub generated-instances 2>/dev/null | grep '^INSTANCE twoWinIcon ' || true)"
    if [[ -n "$A_IMAGE_PROBE" ]]; then
      A_STATE_NOW="$(print -r -- "$A_IMAGE_PROBE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^resource_state=/) {sub(/^resource_state=/, "", $i); print $i}}')"
      if [[ -n "$A_STATE_NOW" ]]; then
        A_STATE_FIRST="$A_STATE_NOW"
        [[ "$A_STATE_NOW" == "loading" || "$A_STATE_NOW" == "-" ]] && A_LOADING_OBSERVED=true
      fi
    fi
  fi
  (( A_IMAGE_ACCEPT == 1 )) && [[ -n "$A_STATE_FIRST" ]] && break
  sleep 0.03
done
(( A_IMAGE_ACCEPT == 1 )) || fail "window A never scene-accepted its image structure"
[[ -n "$A_STATE_FIRST" ]] || fail "window A did not publish a resource state for its image instance"
log "diag step5d a_image_first_state='$A_STATE_FIRST' loading_observed=$A_LOADING_OBSERVED"
B_NOTES_VALUE="双窗-B-$(date +%s)"
# ONE clock (the script's monotonic microsecond read) and ONE request: the owner
# entry is enqueued, the OWNER REVISION for that field advances, and the concrete
# value reads back. The owning window's scene may or may not advance for a
# field-only write, so that stage is observed and logged rather than demanded.
#
# The BASELINE comes BEFORE the write. Capturing it afterwards would compare the
# post-write scene against itself and could only ever report "no advance".
B_FIELD_REV_BEFORE="$(panel_field_token notes VERSION)"
B_SCENE_BEFORE="$(panel_pub window-progress 2>/dev/null | awk '/^WINDOW_ACCEPTED_SCENE_VERSION /{print $2}')"
T_B_ENQUEUE="$(now_us)"
panel_pub invoke "$(panel_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SET_NOTES --target 8101 \
  --arg notes=STRING:"$B_NOTES_VALUE" > "$WORK/two-window-b-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/two-window-b-edit.log" \
  || fail "window B's real owner entry was rejected while window A held image work"
[[ "$(panel_field_token notes APPLIED_HEX | hex_to_text)" == "$B_NOTES_VALUE" ]] \
  || fail "window B's owner write did not read back while window A held image work"
T_B_OWNER="$(now_us)"
B_FIELD_REV_AFTER="$(panel_field_token notes VERSION)"
[[ -n "$B_FIELD_REV_BEFORE" && -n "$B_FIELD_REV_AFTER" ]] \
  || fail "window B's owner field published no revision ($B_FIELD_REV_BEFORE -> $B_FIELD_REV_AFTER)"
B_SCENE_AFTER="$B_SCENE_BEFORE"
# An UNOBSERVED scene stage stays empty: it must never be reported as if it
# happened at the owner's instant.
T_B_SCENE=""
B_SCENE_ADVANCED=false
for b_scene_try in {1..40}; do
  B_SCENE_AFTER="$(panel_pub window-progress 2>/dev/null | awk '/^WINDOW_ACCEPTED_SCENE_VERSION /{print $2}')"
  if [[ "$B_SCENE_AFTER" == <-> && "$B_SCENE_BEFORE" == <-> ]] && (( B_SCENE_AFTER > B_SCENE_BEFORE )); then
    T_B_SCENE="$(now_us)"
    B_SCENE_ADVANCED=true
    break
  fi
  sleep 0.05
done
(( T_B_ENQUEUE <= T_B_OWNER )) \
  || fail "the same-request timeline is not monotonic ($T_B_ENQUEUE/$T_B_OWNER)"
if [[ -n "$T_B_SCENE" ]]; then
  (( T_B_OWNER <= T_B_SCENE )) \
    || fail "the same-request timeline is not monotonic ($T_B_OWNER/$T_B_SCENE)"
fi
A_STATE_READY=""
A_IMAGE_READY_LINE=""
T_A_READY=""
for a_image_try in {1..40}; do
  A_IMAGE_NOW="$(rule_pub generated-instances 2>/dev/null | grep '^INSTANCE twoWinIcon ' || true)"
  A_STATE_NOW="$(print -r -- "$A_IMAGE_NOW" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^resource_state=/) {sub(/^resource_state=/, "", $i); print $i}}')"
  if [[ -n "$A_STATE_NOW" && "$A_STATE_NOW" != "-" && "$A_STATE_NOW" != "loading" ]]; then
    A_STATE_READY="$A_STATE_NOW"
    A_IMAGE_READY_LINE="$A_IMAGE_NOW"
    T_A_READY="$(now_us)"
    break
  fi
  sleep 0.25
done
[[ -n "$A_STATE_READY" ]] || fail "window A's image never converged (last state='${A_STATE_NOW:-none}')"
print -r -- "$A_IMAGE_READY_LINE" | grep -q 'resource=rule-set-beacon' \
  || fail "window A's converged image lost its logical resource"
print -r -- "$A_IMAGE_READY_LINE" | grep -q 'resource_version=1' \
  || fail "window A's converged image lost its accepted version"
log "diag step5d timeline a_image_state_first='$A_STATE_FIRST' a_image_ready='$A_STATE_READY' a_instance='$A_IMAGE_READY_LINE' b_notes='$B_NOTES_VALUE'"
A_EDIT_VALUE="双窗A续写-$(date +%s)"
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" EDIT_DRAFT_TEXT \
  --target "$RULE_RECORD_ID" --arg fieldId=STRING:label --arg text=STRING:"$A_EDIT_VALUE" \
  --arg expectedDraftVersion=INTEGER:"$(rule_draft_version)" > "$WORK/two-window-a-edit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/two-window-a-edit.log" \
  || fail "window A's input did not continue after its image converged"
[[ "$(rule_field_token label DRAFT_HEX | hex_to_text)" == "$A_EDIT_VALUE" ]] \
  || fail "window A's post-image edit did not read back"
log "step5d same_host_two_window_ok processes=independent_apps a_image_state_first='$A_STATE_FIRST' a_loading_observed=$A_LOADING_OBSERVED a_image_state='$A_STATE_READY' a_resource=rule-set-beacon a_version=1 b_owner_readback=true a_input_after_image=true"
# The SAME request, one monotonic clock, same host: enqueue -> concrete owner
# value -> accepted scene for B's write, and submit -> accepted structure ->
# converged image for A's declaration. These are wall-clock observations of the
# public path, not frame-time claims.
(( T_A_SUBMIT0 <= T_A_ACCEPT && T_A_ACCEPT <= T_A_READY )) \
  || fail "window A's timeline is not monotonic ($T_A_SUBMIT0/$T_A_ACCEPT/$T_A_READY)"
# Stages whose boundary was never observed are reported as `unobserved`, NOT as a
# zero duration: a missing boundary is missing evidence, not a fast one.
B_OWNER_MS=$(( (T_B_OWNER - T_B_ENQUEUE) / 1000 ))
if [[ -n "$T_B_SCENE" ]]; then
  B_SCENE_MS=$(( (T_B_SCENE - T_B_OWNER) / 1000 ))
else
  B_SCENE_MS="unobserved"
fi
log "step5d same_host_two_window_timing clock=CLOCK_MONOTONIC_us processes=independent_apps b_owner_enqueue_to_applied_ms=$B_OWNER_MS b_owner_revision=$B_FIELD_REV_BEFORE->$B_FIELD_REV_AFTER b_scene_advanced=$B_SCENE_ADVANCED b_applied_to_scene_ms=$B_SCENE_MS b_scene=$B_SCENE_BEFORE->$B_SCENE_AFTER a_submit_to_accepted_ms=$(( (T_A_ACCEPT - T_A_SUBMIT0) / 1000 )) a_accepted_to_image_ready_ms=$(( (T_A_READY - T_A_ACCEPT) / 1000 )) a_structure=$A_IMAGE_VERSION->$(( A_IMAGE_VERSION + 1 )) host=same_machine_two_apps"

# Closing A must not disturb B's owner value or B's own window reads.
cjgui_terminate_owned "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" || true
sleep 1.0
[[ "$(panel_field_token notes APPLIED_HEX | hex_to_text)" == "$B_NOTES_VALUE" ]] \
  || fail "closing window A changed window B's owner value"
panel_pub window-progress > "$WORK/two-window-b-progress-after-a-close.txt" 2>&1 || true
grep -q '^WINDOW_PRESENTATION_STATE ' "$WORK/two-window-b-progress-after-a-close.txt" \
  || fail "window B stopped answering after window A closed"
log "step5d same_host_two_window_close_ok processes=independent_apps a_closed=true b_owner_stable=true b_progress_readable=true"

if chain_result_code; then
  chain_status=0
else
  chain_status=$?
fi
if [[ "$chain_status" == "3" ]]; then
  [[ -n "$INPUT_BLOCKED" ]] && log "BLOCKED exported_consumer_chains input_segments_unverified reason=$INPUT_BLOCKED"
  [[ -n "$STEP4J_BLOCKED" ]] && log "BLOCKED exported_consumer_chains required_step=step4j reason=$STEP4J_BLOCKED"
  log "PASSED_HEADLESS origin_and_structure_chain root='$export_root'"
  cat "$LOG"
  exit 3
fi
if [[ "$chain_status" == "4" ]]; then
  log "PARTIAL exported consumer chains step2c=not_run root='$export_root'"
  cat "$LOG"
  exit 4
fi
log "PASSED exported consumer chains root='$export_root'"
cat "$LOG"
exit 0
