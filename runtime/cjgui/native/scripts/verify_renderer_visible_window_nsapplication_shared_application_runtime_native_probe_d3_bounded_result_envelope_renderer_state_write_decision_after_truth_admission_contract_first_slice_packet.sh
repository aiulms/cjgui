#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage144 renderer-state write decision packet。它消费
# stage143 truth-admission suite packet，并把缺失 truth / backend / write
# admission 显式映射为 write denial，不做任何状态写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE144_PACKET_TMPDIR:-/tmp/cjgui-stage144-renderer-state-write-decision-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_after_truth_admission_contract_first_slice_owner.sh"
STAGE143_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_truth_admission_after_first_frame_observation_contract_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE143_LOG="$TMP_DIR/stage143.log"
RESULT_PACKET="$TMP_DIR/stage144-renderer-state-write-decision-after-truth-admission-contract.packet"
STAGE143_SUITE_PACKET="${CJGUI_STAGE143_TRUTH_ADMISSION_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage143"
: > "$OWNER_LOG"
: > "$STAGE143_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE143_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage144 renderer-state write decision packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage144 renderer-state write decision packet: syntax check failed $script" >&2
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
    echo "cjgui stage144 renderer-state write decision packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage144 renderer-state write decision packet: owner probe failed" >&2
  echo "cjgui stage144 renderer-state write decision packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage144_renderer_state_write_decision_after_truth_admission_contract_owner_present=true" \
  "stage143_truth_admission_packet_required=true" \
  "renderer_state_write_decision_non_mutating=true" \
  "renderer_state_write_allowed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage143_input_mode="generated_stage143_suite_packet"
if [[ -n "$STAGE143_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE143_SUITE_PACKET" ]]; then
    echo "cjgui stage144 renderer-state write decision packet: provided stage143 suite packet missing $STAGE143_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage143_suite_packet_used=true"
    echo "stage143_suite_packet_path=$STAGE143_SUITE_PACKET"
  } > "$STAGE143_LOG"
  stage143_input_mode="provided_stage143_suite_packet"
else
  if ! env CJGUI_STAGE143_TMPDIR="$TMP_DIR/stage143" zsh "$STAGE143_SUITE_SCRIPT" > "$STAGE143_LOG" 2>&1; then
    echo "cjgui stage144 renderer-state write decision packet: stage143 suite failed" >&2
    echo "cjgui stage144 renderer-state write decision packet: log=$STAGE143_LOG" >&2
    exit 8
  fi
  STAGE143_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE143_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE143_SUITE_PACKET" || ! -f "$STAGE143_SUITE_PACKET" ]]; then
  echo "cjgui stage144 renderer-state write decision packet: missing stage143 suite packet" >&2
  exit 9
fi
for fact in \
  "stage143_truth_admission_after_first_frame_observation_contract_first_slice_suite_passed=true" \
  "stage143_truth_admission_packet_passed=true" \
  "production_render_truth=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE143_SUITE_PACKET" "$fact"
done

stage143_truth_route="$(fact_value "$STAGE143_SUITE_PACKET" "truth_admission_route_classification")"
truth_admission_preflight_ready="$(fact_value "$STAGE143_SUITE_PACKET" "truth_admission_preflight_ready")"
positive_first_frame_input_ready="$(fact_value "$STAGE143_SUITE_PACKET" "positive_first_frame_input_ready")"
production_render_truth="$(fact_value "$STAGE143_SUITE_PACKET" "production_render_truth")"
backend_ready_truth="$(fact_value "$STAGE143_SUITE_PACKET" "backend_ready_truth")"
result_promoted="$(fact_value "$STAGE143_SUITE_PACKET" "result_envelope_promoted_to_production_truth")"

truth_admission_preflight_ready="${truth_admission_preflight_ready:-false}"
positive_first_frame_input_ready="${positive_first_frame_input_ready:-false}"
production_render_truth="${production_render_truth:-false}"
backend_ready_truth="${backend_ready_truth:-false}"
result_promoted="${result_promoted:-false}"

renderer_state_write_decision_ready="true"
renderer_state_write_allowed="false"
renderer_state_write_denied="true"
renderer_state_write_decision_route="renderer_state_write_decision_denied_missing_truth_or_admission"
renderer_state_write_denial_reason="production_render_truth_false,backend_ready_truth_false,production_write_admission_missing"
if [[ "$stage143_truth_route" == "host_metal_device_unavailable" ]]; then
  renderer_state_write_decision_route="renderer_state_write_decision_denied_host_metal_device_unavailable"
  renderer_state_write_denial_reason="host_metal_device_unavailable,production_render_truth_false,backend_ready_truth_false"
elif [[ "$stage143_truth_route" == "host_window_capture_unavailable" ]]; then
  renderer_state_write_decision_route="renderer_state_write_decision_denied_host_window_capture_unavailable"
  renderer_state_write_denial_reason="host_window_capture_unavailable,production_render_truth_false,backend_ready_truth_false"
elif [[ "$stage143_truth_route" == "truth_admission_after_first_frame_observation_contract_preflight_ready" ]]; then
  renderer_state_write_decision_route="renderer_state_write_decision_denied_pending_production_truth_and_write_admission"
fi

if [[ "$truth_admission_preflight_ready" == "true" &&
      "$production_render_truth" == "true" &&
      "$backend_ready_truth" == "true" &&
      "$result_promoted" == "true" ]]; then
  renderer_state_write_decision_route="renderer_state_write_decision_pending_explicit_production_write_admission"
  renderer_state_write_denial_reason="production_write_admission_missing"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage144 renderer-state write decision packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_packet_version=1"
  echo "stage143_input_mode=$stage143_input_mode"
  echo "stage143_suite_packet=$STAGE143_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage143_log=$STAGE143_LOG"
  echo "stage143_truth_admission_packet_consumed=true"
  echo "stage143_truth_admission_route_classification=$stage143_truth_route"
  echo "truth_admission_preflight_ready=$truth_admission_preflight_ready"
  echo "positive_first_frame_input_ready=$positive_first_frame_input_ready"
  echo "result_envelope_promoted_to_production_truth=$result_promoted"
  echo "production_render_truth=$production_render_truth"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "production_write_admission=false"
  echo "state_mutation_request_envelope_ready=false"
  echo "renderer_state_write_decision_ready=$renderer_state_write_decision_ready"
  echo "renderer_state_write_decision_route_classification=$renderer_state_write_decision_route"
  echo "renderer_state_write_denial_reason=$renderer_state_write_denial_reason"
  echo "renderer_state_write_allowed=$renderer_state_write_allowed"
  echo "renderer_state_write_denied=$renderer_state_write_denied"
  echo "renderer_state_write_decision_non_mutating=true"
  echo "state_mutation_executed=false"
  echo "visibility_published=false"
  echo "rollback_required=false"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=positive_rerun_through_first_frame_or_baseline_semantic_verification"
  echo "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage144 renderer-state write decision packet: route_classification=$renderer_state_write_decision_route"
echo "cjgui stage144 renderer-state write decision packet: write_decision_packet_path=$RESULT_PACKET"
echo "cjgui stage144 renderer-state write decision packet: renderer_state_write=false"
