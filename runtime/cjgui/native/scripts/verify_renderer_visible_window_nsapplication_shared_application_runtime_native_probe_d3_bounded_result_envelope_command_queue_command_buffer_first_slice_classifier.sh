#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage106 command queue / command buffer first-slice
# packet。它把可执行、已执行、host Metal unavailable 和 renderer-state
# stop-line 分开输出。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage106-command-queue-command-buffer-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/first-slice-packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-queue-command-buffer-first-slice-classifier.packet"
FIRST_SLICE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_QUEUE_COMMAND_BUFFER_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi

if [[ -n "$FIRST_SLICE_PACKET" ]]; then
  if [[ ! -f "$FIRST_SLICE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: first slice packet missing $FIRST_SLICE_PACKET" >&2
    exit 4
  fi
  {
    echo "provided_first_slice_packet_used=true"
    echo "first_slice_packet_path=$FIRST_SLICE_PACKET"
    cat "$FIRST_SLICE_PACKET"
  } > "$PACKET_LOG"
else
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: log=$PACKET_LOG" >&2
    exit 5
  fi
fi

first_slice_packet="${FIRST_SLICE_PACKET:-$(grep -Eo 'first_slice_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$first_slice_packet" || ! -f "$first_slice_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: missing first slice packet" >&2
  exit 6
fi

fact_value() {
  local key="$1"
  grep -E "^${key}=" "$first_slice_packet" | tail -1 | cut -d= -f2- || true
}

require_fact() {
  local fact="$1"
  if ! grep -F "$fact" "$first_slice_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: missing packet fact $fact" >&2
    exit 7
  fi
}

required_facts=(
  "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet_passed=true"
  "stage105_command_pipeline_suite_passed=true"
  "command_pipeline_readiness_envelope_ready=true"
  "visible_window_appkit_harness_ready=true"
  "encoder_created=false"
  "draw_called=false"
  "commit_called=false"
  "present_called=false"
  "gpu_work_submitted=false"
  "render_executed=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_facts[@]}"; do
  require_fact "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: protected path modified" >&2
  exit 8
fi

first_slice_should_execute="$(fact_value "bounded_command_queue_command_buffer_first_slice_should_execute")"
first_slice_executed="$(fact_value "bounded_command_queue_command_buffer_first_slice_executed")"
first_slice_passed="$(fact_value "bounded_command_queue_command_buffer_first_slice_passed")"
first_slice_failure_classification="$(fact_value "first_slice_failure_classification")"
metal_device_available="$(fact_value "isolated_metal_device_available")"
command_queue_probe_passed="$(fact_value "command_queue_probe_passed")"
command_buffer_probe_passed="$(fact_value "command_buffer_probe_passed")"

if [[ "$first_slice_should_execute" == "true" && "$first_slice_executed" != "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: first slice should execute but did not" >&2
  exit 9
fi
if [[ "$first_slice_executed" == "true" &&
      ( "$first_slice_passed" != "true" ||
        "$command_queue_probe_passed" != "true" ||
        "$command_buffer_probe_passed" != "true" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: executed first slice missing success facts" >&2
  exit 10
fi
if [[ "$metal_device_available" == "false" &&
      "$first_slice_failure_classification" != "host_metal_device_unavailable" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: Metal unavailable without host classification" >&2
  exit 11
fi

current_shell_first_slice_admitted="false"
if [[ "$first_slice_executed" == "true" && "$first_slice_passed" == "true" ]]; then
  current_shell_first_slice_admitted="true"
fi

{
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier_packet_version=1"
  echo "first_slice_packet=$first_slice_packet"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier_passed=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  echo "visible_window_appkit_harness_ready=true"
  echo "isolated_metal_device_available=$metal_device_available"
  echo "bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
  echo "bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
  echo "bounded_command_queue_command_buffer_first_slice_passed=$first_slice_passed"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  echo "command_queue_probe_passed=$command_queue_probe_passed"
  echo "command_buffer_probe_passed=$command_buffer_probe_passed"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: route_classification=d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: first_slice_failure_classification=$first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice classifier: renderer_state_write=false"
