#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage160 renderer-state write dry-run packet。它消费
# stage159 visibility result bridge，只输出非写入 dry-run envelope 与 admission 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE160_PACKET_TMPDIR:-/tmp/cjgui-stage160-renderer-state-write-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage160_renderer_state_write_dry_run_first_slice_owner.sh"
STAGE159_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage159_visibility_result_bridge_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE159_LOG="$TMP_DIR/stage159.log"
RESULT_PACKET="$TMP_DIR/stage160-renderer-state-write-dry-run-first-slice.packet"
STAGE159_SUITE_PACKET="${CJGUI_STAGE159_VISIBILITY_RESULT_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage159"
: > "$OWNER_LOG"
: > "$STAGE159_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE159_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage160 renderer-state write dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage160 renderer-state write dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage160 renderer-state write dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage160 renderer-state write dry-run packet: owner probe failed" >&2
  echo "cjgui stage160 renderer-state write dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage160_renderer_state_write_dry_run_owner_present=true" \
  "stage159_visibility_result_bridge_required=true" \
  "renderer_state_write_dry_run_envelope_materialized=true" \
  "renderer_state_write_dry_run_positive_predicate_map_materialized=true" \
  "renderer_state_write_admission_ledger_input_prepared=true" \
  "renderer_state_write_dry_run_ready=true" \
  "renderer_state_write_dry_run_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage159_input_mode="generated_stage159_suite_packet"
if [[ -n "$STAGE159_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE159_SUITE_PACKET" ]]; then
    echo "cjgui stage160 renderer-state write dry-run packet: provided stage159 suite packet missing $STAGE159_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage159_suite_packet_used=true" > "$STAGE159_LOG"
  stage159_input_mode="provided_stage159_suite_packet"
else
  if ! env CJGUI_STAGE159_TMPDIR="$TMP_DIR/stage159" zsh "$STAGE159_SUITE_SCRIPT" > "$STAGE159_LOG" 2>&1; then
    echo "cjgui stage160 renderer-state write dry-run packet: stage159 suite failed" >&2
    echo "cjgui stage160 renderer-state write dry-run packet: log=$STAGE159_LOG" >&2
    exit 8
  fi
  STAGE159_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE159_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE159_SUITE_PACKET" || ! -f "$STAGE159_SUITE_PACKET" ]]; then
  echo "cjgui stage160 renderer-state write dry-run packet: missing stage159 suite packet" >&2
  exit 9
fi
for fact in \
  "stage159_visibility_result_bridge_suite_passed=true" \
  "visibility_result_bridge_ready=true" \
  "visibility_result_bridge_source_ready=true" \
  "visibility_result_bridge_runtime_admitted=false" \
  "renderer_state_write_first_slice_next_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE159_SUITE_PACKET" "$fact"
done

stage159_route="$(fact_value "$STAGE159_SUITE_PACKET" "visibility_result_bridge_route_classification")"
stage159_runtime_admitted="$(fact_value "$STAGE159_SUITE_PACKET" "visibility_result_bridge_runtime_admitted")"
stage159_runtime_admitted="${stage159_runtime_admitted:-false}"
dry_run_route="renderer_state_write_dry_run_blocked_stage159_runtime_admission"
if [[ "$stage159_route" == "visibility_result_bridge_blocked_host_metal_device_unavailable" ]]; then
  dry_run_route="renderer_state_write_dry_run_blocked_host_metal_device_unavailable"
elif [[ "$stage159_runtime_admitted" == "true" ]]; then
  dry_run_route="renderer_state_write_dry_run_ready_for_admission_ledger"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage160 renderer-state write dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage160_renderer_state_write_dry_run_packet_version=1"
  echo "stage159_input_mode=$stage159_input_mode"
  echo "stage159_suite_packet=$STAGE159_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage159_log=$STAGE159_LOG"
  echo "stage159_visibility_result_bridge_consumed=true"
  echo "stage159_visibility_result_bridge_route_classification=$stage159_route"
  echo "stage159_visibility_result_bridge_runtime_admitted=$stage159_runtime_admitted"
  echo "renderer_state_write_dry_run_route_classification=$dry_run_route"
  echo "renderer_state_write_dry_run_ready=true"
  echo "renderer_state_write_dry_run_source_ready=true"
  echo "renderer_state_write_dry_run_runtime_admitted=false"
  echo "renderer_state_write_dry_run_envelope_materialized=true"
  echo "visibility_result_to_renderer_state_write_dry_run_bridged=true"
  echo "rollback_visibility_boundary_bound=true"
  echo "visibility_publication_boundary_bound=true"
  echo "renderer_state_write_dry_run_positive_predicate_map_materialized=true"
  echo "renderer_state_write_admission_ledger_input_prepared=true"
  echo "renderer_state_write_dry_run_non_mutating=true"
  echo "renderer_state_write_first_slice_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage161_renderer_state_write_admission_ledger_first_slice_after_dry_run"
  echo "stage160_renderer_state_write_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage160 renderer-state write dry-run packet: route_classification=$dry_run_route"
echo "cjgui stage160 renderer-state write dry-run packet: renderer_state_write_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage160 renderer-state write dry-run packet: renderer_state_write=false"
