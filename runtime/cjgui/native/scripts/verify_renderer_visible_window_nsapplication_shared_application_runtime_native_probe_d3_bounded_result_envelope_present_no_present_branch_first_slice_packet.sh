#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage115 present/no-present branch first-slice packet。
# 它消费 stage114 command-buffer commit no-present suite packet；只有拿到
# positive commit envelope 时，才执行 bounded present branch probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage115-present-no-present-branch-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_owner.sh"
STAGE114_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_suite.sh"
PRESENT_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_present_no_present_branch_first_slice.sh"
DEFAULT_STAGE114_SUITE_PACKET="/tmp/cjgui-stage114-command-buffer-commit-no-present-first-slice-suite/d3-bounded-result-envelope-command-buffer-commit-no-present-first-slice-suite.packet"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE114_LOG="$TMP_DIR/stage114.log"
PRESENT_PROBE_LOG="$TMP_DIR/present-no-present-branch-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-present-no-present-branch-first-slice.packet"
STAGE114_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_BUFFER_COMMIT_NO_PRESENT_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage114" "$TMP_DIR/present-probe"
: > "$OWNER_LOG"
: > "$STAGE114_LOG"
: > "$PRESENT_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE114_SUITE_SCRIPT" "$PRESENT_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_present_no_present_branch_first_slice_owner_present=true" \
  "command_buffer_commit_no_present_first_slice_input=true" \
  "positive_command_buffer_commit_no_present_envelope_before_present_branch_required=true" \
  "bounded_isolated_present_no_present_branch_probe_required=true" \
  "probe_local_drawable_present_scheduling_required=true" \
  "present_after_encoding_before_commit_required=true" \
  "no_present_branch_when_commit_envelope_missing_required=true" \
  "production_present_blocked=true" \
  "production_render_truth_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage114_input_mode="missing_positive_command_buffer_commit_no_present_suite_packet"
stage114_suite_generation_exit_code="not_run"
if [[ -n "$STAGE114_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE114_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: provided stage114 suite packet missing $STAGE114_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage114_suite_packet_used=true"
    echo "stage114_suite_packet_path=$STAGE114_SUITE_PACKET"
  } > "$STAGE114_LOG"
  stage114_input_mode="provided_stage114_suite_packet"
elif [[ -f "$DEFAULT_STAGE114_SUITE_PACKET" ]]; then
  STAGE114_SUITE_PACKET="$DEFAULT_STAGE114_SUITE_PACKET"
  {
    echo "cached_stage114_suite_packet_used=true"
    echo "stage114_suite_packet_path=$STAGE114_SUITE_PACKET"
  } > "$STAGE114_LOG"
  stage114_input_mode="cached_stage114_suite_packet"
else
  set +e
  env TMPDIR="$TMP_DIR/stage114" zsh "$STAGE114_SUITE_SCRIPT" > "$STAGE114_LOG" 2>&1
  stage114_suite_generation_exit_code="$?"
  set -e
  if [[ "$stage114_suite_generation_exit_code" == "0" ]]; then
    STAGE114_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE114_LOG" | tail -1 | cut -d= -f2-)"
    stage114_input_mode="generated_stage114_suite_packet"
  fi
fi

stage114_envelope_ready="false"
stage114_commit_ready="false"
stage114_commit_executed="false"
stage114_failure_classification="missing_positive_command_buffer_commit_no_present_suite_packet"
stage114_isolated_metal_device_available="unknown"
stage114_commit_called="false"
stage114_completion_wait="false"
stage114_command_buffer_completed="false"
stage114_gpu_submission_completed="false"
stage114_gpu_work_submitted="false"

if [[ -n "$STAGE114_SUITE_PACKET" && -f "$STAGE114_SUITE_PACKET" ]]; then
  for fact in \
    "d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_suite_passed=true" \
    "command_buffer_commit_no_present_first_slice_envelope_ready=true" \
    "present_called=false" \
    "drawable_presented=false" \
    "production_gpu_submission=false" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$STAGE114_SUITE_PACKET" "$fact"
  done
  stage114_envelope_ready="$(fact_value "$STAGE114_SUITE_PACKET" "command_buffer_commit_no_present_first_slice_envelope_ready")"
  stage114_commit_ready="$(fact_value "$STAGE114_SUITE_PACKET" "current_shell_command_buffer_commit_no_present_first_slice_ready")"
  stage114_commit_executed="$(fact_value "$STAGE114_SUITE_PACKET" "bounded_command_buffer_commit_no_present_first_slice_executed")"
  stage114_failure_classification="$(fact_value "$STAGE114_SUITE_PACKET" "command_buffer_commit_no_present_first_slice_failure_classification")"
  stage114_isolated_metal_device_available="$(fact_value "$STAGE114_SUITE_PACKET" "current_shell_commit_probe_isolated_metal_device_available")"
  stage114_commit_called="$(fact_value "$STAGE114_SUITE_PACKET" "commit_called")"
  stage114_completion_wait="$(fact_value "$STAGE114_SUITE_PACKET" "bounded_completion_wait_completed")"
  stage114_command_buffer_completed="$(fact_value "$STAGE114_SUITE_PACKET" "command_buffer_status_completed")"
  stage114_gpu_submission_completed="$(fact_value "$STAGE114_SUITE_PACKET" "bounded_gpu_submission_completed")"
  stage114_gpu_work_submitted="$(fact_value "$STAGE114_SUITE_PACKET" "gpu_work_submitted")"
fi

bounded_present_no_present_branch_first_slice_should_execute="false"
bounded_present_no_present_branch_first_slice_executed="false"
current_shell_present_no_present_branch_first_slice_ready="false"
present_no_present_failure_classification="blocked_pending_positive_command_buffer_commit_no_present_envelope"
present_no_present_failure_domain="command_buffer_commit_no_present_first_slice_not_ready"
present_probe_exit_code="not_run"
present_branch_selected="false"
no_present_branch_selected="true"
present_after_encoding_before_commit="false"
present_called="false"
drawable_present_scheduled="false"
bounded_drawable_present_scheduled="false"
commit_called="false"
completion_handler_called="false"
bounded_completion_wait_completed="false"
command_buffer_status_completed="false"
bounded_gpu_submission_completed="false"
gpu_work_submitted="false"
production_present_call="false"
production_gpu_submission="false"
current_shell_present_probe_isolated_metal_device_available="not_run"

if [[ "$stage114_envelope_ready" == "true" &&
      "$stage114_commit_ready" == "true" &&
      "$stage114_commit_executed" == "true" &&
      "$stage114_commit_called" == "true" &&
      "$stage114_completion_wait" == "true" &&
      "$stage114_command_buffer_completed" == "true" &&
      "$stage114_gpu_submission_completed" == "true" &&
      "$stage114_gpu_work_submitted" == "true" ]]; then
  bounded_present_no_present_branch_first_slice_should_execute="true"
  no_present_branch_selected="false"
elif [[ "$stage114_failure_classification" == "host_metal_device_unavailable" ]]; then
  present_no_present_failure_classification="host_metal_device_unavailable"
  present_no_present_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_present_no_present_branch_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/present-probe" zsh "$PRESENT_PROBE" > "$PRESENT_PROBE_LOG" 2>&1
  present_probe_exit_code="$?"
  set -e
  if [[ "$present_probe_exit_code" == "0" ]]; then
    require_file_fact "$PRESENT_PROBE_LOG" "present_no_present_branch_first_slice_probe=passed"
    current_shell_present_probe_isolated_metal_device_available="$(fact_value "$PRESENT_PROBE_LOG" "isolated_metal_device_available")"
    bounded_present_no_present_branch_first_slice_executed="true"
    current_shell_present_no_present_branch_first_slice_ready="true"
    present_no_present_failure_classification="none"
    present_no_present_failure_domain="none"
    present_branch_selected="$(fact_value "$PRESENT_PROBE_LOG" "present_branch_selected")"
    no_present_branch_selected="$(fact_value "$PRESENT_PROBE_LOG" "no_present_branch_selected")"
    present_after_encoding_before_commit="$(fact_value "$PRESENT_PROBE_LOG" "present_after_encoding_before_commit")"
    present_called="$(fact_value "$PRESENT_PROBE_LOG" "present_called")"
    drawable_present_scheduled="$(fact_value "$PRESENT_PROBE_LOG" "drawable_present_scheduled")"
    bounded_drawable_present_scheduled="$(fact_value "$PRESENT_PROBE_LOG" "bounded_drawable_present_scheduled")"
    commit_called="$(fact_value "$PRESENT_PROBE_LOG" "commit_called")"
    completion_handler_called="$(fact_value "$PRESENT_PROBE_LOG" "completion_handler_called")"
    bounded_completion_wait_completed="$(fact_value "$PRESENT_PROBE_LOG" "bounded_completion_wait_completed")"
    command_buffer_status_completed="$(fact_value "$PRESENT_PROBE_LOG" "command_buffer_status_completed")"
    bounded_gpu_submission_completed="$(fact_value "$PRESENT_PROBE_LOG" "bounded_gpu_submission_completed")"
    gpu_work_submitted="$(fact_value "$PRESENT_PROBE_LOG" "gpu_work_submitted")"
    production_present_call="$(fact_value "$PRESENT_PROBE_LOG" "production_present_call")"
    production_gpu_submission="$(fact_value "$PRESENT_PROBE_LOG" "production_gpu_submission")"
  elif [[ "$present_probe_exit_code" == "20" &&
          "$(fact_value "$PRESENT_PROBE_LOG" "present_no_present_branch_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    current_shell_present_probe_isolated_metal_device_available="$(fact_value "$PRESENT_PROBE_LOG" "isolated_metal_device_available")"
    present_no_present_failure_classification="host_metal_device_unavailable"
    present_no_present_failure_domain="metal_device_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: present/no-present branch probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: exit=$present_probe_exit_code log=$PRESENT_PROBE_LOG" >&2
    exit 8
  fi
fi

if [[ "$current_shell_present_no_present_branch_first_slice_ready" == "true" ]]; then
  for fact in \
    "present_branch_selected=true" \
    "no_present_branch_selected=false" \
    "present_after_encoding_before_commit=true" \
    "present_called=true" \
    "drawable_present_scheduled=true" \
    "bounded_drawable_present_scheduled=true" \
    "commit_called=true" \
    "bounded_completion_wait_completed=true" \
    "command_buffer_status_completed=true" \
    "bounded_gpu_submission_completed=true" \
    "production_present_call=false" \
    "production_gpu_submission=false" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$PRESENT_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: protected path modified" >&2
  exit 9
fi

{
  echo "d3_bounded_result_envelope_present_no_present_branch_first_slice_packet_version=1"
  echo "stage114_input_mode=$stage114_input_mode"
  echo "stage114_suite_generation_exit_code=$stage114_suite_generation_exit_code"
  echo "stage114_suite_packet=$STAGE114_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage114_log=$STAGE114_LOG"
  echo "present_probe_log=$PRESENT_PROBE_LOG"
  echo "present_probe_exit_code=$present_probe_exit_code"
  echo "present_no_present_branch_first_slice_owner_ready=true"
  echo "command_buffer_commit_no_present_first_slice_envelope_ready=$stage114_envelope_ready"
  echo "stage114_current_shell_command_buffer_commit_no_present_first_slice_ready=$stage114_commit_ready"
  echo "stage114_bounded_command_buffer_commit_no_present_first_slice_executed=$stage114_commit_executed"
  echo "stage114_command_buffer_commit_no_present_first_slice_failure_classification=$stage114_failure_classification"
  echo "stage114_current_shell_commit_probe_isolated_metal_device_available=$stage114_isolated_metal_device_available"
  echo "stage114_commit_called=$stage114_commit_called"
  echo "stage114_bounded_completion_wait_completed=$stage114_completion_wait"
  echo "stage114_command_buffer_status_completed=$stage114_command_buffer_completed"
  echo "stage114_bounded_gpu_submission_completed=$stage114_gpu_submission_completed"
  echo "stage114_gpu_work_submitted=$stage114_gpu_work_submitted"
  echo "positive_command_buffer_commit_no_present_envelope_before_present_branch_required=true"
  echo "bounded_present_no_present_branch_first_slice_should_execute=$bounded_present_no_present_branch_first_slice_should_execute"
  echo "bounded_present_no_present_branch_first_slice_executed=$bounded_present_no_present_branch_first_slice_executed"
  echo "current_shell_present_no_present_branch_first_slice_ready=$current_shell_present_no_present_branch_first_slice_ready"
  echo "present_no_present_branch_first_slice_failure_classification=$present_no_present_failure_classification"
  echo "present_no_present_branch_first_slice_failure_domain=$present_no_present_failure_domain"
  echo "current_shell_present_probe_isolated_metal_device_available=$current_shell_present_probe_isolated_metal_device_available"
  echo "present_branch_selected=$present_branch_selected"
  echo "no_present_branch_selected=$no_present_branch_selected"
  echo "present_after_encoding_before_commit=$present_after_encoding_before_commit"
  echo "present_called=$present_called"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "commit_called=$commit_called"
  echo "completion_handler_called=$completion_handler_called"
  echo "bounded_completion_wait_completed=$bounded_completion_wait_completed"
  echo "command_buffer_status_completed=$command_buffer_status_completed"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "bounded_probe_gpu_work_submitted=$gpu_work_submitted"
  echo "drawable_presented=false"
  echo "production_present_call=$production_present_call"
  echo "production_gpu_submission=$production_gpu_submission"
  echo "render_executed=false"
  echo "production_render_truth=false"
  echo "production_draw_call=false"
  echo "runtime_native_probe_execution=$bounded_present_no_present_branch_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_present_no_present_branch_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: route_classification=d3_bounded_result_envelope_present_no_present_branch_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: present_no_present_branch_first_slice_failure_classification=$present_no_present_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice packet: renderer_state_write=false"
