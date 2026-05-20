#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage164 rollback publication packet，消费 stage163
# executor dry-run suite packet 并输出 visibility publication result 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE164_PACKET_TMPDIR:-/tmp/cjgui-stage164-renderer-state-write-rollback-publication-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage164_renderer_state_write_rollback_publication_first_slice_owner.sh"
STAGE163_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage163_renderer_state_write_executor_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE163_LOG="$TMP_DIR/stage163.log"
RESULT_PACKET="$TMP_DIR/stage164-renderer-state-write-rollback-publication-first-slice.packet"
STAGE163_SUITE_PACKET="${CJGUI_STAGE163_RENDERER_STATE_WRITE_EXECUTOR_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage163"
: > "$OWNER_LOG"
: > "$STAGE163_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE163_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage164 renderer-state write rollback publication packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage164 renderer-state write rollback publication packet: syntax check failed $script" >&2
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
    echo "cjgui stage164 renderer-state write rollback publication packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage164 renderer-state write rollback publication packet: owner probe failed" >&2
  echo "cjgui stage164 renderer-state write rollback publication packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage164_renderer_state_write_rollback_publication_owner_present=true" \
  "stage163_renderer_state_write_executor_dry_run_required=true" \
  "renderer_state_write_rollback_publication_result_materialized=true" \
  "renderer_state_write_rollback_publication_boundary_bound=true" \
  "renderer_state_write_visibility_publication_result_input_prepared=true" \
  "renderer_state_write_rollback_publication_ready=true" \
  "renderer_state_write_rollback_publication_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage163_input_mode="generated_stage163_suite_packet"
if [[ -n "$STAGE163_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE163_SUITE_PACKET" ]]; then
    echo "cjgui stage164 renderer-state write rollback publication packet: provided stage163 suite packet missing $STAGE163_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage163_suite_packet_used=true" > "$STAGE163_LOG"
  stage163_input_mode="provided_stage163_suite_packet"
else
  if ! env CJGUI_STAGE163_TMPDIR="$TMP_DIR/stage163" zsh "$STAGE163_SUITE_SCRIPT" > "$STAGE163_LOG" 2>&1; then
    echo "cjgui stage164 renderer-state write rollback publication packet: stage163 suite failed" >&2
    echo "cjgui stage164 renderer-state write rollback publication packet: log=$STAGE163_LOG" >&2
    exit 8
  fi
  STAGE163_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE163_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE163_SUITE_PACKET" || ! -f "$STAGE163_SUITE_PACKET" ]]; then
  echo "cjgui stage164 renderer-state write rollback publication packet: missing stage163 suite packet" >&2
  exit 9
fi
for fact in \
  "stage163_renderer_state_write_executor_dry_run_suite_passed=true" \
  "renderer_state_write_executor_dry_run_ready=true" \
  "renderer_state_write_executor_dry_run_source_ready=true" \
  "renderer_state_write_executor_dry_run_runtime_admitted=false" \
  "renderer_state_write_rollback_publication_result_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE163_SUITE_PACKET" "$fact"
done

stage163_route="$(fact_value "$STAGE163_SUITE_PACKET" "renderer_state_write_executor_dry_run_route_classification")"
stage163_runtime_admitted="$(fact_value "$STAGE163_SUITE_PACKET" "renderer_state_write_executor_dry_run_runtime_admitted")"
stage163_runtime_admitted="${stage163_runtime_admitted:-false}"
rollback_route="renderer_state_write_rollback_publication_blocked_stage163_runtime_admission"
if [[ "$stage163_route" == *"host_metal_device_unavailable" ]]; then
  rollback_route="renderer_state_write_rollback_publication_blocked_host_metal_device_unavailable"
elif [[ "$stage163_runtime_admitted" == "true" ]]; then
  rollback_route="renderer_state_write_rollback_publication_ready_for_visibility_publication"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage164 renderer-state write rollback publication packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage164_renderer_state_write_rollback_publication_packet_version=1"
  echo "stage163_input_mode=$stage163_input_mode"
  echo "stage163_suite_packet=$STAGE163_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage163_log=$STAGE163_LOG"
  echo "stage163_renderer_state_write_executor_dry_run_consumed=true"
  echo "stage163_renderer_state_write_executor_dry_run_route_classification=$stage163_route"
  echo "stage163_renderer_state_write_executor_dry_run_runtime_admitted=$stage163_runtime_admitted"
  echo "renderer_state_write_rollback_publication_route_classification=$rollback_route"
  echo "renderer_state_write_rollback_publication_ready=true"
  echo "renderer_state_write_rollback_publication_source_ready=true"
  echo "renderer_state_write_rollback_publication_runtime_admitted=false"
  echo "renderer_state_write_rollback_publication_result_materialized=true"
  echo "renderer_state_write_rollback_publication_boundary_bound=true"
  echo "renderer_state_write_visibility_publication_result_input_prepared=true"
  echo "renderer_state_write_rollback_publication_non_mutating=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage165_renderer_state_write_visibility_publication_first_slice_after_rollback_publication"
  echo "stage164_renderer_state_write_rollback_publication_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage164 renderer-state write rollback publication packet: route_classification=$rollback_route"
echo "cjgui stage164 renderer-state write rollback publication packet: renderer_state_write_rollback_publication_packet_path=$RESULT_PACKET"
echo "cjgui stage164 renderer-state write rollback publication packet: renderer_state_write=false"
