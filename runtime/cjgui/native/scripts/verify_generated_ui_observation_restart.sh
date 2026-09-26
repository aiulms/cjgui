#!/usr/bin/env zsh
# Endpoint-restart acceptance for the generated-UI observation seam.
#
# A client that observed cursor C on endpoint A cannot be served incrementally
# by a DIFFERENT endpoint B: the stream epoch and cursor space are not the same,
# and the old cache must be discarded in favour of a fresh snapshot. This script
# proves that with two real application instances (own bundle id, exec name,
# directory and descriptor each), reclaimed by exact identity.
#
#   1. launch instance A, take an atomic snapshot, record (stream_epoch, cursor);
#   2. close A and verify it really exited (its descriptor/endpoint is gone);
#   3. launch instance B with a NEW identity and the SAME rule application;
#   4. seed the OLD (epoch, cursor) into a fresh public client connected to B and
#      require: the increment is refused (RESYNC_REQUIRED or a different stream
#      epoch) and a fresh snapshot is taken from B.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_OBSERVATION_RESTART_TMPDIR:-/private/tmp/cjgui-observation-restart}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/restart.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

OBS_EXAMPLE="$RUNTIME_DIR/shared_operation_core/example_generated_observation.py"
OBS_STATE="$WORK/restart-state.json"
APP_PIDS=()
DESCRIPTORS=()
ROUND_DIRS=()
ROUND_EXECS=()

cleanup() {
  local index=1
  while (( index <= ${#APP_PIDS} )); do
    if [[ -n "${APP_PIDS[index]}" ]]; then
      cjgui_terminate_owned "${APP_PIDS[index]}" "${DESCRIPTORS[index]}" \
        "${ROUND_EXECS[index]}" "${ROUND_DIRS[index]}" || true
    fi
    index=$(( index + 1 ))
  done
}
trap cleanup EXIT

launch_instance() { # launch_instance <suffix>
  local suffix="$1"
  # The copy helper rewrites the launcher's BASE name token with the suffix, so
  # the base must be the token the template actually contains.
  local name_token="CJGUIRuleSet"
  local app_suffix="Obs${suffix}${RUN_TAG}"
  local bundle_token="org.cangjie.cjgui.rule-set.example"
  local round_dir="$WORK/round-${suffix}"
  cjgui_prepare_app_copy "$APP_DIR" "$round_dir" "$RUNTIME_DIR" "$name_token" "$app_suffix" \
    "$bundle_token" || fail "per-round application copy ($suffix) failed"
  local round_exec="$round_dir/target/release/${name_token}${app_suffix}.app/Contents/MacOS/${name_token}${app_suffix}"
  local stdout_log="$WORK/app-${suffix}.log"
  local started_before="$(date +%s)"
  ( cd "$round_dir" && nohup zsh run.sh > "$stdout_log" 2>&1 & )
  local descriptor
  descriptor="$(cjgui_wait_descriptor "$stdout_log" 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' 150 || true)"
  [[ -f "${descriptor:-}" ]] || fail "instance $suffix did not publish a descriptor"
  local pid
  pid="$(cjgui_descriptor_owner_pid "$descriptor" "$round_exec" "$round_dir" "$started_before" || true)"
  [[ -n "$pid" ]] || fail "instance $suffix descriptor has no matching owner"
  cjgui_pid_owns "$pid" "$descriptor" "$round_exec" "$round_dir" \
    || fail "instance $suffix pid is not this round's instance"
  APP_PIDS+=("$pid")
  DESCRIPTORS+=("$descriptor")
  ROUND_DIRS+=("$round_dir")
  ROUND_EXECS+=("$round_exec")
  log "launched_instance suffix=$suffix pid=$pid descriptor=$descriptor owner_verified=descriptor+exec+dir"
}

# --- 1. instance A: one atomic snapshot, then record its cursor --------------
launch_instance A
python3 "$OBS_EXAMPLE" "${DESCRIPTORS[1]}" phase1 "$OBS_STATE" > "$WORK/phase1.log" 2>&1 || {
  cat "$WORK/phase1.log" >> "$LOG" 2>/dev/null || true
  fail "instance A observation phase1 did not pass"
}
grep -q '^PASSED observation phase1' "$WORK/phase1.log" \
  || fail "instance A observation phase1 did not report success"
OBS_EPOCH="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["stream_epoch"])' "$OBS_STATE")"
OBS_CURSOR="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["cursor"])' "$OBS_STATE")"
log "step1 instance_a_observed epoch=$OBS_EPOCH cursor=$OBS_CURSOR"

# --- 2. close A and prove it is gone ----------------------------------------
A_PID="${APP_PIDS[1]}"; A_DESCRIPTOR="${DESCRIPTORS[1]}"
A_DIR="${ROUND_DIRS[1]}"; A_EXEC="${ROUND_EXECS[1]}"
cjgui_terminate_owned "$A_PID" "$A_DESCRIPTOR" "$A_EXEC" "$A_DIR" || fail "instance A did not shut down"
cjgui_pid_owns "$A_PID" "$A_DESCRIPTOR" "$A_EXEC" "$A_DIR" \
  && fail "instance A still owns its identity after shutdown"
# A terminated process cannot remove its own descriptor; reclaim the exact
# directory of this round's instance (own identity only) and verify the
# endpoint is really gone.
rm -rf "$(dirname "$A_DESCRIPTOR")"
[[ -f "$A_DESCRIPTOR" ]] && fail "instance A descriptor survived shutdown"
APP_PIDS[1]=""; DESCRIPTORS[1]=""; ROUND_EXECS[1]=""; ROUND_DIRS[1]=""
log "step2 instance_a_closed pid=$A_PID descriptor_removed=true"

# --- 3. instance B: new identity, same application ---------------------------
launch_instance B

# --- 4. the old cursor cannot be served by the new endpoint ------------------
python3 "$OBS_EXAMPLE" "${DESCRIPTORS[2]}" phase4 "$OBS_STATE" "$OBS_EPOCH" "$OBS_CURSOR" \
  > "$WORK/phase4.log" 2>&1 || {
  cat "$WORK/phase4.log" >> "$LOG" 2>/dev/null || true
  fail "the restarted-endpoint observation did not pass"
}
grep -q '^PASSED observation phase4' "$WORK/phase4.log" \
  || fail "the restarted-endpoint observation did not report success"
log "step4 restart_ok $(grep -m1 '^restart ' "$WORK/phase4.log")"

log "PASSED observation endpoint restart (old_cursor_epoch=$OBS_EPOCH old_cursor=$OBS_CURSOR)"
cat "$LOG"
exit 0
