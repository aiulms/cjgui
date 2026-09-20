#!/usr/bin/env zsh
# Stage acceptance sweep for the runtime-generated-UI milestone.
#
# One entry point that runs the milestone's acceptance scripts in order and
# reports an honest PASS / FAIL / BLOCKED summary. The individual scripts stay
# the source of truth for what is asserted; this driver only sequences them,
# keeps their logs, and separates "not verifiable in the current session"
# from "verified".
#
# The six interaction scripts below need real synthesized input or the
# accessibility bridge to reach the application. When the session is locked
# (loginwindow frontmost) those tools cannot reach any app window, so the
# driver records them as BLOCKED instead of turning an environment property
# into a red verdict. BLOCKED is never a pass: run the driver again from an
# unlocked session to finish the acceptance.
#
# Usage: zsh verify_runtime_generated_ui_acceptance.sh
#   CJGUI_ACCEPTANCE_SWEEP_TMPDIR  output directory (default /private/tmp/...)
#   CJGUI_ACCEPTANCE_FORCE_DESKTOP=1  run the interaction scripts even when the
#                                     session looks locked (they will fail)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_ACCEPTANCE_SWEEP_TMPDIR:-/private/tmp/cjgui-acceptance-sweep}/$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$OUTPUT_DIR"
LOG="$OUTPUT_DIR/sweep.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

# Scripts that need no window at all: they verify the verification premises
# (clipboard guard contract, instance-ownership rules) and always run.
HEADLESS_SCRIPTS=(
  verify_clipboard_guard_semantics.sh
  verify_instance_lib_semantics.sh
  verify_composable_transfer_ledger_judge.sh
)

# Scripts that drive a real window but read only window/public state; they
# work with a locked screen because AppKit still accepts scene submissions.
WINDOW_SCRIPTS=(
  verify_common_definition_acceptance.sh
  verify_generated_ui_chain.sh
  verify_generated_ui_second_consumer.sh
  verify_composable_data_transfer_window_integration.sh
  # Cross-layer payload regression: a pointer-originated activation carries its
  # gesture's modifiers through native -> queue -> FFI -> window -> controller,
  # a keyboard/AX activation carries none, and the Command-A navigation intent
  # reaches the controller. Needs a window but no desktop input.
  verify_composable_ui_modifier_payload.sh
  # Generated candidate + native submission failure: the candidate must roll
  # back without publishing, the old structure must stay addressable, and a
  # fresh candidate must commit afterwards.
  verify_composable_ui_generated_commit.sh
  # Real NSEvents (arrows, Home/End, Shift- and Command-modified chords) through
  # NSApplication into the production keyDown path: focus-only movement, Shift
  # ranges, expand/collapse, select-all and text-scope isolation.
  verify_composable_ui_keyboard_navigation.sh
  # Final export consumption: exports to a path with spaces, builds and runs
  # the UI-only tree consumer plus both generated consumers from that export.
  verify_framework_preview_consumer_chains.sh
)
# Scripts that need synthesized input or the accessibility bridge. They report
# their own environment block with exit 3 (for example when the host does not
# deliver synthetic keyboard or mouse-modifier state), which this driver keeps
# distinct from a failed verdict.
INTERACTION_SCRIPTS=(
  # The 100-record chain's public/external half runs anywhere, but its human
  # step (real row click + typing + apply in the same instance) needs a desktop;
  # the sweep runs it in that mode so a missing desktop is reported as BLOCKED.
  verify_tree_shared_selection_chain.sh
  verify_generated_ui_human_action.sh
  verify_generated_ui_human_input.sh
  verify_tree_human_selection.sh
  verify_tree_modifier_click_selection.sh
  # Real CGEvent keyboard chain: click focus, arrows, Left/Right collapse and
  # expand, Home/End, Command-A, off-screen reveal and text-field isolation.
  verify_tree_keyboard_navigation.sh
  verify_tree_consumer_human_rows.sh
  verify_composable_data_transfer_cross_window.sh
  verify_shared_document_transfer_chain.sh
  verify_instance_isolation.sh
)

frontmost_process() {
  cjgui_ax 10 -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null | tail -1 || true
}

# Desktop availability, reported as one concrete state instead of collapsing
# every failure into "locked":
#   locked         the session lock flag says so, or the frontmost process is
#                  the login window (positive evidence);
#   ax_unavailable the accessibility bridge returned nothing and no lock
#                  evidence exists -- that is a driver limitation, NOT a lock;
#   unlocked       the bridge answered with a real application.
# A synthesized-input assertion is never reported as PASS while any of these
# is not `unlocked`.
desktop_state() {
  local state front
  # The lock flag can disappear from the IORegistry (for example once the
  # session is unlocked, or while that registry node is being rebuilt). A
  # missing flag is not an error: it falls through to the accessibility probe.
  state="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
  state="${state//[[:space:]]/}"
  if [[ "$state" == "Yes" ]]; then
    print -r -- "locked"
    return 0
  fi
  front="$(frontmost_process || true)"
  if [[ "$front" == "loginwindow" ]]; then
    print -r -- "locked"
    return 0
  fi
  if [[ -z "$front" ]]; then
    print -r -- "ax_unavailable"
    return 0
  fi
  print -r -- "unlocked"
}

DESKTOP_STATE="unlocked"
if [[ "${CJGUI_ACCEPTANCE_FORCE_DESKTOP:-0}" != "1" ]]; then
  DESKTOP_STATE="$(desktop_state)"
fi
log "=== acceptance sweep $(date '+%Y-%m-%d %H:%M:%S') desktop=$DESKTOP_STATE ==="

pass=0
fail=0
blocked=0
run_script() { # run_script <script> [NAME=VALUE ...]
  local script="$1"; shift
  run_script_as "$script" "${script%.sh}" "$@"
}

# Same runner with an explicit label, so one script can contribute two distinct
# checks (for example its headless classification and its desktop chain).
run_script_as() { # run_script_as <script> <label> [NAME=VALUE ...]
  local script="$1" name="$2"; shift 2
  local started=$SECONDS
  local rc=0
  (cd "$SCRIPT_DIR" && env "$@" zsh "$script") > "$OUTPUT_DIR/$name.log" 2>&1 || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    log "PASS $name ($((SECONDS - started))s)"
    pass=$((pass + 1))
  elif [[ "$rc" -eq 3 ]]; then
    log "BLOCKED $name (exit 3, condition: $(tail -1 "$OUTPUT_DIR/$name.log"))"
    blocked=$((blocked + 1))
  else
    log "FAIL $name (exit $rc, log=$OUTPUT_DIR/$name.log)"
    fail=$((fail + 1))
  fi
}

for script in "${HEADLESS_SCRIPTS[@]}"; do
  run_script "$script"
done

# The isolation driver's failure-classification matrix and its clipboard-guard
# semantics are environment-independent, so they are exercised even when the
# desktop chain below is skipped for a locked session.
run_script_as verify_instance_isolation.sh verify_instance_isolation_classification CJGUI_ISOLATION_HEADLESS_ONLY=1

for script in "${WINDOW_SCRIPTS[@]}"; do
  run_script "$script"
done

if [[ "$DESKTOP_STATE" != "unlocked" ]]; then
  for script in "${INTERACTION_SCRIPTS[@]}"; do
    log "BLOCKED ${script%.sh} (desktop_state=$DESKTOP_STATE; the synthesized-input/accessibility assertion did not run)"
    blocked=$((blocked + 1))
  done
else
  for script in "${INTERACTION_SCRIPTS[@]}"; do
    if [[ "$script" == "verify_tree_shared_selection_chain.sh" ]]; then
      run_script "$script" CHAIN_DESKTOP_STEP=1
    else
      run_script "$script"
    fi
  done
fi

# Real single-id leak run of the integration probe: the negative control for
# the transfer owner chain (its own log, not a second copy of the script).
LEAK_LOG="$OUTPUT_DIR/integration_leak.log"
LEAK_RC=0
(cd "$SCRIPT_DIR" && CJGUI_TRANSFER_LEAK_TEST=5 zsh verify_composable_data_transfer_window_integration.sh) > "$LEAK_LOG" 2>&1 || LEAK_RC=$?
if [[ "$LEAK_RC" -eq 0 ]]; then
  log "PASS integration_leak (CJGUI_TRANSFER_LEAK_TEST=5)"
  pass=$((pass + 1))
elif [[ "$LEAK_RC" -eq 3 ]]; then
  log "BLOCKED integration_leak (exit 3, condition: $(tail -1 "$LEAK_LOG"))"
  blocked=$((blocked + 1))
else
  log "FAIL integration_leak (exit $LEAK_RC, log=$LEAK_LOG)"
  fail=$((fail + 1))
fi

log "SWEEP pass=$pass fail=$fail blocked=$blocked desktop_state=$DESKTOP_STATE"
if [[ "$blocked" -gt 0 ]]; then
  log "NOTE blocked checks are NOT verified; each blocked log names its concrete condition"
fi
log "logs=$OUTPUT_DIR"
cat "$LOG"
# Exit contract: any product/verification failure is a red verdict; a sweep
# with only unverifiable (BLOCKED) items exits 3; 0 means every targeted
# assertion actually ran and passed.
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
if [[ "$blocked" -gt 0 ]]; then
  exit 3
fi
exit 0
