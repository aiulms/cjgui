#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage162 precommit visibility boundary packet。它消费
# stage161 ledger，输出 executor first-slice 的非 public 前置输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE162_PACKET_TMPDIR:-/tmp/cjgui-stage162-renderer-state-write-precommit-visibility-boundary-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage162_renderer_state_write_precommit_visibility_boundary_first_slice_owner.sh"
STAGE161_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage161_renderer_state_write_admission_ledger_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE161_LOG="$TMP_DIR/stage161.log"
RESULT_PACKET="$TMP_DIR/stage162-renderer-state-write-precommit-visibility-boundary-first-slice.packet"
STAGE161_SUITE_PACKET="${CJGUI_STAGE161_RENDERER_STATE_WRITE_ADMISSION_LEDGER_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage161"
: > "$OWNER_LOG"
: > "$STAGE161_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE161_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: syntax check failed $script" >&2
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
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage162 renderer-state write precommit visibility boundary packet: owner probe failed" >&2
  echo "cjgui stage162 renderer-state write precommit visibility boundary packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage162_renderer_state_write_precommit_visibility_boundary_owner_present=true" \
  "stage161_renderer_state_write_admission_ledger_required=true" \
  "renderer_state_write_precommit_visibility_boundary_materialized=true" \
  "renderer_state_write_precommit_rollback_stop_line_bound=true" \
  "renderer_state_write_executor_first_slice_input_prepared=true" \
  "renderer_state_write_precommit_visibility_boundary_ready=true" \
  "renderer_state_write_precommit_visibility_boundary_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage161_input_mode="generated_stage161_suite_packet"
if [[ -n "$STAGE161_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE161_SUITE_PACKET" ]]; then
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: provided stage161 suite packet missing $STAGE161_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage161_suite_packet_used=true" > "$STAGE161_LOG"
  stage161_input_mode="provided_stage161_suite_packet"
else
  if ! env CJGUI_STAGE161_TMPDIR="$TMP_DIR/stage161" zsh "$STAGE161_SUITE_SCRIPT" > "$STAGE161_LOG" 2>&1; then
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: stage161 suite failed" >&2
    echo "cjgui stage162 renderer-state write precommit visibility boundary packet: log=$STAGE161_LOG" >&2
    exit 8
  fi
  STAGE161_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE161_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE161_SUITE_PACKET" || ! -f "$STAGE161_SUITE_PACKET" ]]; then
  echo "cjgui stage162 renderer-state write precommit visibility boundary packet: missing stage161 suite packet" >&2
  exit 9
fi
for fact in \
  "stage161_renderer_state_write_admission_ledger_suite_passed=true" \
  "renderer_state_write_admission_ledger_ready=true" \
  "renderer_state_write_admission_ledger_source_ready=true" \
  "renderer_state_write_admission_ledger_runtime_admitted=false" \
  "renderer_state_write_admission_ledger_materialized=true" \
  "renderer_state_write_precommit_visibility_boundary_input_prepared=true" \
  "renderer_state_write_admission_predicates_satisfied=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE161_SUITE_PACKET" "$fact"
done

stage161_route="$(fact_value "$STAGE161_SUITE_PACKET" "renderer_state_write_admission_ledger_route_classification")"
stage161_runtime_admitted="$(fact_value "$STAGE161_SUITE_PACKET" "renderer_state_write_admission_ledger_runtime_admitted")"
stage161_runtime_admitted="${stage161_runtime_admitted:-false}"
precommit_route="renderer_state_write_precommit_visibility_boundary_blocked_stage161_runtime_admission"
if [[ "$stage161_route" == "renderer_state_write_admission_ledger_blocked_host_metal_device_unavailable" ]]; then
  precommit_route="renderer_state_write_precommit_visibility_boundary_blocked_host_metal_device_unavailable"
elif [[ "$stage161_runtime_admitted" == "true" ]]; then
  precommit_route="renderer_state_write_precommit_visibility_boundary_ready_for_executor_first_slice"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage162 renderer-state write precommit visibility boundary packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage162_renderer_state_write_precommit_visibility_boundary_packet_version=1"
  echo "stage161_input_mode=$stage161_input_mode"
  echo "stage161_suite_packet=$STAGE161_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage161_log=$STAGE161_LOG"
  echo "stage161_renderer_state_write_admission_ledger_consumed=true"
  echo "stage161_renderer_state_write_admission_ledger_route_classification=$stage161_route"
  echo "stage161_renderer_state_write_admission_ledger_runtime_admitted=$stage161_runtime_admitted"
  echo "renderer_state_write_precommit_visibility_boundary_route_classification=$precommit_route"
  echo "renderer_state_write_precommit_visibility_boundary_ready=true"
  echo "renderer_state_write_precommit_visibility_boundary_source_ready=true"
  echo "renderer_state_write_precommit_visibility_boundary_runtime_admitted=false"
  echo "renderer_state_write_precommit_visibility_boundary_materialized=true"
  echo "renderer_state_write_precommit_visibility_boundary_internal_only=true"
  echo "renderer_state_write_precommit_rollback_stop_line_bound=true"
  echo "renderer_state_write_executor_first_slice_input_prepared=true"
  echo "renderer_state_write_precommit_predicates_satisfied=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage163_renderer_state_write_executor_first_slice_dry_run_after_precommit_visibility_boundary"
  echo "stage162_renderer_state_write_precommit_visibility_boundary_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage162 renderer-state write precommit visibility boundary packet: route_classification=$precommit_route"
echo "cjgui stage162 renderer-state write precommit visibility boundary packet: renderer_state_write_precommit_visibility_boundary_packet_path=$RESULT_PACKET"
echo "cjgui stage162 renderer-state write precommit visibility boundary packet: renderer_state_write=false"
