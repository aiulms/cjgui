#!/usr/bin/env zsh
# Bounded negative control for the export chain's PRE-REGISTRATION cleanup.
#
# The failure it pins: an instance starts but dies (or never answers) before the
# ready/ownership handshake registers it. Registering the round-unique identity
# BEFORE launch must let cleanup reclaim exactly that process, while a control
# instance outside this round's registered identities stays alive and responsive.
#
# Identity shape, not a window: the two processes are stand-ins whose executable
# path is a round-unique name inside their own directory, which is the identity
# the shared helper resolves. The window-level evidence is the real export chain;
# this control only proves the reclamation rule and its discrimination.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${CJGUI_PRELAUNCH_CLEANUP_TMPDIR:-/private/tmp/cjgui-prelaunch-cleanup}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK/lost-round" "$WORK/control-round"
LOG="$WORK/control.log"
: > "$LOG"
log() { print -r -- "$*" | tee -a "$LOG"; }
fail() { log "FAIL $*"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

LOST_EXEC="$WORK/lost-round/CJGUIPrelaunchLost${RUN_TAG}"
CONTROL_EXEC="$WORK/control-round/CJGUIPrelaunchControl${RUN_TAG}"
for target in "$LOST_EXEC" "$CONTROL_EXEC"; do
  cat > "$target" <<'STUB'
#!/bin/zsh
while true; do sleep 1; done
STUB
  chmod +x "$target"
done

( "$LOST_EXEC" > /dev/null 2>&1 & )
( "$CONTROL_EXEC" > /dev/null 2>&1 & )
sleep 1
LOST_PID="$(cjgui_unique_round_pid "$LOST_EXEC" "$WORK/lost-round" || true)"
CONTROL_PID="$(cjgui_unique_round_pid "$CONTROL_EXEC" "$WORK/control-round" || true)"
[[ -n "$LOST_PID" ]] || fail "lost stand-in did not start"
[[ -n "$CONTROL_PID" ]] || fail "control stand-in did not start"
log "started lost=$LOST_PID control=$CONTROL_PID (neither reached a handshake)"

cleanup() {
  # Only the lost identity is registered as a candidate, exactly like a round
  # that failed before register_round.
  typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
  CANDIDATE_EXECS=("$LOST_EXEC")
  CANDIDATE_DIRS=("$WORK/lost-round")
  CANDIDATE_DESCS=("")
  cjgui_reclaim_candidates log
}
trap cleanup EXIT

cleanup
trap - EXIT
if kill -0 "$LOST_PID" 2>/dev/null; then
  fail "pre-registration candidate was not reclaimed (pid $LOST_PID still alive)"
fi
log "lost_stand_in_reclaimed=true"

# The control instance is NOT in this round's candidate list: it must be
# untouched and still resolvable by its own identity.
if ! kill -0 "$CONTROL_PID" 2>/dev/null; then
  fail "control instance was reclaimed although it was never registered"
fi
RESOLVED_CONTROL="$(cjgui_unique_round_pid "$CONTROL_EXEC" "$WORK/control-round" || true)"
[[ "$RESOLVED_CONTROL" == "$CONTROL_PID" ]] || \
  fail "control instance identity no longer resolves ($RESOLVED_CONTROL vs $CONTROL_PID)"
log "control_instance_untouched=true pid=$CONTROL_PID"

# Reclaim the control by its own identity so the control leaves nothing behind.
cjgui_terminate_owned "$CONTROL_PID" "" "$CONTROL_EXEC" "$WORK/control-round" || true
if kill -0 "$CONTROL_PID" 2>/dev/null; then
  fail "control instance could not be reclaimed by its own identity"
fi
log "control_instance_reclaimed_by_own_identity=true"
log "PASSED pre-registration cleanup (candidate reclaimed, unregistered control untouched)"
exit 0
