#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage117 first-frame observation packet 分类为
# admitted / host Metal unavailable / host window capture unavailable /
# pending present scheduling envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage117-first-frame-observation-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-first-slice-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: missing fact $fact in $file" >&2
    exit 3
  fi
}

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: log=$PACKET_LOG" >&2
    exit 4
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: provided packet missing $READINESS_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: missing readiness packet" >&2
  exit 6
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_first_slice_packet_passed=true" \
  "first_frame_observation_first_slice_owner_ready=true" \
  "positive_present_scheduled_envelope_before_first_frame_observation_required=true" \
  "frame_hash_persisted=false" \
  "frame_hash_value_logged=false" \
  "baseline_compared=false" \
  "production_present_call=false" \
  "production_gpu_submission=false" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

first_frame_ready="$(fact_value "$READINESS_PACKET" "current_shell_first_frame_observation_first_slice_ready")"
bounded_executed="$(fact_value "$READINESS_PACKET" "bounded_first_frame_observation_first_slice_executed")"
present_called="$(fact_value "$READINESS_PACKET" "present_called")"
drawable_present_scheduled="$(fact_value "$READINESS_PACKET" "drawable_present_scheduled")"
bounded_drawable_present_scheduled="$(fact_value "$READINESS_PACKET" "bounded_drawable_present_scheduled")"
commit_called="$(fact_value "$READINESS_PACKET" "commit_called")"
completion_wait="$(fact_value "$READINESS_PACKET" "bounded_completion_wait_completed")"
command_buffer_completed="$(fact_value "$READINESS_PACKET" "command_buffer_status_completed")"
gpu_submission_completed="$(fact_value "$READINESS_PACKET" "bounded_gpu_submission_completed")"
gpu_work_submitted="$(fact_value "$READINESS_PACKET" "gpu_work_submitted")"
capture_attempted="$(fact_value "$READINESS_PACKET" "first_frame_capture_attempted")"
window_capture_requested="$(fact_value "$READINESS_PACKET" "window_capture_requested")"
window_id_observed="$(fact_value "$READINESS_PACKET" "window_id_observed")"
user_visible_window_capture_source="$(fact_value "$READINESS_PACKET" "user_visible_window_capture_source")"
frame_capture_image_created="$(fact_value "$READINESS_PACKET" "frame_capture_image_created")"
frame_hash_computed="$(fact_value "$READINESS_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$READINESS_PACKET" "frame_hash_nonzero")"
first_frame_observed="$(fact_value "$READINESS_PACKET" "first_frame_observed")"
failure_classification="$(fact_value "$READINESS_PACKET" "first_frame_observation_first_slice_failure_classification")"

classifier_route="blocked_pending_positive_present_scheduled_envelope"
if [[ "$first_frame_ready" == "true" &&
      "$bounded_executed" == "true" &&
      "$present_called" == "true" &&
      "$drawable_present_scheduled" == "true" &&
      "$bounded_drawable_present_scheduled" == "true" &&
      "$commit_called" == "true" &&
      "$completion_wait" == "true" &&
      "$command_buffer_completed" == "true" &&
      "$gpu_submission_completed" == "true" &&
      "$gpu_work_submitted" == "true" &&
      "$capture_attempted" == "true" &&
      "$window_capture_requested" == "true" &&
      "$window_id_observed" == "true" &&
      "$user_visible_window_capture_source" == "true" &&
      "$frame_capture_image_created" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" &&
      "$first_frame_observed" == "true" ]]; then
  classifier_route="admitted_bounded_first_frame_observed_first_slice"
elif [[ "$failure_classification" == "host_metal_device_unavailable" ]]; then
  classifier_route="host_metal_device_unavailable"
elif [[ "$failure_classification" == "host_window_capture_unavailable" ]]; then
  classifier_route="host_window_capture_unavailable"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_classifier_version=1"
  echo "readiness_packet=$READINESS_PACKET"
  echo "packet_log=$PACKET_LOG"
  echo "current_shell_first_frame_observation_first_slice_ready=$first_frame_ready"
  echo "bounded_first_frame_observation_first_slice_executed=$bounded_executed"
  echo "present_called=$present_called"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "commit_called=$commit_called"
  echo "bounded_completion_wait_completed=$completion_wait"
  echo "command_buffer_status_completed=$command_buffer_completed"
  echo "bounded_gpu_submission_completed=$gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "first_frame_capture_attempted=$capture_attempted"
  echo "window_capture_requested=$window_capture_requested"
  echo "window_id_observed=$window_id_observed"
  echo "user_visible_window_capture_source=$user_visible_window_capture_source"
  echo "frame_capture_image_created=$frame_capture_image_created"
  grep -E '^frame_pixel_width=' "$READINESS_PACKET" | tail -1
  grep -E '^frame_pixel_height=' "$READINESS_PACKET" | tail -1
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  grep -E '^captured_nonzero_pixel_sample_count=' "$READINESS_PACKET" | tail -1
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "first_frame_observed=$first_frame_observed"
  echo "first_frame_observation_first_slice_failure_classification=$failure_classification"
  echo "first_frame_observation_first_slice_classifier_route=$classifier_route"
  grep -E '^present_no_present_branch_first_slice_envelope_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage115_current_shell_present_no_present_branch_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage115_bounded_present_no_present_branch_first_slice_executed=' "$READINESS_PACKET" | tail -1
  grep -E '^stage115_present_called=' "$READINESS_PACKET" | tail -1
  grep -E '^stage115_bounded_drawable_present_scheduled=' "$READINESS_PACKET" | tail -1
  grep -E '^current_shell_first_frame_probe_isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  echo "drawable_presented=false"
  echo "production_present_call=false"
  echo "production_gpu_submission=false"
  echo "render_executed=false"
  echo "production_render_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_classifier_passed=true"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: route_classification=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice classifier: renderer_state_write=false"
