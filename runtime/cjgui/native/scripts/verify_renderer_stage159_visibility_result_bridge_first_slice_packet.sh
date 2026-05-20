#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage159 visibility result bridge packet。它消费
# stage158 dry-run envelope，输出下一阶段 state-write first-slice readiness。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE159_PACKET_TMPDIR:-/tmp/cjgui-stage159-visibility-result-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage159_visibility_result_bridge_first_slice_owner.sh"
STAGE158_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage158_mutation_dry_run_envelope_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE158_LOG="$TMP_DIR/stage158.log"
RESULT_PACKET="$TMP_DIR/stage159-visibility-result-bridge-first-slice.packet"
STAGE158_SUITE_PACKET="${CJGUI_STAGE158_MUTATION_DRY_RUN_ENVELOPE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage158"
: > "$OWNER_LOG"
: > "$STAGE158_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE158_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage159 visibility result bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage159 visibility result bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage159 visibility result bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage159 visibility result bridge packet: owner probe failed" >&2
  echo "cjgui stage159 visibility result bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage159_visibility_result_bridge_owner_present=true" \
  "stage158_mutation_dry_run_envelope_required=true" \
  "visibility_result_publication_readiness_materialized=true" \
  "renderer_state_write_first_slice_readiness_output_prepared=true" \
  "visibility_result_bridge_ready=true" \
  "visibility_result_bridge_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage158_input_mode="generated_stage158_suite_packet"
if [[ -n "$STAGE158_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE158_SUITE_PACKET" ]]; then
    echo "cjgui stage159 visibility result bridge packet: provided stage158 suite packet missing $STAGE158_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage158_suite_packet_used=true" > "$STAGE158_LOG"
  stage158_input_mode="provided_stage158_suite_packet"
else
  if ! env CJGUI_STAGE158_TMPDIR="$TMP_DIR/stage158" zsh "$STAGE158_SUITE_SCRIPT" > "$STAGE158_LOG" 2>&1; then
    echo "cjgui stage159 visibility result bridge packet: stage158 suite failed" >&2
    echo "cjgui stage159 visibility result bridge packet: log=$STAGE158_LOG" >&2
    exit 8
  fi
  STAGE158_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE158_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE158_SUITE_PACKET" || ! -f "$STAGE158_SUITE_PACKET" ]]; then
  echo "cjgui stage159 visibility result bridge packet: missing stage158 suite packet" >&2
  exit 9
fi
for fact in \
  "stage158_mutation_dry_run_envelope_suite_passed=true" \
  "mutation_dry_run_envelope_ready=true" \
  "mutation_dry_run_source_ready=true" \
  "mutation_dry_run_runtime_admitted=false" \
  "guarded_executor_dry_run_input_prepared=true" \
  "visibility_result_bridge_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE158_SUITE_PACKET" "$fact"
done

stage158_route="$(fact_value "$STAGE158_SUITE_PACKET" "mutation_dry_run_route_classification")"
stage158_runtime_admitted="$(fact_value "$STAGE158_SUITE_PACKET" "mutation_dry_run_runtime_admitted")"
stage158_runtime_admitted="${stage158_runtime_admitted:-false}"
visibility_route="visibility_result_bridge_blocked_stage158_runtime_admission"
if [[ "$stage158_route" == "mutation_dry_run_blocked_host_metal_device_unavailable" ]]; then
  visibility_route="visibility_result_bridge_blocked_host_metal_device_unavailable"
elif [[ "$stage158_runtime_admitted" == "true" ]]; then
  visibility_route="visibility_result_bridge_ready_for_state_write_first_slice"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage159 visibility result bridge packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage159_visibility_result_bridge_packet_version=1"
  echo "stage158_input_mode=$stage158_input_mode"
  echo "stage158_suite_packet=$STAGE158_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage158_log=$STAGE158_LOG"
  echo "stage158_mutation_dry_run_envelope_consumed=true"
  echo "stage158_mutation_dry_run_route_classification=$stage158_route"
  echo "stage158_mutation_dry_run_runtime_admitted=$stage158_runtime_admitted"
  echo "visibility_result_bridge_route_classification=$visibility_route"
  echo "visibility_result_bridge_ready=true"
  echo "visibility_result_bridge_source_ready=true"
  echo "visibility_result_bridge_runtime_admitted=false"
  echo "guarded_executor_dry_run_to_visibility_result_bridged=true"
  echo "visibility_result_publication_readiness_materialized=true"
  echo "visibility_result_publication_internal_only=true"
  echo "renderer_state_write_first_slice_readiness_output_prepared=true"
  echo "renderer_state_write_first_slice_next_input_prepared=true"
  echo "renderer_state_write_first_slice_predicates_satisfied=false"
  echo "renderer_state_write_first_slice_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage160_minimal_renderer_state_write_first_slice_dry_run_after_visibility_result_bridge"
  echo "stage159_visibility_result_bridge_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage159 visibility result bridge packet: route_classification=$visibility_route"
echo "cjgui stage159 visibility result bridge packet: visibility_result_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage159 visibility result bridge packet: renderer_state_write=false"
