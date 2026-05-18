#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage106 command queue / command buffer first-slice
# focused suite。它先生成 stage105 readiness envelope，再执行或分类
# bounded command queue / command buffer first slice，并保持 renderer state
# write blocked。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage106-command-queue-command-buffer-first-slice-suite"
COMMAND_PIPELINE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_suite.sh"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_source_build_guard.sh"
COMMAND_PIPELINE_LOG="$TMP_DIR/stage105-command-pipeline-suite.log"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-queue-command-buffer-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$COMMAND_PIPELINE_LOG"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$COMMAND_PIPELINE_SUITE_SCRIPT" "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! env TMPDIR="$TMP_DIR/stage105" zsh "$COMMAND_PIPELINE_SUITE_SCRIPT" > "$COMMAND_PIPELINE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: stage105 command pipeline suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: log=$COMMAND_PIPELINE_LOG" >&2
  exit 5
fi
command_pipeline_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$COMMAND_PIPELINE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$command_pipeline_suite_packet" || ! -f "$command_pipeline_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing stage105 suite packet" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: log=$OWNER_LOG" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_SUITE_PACKET="$command_pipeline_suite_packet" \
  zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: first slice packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: log=$PACKET_LOG" >&2
  exit 8
fi
first_slice_packet="$(grep -Eo 'first_slice_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$first_slice_packet" || ! -f "$first_slice_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing first slice packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_QUEUE_COMMAND_BUFFER_FIRST_SLICE_PACKET="$first_slice_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: log=$CLASSIFIER_LOG" >&2
  exit 10
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing classifier packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_QUEUE_COMMAND_BUFFER_FIRST_SLICE_PACKET="$first_slice_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_QUEUE_COMMAND_BUFFER_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing source build packet" >&2
  exit 13
fi

required_suite_facts=(
  "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet_passed=true"
  "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier_passed=true"
  "source_build_command_queue_command_buffer_first_slice_guard_passed=true"
  "runtime_package_build_passed=true"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$first_slice_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: missing fact $fact" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: protected path modified" >&2
  exit 15
fi

isolated_metal_device_available="$(grep -E '^isolated_metal_device_available=' "$first_slice_packet" | tail -1 | cut -d= -f2-)"
first_slice_should_execute="$(grep -E '^bounded_command_queue_command_buffer_first_slice_should_execute=' "$first_slice_packet" | tail -1 | cut -d= -f2-)"
first_slice_executed="$(grep -E '^bounded_command_queue_command_buffer_first_slice_executed=' "$first_slice_packet" | tail -1 | cut -d= -f2-)"
first_slice_failure_classification="$(grep -E '^first_slice_failure_classification=' "$first_slice_packet" | tail -1 | cut -d= -f2-)"
current_shell_first_slice_admitted="$(grep -E '^current_shell_first_slice_admitted=' "$classifier_packet" | tail -1 | cut -d= -f2-)"

{
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_suite_version=1"
  echo "stage105_command_pipeline_log=$COMMAND_PIPELINE_LOG"
  echo "stage105_command_pipeline_suite_packet=$command_pipeline_suite_packet"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "first_slice_packet=$first_slice_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_classifier_passed=true"
  echo "source_build_command_queue_command_buffer_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_suite_passed=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
  echo "bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  grep -E '^command_queue_probe_passed=' "$first_slice_packet" | tail -1
  grep -E '^command_buffer_probe_passed=' "$first_slice_packet" | tail -1
  grep -E '^command_queue_created_by_stage=' "$first_slice_packet" | tail -1
  grep -E '^command_buffer_created_by_stage=' "$first_slice_packet" | tail -1
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: route_classification=d3_bounded_result_envelope_command_queue_command_buffer_first_slice_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: d3_bounded_result_envelope_command_queue_command_buffer_first_slice_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: first_slice_failure_classification=$first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice suite: renderer_state_write=false"
