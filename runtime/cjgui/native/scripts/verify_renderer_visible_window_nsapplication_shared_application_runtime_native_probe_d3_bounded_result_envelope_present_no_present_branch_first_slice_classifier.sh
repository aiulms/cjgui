#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage115 present/no-present branch packet 分类为
# admitted / host Metal unavailable / pending commit envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage115-present-no-present-branch-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-present-no-present-branch-first-slice-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PRESENT_NO_PRESENT_BRANCH_FIRST_SLICE_PACKET:-}"

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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: missing fact $fact in $file" >&2
    exit 3
  fi
}

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: log=$PACKET_LOG" >&2
    exit 4
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: provided packet missing $READINESS_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: missing readiness packet" >&2
  exit 6
fi

for fact in \
  "d3_bounded_result_envelope_present_no_present_branch_first_slice_packet_passed=true" \
  "present_no_present_branch_first_slice_owner_ready=true" \
  "positive_command_buffer_commit_no_present_envelope_before_present_branch_required=true" \
  "production_present_call=false" \
  "production_gpu_submission=false" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

present_ready="$(fact_value "$READINESS_PACKET" "current_shell_present_no_present_branch_first_slice_ready")"
bounded_executed="$(fact_value "$READINESS_PACKET" "bounded_present_no_present_branch_first_slice_executed")"
present_branch_selected="$(fact_value "$READINESS_PACKET" "present_branch_selected")"
no_present_branch_selected="$(fact_value "$READINESS_PACKET" "no_present_branch_selected")"
present_ordering="$(fact_value "$READINESS_PACKET" "present_after_encoding_before_commit")"
present_called="$(fact_value "$READINESS_PACKET" "present_called")"
drawable_present_scheduled="$(fact_value "$READINESS_PACKET" "drawable_present_scheduled")"
bounded_drawable_present_scheduled="$(fact_value "$READINESS_PACKET" "bounded_drawable_present_scheduled")"
commit_called="$(fact_value "$READINESS_PACKET" "commit_called")"
completion_wait="$(fact_value "$READINESS_PACKET" "bounded_completion_wait_completed")"
command_buffer_completed="$(fact_value "$READINESS_PACKET" "command_buffer_status_completed")"
gpu_submission_completed="$(fact_value "$READINESS_PACKET" "bounded_gpu_submission_completed")"
gpu_work_submitted="$(fact_value "$READINESS_PACKET" "gpu_work_submitted")"
failure_classification="$(fact_value "$READINESS_PACKET" "present_no_present_branch_first_slice_failure_classification")"

classifier_route="blocked_pending_positive_command_buffer_commit_no_present_envelope"
if [[ "$present_ready" == "true" &&
      "$bounded_executed" == "true" &&
      "$present_branch_selected" == "true" &&
      "$no_present_branch_selected" == "false" &&
      "$present_ordering" == "true" &&
      "$present_called" == "true" &&
      "$drawable_present_scheduled" == "true" &&
      "$bounded_drawable_present_scheduled" == "true" &&
      "$commit_called" == "true" &&
      "$completion_wait" == "true" &&
      "$command_buffer_completed" == "true" &&
      "$gpu_submission_completed" == "true" &&
      "$gpu_work_submitted" == "true" ]]; then
  classifier_route="admitted_bounded_present_scheduled_branch_first_slice"
elif [[ "$failure_classification" == "host_metal_device_unavailable" ]]; then
  classifier_route="host_metal_device_unavailable"
fi

{
  echo "d3_bounded_result_envelope_present_no_present_branch_first_slice_classifier_version=1"
  echo "readiness_packet=$READINESS_PACKET"
  echo "packet_log=$PACKET_LOG"
  echo "current_shell_present_no_present_branch_first_slice_ready=$present_ready"
  echo "bounded_present_no_present_branch_first_slice_executed=$bounded_executed"
  echo "present_branch_selected=$present_branch_selected"
  echo "no_present_branch_selected=$no_present_branch_selected"
  echo "present_after_encoding_before_commit=$present_ordering"
  echo "present_called=$present_called"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "commit_called=$commit_called"
  echo "bounded_completion_wait_completed=$completion_wait"
  echo "command_buffer_status_completed=$command_buffer_completed"
  echo "bounded_gpu_submission_completed=$gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "present_no_present_branch_first_slice_failure_classification=$failure_classification"
  echo "present_no_present_branch_first_slice_classifier_route=$classifier_route"
  grep -E '^command_buffer_commit_no_present_first_slice_envelope_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage114_current_shell_command_buffer_commit_no_present_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage114_bounded_command_buffer_commit_no_present_first_slice_executed=' "$READINESS_PACKET" | tail -1
  grep -E '^stage114_commit_called=' "$READINESS_PACKET" | tail -1
  grep -E '^stage114_bounded_gpu_submission_completed=' "$READINESS_PACKET" | tail -1
  grep -E '^current_shell_present_probe_isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
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
  echo "d3_bounded_result_envelope_present_no_present_branch_first_slice_classifier_passed=true"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: route_classification=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice classifier: renderer_state_write=false"
