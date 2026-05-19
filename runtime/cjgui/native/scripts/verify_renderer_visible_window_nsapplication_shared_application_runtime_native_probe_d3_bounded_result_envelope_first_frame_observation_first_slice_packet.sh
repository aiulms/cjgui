#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage117 first-frame observation first-slice packet。
# 它消费 stage115 present/no-present suite packet；只有拿到 positive present
# scheduling envelope 时，才执行 bounded first-frame observation probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage117-first-frame-observation-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_owner.sh"
STAGE115_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_suite.sh"
FIRST_FRAME_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh"
DEFAULT_STAGE115_SUITE_PACKET="/tmp/cjgui-stage115-present-no-present-branch-first-slice-suite/d3-bounded-result-envelope-present-no-present-branch-first-slice-suite.packet"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE115_LOG="$TMP_DIR/stage115.log"
FIRST_FRAME_PROBE_LOG="$TMP_DIR/first-frame-observation-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-first-slice.packet"
STAGE115_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PRESENT_NO_PRESENT_BRANCH_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage115" "$TMP_DIR/first-frame-probe"
: > "$OWNER_LOG"
: > "$STAGE115_LOG"
: > "$FIRST_FRAME_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE115_SUITE_SCRIPT" "$FIRST_FRAME_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_first_slice_owner_present=true" \
  "present_no_present_branch_first_slice_input=true" \
  "positive_present_scheduled_envelope_before_first_frame_observation_required=true" \
  "bounded_isolated_first_frame_observation_probe_required=true" \
  "user_visible_window_capture_observation_required=true" \
  "frame_hash_summary_required=true" \
  "frame_hash_persisted=false" \
  "frame_hash_value_logged=false" \
  "baseline_compared=false" \
  "production_render_truth_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage115_input_mode="missing_positive_present_no_present_suite_packet"
stage115_suite_generation_exit_code="not_run"
if [[ -n "$STAGE115_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE115_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: provided stage115 suite packet missing $STAGE115_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage115_suite_packet_used=true"
    echo "stage115_suite_packet_path=$STAGE115_SUITE_PACKET"
  } > "$STAGE115_LOG"
  stage115_input_mode="provided_stage115_suite_packet"
elif [[ -f "$DEFAULT_STAGE115_SUITE_PACKET" ]]; then
  STAGE115_SUITE_PACKET="$DEFAULT_STAGE115_SUITE_PACKET"
  {
    echo "cached_stage115_suite_packet_used=true"
    echo "stage115_suite_packet_path=$STAGE115_SUITE_PACKET"
  } > "$STAGE115_LOG"
  stage115_input_mode="cached_stage115_suite_packet"
else
  set +e
  env TMPDIR="$TMP_DIR/stage115" zsh "$STAGE115_SUITE_SCRIPT" > "$STAGE115_LOG" 2>&1
  stage115_suite_generation_exit_code="$?"
  set -e
  if [[ "$stage115_suite_generation_exit_code" == "0" ]]; then
    STAGE115_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE115_LOG" | tail -1 | cut -d= -f2-)"
    stage115_input_mode="generated_stage115_suite_packet"
  fi
fi

stage115_envelope_ready="false"
stage115_present_ready="false"
stage115_present_executed="false"
stage115_failure_classification="missing_positive_present_no_present_suite_packet"
stage115_present_branch_selected="false"
stage115_present_called="false"
stage115_drawable_present_scheduled="false"
stage115_bounded_drawable_present_scheduled="false"
stage115_commit_called="false"
stage115_gpu_submission_completed="false"
stage115_gpu_work_submitted="false"

if [[ -n "$STAGE115_SUITE_PACKET" && -f "$STAGE115_SUITE_PACKET" ]]; then
  for fact in \
    "d3_bounded_result_envelope_present_no_present_branch_first_slice_suite_passed=true" \
    "present_no_present_branch_first_slice_envelope_ready=true" \
    "production_present_call=false" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$STAGE115_SUITE_PACKET" "$fact"
  done
  stage115_envelope_ready="$(fact_value "$STAGE115_SUITE_PACKET" "present_no_present_branch_first_slice_envelope_ready")"
  stage115_present_ready="$(fact_value "$STAGE115_SUITE_PACKET" "current_shell_present_no_present_branch_first_slice_ready")"
  stage115_present_executed="$(fact_value "$STAGE115_SUITE_PACKET" "bounded_present_no_present_branch_first_slice_executed")"
  stage115_failure_classification="$(fact_value "$STAGE115_SUITE_PACKET" "present_no_present_branch_first_slice_failure_classification")"
  stage115_present_branch_selected="$(fact_value "$STAGE115_SUITE_PACKET" "present_branch_selected")"
  stage115_present_called="$(fact_value "$STAGE115_SUITE_PACKET" "present_called")"
  stage115_drawable_present_scheduled="$(fact_value "$STAGE115_SUITE_PACKET" "drawable_present_scheduled")"
  stage115_bounded_drawable_present_scheduled="$(fact_value "$STAGE115_SUITE_PACKET" "bounded_drawable_present_scheduled")"
  stage115_commit_called="$(fact_value "$STAGE115_SUITE_PACKET" "commit_called")"
  stage115_gpu_submission_completed="$(fact_value "$STAGE115_SUITE_PACKET" "bounded_gpu_submission_completed")"
  stage115_gpu_work_submitted="$(fact_value "$STAGE115_SUITE_PACKET" "gpu_work_submitted")"
fi

bounded_first_frame_observation_first_slice_should_execute="false"
bounded_first_frame_observation_first_slice_executed="false"
current_shell_first_frame_observation_first_slice_ready="false"
first_frame_observation_failure_classification="blocked_pending_positive_present_scheduled_envelope"
first_frame_observation_failure_domain="present_no_present_branch_first_slice_not_ready"
first_frame_probe_exit_code="not_run"
current_shell_first_frame_probe_isolated_metal_device_available="not_run"
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
present_called="false"
drawable_present_scheduled="false"
bounded_drawable_present_scheduled="false"
commit_called="false"
bounded_completion_wait_completed="false"
command_buffer_status_completed="false"
bounded_gpu_submission_completed="false"
gpu_work_submitted="false"
production_present_call="false"
production_gpu_submission="false"

if [[ "$stage115_envelope_ready" == "true" &&
      "$stage115_present_ready" == "true" &&
      "$stage115_present_executed" == "true" &&
      "$stage115_present_branch_selected" == "true" &&
      "$stage115_present_called" == "true" &&
      "$stage115_drawable_present_scheduled" == "true" &&
      "$stage115_bounded_drawable_present_scheduled" == "true" &&
      "$stage115_commit_called" == "true" &&
      "$stage115_gpu_submission_completed" == "true" &&
      "$stage115_gpu_work_submitted" == "true" ]]; then
  bounded_first_frame_observation_first_slice_should_execute="true"
elif [[ "$stage115_failure_classification" == "host_metal_device_unavailable" ]]; then
  first_frame_observation_failure_classification="host_metal_device_unavailable"
  first_frame_observation_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_first_frame_observation_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/first-frame-probe" zsh "$FIRST_FRAME_PROBE" > "$FIRST_FRAME_PROBE_LOG" 2>&1
  first_frame_probe_exit_code="$?"
  set -e
  current_shell_first_frame_probe_isolated_metal_device_available="$(fact_value "$FIRST_FRAME_PROBE_LOG" "isolated_metal_device_available")"
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
  first_frame_observation_failure_domain="$(fact_value "$FIRST_FRAME_PROBE_LOG" "first_frame_observation_first_slice_failure_domain")"
  if [[ "$first_frame_probe_exit_code" == "0" ]]; then
    require_file_fact "$FIRST_FRAME_PROBE_LOG" "first_frame_observation_first_slice_probe=passed"
    bounded_first_frame_observation_first_slice_executed="true"
    current_shell_first_frame_observation_first_slice_ready="true"
    first_frame_observation_failure_classification="none"
    first_frame_observation_failure_domain="none"
  elif [[ "$first_frame_probe_exit_code" == "20" &&
          "$first_frame_observation_failure_domain" == "metal_device_unavailable" ]]; then
    first_frame_observation_failure_classification="host_metal_device_unavailable"
  elif [[ "$first_frame_probe_exit_code" == "20" &&
          "$first_frame_observation_failure_domain" == "window_capture_unavailable" ]]; then
    bounded_first_frame_observation_first_slice_executed="true"
    first_frame_observation_failure_classification="host_window_capture_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: first-frame observation probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: exit=$first_frame_probe_exit_code log=$FIRST_FRAME_PROBE_LOG" >&2
    exit 8
  fi
fi

if [[ "$current_shell_first_frame_observation_first_slice_ready" == "true" ]]; then
  for fact in \
    "present_called=true" \
    "drawable_present_scheduled=true" \
    "bounded_drawable_present_scheduled=true" \
    "commit_called=true" \
    "bounded_completion_wait_completed=true" \
    "command_buffer_status_completed=true" \
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
    "production_present_call=false" \
    "production_gpu_submission=false" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$FIRST_FRAME_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: protected path modified" >&2
  exit 9
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_packet_version=1"
  echo "stage115_input_mode=$stage115_input_mode"
  echo "stage115_suite_generation_exit_code=$stage115_suite_generation_exit_code"
  echo "stage115_suite_packet=$STAGE115_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage115_log=$STAGE115_LOG"
  echo "first_frame_probe_log=$FIRST_FRAME_PROBE_LOG"
  echo "first_frame_probe_exit_code=$first_frame_probe_exit_code"
  echo "first_frame_observation_first_slice_owner_ready=true"
  echo "present_no_present_branch_first_slice_envelope_ready=$stage115_envelope_ready"
  echo "stage115_current_shell_present_no_present_branch_first_slice_ready=$stage115_present_ready"
  echo "stage115_bounded_present_no_present_branch_first_slice_executed=$stage115_present_executed"
  echo "stage115_present_no_present_branch_first_slice_failure_classification=$stage115_failure_classification"
  echo "stage115_present_branch_selected=$stage115_present_branch_selected"
  echo "stage115_present_called=$stage115_present_called"
  echo "stage115_drawable_present_scheduled=$stage115_drawable_present_scheduled"
  echo "stage115_bounded_drawable_present_scheduled=$stage115_bounded_drawable_present_scheduled"
  echo "stage115_commit_called=$stage115_commit_called"
  echo "stage115_bounded_gpu_submission_completed=$stage115_gpu_submission_completed"
  echo "stage115_gpu_work_submitted=$stage115_gpu_work_submitted"
  echo "positive_present_scheduled_envelope_before_first_frame_observation_required=true"
  echo "bounded_first_frame_observation_first_slice_should_execute=$bounded_first_frame_observation_first_slice_should_execute"
  echo "bounded_first_frame_observation_first_slice_executed=$bounded_first_frame_observation_first_slice_executed"
  echo "current_shell_first_frame_observation_first_slice_ready=$current_shell_first_frame_observation_first_slice_ready"
  echo "first_frame_observation_first_slice_failure_classification=$first_frame_observation_failure_classification"
  echo "first_frame_observation_first_slice_failure_domain=$first_frame_observation_failure_domain"
  echo "current_shell_first_frame_probe_isolated_metal_device_available=$current_shell_first_frame_probe_isolated_metal_device_available"
  echo "present_called=$present_called"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "commit_called=$commit_called"
  echo "bounded_completion_wait_completed=$bounded_completion_wait_completed"
  echo "command_buffer_status_completed=$command_buffer_status_completed"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
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
  echo "frame_hash_persisted=$frame_hash_persisted"
  echo "frame_hash_value_logged=$frame_hash_value_logged"
  echo "baseline_compared=$baseline_compared"
  echo "first_frame_observed=$first_frame_observed"
  echo "drawable_presented=false"
  echo "production_present_call=$production_present_call"
  echo "production_gpu_submission=$production_gpu_submission"
  echo "production_render_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: route_classification=d3_bounded_result_envelope_first_frame_observation_first_slice_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: bounded_first_frame_observation_first_slice_executed=$bounded_first_frame_observation_first_slice_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: first_frame_observation_first_slice_failure_classification=$first_frame_observation_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice packet: renderer_state_write=false"
