#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage143 truth admission packet。它消费 stage142
# first-frame observation suite packet，只做 truth-admission preflight 分类，不升级
# production truth，不允许 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE143_PACKET_TMPDIR:-/tmp/cjgui-stage143-truth-admission-after-first-frame-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_truth_admission_after_first_frame_observation_contract_first_slice_owner.sh"
STAGE142_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_after_present_scheduling_contract_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE142_LOG="$TMP_DIR/stage142.log"
RESULT_PACKET="$TMP_DIR/stage143-truth-admission-after-first-frame-observation-contract.packet"
STAGE142_SUITE_PACKET="${CJGUI_STAGE142_FIRST_FRAME_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage142"
: > "$OWNER_LOG"
: > "$STAGE142_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE142_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage143 truth admission packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage143 truth admission packet: syntax check failed $script" >&2
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
    echo "cjgui stage143 truth admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage143 truth admission packet: owner probe failed" >&2
  echo "cjgui stage143 truth admission packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage143_truth_admission_after_first_frame_observation_contract_owner_present=true" \
  "stage142_first_frame_packet_required=true" \
  "positive_first_frame_before_truth_admission_required=true" \
  "truth_admission_preflight_only=true" \
  "production_render_truth=false" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage142_input_mode="generated_stage142_suite_packet"
if [[ -n "$STAGE142_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE142_SUITE_PACKET" ]]; then
    echo "cjgui stage143 truth admission packet: provided stage142 suite packet missing $STAGE142_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage142_suite_packet_used=true"
    echo "stage142_suite_packet_path=$STAGE142_SUITE_PACKET"
  } > "$STAGE142_LOG"
  stage142_input_mode="provided_stage142_suite_packet"
else
  if ! env CJGUI_STAGE142_TMPDIR="$TMP_DIR/stage142" zsh "$STAGE142_SUITE_SCRIPT" > "$STAGE142_LOG" 2>&1; then
    echo "cjgui stage143 truth admission packet: stage142 suite failed" >&2
    echo "cjgui stage143 truth admission packet: log=$STAGE142_LOG" >&2
    exit 8
  fi
  STAGE142_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE142_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE142_SUITE_PACKET" || ! -f "$STAGE142_SUITE_PACKET" ]]; then
  echo "cjgui stage143 truth admission packet: missing stage142 suite packet" >&2
  exit 9
fi
for fact in \
  "stage142_first_frame_observation_after_present_scheduling_contract_first_slice_suite_passed=true" \
  "stage142_first_frame_packet_passed=true" \
  "frame_hash_persisted=false" \
  "frame_hash_value_logged=false" \
  "baseline_compared=false" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE142_SUITE_PACKET" "$fact"
done

stage142_first_frame_route="$(fact_value "$STAGE142_SUITE_PACKET" "first_frame_observation_route_classification")"
stage142_first_frame_ready="$(fact_value "$STAGE142_SUITE_PACKET" "current_shell_first_frame_observation_ready")"
stage142_first_frame_observed="$(fact_value "$STAGE142_SUITE_PACKET" "first_frame_observed")"
stage142_hash_computed="$(fact_value "$STAGE142_SUITE_PACKET" "frame_hash_computed")"
stage142_hash_nonzero="$(fact_value "$STAGE142_SUITE_PACKET" "frame_hash_nonzero")"
stage142_present_called="$(fact_value "$STAGE142_SUITE_PACKET" "present_called")"
stage142_drawable_present_scheduled="$(fact_value "$STAGE142_SUITE_PACKET" "drawable_present_scheduled")"
stage142_commit_called="$(fact_value "$STAGE142_SUITE_PACKET" "commit_called")"
stage142_gpu_work_submitted="$(fact_value "$STAGE142_SUITE_PACKET" "gpu_work_submitted")"

stage142_first_frame_ready="${stage142_first_frame_ready:-false}"
stage142_first_frame_observed="${stage142_first_frame_observed:-false}"
stage142_hash_computed="${stage142_hash_computed:-false}"
stage142_hash_nonzero="${stage142_hash_nonzero:-false}"
stage142_present_called="${stage142_present_called:-false}"
stage142_drawable_present_scheduled="${stage142_drawable_present_scheduled:-false}"
stage142_commit_called="${stage142_commit_called:-false}"
stage142_gpu_work_submitted="${stage142_gpu_work_submitted:-false}"

positive_first_frame_input_ready="false"
truth_admission_route="blocked_pending_first_frame_observation_contract"
truth_admission_preflight_ready="false"
truth_admission_missing_predicates="positive_first_frame_observation,frame_hash_nonzero,baseline_or_semantic_verification,backend_ready_truth"
if [[ "$stage142_first_frame_route" == "first_frame_observation_after_present_scheduling_contract_ready" &&
      "$stage142_first_frame_ready" == "true" &&
      "$stage142_first_frame_observed" == "true" &&
      "$stage142_hash_computed" == "true" &&
      "$stage142_hash_nonzero" == "true" ]]; then
  positive_first_frame_input_ready="true"
  truth_admission_route="truth_admission_after_first_frame_observation_contract_preflight_ready"
  truth_admission_preflight_ready="true"
  truth_admission_missing_predicates="baseline_or_semantic_verification,backend_ready_truth,production_write_admission"
elif [[ "$stage142_first_frame_route" == "host_metal_device_unavailable" ]]; then
  truth_admission_route="host_metal_device_unavailable"
elif [[ "$stage142_first_frame_route" == "host_window_capture_unavailable" ]]; then
  truth_admission_route="host_window_capture_unavailable"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage143 truth admission packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage143_truth_admission_after_first_frame_observation_contract_first_slice_packet_version=1"
  echo "stage142_input_mode=$stage142_input_mode"
  echo "stage142_suite_packet=$STAGE142_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage142_log=$STAGE142_LOG"
  echo "stage142_first_frame_packet_consumed=true"
  echo "stage142_first_frame_observation_route_classification=$stage142_first_frame_route"
  echo "stage142_current_shell_first_frame_observation_ready=$stage142_first_frame_ready"
  echo "present_called=$stage142_present_called"
  echo "drawable_present_scheduled=$stage142_drawable_present_scheduled"
  echo "commit_called=$stage142_commit_called"
  echo "gpu_work_submitted=$stage142_gpu_work_submitted"
  echo "first_frame_observed=$stage142_first_frame_observed"
  echo "frame_hash_computed=$stage142_hash_computed"
  echo "frame_hash_nonzero=$stage142_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "positive_first_frame_input_ready=$positive_first_frame_input_ready"
  echo "truth_admission_route_classification=$truth_admission_route"
  echo "truth_admission_preflight_ready=$truth_admission_preflight_ready"
  echo "truth_admission_preflight_only=true"
  echo "truth_admission_missing_predicates=$truth_admission_missing_predicates"
  echo "baseline_or_semantic_verification_before_production_truth_required=true"
  echo "backend_ready_predicate_before_production_truth_required=true"
  echo "production_write_admission_after_truth_admission_required=true"
  echo "production_render_truth_after_truth_admission_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_after_truth_admission_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=renderer_state_write_decision_after_truth_admission_contract"
  echo "stage143_truth_admission_after_first_frame_observation_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage143 truth admission packet: route_classification=$truth_admission_route"
echo "cjgui stage143 truth admission packet: truth_admission_packet_path=$RESULT_PACKET"
echo "cjgui stage143 truth admission packet: renderer_state_write=false"
