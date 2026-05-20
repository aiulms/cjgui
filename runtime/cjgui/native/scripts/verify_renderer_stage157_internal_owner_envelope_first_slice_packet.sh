#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage157 internal owner envelope packet。它消费
# stage156 readiness packet，并输出非变更 owner-local envelope 证据。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE157_PACKET_TMPDIR:-/tmp/cjgui-stage157-internal-owner-envelope-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage157_internal_owner_envelope_first_slice_owner.sh"
STAGE156_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage156_renderer_state_write_first_slice_readiness_contract_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE156_LOG="$TMP_DIR/stage156.log"
RESULT_PACKET="$TMP_DIR/stage157-internal-owner-envelope-first-slice.packet"
STAGE156_SUITE_PACKET="${CJGUI_STAGE156_RENDERER_STATE_WRITE_READINESS_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage156"
: > "$OWNER_LOG"
: > "$STAGE156_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE156_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage157 internal owner envelope packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage157 internal owner envelope packet: syntax check failed $script" >&2
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
    echo "cjgui stage157 internal owner envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage157 internal owner envelope packet: owner probe failed" >&2
  echo "cjgui stage157 internal owner envelope packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage157_internal_owner_envelope_owner_present=true" \
  "stage156_readiness_contract_required=true" \
  "owner_local_renderer_state_envelope_materialized=true" \
  "owner_local_result_shapes_prepared=true" \
  "internal_owner_envelope_ready=true" \
  "internal_owner_envelope_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage156_input_mode="generated_stage156_suite_packet"
if [[ -n "$STAGE156_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE156_SUITE_PACKET" ]]; then
    echo "cjgui stage157 internal owner envelope packet: provided stage156 suite packet missing $STAGE156_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage156_suite_packet_used=true" > "$STAGE156_LOG"
  stage156_input_mode="provided_stage156_suite_packet"
else
  if ! env CJGUI_STAGE156_TMPDIR="$TMP_DIR/stage156" zsh "$STAGE156_SUITE_SCRIPT" > "$STAGE156_LOG" 2>&1; then
    echo "cjgui stage157 internal owner envelope packet: stage156 suite failed" >&2
    echo "cjgui stage157 internal owner envelope packet: log=$STAGE156_LOG" >&2
    exit 8
  fi
  STAGE156_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE156_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE156_SUITE_PACKET" || ! -f "$STAGE156_SUITE_PACKET" ]]; then
  echo "cjgui stage157 internal owner envelope packet: missing stage156 suite packet" >&2
  exit 9
fi
for fact in \
  "stage156_renderer_state_write_first_slice_readiness_contract_suite_passed=true" \
  "renderer_state_write_first_slice_readiness_contract_ready=true" \
  "renderer_state_write_first_slice_source_ready=true" \
  "renderer_state_write_first_slice_precondition_ledger_materialized=true" \
  "renderer_state_write_positive_dry_run_candidate_defined=true" \
  "renderer_state_write_first_slice_predicates_satisfied=false" \
  "renderer_state_write_first_slice_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE156_SUITE_PACKET" "$fact"
done

stage156_route="$(fact_value "$STAGE156_SUITE_PACKET" "renderer_state_write_first_slice_route_classification")"
stage156_runtime_admitted="$(fact_value "$STAGE156_SUITE_PACKET" "renderer_state_write_first_slice_runtime_admitted")"
stage156_runtime_admitted="${stage156_runtime_admitted:-false}"
owner_route="internal_owner_envelope_blocked_stage156_runtime_admission"
if [[ "$stage156_route" == "renderer_state_write_first_slice_readiness_contract_blocked_host_metal_device_unavailable" ]]; then
  owner_route="internal_owner_envelope_blocked_host_metal_device_unavailable"
elif [[ "$stage156_runtime_admitted" == "true" ]]; then
  owner_route="internal_owner_envelope_ready_for_mutation_dry_run"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage157 internal owner envelope packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage157_internal_owner_envelope_packet_version=1"
  echo "stage156_input_mode=$stage156_input_mode"
  echo "stage156_suite_packet=$STAGE156_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage156_log=$STAGE156_LOG"
  echo "stage156_readiness_contract_consumed=true"
  echo "stage156_renderer_state_write_first_slice_route_classification=$stage156_route"
  echo "stage156_renderer_state_write_first_slice_runtime_admitted=$stage156_runtime_admitted"
  echo "internal_owner_envelope_route_classification=$owner_route"
  echo "internal_owner_envelope_ready=true"
  echo "internal_owner_envelope_source_ready=true"
  echo "internal_owner_envelope_runtime_admitted=false"
  echo "owner_local_renderer_state_envelope_materialized=true"
  echo "owner_local_result_shapes_prepared=true"
  echo "mutation_request_result_shape_prepared=true"
  echo "visibility_publication_result_shape_prepared=true"
  echo "rollback_visibility_result_shape_prepared=true"
  echo "mutation_dry_run_input_prepared=true"
  echo "renderer_state_write_first_slice_predicates_satisfied=false"
  echo "renderer_state_write_first_slice_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage158_mutation_dry_run_envelope_after_stage157"
  echo "stage157_internal_owner_envelope_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage157 internal owner envelope packet: route_classification=$owner_route"
echo "cjgui stage157 internal owner envelope packet: internal_owner_envelope_packet_path=$RESULT_PACKET"
echo "cjgui stage157 internal owner envelope packet: renderer_state_write=false"
