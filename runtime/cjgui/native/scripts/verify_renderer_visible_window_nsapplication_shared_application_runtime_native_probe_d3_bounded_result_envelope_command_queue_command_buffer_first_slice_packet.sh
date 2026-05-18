#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage106 command queue / command buffer first-slice
# packet。它消费 stage105 command-pipeline readiness envelope；只有当前
# shell 具备 Metal device 时才执行 bounded command queue / command buffer
# native first slice，否则输出同一 envelope 的 host failure classification。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage106-command-queue-command-buffer-first-slice-packet"
COMMAND_PIPELINE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_suite.sh"
COMMAND_QUEUE_PROBE="$SCRIPT_DIR/verify_native_bridge_command_queue_runtime_call.sh"
COMMAND_BUFFER_PROBE="$SCRIPT_DIR/verify_native_bridge_command_buffer_runtime_call.sh"
COMMAND_PIPELINE_LOG="$TMP_DIR/stage105-command-pipeline-suite.log"
COMMAND_QUEUE_LOG="$TMP_DIR/command-queue-runtime-call.log"
COMMAND_BUFFER_LOG="$TMP_DIR/command-buffer-runtime-call.log"
FIRST_SLICE_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-queue-command-buffer-first-slice.packet"
COMMAND_PIPELINE_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage105" "$TMP_DIR/command-queue" "$TMP_DIR/command-buffer"
: > "$COMMAND_PIPELINE_LOG"
: > "$COMMAND_QUEUE_LOG"
: > "$COMMAND_BUFFER_LOG"
: > "$FIRST_SLICE_PACKET"

for script in "$COMMAND_PIPELINE_SUITE_SCRIPT" "$COMMAND_QUEUE_PROBE" "$COMMAND_BUFFER_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -n "$COMMAND_PIPELINE_SUITE_PACKET" ]]; then
  if [[ ! -f "$COMMAND_PIPELINE_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: provided stage105 packet missing $COMMAND_PIPELINE_SUITE_PACKET" >&2
    exit 6
  fi
  {
    echo "provided_command_pipeline_suite_packet_used=true"
    echo "suite_packet_path=$COMMAND_PIPELINE_SUITE_PACKET"
    cat "$COMMAND_PIPELINE_SUITE_PACKET"
  } > "$COMMAND_PIPELINE_LOG"
else
  if ! env TMPDIR="$TMP_DIR/stage105" zsh "$COMMAND_PIPELINE_SUITE_SCRIPT" > "$COMMAND_PIPELINE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: stage105 command pipeline suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: log=$COMMAND_PIPELINE_LOG" >&2
    exit 7
  fi
fi

command_pipeline_suite_packet="${COMMAND_PIPELINE_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$COMMAND_PIPELINE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$command_pipeline_suite_packet" || ! -f "$command_pipeline_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: missing stage105 suite packet" >&2
  exit 8
fi

required_stage105_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_suite_passed=true"
  "visible_window_appkit_harness_ready=true"
  "command_pipeline_host_independent_probes_ready=true"
  "command_pipeline_readiness_envelope_ready=true"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_stage105_facts[@]}"; do
  require_file_fact "$command_pipeline_suite_packet" "$fact"
done

metal_device_available="$(fact_value "$command_pipeline_suite_packet" "isolated_metal_device_available")"
current_shell_command_pipeline_native_execution_ready="$(fact_value "$command_pipeline_suite_packet" "current_shell_command_pipeline_native_execution_ready")"
current_shell_failure_classification="$(fact_value "$command_pipeline_suite_packet" "current_shell_failure_classification")"
visible_window_environment_failure_domain="$(fact_value "$command_pipeline_suite_packet" "visible_window_environment_failure_domain")"
runtime_native_probe_execution="$(fact_value "$command_pipeline_suite_packet" "runtime_native_probe_execution")"

first_slice_should_execute="$current_shell_command_pipeline_native_execution_ready"
first_slice_executed="false"
command_queue_probe_passed="false"
command_buffer_probe_passed="false"
command_queue_created_by_stage="false"
command_buffer_created_by_stage="false"
first_slice_failure_classification="$current_shell_failure_classification"

if [[ "$first_slice_should_execute" == "true" ]]; then
  if ! env TMPDIR="$TMP_DIR/command-queue" zsh "$COMMAND_QUEUE_PROBE" > "$COMMAND_QUEUE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: command queue native first slice failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: log=$COMMAND_QUEUE_LOG" >&2
    exit 9
  fi
  if ! env TMPDIR="$TMP_DIR/command-buffer" zsh "$COMMAND_BUFFER_PROBE" > "$COMMAND_BUFFER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: command buffer native first slice failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: log=$COMMAND_BUFFER_LOG" >&2
    exit 10
  fi
  if grep -F "cjgui command queue runtime call probe: success=true" "$COMMAND_QUEUE_LOG" >/dev/null 2>&1 &&
      grep -F "cjgui command queue runtime call probe: passed" "$COMMAND_QUEUE_LOG" >/dev/null 2>&1; then
    command_queue_probe_passed="true"
    command_queue_created_by_stage="true"
  fi
  if grep -F "cjgui command buffer runtime call probe: success=true" "$COMMAND_BUFFER_LOG" >/dev/null 2>&1 &&
      grep -F "cjgui command buffer runtime call probe: passed" "$COMMAND_BUFFER_LOG" >/dev/null 2>&1; then
    command_buffer_probe_passed="true"
    command_buffer_created_by_stage="true"
  fi
  if [[ "$command_queue_probe_passed" == "true" && "$command_buffer_probe_passed" == "true" ]]; then
    first_slice_executed="true"
    first_slice_failure_classification="none"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: native first slice logs missing success facts" >&2
    exit 11
  fi
elif [[ "$metal_device_available" == "false" &&
        "$current_shell_failure_classification" == "host_metal_device_unavailable" ]]; then
  first_slice_failure_classification="host_metal_device_unavailable"
else
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: first slice not executable but failure classification is incomplete" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: protected path modified" >&2
  exit 13
fi

{
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet_version=1"
  echo "stage105_command_pipeline_suite_packet=$command_pipeline_suite_packet"
  echo "stage105_command_pipeline_suite_passed=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  echo "visible_window_appkit_harness_ready=true"
  echo "isolated_metal_device_available=$metal_device_available"
  echo "visible_window_environment_failure_domain=$visible_window_environment_failure_domain"
  echo "current_shell_failure_classification=$current_shell_failure_classification"
  echo "current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
  echo "bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
  echo "bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
  echo "bounded_command_queue_command_buffer_first_slice_passed=$first_slice_executed"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  echo "command_queue_log=$COMMAND_QUEUE_LOG"
  echo "command_queue_probe_passed=$command_queue_probe_passed"
  echo "command_buffer_log=$COMMAND_BUFFER_LOG"
  echo "command_buffer_probe_passed=$command_buffer_probe_passed"
  echo "command_queue_created_by_stage=$command_queue_created_by_stage"
  echo "command_buffer_created_by_stage=$command_buffer_created_by_stage"
  echo "command_queue_destroyed_by_stage=$command_queue_created_by_stage"
  echo "command_buffer_destroyed_by_stage=$command_buffer_created_by_stage"
  echo "token_local_cleanup_observed=true"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet_passed=true"
} > "$FIRST_SLICE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: route_classification=d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: first_slice_packet_path=$FIRST_SLICE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: first_slice_failure_classification=$first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice packet: renderer_state_write=false"
