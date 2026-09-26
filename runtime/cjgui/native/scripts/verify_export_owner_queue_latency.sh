#!/usr/bin/env zsh
# Public-client latency observation on ONE rule window driven only through its
# public UDS client.
#
#   1. enqueue      - the external request is written to the connection
#   2. owner applied- the owner's own version / draft value advanced
#   3. scene accepted- the window's accepted structure version advanced
#
# SCOPE (corrected): this runs a SINGLE rule window. Step 2 (owner modify) and
# step 3 (structure submit) are two DIFFERENT operations timed separately, so
# their numbers may NOT be added or read as one request's owner -> scene stages,
# and this is NOT a same-host two-window fixture. Timestamps come from
# `time.time()` wall-clock milliseconds plus a public polling loop, so the raw
# samples and p50/p95/max are automation-cost observations; they are functional
# readback evidence, NOT a rendering-performance conclusion. Comparable
# build/layout/submit work has to come from the window's MonoTime/refresh-timing
# counters on a same-load fixture.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_QUEUE_LATENCY_TMPDIR:-/private/tmp/cjgui-queue-latency}"
SAMPLES="${CJGUI_QUEUE_LATENCY_SAMPLES:-12}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/queue-latency.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

NAME_TOKEN="CJGUIRuleSet"
BUNDLE_TOKEN="org.cangjie.cjgui.rule-set.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Queue${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}Queue${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}Queue${RUN_TAG}"
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
waited=0
while (( waited < 150 )); do
  DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$STDOUT_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]] && break
  sleep 2; waited=$(( waited + 2 ))
done
[[ -f "${DESCRIPTOR:-}" ]] || fail "app did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "app descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "app pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR samples=$SAMPLES"

CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
business_version() { pub get 2>/dev/null | awk '/^VERSION /{print $2}'; }
structure_version() { pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
draft_version() { pub generated-fields 2>/dev/null | awk '/^FIELD label /{for(i=1;i<=NF;i++) if ($i=="VERSION") print $(i+1); exit}'; }
# The owner-applied boundary is observed on the VALUE the owner now holds, not on
# a version number that could belong to any field.
draft_text() {
  pub generated-fields 2>/dev/null | awk '/^FIELD label /{for(i=1;i<=NF;i++) if ($i=="DRAFT_HEX") print $(i+1); exit}' \
    | python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'
}

# The record the round edits, created through the same public entry.
pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"时延基线" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"queue-create" \
  > "$WORK/create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/create.log" || fail "record creation failed"
RECORD_ID="$(pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2}' | head -1)"
[[ -n "$RECORD_ID" ]] || fail "created record not visible"

now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }
typeset -a OWNER_MS ACCEPT_MS
OWNER_MS=()
ACCEPT_MS=()

sample=0
while (( sample < SAMPLES )); do
  # --- boundary 1: a real business request through the public connection -----
  local_draft="$(draft_version)"
  enqueue="$(now_ms)"
  pub invoke "$(business_version)" EDIT_DRAFT_TEXT --target "$RECORD_ID" \
    --arg fieldId=STRING:label --arg text=STRING:"时延样本${sample}" \
    --arg expectedDraftVersion=INTEGER:"$local_draft" > "$WORK/owner-$sample.log" 2>&1 || true
  applied=""
  waited=0
  while (( waited < 200 )); do
    [[ "$(draft_text)" == "时延样本${sample}" ]] && { applied="$(now_ms)"; break; }
    sleep 0.01; waited=$(( waited + 1 ))
  done
  [[ -n "$applied" ]] || fail "the owner never applied sample $sample (request log: $(tail -1 "$WORK/owner-$sample.log"))"
  OWNER_MS+=($(( applied - enqueue )))

  # --- boundary 2: a real structure submission, accepted by the scene --------
  cat > "$WORK/s-$sample.txt" <<STRUCT
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 nameField textInput field=label
PROPERTY 1 nameField label 时延字段${sample}
END
STRUCT
  structure_before="$(structure_version)"
  enqueue2="$(now_ms)"
  pub generated-submit --structure-version "$structure_before" --payload-file "$WORK/s-$sample.txt" \
    > "$WORK/submit-$sample.log" 2>&1 || true
  grep -q '^CANDIDATE_ACCEPTED true' "$WORK/submit-$sample.log" || \
    fail "sample $sample candidate was not received (log: $(tail -1 "$WORK/submit-$sample.log"))"
  accepted=""
  waited=0
  while (( waited < 200 )); do
    [[ "$(structure_version)" != "$structure_before" ]] && { accepted="$(now_ms)"; break; }
    sleep 0.01; waited=$(( waited + 1 ))
  done
  [[ -n "$accepted" ]] || fail "sample $sample was never scene-accepted"
  ACCEPT_MS+=($(( accepted - enqueue2 )))
  sample=$(( sample + 1 ))
done

stats() { # stats <label> <values...>
  local label="$1"; shift
  python3 - "$label" "$@" <<'PY'
import statistics
import sys
label = sys.argv[1]
values = sorted(int(v) for v in sys.argv[2:])
def pct(p):
    rank = max(1, (p * len(values) + 99) // 100)
    return values[rank - 1]
print("%s n=%d raw=%s p50=%d p95=%d max=%d min=%d"
      % (label, len(values), ",".join(str(v) for v in values), pct(50), pct(95), values[-1], values[0]))
PY
}
stats "owner_applied_ms" "${OWNER_MS[@]}" >> "$LOG"
stats "scene_accepted_ms" "${ACCEPT_MS[@]}" >> "$LOG"

# --- quiet period: no further owner or scene movement without a request ------
quiet_version="$(business_version)"
quiet_structure="$(structure_version)"
sleep 3
[[ "$(business_version)" == "$quiet_version" ]] || fail "the owner moved without a request"
[[ "$(structure_version)" == "$quiet_structure" ]] || fail "the scene moved without a request"
log "quiet_period_ok owner_version=$quiet_version structure_version=$quiet_structure"

log "PASSED public_client_latency_observation (samples=$SAMPLES single_window=true owner_and_structure_are_separate_operations=true not_two_window=true clock=time.time_ms scope=automation_cost_not_rendering_performance)"
cat "$LOG"
exit 0
