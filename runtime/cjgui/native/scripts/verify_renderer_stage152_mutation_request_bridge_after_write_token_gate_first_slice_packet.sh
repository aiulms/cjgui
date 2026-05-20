#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage152 mutation request bridge packet。它消费
# stage151 write token gate 与 legacy mutation request result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE152_PACKET_TMPDIR:-/tmp/cjgui-stage152-mutation-request-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage152_mutation_request_bridge_after_write_token_gate_first_slice_owner.sh"
STAGE151_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice_suite.sh"
MUTATION_REQUEST_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE151_LOG="$TMP_DIR/stage151.log"
MUTATION_REQUEST_LOG="$TMP_DIR/mutation-request-result.log"
RESULT_PACKET="$TMP_DIR/stage152-mutation-request-bridge-after-write-token-gate.packet"
STAGE151_SUITE_PACKET="${CJGUI_STAGE151_WRITE_TOKEN_GATE_SUITE_PACKET:-}"
MUTATION_REQUEST_PACKET="${CJGUI_STAGE127_MUTATION_REQUEST_RESULT_ENVELOPE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage151" "$TMP_DIR/mutation-request"
: > "$OWNER_LOG"
: > "$STAGE151_LOG"
: > "$MUTATION_REQUEST_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE151_SUITE_SCRIPT" "$MUTATION_REQUEST_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage152 mutation request bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage152 mutation request bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage152 mutation request bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage152 mutation request bridge packet: owner probe failed" >&2
  echo "cjgui stage152 mutation request bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage152_mutation_request_bridge_after_write_token_gate_owner_present=true" \
  "stage151_write_token_gate_packet_required=true" \
  "legacy_mutation_request_result_envelope_required=true" \
  "mutation_request_shape_bound_to_stage151_write_token_gate=true" \
  "mutation_request_bridge_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage151_input_mode="generated_stage151_suite_packet"
if [[ -n "$STAGE151_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE151_SUITE_PACKET" ]]; then
    echo "cjgui stage152 mutation request bridge packet: provided stage151 suite packet missing $STAGE151_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage151_suite_packet_used=true" > "$STAGE151_LOG"
  stage151_input_mode="provided_stage151_suite_packet"
else
  if ! env CJGUI_STAGE151_TMPDIR="$TMP_DIR/stage151" zsh "$STAGE151_SUITE_SCRIPT" > "$STAGE151_LOG" 2>&1; then
    echo "cjgui stage152 mutation request bridge packet: stage151 suite failed" >&2
    echo "cjgui stage152 mutation request bridge packet: log=$STAGE151_LOG" >&2
    exit 8
  fi
  STAGE151_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE151_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE151_SUITE_PACKET" || ! -f "$STAGE151_SUITE_PACKET" ]]; then
  echo "cjgui stage152 mutation request bridge packet: missing stage151 suite packet" >&2
  exit 9
fi
for fact in \
  "stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice_suite_passed=true" \
  "renderer_state_write_token_gate_ready=true" \
  "renderer_state_write_token_allowed=false" \
  "state_mutation_request_blocked=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE151_SUITE_PACKET" "$fact"
done

mutation_request_input_mode="generated_legacy_mutation_request_result_packet"
if [[ -n "$MUTATION_REQUEST_PACKET" ]]; then
  if [[ ! -f "$MUTATION_REQUEST_PACKET" ]]; then
    echo "cjgui stage152 mutation request bridge packet: provided mutation request packet missing $MUTATION_REQUEST_PACKET" >&2
    exit 10
  fi
  echo "provided_mutation_request_result_packet_used=true" > "$MUTATION_REQUEST_LOG"
  mutation_request_input_mode="provided_legacy_mutation_request_result_packet"
else
  if ! env CJGUI_STAGE127_TMPDIR="$TMP_DIR/mutation-request" zsh "$MUTATION_REQUEST_PACKET_SCRIPT" > "$MUTATION_REQUEST_LOG" 2>&1; then
    echo "cjgui stage152 mutation request bridge packet: mutation request packet failed" >&2
    echo "cjgui stage152 mutation request bridge packet: log=$MUTATION_REQUEST_LOG" >&2
    exit 11
  fi
  MUTATION_REQUEST_PACKET="$(grep -Eo 'mutation_request_result_envelope_packet_path=[^[:space:]]+' "$MUTATION_REQUEST_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$MUTATION_REQUEST_PACKET" || ! -f "$MUTATION_REQUEST_PACKET" ]]; then
  echo "cjgui stage152 mutation request bridge packet: missing mutation request result packet" >&2
  exit 12
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true" \
  "mutation_request_shape_persisted_as_dry_run_fact=true" \
  "mutation_request_rejection_persisted_as_dry_run_fact=true" \
  "rollback_eligibility_blocked=true" \
  "guarded_state_write_executor_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$MUTATION_REQUEST_PACKET" "$fact"
done

stage151_route="$(fact_value "$STAGE151_SUITE_PACKET" "renderer_state_write_token_gate_route_classification")"
write_token_allowed="$(fact_value "$STAGE151_SUITE_PACKET" "renderer_state_write_token_allowed")"
write_token_allowed="${write_token_allowed:-false}"
mutation_bridge_route="mutation_request_bridge_source_ready_runtime_blocked_denied_write_token"
if [[ "$stage151_route" == "renderer_state_write_token_gate_denied_host_metal_device_unavailable" ]]; then
  mutation_bridge_route="mutation_request_bridge_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$stage151_route" == "renderer_state_write_token_gate_denied_missing_production_truth_recheck" ]]; then
  mutation_bridge_route="mutation_request_bridge_source_ready_runtime_blocked_missing_production_truth"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage152 mutation request bridge packet: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage152_mutation_request_bridge_after_write_token_gate_first_slice_packet_version=1"
  echo "stage151_input_mode=$stage151_input_mode"
  echo "mutation_request_input_mode=$mutation_request_input_mode"
  echo "stage151_suite_packet=$STAGE151_SUITE_PACKET"
  echo "legacy_mutation_request_result_packet=$MUTATION_REQUEST_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage151_log=$STAGE151_LOG"
  echo "mutation_request_log=$MUTATION_REQUEST_LOG"
  echo "stage151_write_token_gate_packet_consumed=true"
  echo "legacy_mutation_request_result_envelope_consumed=true"
  echo "stage151_write_token_gate_route_classification=$stage151_route"
  echo "renderer_state_write_token_allowed=$write_token_allowed"
  echo "mutation_request_bridge_ready=true"
  echo "mutation_request_bridge_source_ready=true"
  echo "mutation_request_bridge_runtime_admitted=false"
  echo "mutation_request_bridge_route_classification=$mutation_bridge_route"
  echo "mutation_request_shape_bound_to_stage151_write_token_gate=true"
  echo "mutation_request_rejection_bound_to_denied_write_token=true"
  echo "rollback_eligibility_bound_to_blocked_stage151=true"
  echo "guarded_state_write_executor_bridge_input_prepared=true"
  echo "guarded_state_write_executor_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=guarded_executor_bridge_after_mutation_request_bridge"
  echo "stage152_mutation_request_bridge_after_write_token_gate_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage152 mutation request bridge packet: route_classification=$mutation_bridge_route"
echo "cjgui stage152 mutation request bridge packet: mutation_request_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage152 mutation request bridge packet: renderer_state_write=false"
