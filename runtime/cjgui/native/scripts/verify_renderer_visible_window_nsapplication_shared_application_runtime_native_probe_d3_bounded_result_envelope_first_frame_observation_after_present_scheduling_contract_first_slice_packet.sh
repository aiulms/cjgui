#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage142 first-frame observation after stage141
# present scheduling packet。只有 stage141 packet 证明 probe-local present
# scheduling 正向成立时，才运行 bounded first-frame observation probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE142_PACKET_TMPDIR:-/tmp/cjgui-stage142-first-frame-observation-after-present-scheduling-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_after_present_scheduling_contract_first_slice_owner.sh"
STAGE141_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice_suite.sh"
FIRST_FRAME_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE141_LOG="$TMP_DIR/stage141.log"
FIRST_FRAME_PROBE_LOG="$TMP_DIR/first-frame-observation-probe.log"
RESULT_PACKET="$TMP_DIR/stage142-first-frame-observation-after-present-scheduling-contract.packet"
STAGE141_SUITE_PACKET="${CJGUI_STAGE141_PRESENT_SCHEDULING_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage141" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE141_LOG"
: > "$FIRST_FRAME_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE141_SUITE_SCRIPT" "$FIRST_FRAME_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage142 first-frame observation packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage142 first-frame observation packet: syntax check failed $script" >&2
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
    echo "cjgui stage142 first-frame observation packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage142 first-frame observation packet: owner probe failed" >&2
  echo "cjgui stage142 first-frame observation packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage142_first_frame_observation_after_present_scheduling_contract_owner_present=true" \
  "stage141_present_scheduling_packet_required=true" \
  "bounded_first_frame_observation_probe_required=true" \
  "frame_hash_persisted=false" \
  "frame_hash_value_logged=false" \
  "production_render_truth=false" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage141_input_mode="generated_stage141_suite_packet"
if [[ -n "$STAGE141_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE141_SUITE_PACKET" ]]; then
    echo "cjgui stage142 first-frame observation packet: provided stage141 suite packet missing $STAGE141_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage141_suite_packet_used=true"
    echo "stage141_suite_packet_path=$STAGE141_SUITE_PACKET"
  } > "$STAGE141_LOG"
  stage141_input_mode="provided_stage141_suite_packet"
else
  if ! env CJGUI_STAGE141_TMPDIR="$TMP_DIR/stage141" zsh "$STAGE141_SUITE_SCRIPT" > "$STAGE141_LOG" 2>&1; then
    echo "cjgui stage142 first-frame observation packet: stage141 suite failed" >&2
    echo "cjgui stage142 first-frame observation packet: log=$STAGE141_LOG" >&2
    exit 8
  fi
  STAGE141_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE141_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE141_SUITE_PACKET" || ! -f "$STAGE141_SUITE_PACKET" ]]; then
  echo "cjgui stage142 first-frame observation packet: missing stage141 suite packet" >&2
  exit 9
fi
for fact in \
  "stage141_present_scheduling_after_commit_no_present_contract_first_slice_suite_passed=true" \
  "stage141_present_scheduling_packet_passed=true" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE141_SUITE_PACKET" "$fact"
done

stage141_present_route="$(fact_value "$STAGE141_SUITE_PACKET" "present_scheduling_route_classification")"
stage141_present_executed="$(fact_value "$STAGE141_SUITE_PACKET" "bounded_present_scheduling_executed")"
stage141_present_ready="$(fact_value "$STAGE141_SUITE_PACKET" "current_shell_present_scheduling_ready")"
stage141_drawable_present_scheduled="$(fact_value "$STAGE141_SUITE_PACKET" "drawable_present_scheduled")"
stage141_present_called="$(fact_value "$STAGE141_SUITE_PACKET" "present_called")"
stage141_commit_called="$(fact_value "$STAGE141_SUITE_PACKET" "commit_called")"
stage141_gpu_work_submitted="$(fact_value "$STAGE141_SUITE_PACKET" "gpu_work_submitted")"
stage141_gpu_submission_completed="$(fact_value "$STAGE141_SUITE_PACKET" "bounded_gpu_submission_completed")"

# 维护注释：stage141 suite packet 只透出关键汇总字段；缺失布尔必须
# fail-closed，不能在 stage142 result envelope 中落成空值。
stage141_present_executed="${stage141_present_executed:-false}"
stage141_present_ready="${stage141_present_ready:-false}"
stage141_drawable_present_scheduled="${stage141_drawable_present_scheduled:-false}"
stage141_present_called="${stage141_present_called:-false}"
stage141_commit_called="${stage141_commit_called:-false}"
stage141_gpu_work_submitted="${stage141_gpu_work_submitted:-false}"
stage141_gpu_submission_completed="${stage141_gpu_submission_completed:-false}"

bounded_first_frame_should_execute="false"
bounded_first_frame_executed="false"
current_shell_first_frame_ready="false"
first_frame_route="blocked_pending_present_scheduling_contract"
first_frame_failure_domain="present_scheduling_contract_not_ready"
first_frame_probe_exit_code="not_run"
first_frame_capture_attempted="false"
window_capture_requested="false"
window_id_observed="false"
user_visible_window_capture_source="false"
frame_capture_image_created="false"
frame_pixel_width="0"
frame_pixel_height="0"
frame_hash_computed="false"
frame_hash_nonzero="false"
captured_nonzero_pixel_sample_count="0"
frame_hash_persisted="false"
frame_hash_value_logged="false"
baseline_compared="false"
first_frame_observed="false"
present_called="$stage141_present_called"
drawable_present_scheduled="$stage141_drawable_present_scheduled"
bounded_drawable_present_scheduled="$stage141_drawable_present_scheduled"
commit_called="$stage141_commit_called"
bounded_gpu_submission_completed="$stage141_gpu_submission_completed"
gpu_work_submitted="$stage141_gpu_work_submitted"
bounded_completion_wait_completed="$stage141_gpu_submission_completed"
command_buffer_status_completed="$stage141_gpu_submission_completed"
production_present_call="false"
production_gpu_submission="false"

if [[ "$stage141_present_route" == "present_scheduling_after_commit_no_present_contract_ready" &&
      "$stage141_present_executed" == "true" &&
      "$stage141_present_ready" == "true" &&
      "$stage141_drawable_present_scheduled" == "true" &&
      "$stage141_present_called" == "true" &&
      "$stage141_commit_called" == "true" &&
      "$stage141_gpu_work_submitted" == "true" &&
      "$stage141_gpu_submission_completed" == "true" ]]; then
  bounded_first_frame_should_execute="true"
elif [[ "$stage141_present_route" == "host_metal_device_unavailable" ]]; then
  first_frame_route="host_metal_device_unavailable"
  first_frame_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_first_frame_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$FIRST_FRAME_PROBE" > "$FIRST_FRAME_PROBE_LOG" 2>&1
  first_frame_probe_exit_code="$?"
  set -e
  first_frame_capture_attempted="$(fact_value "$FIRST_FRAME_PROBE_LOG" "first_frame_capture_attempted")"
  window_capture_requested="$(fact_value "$FIRST_FRAME_PROBE_LOG" "window_capture_requested")"
  window_id_observed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "window_id_observed")"
  user_visible_window_capture_source="$(fact_value "$FIRST_FRAME_PROBE_LOG" "user_visible_window_capture_source")"
  frame_capture_image_created="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_capture_image_created")"
  frame_pixel_width="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_pixel_width")"
  frame_pixel_height="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_pixel_height")"
  frame_hash_computed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_hash_computed")"
  frame_hash_nonzero="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_hash_nonzero")"
  captured_nonzero_pixel_sample_count="$(fact_value "$FIRST_FRAME_PROBE_LOG" "captured_nonzero_pixel_sample_count")"
  frame_hash_persisted="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_hash_persisted")"
  frame_hash_value_logged="$(fact_value "$FIRST_FRAME_PROBE_LOG" "frame_hash_value_logged")"
  baseline_compared="$(fact_value "$FIRST_FRAME_PROBE_LOG" "baseline_compared")"
  first_frame_observed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "first_frame_observed")"
  present_called="$(fact_value "$FIRST_FRAME_PROBE_LOG" "present_called")"
  drawable_present_scheduled="$(fact_value "$FIRST_FRAME_PROBE_LOG" "drawable_present_scheduled")"
  bounded_drawable_present_scheduled="$(fact_value "$FIRST_FRAME_PROBE_LOG" "bounded_drawable_present_scheduled")"
  commit_called="$(fact_value "$FIRST_FRAME_PROBE_LOG" "commit_called")"
  bounded_completion_wait_completed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "bounded_completion_wait_completed")"
  command_buffer_status_completed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "command_buffer_status_completed")"
  bounded_gpu_submission_completed="$(fact_value "$FIRST_FRAME_PROBE_LOG" "bounded_gpu_submission_completed")"
  gpu_work_submitted="$(fact_value "$FIRST_FRAME_PROBE_LOG" "gpu_work_submitted")"
  production_present_call="$(fact_value "$FIRST_FRAME_PROBE_LOG" "production_present_call")"
  production_gpu_submission="$(fact_value "$FIRST_FRAME_PROBE_LOG" "production_gpu_submission")"
  first_frame_failure_domain="$(fact_value "$FIRST_FRAME_PROBE_LOG" "first_frame_observation_first_slice_failure_domain")"
  if [[ "$first_frame_probe_exit_code" == "0" ]]; then
    require_file_fact "$FIRST_FRAME_PROBE_LOG" "first_frame_observation_first_slice_probe=passed"
    bounded_first_frame_executed="true"
    current_shell_first_frame_ready="true"
    first_frame_route="first_frame_observation_after_present_scheduling_contract_ready"
    first_frame_failure_domain="none"
  elif [[ "$first_frame_probe_exit_code" == "20" &&
          "$first_frame_failure_domain" == "metal_device_unavailable" ]]; then
    first_frame_route="host_metal_device_unavailable"
  elif [[ "$first_frame_probe_exit_code" == "20" &&
          "$first_frame_failure_domain" == "window_capture_unavailable" ]]; then
    bounded_first_frame_executed="true"
    first_frame_route="host_window_capture_unavailable"
  else
    echo "cjgui stage142 first-frame observation packet: bounded first-frame probe failed" >&2
    echo "cjgui stage142 first-frame observation packet: exit=$first_frame_probe_exit_code log=$FIRST_FRAME_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_first_frame_ready" == "true" ]]; then
  for fact in \
    "present_called=true" \
    "drawable_present_scheduled=true" \
    "bounded_drawable_present_scheduled=true" \
    "commit_called=true" \
    "bounded_gpu_submission_completed=true" \
    "first_frame_capture_attempted=true" \
    "window_capture_requested=true" \
    "window_id_observed=true" \
    "user_visible_window_capture_source=true" \
    "frame_capture_image_created=true" \
    "frame_hash_computed=true" \
    "frame_hash_nonzero=true" \
    "frame_hash_persisted=false" \
    "frame_hash_value_logged=false" \
    "baseline_compared=false" \
    "first_frame_observed=true" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$FIRST_FRAME_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage142 first-frame observation packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage142_first_frame_observation_after_present_scheduling_contract_first_slice_packet_version=1"
  echo "stage141_input_mode=$stage141_input_mode"
  echo "stage141_suite_packet=$STAGE141_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage141_log=$STAGE141_LOG"
  echo "first_frame_probe_log=$FIRST_FRAME_PROBE_LOG"
  echo "first_frame_probe_exit_code=$first_frame_probe_exit_code"
  echo "stage141_present_scheduling_packet_consumed=true"
  echo "stage141_present_scheduling_route_classification=$stage141_present_route"
  echo "positive_present_scheduling_before_first_frame_observation_required=true"
  echo "bounded_first_frame_observation_should_execute=$bounded_first_frame_should_execute"
  echo "bounded_first_frame_observation_executed=$bounded_first_frame_executed"
  echo "current_shell_first_frame_observation_ready=$current_shell_first_frame_ready"
  echo "first_frame_observation_route_classification=$first_frame_route"
  echo "first_frame_observation_failure_domain=$first_frame_failure_domain"
  echo "first_frame_capture_attempted=$first_frame_capture_attempted"
  echo "window_capture_requested=$window_capture_requested"
  echo "window_id_observed=$window_id_observed"
  echo "user_visible_window_capture_source=$user_visible_window_capture_source"
  echo "frame_capture_image_created=$frame_capture_image_created"
  echo "frame_pixel_width=$frame_pixel_width"
  echo "frame_pixel_height=$frame_pixel_height"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "captured_nonzero_pixel_sample_count=$captured_nonzero_pixel_sample_count"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "first_frame_observed=$first_frame_observed"
  echo "present_called=$present_called"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "commit_called=$commit_called"
  echo "bounded_completion_wait_completed=$bounded_completion_wait_completed"
  echo "command_buffer_status_completed=$command_buffer_status_completed"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "production_present_call=$production_present_call"
  echo "production_gpu_submission=$production_gpu_submission"
  echo "production_render_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=truth_admission_after_first_frame_observation_contract"
  echo "stage142_first_frame_observation_after_present_scheduling_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage142 first-frame observation packet: route_classification=$first_frame_route"
echo "cjgui stage142 first-frame observation packet: first_frame_packet_path=$RESULT_PACKET"
echo "cjgui stage142 first-frame observation packet: renderer_state_write=false"
