#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage114 command-buffer commit no-present first-slice
# packet。它消费 stage113 draw-call suite packet；只有拿到 positive draw
# envelope 时，才执行 bounded commit no-present probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage114-command-buffer-commit-no-present-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner.sh"
STAGE113_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_suite.sh"
COMMIT_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_command_buffer_commit_no_present_first_slice.sh"
DEFAULT_STAGE113_SUITE_PACKET="/tmp/cjgui-stage113-suite-check/cjgui-stage113-draw-call-first-slice-suite/d3-bounded-result-envelope-draw-call-first-slice-suite.packet"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE113_LOG="$TMP_DIR/stage113.log"
COMMIT_PROBE_LOG="$TMP_DIR/command-buffer-commit-no-present-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-buffer-commit-no-present-first-slice.packet"
STAGE113_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAW_CALL_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage113" "$TMP_DIR/commit-probe"
: > "$OWNER_LOG"
: > "$STAGE113_LOG"
: > "$COMMIT_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE113_SUITE_SCRIPT" "$COMMIT_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner_present=true" \
  "draw_call_first_slice_input=true" \
  "positive_draw_call_envelope_before_commit_required=true" \
  "bounded_isolated_command_buffer_commit_probe_required=true" \
  "probe_local_command_buffer_commit_required=true" \
  "bounded_command_buffer_completion_wait_required=true" \
  "bounded_gpu_submission_completion_envelope_allowed=true" \
  "present_blocked=true" \
  "production_render_truth_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage113_input_mode="missing_positive_draw_call_suite_packet"
stage113_suite_generation_exit_code="not_run"
if [[ -n "$STAGE113_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE113_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: provided stage113 suite packet missing $STAGE113_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage113_suite_packet_used=true"
    echo "stage113_suite_packet_path=$STAGE113_SUITE_PACKET"
  } > "$STAGE113_LOG"
  stage113_input_mode="provided_stage113_suite_packet"
elif [[ -f "$DEFAULT_STAGE113_SUITE_PACKET" ]]; then
  STAGE113_SUITE_PACKET="$DEFAULT_STAGE113_SUITE_PACKET"
  {
    echo "cached_stage113_suite_packet_used=true"
    echo "stage113_suite_packet_path=$STAGE113_SUITE_PACKET"
  } > "$STAGE113_LOG"
  stage113_input_mode="cached_stage113_suite_packet"
else
  set +e
  env TMPDIR="$TMP_DIR/stage113" zsh "$STAGE113_SUITE_SCRIPT" > "$STAGE113_LOG" 2>&1
  stage113_suite_generation_exit_code="$?"
  set -e
  if [[ "$stage113_suite_generation_exit_code" == "0" ]]; then
    STAGE113_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE113_LOG" | tail -1 | cut -d= -f2-)"
    stage113_input_mode="generated_stage113_suite_packet"
  fi
fi

stage113_envelope_ready="false"
stage113_draw_ready="false"
stage113_draw_executed="false"
stage113_failure_classification="missing_positive_draw_call_suite_packet"
stage113_isolated_metal_device_available="unknown"
render_command_encoder_created="false"
end_encoding_called="false"
pipeline_state_bound="false"
vertex_buffer_bound="false"
draw_called="false"

if [[ -n "$STAGE113_SUITE_PACKET" && -f "$STAGE113_SUITE_PACKET" ]]; then
  for fact in \
    "d3_bounded_result_envelope_draw_call_first_slice_suite_passed=true" \
    "draw_call_first_slice_envelope_ready=true" \
    "production_draw_call=false" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "renderer_state_write=false"; do
    require_file_fact "$STAGE113_SUITE_PACKET" "$fact"
  done
  stage113_envelope_ready="$(fact_value "$STAGE113_SUITE_PACKET" "draw_call_first_slice_envelope_ready")"
  stage113_draw_ready="$(fact_value "$STAGE113_SUITE_PACKET" "current_shell_draw_call_first_slice_ready")"
  stage113_draw_executed="$(fact_value "$STAGE113_SUITE_PACKET" "bounded_draw_call_first_slice_executed")"
  stage113_failure_classification="$(fact_value "$STAGE113_SUITE_PACKET" "draw_call_first_slice_failure_classification")"
  stage113_isolated_metal_device_available="$(fact_value "$STAGE113_SUITE_PACKET" "isolated_metal_device_available")"
  render_command_encoder_created="$(fact_value "$STAGE113_SUITE_PACKET" "render_command_encoder_created")"
  end_encoding_called="$(fact_value "$STAGE113_SUITE_PACKET" "end_encoding_called")"
  pipeline_state_bound="$(fact_value "$STAGE113_SUITE_PACKET" "pipeline_state_bound")"
  vertex_buffer_bound="$(fact_value "$STAGE113_SUITE_PACKET" "vertex_buffer_bound")"
  draw_called="$(fact_value "$STAGE113_SUITE_PACKET" "draw_called")"
fi

bounded_commit_no_present_first_slice_should_execute="false"
bounded_commit_no_present_first_slice_executed="false"
current_shell_command_buffer_commit_no_present_first_slice_ready="false"
commit_no_present_failure_classification="blocked_pending_positive_draw_call_envelope"
commit_no_present_failure_domain="draw_call_first_slice_not_ready"
commit_probe_exit_code="not_run"
commit_called="false"
completion_handler_called="false"
bounded_completion_wait_completed="false"
command_buffer_status_completed="false"
bounded_gpu_submission_completed="false"
gpu_work_submitted="false"
production_gpu_submission="false"
current_shell_commit_probe_isolated_metal_device_available="not_run"
cleanup_lifecycle_probe_executed="false"
cleanup_observed="not_run"
bridge_table_counts_clean="not_run"
post_commit_cleanup_lifecycle_observed="false"
cleanup_lifecycle_failure_classification="blocked_pending_positive_draw_call_envelope"

if [[ "$stage113_envelope_ready" == "true" &&
      "$stage113_draw_ready" == "true" &&
      "$stage113_draw_executed" == "true" &&
      "$render_command_encoder_created" == "true" &&
      "$end_encoding_called" == "true" &&
      "$pipeline_state_bound" == "true" &&
      "$vertex_buffer_bound" == "true" &&
      "$draw_called" == "true" ]]; then
  bounded_commit_no_present_first_slice_should_execute="true"
elif [[ "$stage113_failure_classification" == "host_metal_device_unavailable" ]]; then
  commit_no_present_failure_classification="host_metal_device_unavailable"
  commit_no_present_failure_domain="metal_device_unavailable"
  cleanup_lifecycle_failure_classification="host_metal_device_unavailable"
fi

if [[ "$bounded_commit_no_present_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/commit-probe" zsh "$COMMIT_PROBE" > "$COMMIT_PROBE_LOG" 2>&1
  commit_probe_exit_code="$?"
  set -e
  if [[ "$commit_probe_exit_code" == "0" ]]; then
    require_file_fact "$COMMIT_PROBE_LOG" "bounded_command_buffer_commit_no_present_first_slice_probe=passed"
    current_shell_commit_probe_isolated_metal_device_available="$(fact_value "$COMMIT_PROBE_LOG" "isolated_metal_device_available")"
    bounded_commit_no_present_first_slice_executed="true"
    current_shell_command_buffer_commit_no_present_first_slice_ready="true"
    commit_no_present_failure_classification="none"
    commit_no_present_failure_domain="none"
    commit_called="$(fact_value "$COMMIT_PROBE_LOG" "commit_called")"
    completion_handler_called="$(fact_value "$COMMIT_PROBE_LOG" "completion_handler_called")"
    bounded_completion_wait_completed="$(fact_value "$COMMIT_PROBE_LOG" "bounded_completion_wait_completed")"
    command_buffer_status_completed="$(fact_value "$COMMIT_PROBE_LOG" "command_buffer_status_completed")"
    bounded_gpu_submission_completed="$(fact_value "$COMMIT_PROBE_LOG" "bounded_gpu_submission_completed")"
    gpu_work_submitted="$(fact_value "$COMMIT_PROBE_LOG" "gpu_work_submitted")"
    production_gpu_submission="$(fact_value "$COMMIT_PROBE_LOG" "production_gpu_submission")"
    cleanup_lifecycle_probe_executed="true"
    cleanup_observed="$(fact_value "$COMMIT_PROBE_LOG" "cleanup_observed")"
    bridge_table_counts_clean="$(fact_value "$COMMIT_PROBE_LOG" "bridge_table_counts_clean")"
    if [[ "$commit_called" == "true" &&
          "$cleanup_observed" == "true" &&
          "$bridge_table_counts_clean" == "true" ]]; then
      post_commit_cleanup_lifecycle_observed="true"
      cleanup_lifecycle_failure_classification="none"
    else
      cleanup_lifecycle_failure_classification="cleanup_lifecycle_failed"
    fi
  elif [[ "$commit_probe_exit_code" == "20" &&
          "$(fact_value "$COMMIT_PROBE_LOG" "command_buffer_commit_no_present_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    current_shell_commit_probe_isolated_metal_device_available="$(fact_value "$COMMIT_PROBE_LOG" "isolated_metal_device_available")"
    cleanup_lifecycle_probe_executed="true"
    cleanup_observed="$(fact_value "$COMMIT_PROBE_LOG" "cleanup_observed")"
    bridge_table_counts_clean="$(fact_value "$COMMIT_PROBE_LOG" "bridge_table_counts_clean")"
    commit_no_present_failure_classification="host_metal_device_unavailable"
    commit_no_present_failure_domain="metal_device_unavailable"
    cleanup_lifecycle_failure_classification="host_metal_device_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: commit no-present probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: exit=$commit_probe_exit_code log=$COMMIT_PROBE_LOG" >&2
    exit 8
  fi
fi

if [[ "$current_shell_command_buffer_commit_no_present_first_slice_ready" == "true" ]]; then
  for fact in \
    "draw_called=true" \
    "end_encoding_called=true" \
    "commit_called=true" \
    "bounded_completion_wait_completed=true" \
    "command_buffer_status_completed=true" \
    "bounded_gpu_submission_completed=true" \
    "present_called=false" \
    "drawable_presented=false" \
    "production_gpu_submission=false" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$COMMIT_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: protected path modified" >&2
  exit 9
fi

{
  echo "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet_version=1"
  echo "stage113_input_mode=$stage113_input_mode"
  echo "stage113_suite_generation_exit_code=$stage113_suite_generation_exit_code"
  echo "stage113_suite_packet=$STAGE113_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage113_log=$STAGE113_LOG"
  echo "commit_probe_log=$COMMIT_PROBE_LOG"
  echo "commit_probe_exit_code=$commit_probe_exit_code"
  echo "draw_call_first_slice_envelope_ready=$stage113_envelope_ready"
  echo "command_buffer_commit_no_present_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$stage113_isolated_metal_device_available"
  echo "current_shell_commit_probe_isolated_metal_device_available=$current_shell_commit_probe_isolated_metal_device_available"
  echo "stage113_current_shell_draw_call_first_slice_ready=$stage113_draw_ready"
  echo "stage113_bounded_draw_call_first_slice_executed=$stage113_draw_executed"
  echo "stage113_draw_call_first_slice_failure_classification=$stage113_failure_classification"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "pipeline_state_bound=$pipeline_state_bound"
  echo "vertex_buffer_bound=$vertex_buffer_bound"
  echo "draw_called=$draw_called"
  echo "positive_draw_call_envelope_before_commit_required=true"
  echo "bounded_commit_no_present_first_slice_should_execute=$bounded_commit_no_present_first_slice_should_execute"
  echo "bounded_command_buffer_commit_no_present_first_slice_executed=$bounded_commit_no_present_first_slice_executed"
  echo "current_shell_command_buffer_commit_no_present_first_slice_ready=$current_shell_command_buffer_commit_no_present_first_slice_ready"
  echo "command_buffer_commit_no_present_first_slice_failure_classification=$commit_no_present_failure_classification"
  echo "command_buffer_commit_no_present_first_slice_failure_domain=$commit_no_present_failure_domain"
  echo "probe_local_command_buffer_commit=$bounded_commit_no_present_first_slice_executed"
  echo "commit_called=$commit_called"
  echo "completion_handler_called=$completion_handler_called"
  echo "bounded_completion_wait_completed=$bounded_completion_wait_completed"
  echo "command_buffer_status_completed=$command_buffer_status_completed"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "bounded_probe_gpu_work_submitted=$gpu_work_submitted"
  echo "production_gpu_submission=$production_gpu_submission"
  echo "post_commit_cleanup_lifecycle_envelope_ready=true"
  echo "cleanup_lifecycle_probe_executed=$cleanup_lifecycle_probe_executed"
  echo "cleanup_observed=$cleanup_observed"
  echo "bridge_table_counts_clean=$bridge_table_counts_clean"
  echo "post_commit_cleanup_lifecycle_observed=$post_commit_cleanup_lifecycle_observed"
  echo "cleanup_lifecycle_failure_classification=$cleanup_lifecycle_failure_classification"
  echo "layer_device_detach_before_cleanup_required=true"
  echo "attachment_texture_detach_before_cleanup_required=true"
  echo "bridge_table_counts_clean_after_cleanup_required=true"
  echo "present_called=false"
  echo "drawable_presented=false"
  echo "render_executed=false"
  echo "production_render_truth=false"
  echo "production_draw_call=false"
  echo "runtime_native_probe_execution=$bounded_commit_no_present_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: route_classification=d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: command_buffer_commit_no_present_first_slice_failure_classification=$commit_no_present_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command buffer commit no-present first slice packet: renderer_state_write=false"
