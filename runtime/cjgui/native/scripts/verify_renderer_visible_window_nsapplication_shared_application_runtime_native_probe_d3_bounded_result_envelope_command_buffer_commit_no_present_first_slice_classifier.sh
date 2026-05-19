#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage114 command-buffer commit no-present packet
# 分类为 admitted / host Metal unavailable / pending draw envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage114-command-buffer-commit-no-present-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-buffer-commit-no-present-first-slice-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_BUFFER_COMMIT_NO_PRESENT_FIRST_SLICE_PACKET:-}"

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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: missing fact $fact in $file" >&2
    exit 3
  fi
}

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: log=$PACKET_LOG" >&2
    exit 4
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: provided packet missing $READINESS_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: missing readiness packet" >&2
  exit 6
fi

for fact in \
  "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet_passed=true" \
  "command_buffer_commit_no_present_first_slice_owner_ready=true" \
  "positive_draw_call_envelope_before_commit_required=true" \
  "present_called=false" \
  "drawable_presented=false" \
  "production_gpu_submission=false" \
  "post_commit_cleanup_lifecycle_envelope_ready=true" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

commit_ready="$(fact_value "$READINESS_PACKET" "current_shell_command_buffer_commit_no_present_first_slice_ready")"
bounded_executed="$(fact_value "$READINESS_PACKET" "bounded_command_buffer_commit_no_present_first_slice_executed")"
commit_called="$(fact_value "$READINESS_PACKET" "commit_called")"
completion_wait="$(fact_value "$READINESS_PACKET" "bounded_completion_wait_completed")"
command_buffer_completed="$(fact_value "$READINESS_PACKET" "command_buffer_status_completed")"
gpu_submission_completed="$(fact_value "$READINESS_PACKET" "bounded_gpu_submission_completed")"
gpu_work_submitted="$(fact_value "$READINESS_PACKET" "gpu_work_submitted")"
failure_classification="$(fact_value "$READINESS_PACKET" "command_buffer_commit_no_present_first_slice_failure_classification")"
cleanup_probe_executed="$(fact_value "$READINESS_PACKET" "cleanup_lifecycle_probe_executed")"
cleanup_observed="$(fact_value "$READINESS_PACKET" "cleanup_observed")"
bridge_table_counts_clean="$(fact_value "$READINESS_PACKET" "bridge_table_counts_clean")"
post_commit_cleanup_lifecycle_observed="$(fact_value "$READINESS_PACKET" "post_commit_cleanup_lifecycle_observed")"
cleanup_lifecycle_failure_classification="$(fact_value "$READINESS_PACKET" "cleanup_lifecycle_failure_classification")"

classifier_route="blocked_pending_positive_draw_call_envelope"
post_commit_cleanup_lifecycle_classifier_route="blocked_pending_command_buffer_commit"
if [[ "$commit_ready" == "true" &&
      "$bounded_executed" == "true" &&
      "$commit_called" == "true" &&
      "$completion_wait" == "true" &&
      "$command_buffer_completed" == "true" &&
      "$gpu_submission_completed" == "true" &&
      "$gpu_work_submitted" == "true" &&
      "$post_commit_cleanup_lifecycle_observed" == "true" ]]; then
  classifier_route="admitted_bounded_command_buffer_commit_no_present_first_slice"
  post_commit_cleanup_lifecycle_classifier_route="admitted_post_commit_cleanup_lifecycle"
elif [[ "$failure_classification" == "host_metal_device_unavailable" ]]; then
  classifier_route="host_metal_device_unavailable"
  post_commit_cleanup_lifecycle_classifier_route="host_metal_device_unavailable"
elif [[ "$cleanup_lifecycle_failure_classification" == "cleanup_lifecycle_failed" ]]; then
  classifier_route="cleanup_lifecycle_failed"
  post_commit_cleanup_lifecycle_classifier_route="cleanup_lifecycle_failed"
fi

{
  echo "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_classifier_version=1"
  echo "readiness_packet=$READINESS_PACKET"
  echo "packet_log=$PACKET_LOG"
  echo "current_shell_command_buffer_commit_no_present_first_slice_ready=$commit_ready"
  echo "bounded_command_buffer_commit_no_present_first_slice_executed=$bounded_executed"
  echo "commit_called=$commit_called"
  echo "bounded_completion_wait_completed=$completion_wait"
  echo "command_buffer_status_completed=$command_buffer_completed"
  echo "bounded_gpu_submission_completed=$gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "command_buffer_commit_no_present_first_slice_failure_classification=$failure_classification"
  echo "command_buffer_commit_no_present_first_slice_classifier_route=$classifier_route"
  echo "post_commit_cleanup_lifecycle_envelope_ready=true"
  echo "cleanup_lifecycle_probe_executed=$cleanup_probe_executed"
  echo "cleanup_observed=$cleanup_observed"
  echo "bridge_table_counts_clean=$bridge_table_counts_clean"
  echo "post_commit_cleanup_lifecycle_observed=$post_commit_cleanup_lifecycle_observed"
  echo "cleanup_lifecycle_failure_classification=$cleanup_lifecycle_failure_classification"
  echo "post_commit_cleanup_lifecycle_classifier_route=$post_commit_cleanup_lifecycle_classifier_route"
  echo "layer_device_detach_before_cleanup_required=true"
  echo "attachment_texture_detach_before_cleanup_required=true"
  echo "bridge_table_counts_clean_after_cleanup_required=true"
  grep -E '^draw_call_first_slice_envelope_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  grep -E '^current_shell_commit_probe_isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  grep -E '^stage113_current_shell_draw_call_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage113_bounded_draw_call_first_slice_executed=' "$READINESS_PACKET" | tail -1
  grep -E '^render_command_encoder_created=' "$READINESS_PACKET" | tail -1
  grep -E '^end_encoding_called=' "$READINESS_PACKET" | tail -1
  grep -E '^pipeline_state_bound=' "$READINESS_PACKET" | tail -1
  grep -E '^vertex_buffer_bound=' "$READINESS_PACKET" | tail -1
  grep -E '^draw_called=' "$READINESS_PACKET" | tail -1
  echo "present_called=false"
  echo "drawable_presented=false"
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
  echo "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_classifier_passed=true"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: route_classification=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice classifier: renderer_state_write=false"
