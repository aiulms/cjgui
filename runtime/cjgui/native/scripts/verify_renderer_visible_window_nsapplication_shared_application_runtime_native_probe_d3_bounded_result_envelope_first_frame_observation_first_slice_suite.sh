#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage117 first-frame observation first-slice focused
# suite。它串联 owner、packet、classifier 与 source/build guard，并输出下一段
# first-frame truth admission / renderer-state decision 可消费的 suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage117-first-frame-observation-first-slice-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_source_build_guard.sh"
FIRST_FRAME_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"
readiness_packet=""
classifier_packet=""
source_build_packet=""

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD" "$FIRST_FRAME_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "d3_bounded_result_envelope_first_frame_observation_first_slice_owner_present=true"
require_file_fact "$OWNER_LOG" "bounded_isolated_first_frame_observation_probe_required=true"
require_file_fact "$OWNER_LOG" "user_visible_window_capture_observation_required=true"
require_file_fact "$OWNER_LOG" "frame_hash_summary_required=true"
require_file_fact "$OWNER_LOG" "frame_hash_persisted=false"
require_file_fact "$OWNER_LOG" "frame_hash_value_logged=false"
require_file_fact "$OWNER_LOG" "baseline_compared=false"
require_file_fact "$OWNER_LOG" "production_render_truth_blocked=true"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: packet generation failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: log=$PACKET_LOG" >&2
  exit 7
fi
readiness_packet="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$readiness_packet" || ! -f "$readiness_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing readiness packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_FIRST_SLICE_PACKET="$readiness_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_FIRST_SLICE_PACKET="$readiness_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing source build packet" >&2
  exit 12
fi

required_suite_facts=(
  "d3_bounded_result_envelope_first_frame_observation_first_slice_packet_passed=true"
  "d3_bounded_result_envelope_first_frame_observation_first_slice_classifier_passed=true"
  "source_build_first_frame_observation_first_slice_guard_passed=true"
  "runtime_package_build_passed=true"
  "frame_hash_persisted=false"
  "frame_hash_value_logged=false"
  "baseline_compared=false"
  "production_present_call=false"
  "production_gpu_submission=false"
  "production_render_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$readiness_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: protected path modified" >&2
  exit 14
fi

stage115_ready="$(fact_value "$readiness_packet" "stage115_current_shell_present_no_present_branch_first_slice_ready")"
stage115_executed="$(fact_value "$readiness_packet" "stage115_bounded_present_no_present_branch_first_slice_executed")"
stage115_failure_classification="$(fact_value "$readiness_packet" "stage115_present_no_present_branch_first_slice_failure_classification")"
stage115_present_called="$(fact_value "$readiness_packet" "stage115_present_called")"
stage115_bounded_present="$(fact_value "$readiness_packet" "stage115_bounded_drawable_present_scheduled")"
first_frame_should_execute="$(fact_value "$readiness_packet" "bounded_first_frame_observation_first_slice_should_execute")"
first_frame_executed="$(fact_value "$readiness_packet" "bounded_first_frame_observation_first_slice_executed")"
first_frame_ready="$(fact_value "$readiness_packet" "current_shell_first_frame_observation_first_slice_ready")"
first_frame_failure_classification="$(fact_value "$readiness_packet" "first_frame_observation_first_slice_failure_classification")"
classifier_route="$(fact_value "$classifier_packet" "first_frame_observation_first_slice_classifier_route")"
present_called="$(fact_value "$readiness_packet" "present_called")"
drawable_present_scheduled="$(fact_value "$readiness_packet" "drawable_present_scheduled")"
bounded_drawable_present_scheduled="$(fact_value "$readiness_packet" "bounded_drawable_present_scheduled")"
commit_called="$(fact_value "$readiness_packet" "commit_called")"
completion_wait="$(fact_value "$readiness_packet" "bounded_completion_wait_completed")"
command_buffer_completed="$(fact_value "$readiness_packet" "command_buffer_status_completed")"
gpu_submission_completed="$(fact_value "$readiness_packet" "bounded_gpu_submission_completed")"
gpu_work_submitted="$(fact_value "$readiness_packet" "gpu_work_submitted")"
capture_attempted="$(fact_value "$readiness_packet" "first_frame_capture_attempted")"
window_capture_requested="$(fact_value "$readiness_packet" "window_capture_requested")"
window_id_observed="$(fact_value "$readiness_packet" "window_id_observed")"
capture_source="$(fact_value "$readiness_packet" "user_visible_window_capture_source")"
image_created="$(fact_value "$readiness_packet" "frame_capture_image_created")"
frame_width="$(fact_value "$readiness_packet" "frame_pixel_width")"
frame_height="$(fact_value "$readiness_packet" "frame_pixel_height")"
hash_computed="$(fact_value "$readiness_packet" "frame_hash_computed")"
hash_nonzero="$(fact_value "$readiness_packet" "frame_hash_nonzero")"
sample_count="$(fact_value "$readiness_packet" "captured_nonzero_pixel_sample_count")"
first_frame_observed="$(fact_value "$readiness_packet" "first_frame_observed")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "readiness_packet=$readiness_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_classifier_passed=true"
  echo "source_build_first_frame_observation_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_first_slice_suite_passed=true"
  echo "first_frame_observation_first_slice_envelope_ready=true"
  echo "stage115_current_shell_present_no_present_branch_first_slice_ready=$stage115_ready"
  echo "stage115_bounded_present_no_present_branch_first_slice_executed=$stage115_executed"
  echo "stage115_present_no_present_branch_first_slice_failure_classification=$stage115_failure_classification"
  echo "stage115_present_called=$stage115_present_called"
  echo "stage115_bounded_drawable_present_scheduled=$stage115_bounded_present"
  echo "bounded_first_frame_observation_first_slice_should_execute=$first_frame_should_execute"
  echo "bounded_first_frame_observation_first_slice_executed=$first_frame_executed"
  echo "current_shell_first_frame_observation_first_slice_ready=$first_frame_ready"
  echo "first_frame_observation_first_slice_failure_classification=$first_frame_failure_classification"
  echo "first_frame_observation_first_slice_classifier_route=$classifier_route"
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
  echo "user_visible_window_capture_source=$capture_source"
  echo "frame_capture_image_created=$image_created"
  echo "frame_pixel_width=$frame_width"
  echo "frame_pixel_height=$frame_height"
  echo "frame_hash_computed=$hash_computed"
  echo "frame_hash_nonzero=$hash_nonzero"
  echo "captured_nonzero_pixel_sample_count=$sample_count"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "first_frame_observed=$first_frame_observed"
  echo "drawable_presented=false"
  echo "production_present_call=false"
  echo "production_gpu_submission=false"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: route_classification=d3_bounded_result_envelope_first_frame_observation_first_slice_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: d3_bounded_result_envelope_first_frame_observation_first_slice_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: bounded_first_frame_observation_first_slice_executed=$first_frame_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: first_frame_observation_first_slice_failure_classification=$first_frame_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice suite: renderer_state_write=false"
