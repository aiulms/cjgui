#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage140 commit no-present packet。它消费 stage139
# draw-call suite packet；只有 positive draw envelope 已就绪时才运行 bounded
# command-buffer commit no-present probe，且始终禁止 present 与 state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE140_PACKET_TMPDIR:-/tmp/cjgui-stage140-command-buffer-commit-no-present-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_after_draw_call_contract_first_slice_owner.sh"
STAGE139_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice_suite.sh"
COMMIT_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_command_buffer_commit_no_present_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE139_LOG="$TMP_DIR/stage139.log"
COMMIT_PROBE_LOG="$TMP_DIR/commit-no-present-probe.log"
RESULT_PACKET="$TMP_DIR/stage140-command-buffer-commit-no-present-after-draw-call-contract.packet"
STAGE139_SUITE_PACKET="${CJGUI_STAGE139_DRAW_CALL_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage139" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE139_LOG"
: > "$COMMIT_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE139_SUITE_SCRIPT" "$COMMIT_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage140 commit no-present packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage140 commit no-present packet: syntax check failed $script" >&2
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
    echo "cjgui stage140 commit no-present packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage140 commit no-present packet: owner probe failed" >&2
  echo "cjgui stage140 commit no-present packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage140_command_buffer_commit_no_present_after_draw_call_contract_owner_present=true" \
  "stage139_draw_call_packet_required=true" \
  "bounded_command_buffer_commit_no_present_probe_required=true" \
  "probe_local_command_buffer_commit_required=true" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage139_input_mode="generated_stage139_suite_packet"
if [[ -n "$STAGE139_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE139_SUITE_PACKET" ]]; then
    echo "cjgui stage140 commit no-present packet: provided stage139 suite packet missing $STAGE139_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage139_suite_packet_used=true"
    echo "stage139_suite_packet_path=$STAGE139_SUITE_PACKET"
  } > "$STAGE139_LOG"
  stage139_input_mode="provided_stage139_suite_packet"
else
  if ! env CJGUI_STAGE139_TMPDIR="$TMP_DIR/stage139" zsh "$STAGE139_SUITE_SCRIPT" > "$STAGE139_LOG" 2>&1; then
    echo "cjgui stage140 commit no-present packet: stage139 suite failed" >&2
    echo "cjgui stage140 commit no-present packet: log=$STAGE139_LOG" >&2
    exit 8
  fi
  STAGE139_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE139_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE139_SUITE_PACKET" || ! -f "$STAGE139_SUITE_PACKET" ]]; then
  echo "cjgui stage140 commit no-present packet: missing stage139 suite packet" >&2
  exit 9
fi
for fact in \
  "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_suite_passed=true" \
  "stage139_draw_call_packet_passed=true" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE139_SUITE_PACKET" "$fact"
done

stage139_draw_route="$(fact_value "$STAGE139_SUITE_PACKET" "draw_call_route_classification")"
draw_called="$(fact_value "$STAGE139_SUITE_PACKET" "draw_called")"
bounded_commit_should_execute="false"
bounded_commit_executed="false"
current_shell_commit_ready="false"
commit_route="blocked_pending_draw_call_contract"
commit_probe_exit_code="not_run"
completion_handler_called="false"
bounded_completion_wait_completed="false"
command_buffer_status_completed="false"
bounded_gpu_submission_completed="false"
gpu_work_submitted="false"
cleanup_observed="not_run"
bridge_table_counts_clean="not_run"

if [[ "$stage139_draw_route" == "draw_call_after_pipeline_vertex_binding_contract_ready" &&
      "$draw_called" == "true" ]]; then
  bounded_commit_should_execute="true"
elif [[ "$stage139_draw_route" == "host_metal_device_unavailable" ]]; then
  commit_route="host_metal_device_unavailable"
fi

if [[ "$bounded_commit_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$COMMIT_PROBE" > "$COMMIT_PROBE_LOG" 2>&1
  commit_probe_exit_code="$?"
  set -e
  if [[ "$commit_probe_exit_code" == "0" ]]; then
    require_file_fact "$COMMIT_PROBE_LOG" "bounded_command_buffer_commit_no_present_first_slice_probe=passed"
    bounded_commit_executed="true"
    current_shell_commit_ready="true"
    commit_route="command_buffer_commit_no_present_after_draw_call_contract_ready"
    draw_called="$(fact_value "$COMMIT_PROBE_LOG" "draw_called")"
    completion_handler_called="$(fact_value "$COMMIT_PROBE_LOG" "completion_handler_called")"
    bounded_completion_wait_completed="$(fact_value "$COMMIT_PROBE_LOG" "bounded_completion_wait_completed")"
    command_buffer_status_completed="$(fact_value "$COMMIT_PROBE_LOG" "command_buffer_status_completed")"
    bounded_gpu_submission_completed="$(fact_value "$COMMIT_PROBE_LOG" "bounded_gpu_submission_completed")"
    gpu_work_submitted="$(fact_value "$COMMIT_PROBE_LOG" "gpu_work_submitted")"
    cleanup_observed="$(fact_value "$COMMIT_PROBE_LOG" "cleanup_observed")"
    bridge_table_counts_clean="$(fact_value "$COMMIT_PROBE_LOG" "bridge_table_counts_clean")"
  elif [[ "$commit_probe_exit_code" == "20" &&
          "$(fact_value "$COMMIT_PROBE_LOG" "command_buffer_commit_no_present_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    commit_route="host_metal_device_unavailable"
  else
    echo "cjgui stage140 commit no-present packet: bounded commit probe failed" >&2
    echo "cjgui stage140 commit no-present packet: exit=$commit_probe_exit_code log=$COMMIT_PROBE_LOG" >&2
    exit 10
  fi
fi

commit_called="false"
if [[ "$current_shell_commit_ready" == "true" ]]; then
  commit_called="$(fact_value "$COMMIT_PROBE_LOG" "commit_called")"
  for fact in \
    "draw_called=true" \
    "commit_called=true" \
    "bounded_gpu_submission_completed=true" \
    "present_called=false" \
    "drawable_presented=false" \
    "renderer_state_write=false"; do
    require_file_fact "$COMMIT_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage140 commit no-present packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage140_command_buffer_commit_no_present_after_draw_call_contract_first_slice_packet_version=1"
  echo "stage139_input_mode=$stage139_input_mode"
  echo "stage139_suite_packet=$STAGE139_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage139_log=$STAGE139_LOG"
  echo "commit_probe_log=$COMMIT_PROBE_LOG"
  echo "commit_probe_exit_code=$commit_probe_exit_code"
  echo "stage139_draw_call_packet_consumed=true"
  echo "stage139_draw_call_route_classification=$stage139_draw_route"
  echo "positive_draw_call_before_commit_required=true"
  echo "bounded_command_buffer_commit_no_present_should_execute=$bounded_commit_should_execute"
  echo "bounded_command_buffer_commit_no_present_executed=$bounded_commit_executed"
  echo "current_shell_command_buffer_commit_no_present_ready=$current_shell_commit_ready"
  echo "command_buffer_commit_no_present_route_classification=$commit_route"
  echo "draw_called=$draw_called"
  echo "probe_local_command_buffer_commit=$bounded_commit_executed"
  echo "commit_called=$commit_called"
  echo "completion_handler_called=$completion_handler_called"
  echo "bounded_completion_wait_completed=$bounded_completion_wait_completed"
  echo "command_buffer_status_completed=$command_buffer_status_completed"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "cleanup_observed=$cleanup_observed"
  echo "bridge_table_counts_clean=$bridge_table_counts_clean"
  echo "present_called=false"
  echo "drawable_presented=false"
  echo "first_frame_observed=false"
  echo "production_render_truth=false"
  echo "production_gpu_submission=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=present_scheduling_after_commit_no_present_contract"
  echo "stage140_command_buffer_commit_no_present_after_draw_call_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage140 commit no-present packet: route_classification=$commit_route"
echo "cjgui stage140 commit no-present packet: commit_no_present_packet_path=$RESULT_PACKET"
echo "cjgui stage140 commit no-present packet: renderer_state_write=false"
