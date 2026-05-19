#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage113 draw-call first-slice focused suite。它串联
# owner、packet、classifier 与 source/build guard，并输出下一段 command-buffer
# commit readiness 可消费的 suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage113-draw-call-first-slice-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_source_build_guard.sh"
DRAW_CALL_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_draw_call_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-draw-call-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"
readiness_packet=""
classifier_packet=""
source_build_packet=""

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD" "$DRAW_CALL_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "d3_bounded_result_envelope_draw_call_first_slice_owner_present=true"
require_file_fact "$OWNER_LOG" "bounded_isolated_draw_call_probe_required=true"
require_file_fact "$OWNER_LOG" "probe_local_draw_primitives_call_required=true"
require_file_fact "$OWNER_LOG" "commit_present_gpu_render_blocked=true"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: packet generation failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: log=$PACKET_LOG" >&2
  exit 7
fi
readiness_packet="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$readiness_packet" || ! -f "$readiness_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing readiness packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAW_CALL_FIRST_SLICE_PACKET="$readiness_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAW_CALL_FIRST_SLICE_PACKET="$readiness_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAW_CALL_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing source build packet" >&2
  exit 12
fi

required_suite_facts=(
  "d3_bounded_result_envelope_draw_call_first_slice_packet_passed=true"
  "d3_bounded_result_envelope_draw_call_first_slice_classifier_passed=true"
  "source_build_draw_call_first_slice_guard_passed=true"
  "runtime_package_build_passed=true"
  "production_draw_call=false"
  "draw_called=true"
  "commit_called=false"
  "present_called=false"
  "gpu_work_submitted=false"
  "render_executed=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$readiness_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: protected path modified" >&2
  exit 14
fi

isolated_metal_device_available="$(fact_value "$readiness_packet" "isolated_metal_device_available")"
stage112_ready="$(fact_value "$readiness_packet" "stage112_current_shell_pipeline_vertex_binding_first_slice_ready")"
stage112_executed="$(fact_value "$readiness_packet" "stage112_bounded_pipeline_vertex_binding_first_slice_executed")"
draw_should_execute="$(fact_value "$readiness_packet" "bounded_draw_call_first_slice_should_execute")"
draw_executed="$(fact_value "$readiness_packet" "bounded_draw_call_first_slice_executed")"
draw_ready="$(fact_value "$readiness_packet" "current_shell_draw_call_first_slice_ready")"
draw_failure_classification="$(fact_value "$readiness_packet" "draw_call_first_slice_failure_classification")"
classifier_route="$(fact_value "$classifier_packet" "draw_call_first_slice_classifier_route")"
render_command_encoder_created="$(fact_value "$readiness_packet" "render_command_encoder_created")"
end_encoding_called="$(fact_value "$readiness_packet" "end_encoding_called")"
pipeline_state_bound="$(fact_value "$readiness_packet" "pipeline_state_bound")"
vertex_buffer_bound="$(fact_value "$readiness_packet" "vertex_buffer_bound")"
draw_called="$(fact_value "$readiness_packet" "draw_called")"

{
  echo "d3_bounded_result_envelope_draw_call_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "readiness_packet=$readiness_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_draw_call_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_draw_call_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_draw_call_first_slice_classifier_passed=true"
  echo "source_build_draw_call_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_draw_call_first_slice_suite_passed=true"
  echo "draw_call_first_slice_envelope_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "stage112_current_shell_pipeline_vertex_binding_first_slice_ready=$stage112_ready"
  echo "stage112_bounded_pipeline_vertex_binding_first_slice_executed=$stage112_executed"
  echo "bounded_draw_call_first_slice_should_execute=$draw_should_execute"
  echo "bounded_draw_call_first_slice_executed=$draw_executed"
  echo "current_shell_draw_call_first_slice_ready=$draw_ready"
  echo "draw_call_first_slice_failure_classification=$draw_failure_classification"
  echo "draw_call_first_slice_classifier_route=$classifier_route"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "pipeline_state_bound=$pipeline_state_bound"
  echo "vertex_buffer_bound=$vertex_buffer_bound"
  echo "draw_called=$draw_called"
  echo "production_draw_call=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: route_classification=d3_bounded_result_envelope_draw_call_first_slice_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: d3_bounded_result_envelope_draw_call_first_slice_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: bounded_draw_call_first_slice_executed=$draw_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: draw_call_first_slice_failure_classification=$draw_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice suite: renderer_state_write=false"
