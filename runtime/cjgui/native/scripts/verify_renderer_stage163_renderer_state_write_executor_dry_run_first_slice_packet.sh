#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage163 executor dry-run packet，消费 stage162
# precommit visibility boundary suite packet 并输出下一跳 rollback publication 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE163_PACKET_TMPDIR:-/tmp/cjgui-stage163-renderer-state-write-executor-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage163_renderer_state_write_executor_dry_run_first_slice_owner.sh"
STAGE162_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage162_renderer_state_write_precommit_visibility_boundary_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE162_LOG="$TMP_DIR/stage162.log"
RESULT_PACKET="$TMP_DIR/stage163-renderer-state-write-executor-dry-run-first-slice.packet"
STAGE162_SUITE_PACKET="${CJGUI_STAGE162_RENDERER_STATE_WRITE_PRECOMMIT_VISIBILITY_BOUNDARY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage162"
: > "$OWNER_LOG"
: > "$STAGE162_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE162_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage163 renderer-state write executor dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage163 renderer-state write executor dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage163 renderer-state write executor dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage163 renderer-state write executor dry-run packet: owner probe failed" >&2
  echo "cjgui stage163 renderer-state write executor dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage163_renderer_state_write_executor_dry_run_owner_present=true" \
  "stage162_renderer_state_write_precommit_visibility_boundary_required=true" \
  "renderer_state_write_executor_dry_run_result_envelope_materialized=true" \
  "renderer_state_write_guarded_executor_result_envelope_prepared=true" \
  "renderer_state_write_rollback_publication_result_input_prepared=true" \
  "renderer_state_write_executor_dry_run_ready=true" \
  "renderer_state_write_executor_dry_run_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage162_input_mode="generated_stage162_suite_packet"
if [[ -n "$STAGE162_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE162_SUITE_PACKET" ]]; then
    echo "cjgui stage163 renderer-state write executor dry-run packet: provided stage162 suite packet missing $STAGE162_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage162_suite_packet_used=true" > "$STAGE162_LOG"
  stage162_input_mode="provided_stage162_suite_packet"
else
  if ! env CJGUI_STAGE162_TMPDIR="$TMP_DIR/stage162" zsh "$STAGE162_SUITE_SCRIPT" > "$STAGE162_LOG" 2>&1; then
    echo "cjgui stage163 renderer-state write executor dry-run packet: stage162 suite failed" >&2
    echo "cjgui stage163 renderer-state write executor dry-run packet: log=$STAGE162_LOG" >&2
    exit 8
  fi
  STAGE162_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE162_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE162_SUITE_PACKET" || ! -f "$STAGE162_SUITE_PACKET" ]]; then
  echo "cjgui stage163 renderer-state write executor dry-run packet: missing stage162 suite packet" >&2
  exit 9
fi
for fact in \
  "stage162_renderer_state_write_precommit_visibility_boundary_suite_passed=true" \
  "renderer_state_write_precommit_visibility_boundary_ready=true" \
  "renderer_state_write_precommit_visibility_boundary_source_ready=true" \
  "renderer_state_write_precommit_visibility_boundary_runtime_admitted=false" \
  "renderer_state_write_executor_first_slice_input_prepared=true" \
  "renderer_state_write_precommit_predicates_satisfied=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE162_SUITE_PACKET" "$fact"
done

stage162_route="$(fact_value "$STAGE162_SUITE_PACKET" "renderer_state_write_precommit_visibility_boundary_route_classification")"
stage162_runtime_admitted="$(fact_value "$STAGE162_SUITE_PACKET" "renderer_state_write_precommit_visibility_boundary_runtime_admitted")"
stage162_runtime_admitted="${stage162_runtime_admitted:-false}"
executor_route="renderer_state_write_executor_dry_run_blocked_stage162_runtime_admission"
if [[ "$stage162_route" == *"host_metal_device_unavailable" ]]; then
  executor_route="renderer_state_write_executor_dry_run_blocked_host_metal_device_unavailable"
elif [[ "$stage162_runtime_admitted" == "true" ]]; then
  executor_route="renderer_state_write_executor_dry_run_ready_for_rollback_publication"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage163 renderer-state write executor dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage163_renderer_state_write_executor_dry_run_packet_version=1"
  echo "stage162_input_mode=$stage162_input_mode"
  echo "stage162_suite_packet=$STAGE162_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage162_log=$STAGE162_LOG"
  echo "stage162_renderer_state_write_precommit_visibility_boundary_consumed=true"
  echo "stage162_renderer_state_write_precommit_visibility_boundary_route_classification=$stage162_route"
  echo "stage162_renderer_state_write_precommit_visibility_boundary_runtime_admitted=$stage162_runtime_admitted"
  echo "renderer_state_write_executor_dry_run_route_classification=$executor_route"
  echo "renderer_state_write_executor_dry_run_ready=true"
  echo "renderer_state_write_executor_dry_run_source_ready=true"
  echo "renderer_state_write_executor_dry_run_runtime_admitted=false"
  echo "renderer_state_write_executor_dry_run_result_envelope_materialized=true"
  echo "renderer_state_write_guarded_executor_result_envelope_prepared=true"
  echo "renderer_state_write_rollback_publication_result_input_prepared=true"
  echo "renderer_state_write_executor_dry_run_non_mutating=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage164_renderer_state_write_rollback_publication_first_slice_after_executor_dry_run"
  echo "stage163_renderer_state_write_executor_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage163 renderer-state write executor dry-run packet: route_classification=$executor_route"
echo "cjgui stage163 renderer-state write executor dry-run packet: renderer_state_write_executor_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage163 renderer-state write executor dry-run packet: renderer_state_write=false"
