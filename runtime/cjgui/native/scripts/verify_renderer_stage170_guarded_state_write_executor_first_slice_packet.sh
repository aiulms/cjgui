#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage170 guarded state-write executor packet，
# 消费 stage169 owner-local envelope suite packet，并输出 stage171 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE170_PACKET_TMPDIR:-/tmp/cjgui-stage170-guarded-state-write-executor-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage170_guarded_state_write_executor_first_slice_owner.sh"
STAGE169_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage169_owner_local_state_envelope_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE169_LOG="$TMP_DIR/stage169.log"
RESULT_PACKET="$TMP_DIR/stage170-guarded-state-write-executor-first-slice.packet"
STAGE169_SUITE_PACKET="${CJGUI_STAGE169_OWNER_LOCAL_STATE_ENVELOPE_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage169"
: > "$OWNER_LOG"
: > "$STAGE169_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE169_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage170 guarded state-write executor packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage170 guarded state-write executor packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage170 guarded state-write executor packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage170 guarded state-write executor packet: owner probe failed" >&2
  echo "cjgui stage170 guarded state-write executor packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage170_guarded_state_write_executor_owner_present=true" \
  "stage169_owner_local_state_envelope_dry_run_required=true" \
  "guarded_state_write_executor_execution_input_materialized=true" \
  "guarded_state_write_executor_result_envelope_materialized=true" \
  "owner_local_envelope_to_guarded_executor_bound=true" \
  "stage171_guarded_executor_result_boundary_input_prepared=true" \
  "guarded_state_write_executor_ready=true" \
  "guarded_state_write_executor_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage169_input_mode="generated_stage169_suite_packet"
if [[ -n "$STAGE169_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE169_SUITE_PACKET" ]]; then
    echo "cjgui stage170 guarded state-write executor packet: provided stage169 suite packet missing $STAGE169_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage169_suite_packet_used=true" > "$STAGE169_LOG"
  stage169_input_mode="provided_stage169_suite_packet"
else
  if ! env CJGUI_STAGE169_TMPDIR="$TMP_DIR/stage169" zsh "$STAGE169_SUITE_SCRIPT" > "$STAGE169_LOG" 2>&1; then
    echo "cjgui stage170 guarded state-write executor packet: stage169 suite failed" >&2
    echo "cjgui stage170 guarded state-write executor packet: log=$STAGE169_LOG" >&2
    exit 8
  fi
  STAGE169_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE169_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE169_SUITE_PACKET" || ! -f "$STAGE169_SUITE_PACKET" ]]; then
  echo "cjgui stage170 guarded state-write executor packet: missing stage169 suite packet" >&2
  exit 9
fi
for fact in \
  "stage169_owner_local_state_envelope_dry_run_suite_passed=true" \
  "owner_local_state_envelope_dry_run_ready=true" \
  "owner_local_state_envelope_dry_run_source_ready=true" \
  "owner_local_state_envelope_dry_run_runtime_admitted=false" \
  "stage170_guarded_state_write_executor_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE169_SUITE_PACKET" "$fact"
done

stage169_route="$(fact_value "$STAGE169_SUITE_PACKET" "owner_local_state_envelope_dry_run_route_classification")"
stage169_runtime_admitted="$(fact_value "$STAGE169_SUITE_PACKET" "owner_local_state_envelope_dry_run_runtime_admitted")"
stage169_runtime_admitted="${stage169_runtime_admitted:-false}"
executor_route="guarded_state_write_executor_blocked_owner_local_envelope_admission"
if [[ "$stage169_route" == *"host_metal_device_unavailable" ]]; then
  executor_route="guarded_state_write_executor_blocked_host_metal_device_unavailable"
elif [[ "$stage169_runtime_admitted" == "true" ]]; then
  executor_route="guarded_state_write_executor_ready_for_result_boundary"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage170 guarded state-write executor packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage170_guarded_state_write_executor_packet_version=1"
  echo "stage169_input_mode=$stage169_input_mode"
  echo "stage169_suite_packet=$STAGE169_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage169_log=$STAGE169_LOG"
  echo "stage169_owner_local_state_envelope_dry_run_consumed=true"
  echo "stage169_owner_local_state_envelope_dry_run_route_classification=$stage169_route"
  echo "stage169_owner_local_state_envelope_dry_run_runtime_admitted=$stage169_runtime_admitted"
  echo "guarded_state_write_executor_route_classification=$executor_route"
  echo "guarded_state_write_executor_ready=true"
  echo "guarded_state_write_executor_source_ready=true"
  echo "guarded_state_write_executor_runtime_admitted=false"
  echo "guarded_state_write_executor_execution_input_materialized=true"
  echo "guarded_state_write_executor_result_envelope_materialized=true"
  echo "owner_local_envelope_to_guarded_executor_bound=true"
  echo "rollback_visibility_boundaries_to_guarded_executor_bound=true"
  echo "guarded_state_write_executor_non_mutating=true"
  echo "guarded_state_write_executor_predicates_satisfied=false"
  echo "stage171_guarded_executor_result_boundary_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage171_guarded_executor_result_boundary_after_guarded_executor"
  echo "stage170_guarded_state_write_executor_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage170 guarded state-write executor packet: route_classification=$executor_route"
echo "cjgui stage170 guarded state-write executor packet: guarded_state_write_executor_packet_path=$RESULT_PACKET"
echo "cjgui stage170 guarded state-write executor packet: renderer_state_write=false"
