#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage141 present scheduling packet。它消费 stage140
# commit no-present suite packet；只有 positive commit envelope 已就绪时才运行
# bounded present scheduling probe，且不承认 first-frame / production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE141_PACKET_TMPDIR:-/tmp/cjgui-stage141-present-scheduling-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice_owner.sh"
STAGE140_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_after_draw_call_contract_first_slice_suite.sh"
PRESENT_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_present_no_present_branch_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE140_LOG="$TMP_DIR/stage140.log"
PRESENT_PROBE_LOG="$TMP_DIR/present-scheduling-probe.log"
RESULT_PACKET="$TMP_DIR/stage141-present-scheduling-after-commit-no-present-contract.packet"
STAGE140_SUITE_PACKET="${CJGUI_STAGE140_COMMIT_NO_PRESENT_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage140" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE140_LOG"
: > "$PRESENT_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE140_SUITE_SCRIPT" "$PRESENT_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage141 present scheduling packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage141 present scheduling packet: syntax check failed $script" >&2
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
    echo "cjgui stage141 present scheduling packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage141 present scheduling packet: owner probe failed" >&2
  echo "cjgui stage141 present scheduling packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage141_present_scheduling_after_commit_no_present_contract_owner_present=true" \
  "stage140_commit_no_present_packet_required=true" \
  "bounded_present_scheduling_probe_required=true" \
  "first_frame_observed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage140_input_mode="generated_stage140_suite_packet"
if [[ -n "$STAGE140_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE140_SUITE_PACKET" ]]; then
    echo "cjgui stage141 present scheduling packet: provided stage140 suite packet missing $STAGE140_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage140_suite_packet_used=true"
    echo "stage140_suite_packet_path=$STAGE140_SUITE_PACKET"
  } > "$STAGE140_LOG"
  stage140_input_mode="provided_stage140_suite_packet"
else
  if ! env CJGUI_STAGE140_TMPDIR="$TMP_DIR/stage140" zsh "$STAGE140_SUITE_SCRIPT" > "$STAGE140_LOG" 2>&1; then
    echo "cjgui stage141 present scheduling packet: stage140 suite failed" >&2
    echo "cjgui stage141 present scheduling packet: log=$STAGE140_LOG" >&2
    exit 8
  fi
  STAGE140_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE140_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE140_SUITE_PACKET" || ! -f "$STAGE140_SUITE_PACKET" ]]; then
  echo "cjgui stage141 present scheduling packet: missing stage140 suite packet" >&2
  exit 9
fi
for fact in \
  "stage140_command_buffer_commit_no_present_after_draw_call_contract_first_slice_suite_passed=true" \
  "stage140_command_buffer_commit_no_present_packet_passed=true" \
  "first_frame_observed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE140_SUITE_PACKET" "$fact"
done

stage140_commit_route="$(fact_value "$STAGE140_SUITE_PACKET" "command_buffer_commit_no_present_route_classification")"
stage140_commit_called="$(fact_value "$STAGE140_SUITE_PACKET" "commit_called")"
stage140_gpu_work_submitted="$(fact_value "$STAGE140_SUITE_PACKET" "gpu_work_submitted")"
stage140_gpu_submission_completed="$(fact_value "$STAGE140_SUITE_PACKET" "bounded_gpu_submission_completed")"

bounded_present_should_execute="false"
bounded_present_executed="false"
current_shell_present_ready="false"
present_route="blocked_pending_commit_no_present_contract"
present_probe_exit_code="not_run"
drawable_present_scheduled="false"
present_called="false"
commit_called="$stage140_commit_called"
gpu_work_submitted="$stage140_gpu_work_submitted"
bounded_gpu_submission_completed="$stage140_gpu_submission_completed"

if [[ "$stage140_commit_route" == "command_buffer_commit_no_present_after_draw_call_contract_ready" &&
      "$stage140_commit_called" == "true" &&
      "$stage140_gpu_work_submitted" == "true" &&
      "$stage140_gpu_submission_completed" == "true" ]]; then
  bounded_present_should_execute="true"
elif [[ "$stage140_commit_route" == "host_metal_device_unavailable" ]]; then
  present_route="host_metal_device_unavailable"
fi

if [[ "$bounded_present_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$PRESENT_PROBE" > "$PRESENT_PROBE_LOG" 2>&1
  present_probe_exit_code="$?"
  set -e
  if [[ "$present_probe_exit_code" == "0" ]]; then
    require_file_fact "$PRESENT_PROBE_LOG" "present_no_present_branch_first_slice_probe=passed"
    bounded_present_executed="true"
    current_shell_present_ready="true"
    present_route="present_scheduling_after_commit_no_present_contract_ready"
    drawable_present_scheduled="$(fact_value "$PRESENT_PROBE_LOG" "drawable_present_scheduled")"
    present_called="$(fact_value "$PRESENT_PROBE_LOG" "present_called")"
    commit_called="$(fact_value "$PRESENT_PROBE_LOG" "commit_called")"
    bounded_gpu_submission_completed="$(fact_value "$PRESENT_PROBE_LOG" "bounded_gpu_submission_completed")"
    gpu_work_submitted="$(fact_value "$PRESENT_PROBE_LOG" "gpu_work_submitted")"
  elif [[ "$present_probe_exit_code" == "20" &&
          "$(fact_value "$PRESENT_PROBE_LOG" "present_no_present_branch_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    present_route="host_metal_device_unavailable"
  else
    echo "cjgui stage141 present scheduling packet: bounded present probe failed" >&2
    echo "cjgui stage141 present scheduling packet: exit=$present_probe_exit_code log=$PRESENT_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_present_ready" == "true" ]]; then
  for fact in \
    "present_called=true" \
    "drawable_present_scheduled=true" \
    "commit_called=true" \
    "bounded_gpu_submission_completed=true" \
    "production_render_truth=false" \
    "renderer_state_write=false"; do
    require_file_fact "$PRESENT_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage141 present scheduling packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage141_present_scheduling_after_commit_no_present_contract_first_slice_packet_version=1"
  echo "stage140_input_mode=$stage140_input_mode"
  echo "stage140_suite_packet=$STAGE140_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage140_log=$STAGE140_LOG"
  echo "present_probe_log=$PRESENT_PROBE_LOG"
  echo "present_probe_exit_code=$present_probe_exit_code"
  echo "stage140_commit_no_present_packet_consumed=true"
  echo "stage140_command_buffer_commit_no_present_route_classification=$stage140_commit_route"
  echo "positive_commit_before_present_scheduling_required=true"
  echo "bounded_present_scheduling_should_execute=$bounded_present_should_execute"
  echo "bounded_present_scheduling_executed=$bounded_present_executed"
  echo "current_shell_present_scheduling_ready=$current_shell_present_ready"
  echo "present_scheduling_route_classification=$present_route"
  echo "drawable_present_scheduled=$drawable_present_scheduled"
  echo "present_called=$present_called"
  echo "commit_called=$commit_called"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "gpu_work_submitted=$gpu_work_submitted"
  echo "first_frame_observed=false"
  echo "production_render_truth=false"
  echo "production_present_call=false"
  echo "production_gpu_submission=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=first_frame_observation_after_present_scheduling_contract"
  echo "stage141_present_scheduling_after_commit_no_present_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage141 present scheduling packet: route_classification=$present_route"
echo "cjgui stage141 present scheduling packet: present_scheduling_packet_path=$RESULT_PACKET"
echo "cjgui stage141 present scheduling packet: renderer_state_write=false"
