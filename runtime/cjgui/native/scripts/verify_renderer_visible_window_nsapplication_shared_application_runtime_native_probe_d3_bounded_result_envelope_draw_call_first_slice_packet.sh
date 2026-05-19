#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage113 draw-call first-slice packet。它消费
# stage112 binding suite packet；只有拿到 positive binding envelope 时，才执行
# bounded draw-call probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage113-draw-call-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_owner.sh"
STAGE112_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_suite.sh"
DRAW_CALL_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_draw_call_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE112_LOG="$TMP_DIR/stage112.log"
DRAW_CALL_PROBE_LOG="$TMP_DIR/draw-call-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-draw-call-first-slice.packet"
STAGE112_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PIPELINE_VERTEX_BINDING_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage112" "$TMP_DIR/draw-call-probe"
: > "$OWNER_LOG"
: > "$STAGE112_LOG"
: > "$DRAW_CALL_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE112_SUITE_SCRIPT" "$DRAW_CALL_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_draw_call_first_slice_owner_present=true" \
  "pipeline_vertex_binding_first_slice_input=true" \
  "positive_pipeline_vertex_binding_envelope_before_draw_required=true" \
  "bounded_isolated_draw_call_probe_required=true" \
  "probe_local_pipeline_state_bound_required=true" \
  "probe_local_static_triangle_vertex_buffer_bound_required=true" \
  "probe_local_draw_primitives_call_required=true" \
  "commit_present_gpu_render_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage112_input_mode="generated_stage112_suite_packet"
if [[ -n "$STAGE112_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE112_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: provided stage112 suite packet missing $STAGE112_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage112_suite_packet_used=true"
    echo "stage112_suite_packet_path=$STAGE112_SUITE_PACKET"
  } > "$STAGE112_LOG"
  stage112_input_mode="provided_stage112_suite_packet"
else
  if ! env TMPDIR="$TMP_DIR/stage112" zsh "$STAGE112_SUITE_SCRIPT" > "$STAGE112_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: stage112 suite generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: log=$STAGE112_LOG" >&2
    exit 8
  fi
  STAGE112_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE112_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE112_SUITE_PACKET" || ! -f "$STAGE112_SUITE_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: missing stage112 suite packet" >&2
  exit 9
fi

for fact in \
  "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_suite_passed=true" \
  "pipeline_vertex_binding_first_slice_envelope_ready=true" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false"; do
  require_file_fact "$STAGE112_SUITE_PACKET" "$fact"
done

isolated_metal_device_available="$(fact_value "$STAGE112_SUITE_PACKET" "isolated_metal_device_available")"
stage112_binding_ready="$(fact_value "$STAGE112_SUITE_PACKET" "current_shell_pipeline_vertex_binding_first_slice_ready")"
stage112_binding_executed="$(fact_value "$STAGE112_SUITE_PACKET" "bounded_pipeline_vertex_binding_first_slice_executed")"
stage112_failure_classification="$(fact_value "$STAGE112_SUITE_PACKET" "pipeline_vertex_binding_first_slice_failure_classification")"
render_command_encoder_created="$(fact_value "$STAGE112_SUITE_PACKET" "render_command_encoder_created")"
end_encoding_called="$(fact_value "$STAGE112_SUITE_PACKET" "end_encoding_called")"
pipeline_state_created="$(fact_value "$STAGE112_SUITE_PACKET" "pipeline_state_created")"
vertex_buffer_created="$(fact_value "$STAGE112_SUITE_PACKET" "vertex_buffer_created")"
pipeline_state_bound="$(fact_value "$STAGE112_SUITE_PACKET" "pipeline_state_bound")"
vertex_buffer_bound="$(fact_value "$STAGE112_SUITE_PACKET" "vertex_buffer_bound")"

bounded_draw_call_first_slice_should_execute="false"
bounded_draw_call_first_slice_executed="false"
current_shell_draw_call_first_slice_ready="false"
draw_call_first_slice_failure_classification="blocked_pending_positive_pipeline_vertex_binding_envelope"
draw_call_first_slice_failure_domain="pipeline_vertex_binding_not_ready"
draw_call_probe_exit_code="not_run"
draw_called="false"

if [[ "$stage112_binding_ready" == "true" &&
      "$stage112_binding_executed" == "true" &&
      "$render_command_encoder_created" == "true" &&
      "$end_encoding_called" == "true" &&
      "$pipeline_state_created" == "true" &&
      "$vertex_buffer_created" == "true" &&
      "$pipeline_state_bound" == "true" &&
      "$vertex_buffer_bound" == "true" ]]; then
  bounded_draw_call_first_slice_should_execute="true"
elif [[ "$stage112_failure_classification" == "host_metal_device_unavailable" ]]; then
  draw_call_first_slice_failure_classification="host_metal_device_unavailable"
  draw_call_first_slice_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_draw_call_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/draw-call-probe" zsh "$DRAW_CALL_PROBE" > "$DRAW_CALL_PROBE_LOG" 2>&1
  draw_call_probe_exit_code="$?"
  set -e
  if [[ "$draw_call_probe_exit_code" == "0" ]]; then
    require_file_fact "$DRAW_CALL_PROBE_LOG" "bounded_draw_call_first_slice_probe=passed"
    bounded_draw_call_first_slice_executed="true"
    current_shell_draw_call_first_slice_ready="true"
    draw_call_first_slice_failure_classification="none"
    draw_call_first_slice_failure_domain="none"
    draw_called="$(fact_value "$DRAW_CALL_PROBE_LOG" "draw_called")"
    pipeline_state_bound="$(fact_value "$DRAW_CALL_PROBE_LOG" "pipeline_state_bound")"
    vertex_buffer_bound="$(fact_value "$DRAW_CALL_PROBE_LOG" "vertex_buffer_bound")"
  elif [[ "$draw_call_probe_exit_code" == "20" &&
          "$(fact_value "$DRAW_CALL_PROBE_LOG" "draw_call_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    draw_call_first_slice_failure_classification="host_metal_device_unavailable"
    draw_call_first_slice_failure_domain="metal_device_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: draw call probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: exit=$draw_call_probe_exit_code log=$DRAW_CALL_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_draw_call_first_slice_ready" == "true" ]]; then
  for fact in \
    "pipeline_state_bound=true" \
    "vertex_buffer_bound=true" \
    "draw_called=true" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "render_executed=false" \
    "renderer_state_write=false"; do
    require_file_fact "$DRAW_CALL_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: protected path modified" >&2
  exit 11
fi

{
  echo "d3_bounded_result_envelope_draw_call_first_slice_packet_version=1"
  echo "stage112_input_mode=$stage112_input_mode"
  echo "stage112_suite_packet=$STAGE112_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage112_log=$STAGE112_LOG"
  echo "draw_call_probe_log=$DRAW_CALL_PROBE_LOG"
  echo "draw_call_probe_exit_code=$draw_call_probe_exit_code"
  echo "pipeline_vertex_binding_first_slice_envelope_ready=true"
  echo "draw_call_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "stage112_current_shell_pipeline_vertex_binding_first_slice_ready=$stage112_binding_ready"
  echo "stage112_bounded_pipeline_vertex_binding_first_slice_executed=$stage112_binding_executed"
  echo "stage112_pipeline_vertex_binding_first_slice_failure_classification=$stage112_failure_classification"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "pipeline_state_created=$pipeline_state_created"
  echo "vertex_buffer_created=$vertex_buffer_created"
  echo "pipeline_state_bound=$pipeline_state_bound"
  echo "vertex_buffer_bound=$vertex_buffer_bound"
  echo "positive_pipeline_vertex_binding_envelope_before_draw_required=true"
  echo "bounded_draw_call_first_slice_should_execute=$bounded_draw_call_first_slice_should_execute"
  echo "bounded_draw_call_first_slice_executed=$bounded_draw_call_first_slice_executed"
  echo "current_shell_draw_call_first_slice_ready=$current_shell_draw_call_first_slice_ready"
  echo "draw_call_first_slice_failure_classification=$draw_call_first_slice_failure_classification"
  echo "draw_call_first_slice_failure_domain=$draw_call_first_slice_failure_domain"
  echo "probe_local_draw_call=$bounded_draw_call_first_slice_executed"
  echo "production_draw_call=false"
  echo "draw_called=$draw_called"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$bounded_draw_call_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_draw_call_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: route_classification=d3_bounded_result_envelope_draw_call_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: draw_call_first_slice_failure_classification=$draw_call_first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice packet: renderer_state_write=false"
