#!/usr/bin/env zsh
# Bounded negative controls for the common-definition acceptance script's EXIT
# CLASSIFICATION (not a re-run of the desktop matrix).
#
# The accepted behaviour is:
#   * a failed assertion                  -> FAIL  (exit 1)
#   * a real control input not delivered  -> FAIL  (exit 1), never exit 0
#   * a proven environment/tool limit     -> BLOCKED (exit 3), with the
#     independent semantic segments still reported as valid
#
# Each case injects exactly one classification through the script's documented
# `CJGUI_ACCEPTANCE_INJECT` hook and checks both the exit code and the log line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACCEPTANCE="$SCRIPT_DIR/verify_common_definition_acceptance.sh"
OUTPUT_DIR="${CJGUI_ACCEPTANCE_EXIT_TMPDIR:-/private/tmp/cjgui-acceptance-exit-paths}"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" | tee -a "$LOG"; }
fail() { log "FAIL $*"; exit 1; }

run_case() { # run_case <inject> <expected-exit> <expected-log-marker>
  local inject="$1" expected="$2" marker="$3"
  local case_log="$WORK/case-$inject.log"
  CJGUI_ACCEPTANCE_INJECT="$inject" zsh "$ACCEPTANCE" > "$case_log" 2>&1
  local rc=$?
  if [[ "$rc" -ne "$expected" ]]; then
    log "FAIL case inject=$inject exit=$rc (want $expected) log=$case_log"
    tail -12 "$case_log" | sed 's/^/    /'
    return 1
  fi
  if ! grep -q "$marker" "$case_log"; then
    log "FAIL case inject=$inject missing marker '$marker' log=$case_log"
    tail -12 "$case_log" | sed 's/^/    /'
    return 1
  fi
  log "case inject=$inject exit=$rc marker_ok='$marker' log=$case_log"
  return 0
}

# A failed assertion propagates as FAIL.
run_case fail 1 "^FAIL injected assertion failure" || fail "assertion-failure propagation broken"
# An undelivered real control input propagates as FAIL, not PASS and not BLOCKED.
run_case undelivered 1 "^FAIL desktop_control_input_not_delivered" || fail "undelivered-input propagation broken"
# A proven environment/tool limitation propagates as BLOCKED, and the semantic
# segments still complete (their lines are present before the BLOCKED line).
run_case blocked 3 "^BLOCKED desktop_input reason=session_locked" || fail "blocked propagation broken"
grep -q "^step11 redeclaration_mode=startup_flag" "$WORK/case-blocked.log" || \
  fail "blocked path did not still run the independent semantic segments"

log "PASSED acceptance exit-path classification (fail=1 undelivered=1 blocked=3, semantic segments still valid when blocked)"
exit 0
