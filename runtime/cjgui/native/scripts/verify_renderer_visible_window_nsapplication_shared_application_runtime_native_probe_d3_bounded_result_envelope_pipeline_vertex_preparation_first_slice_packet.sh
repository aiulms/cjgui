#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage111 pipeline / vertex preparation first-slice
# packet。它消费 stage110 encoder suite packet；只有拿到 positive encoder
# envelope 时，才执行 bounded pipeline / vertex preparation probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage111-pipeline-vertex-preparation-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice_owner.sh"
STAGE110_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_render_command_encoder_first_slice_suite.sh"
PIPELINE_VERTEX_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_pipeline_vertex_preparation_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE110_LOG="$TMP_DIR/stage110.log"
PIPELINE_VERTEX_PROBE_LOG="$TMP_DIR/pipeline-vertex-preparation-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-pipeline-vertex-preparation-first-slice.packet"
STAGE110_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDER_COMMAND_ENCODER_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage110" "$TMP_DIR/pipeline-vertex-probe"
: > "$OWNER_LOG"
: > "$STAGE110_LOG"
: > "$PIPELINE_VERTEX_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE110_SUITE_SCRIPT" "$PIPELINE_VERTEX_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice_owner_present=true" \
  "render_command_encoder_first_slice_input=true" \
  "positive_encoder_envelope_before_preparation_required=true" \
  "bounded_isolated_pipeline_vertex_probe_required=true" \
  "probe_local_pipeline_state_required=true" \
  "probe_local_static_triangle_vertex_buffer_required=true" \
  "pipeline_binding_blocked=true" \
  "vertex_buffer_binding_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage110_input_mode="generated_stage110_suite_packet"
if [[ -n "$STAGE110_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE110_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: provided stage110 suite packet missing $STAGE110_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage110_suite_packet_used=true"
    echo "stage110_suite_packet_path=$STAGE110_SUITE_PACKET"
  } > "$STAGE110_LOG"
  stage110_input_mode="provided_stage110_suite_packet"
else
  if ! env TMPDIR="$TMP_DIR/stage110" zsh "$STAGE110_SUITE_SCRIPT" > "$STAGE110_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: stage110 suite generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: log=$STAGE110_LOG" >&2
    exit 8
  fi
  STAGE110_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE110_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE110_SUITE_PACKET" || ! -f "$STAGE110_SUITE_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: missing stage110 suite packet" >&2
  exit 9
fi

for fact in \
  "d3_bounded_result_envelope_render_command_encoder_first_slice_suite_passed=true" \
  "render_command_encoder_first_slice_envelope_ready=true" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false"; do
  require_file_fact "$STAGE110_SUITE_PACKET" "$fact"
done

isolated_metal_device_available="$(fact_value "$STAGE110_SUITE_PACKET" "isolated_metal_device_available")"
stage110_encoder_ready="$(fact_value "$STAGE110_SUITE_PACKET" "current_shell_render_command_encoder_first_slice_ready")"
stage110_encoder_executed="$(fact_value "$STAGE110_SUITE_PACKET" "bounded_render_command_encoder_first_slice_executed")"
stage110_failure_classification="$(fact_value "$STAGE110_SUITE_PACKET" "render_command_encoder_first_slice_failure_classification")"
render_command_encoder_created="$(fact_value "$STAGE110_SUITE_PACKET" "render_command_encoder_created")"
end_encoding_called="$(fact_value "$STAGE110_SUITE_PACKET" "end_encoding_called")"

bounded_pipeline_vertex_preparation_first_slice_should_execute="false"
bounded_pipeline_vertex_preparation_first_slice_executed="false"
current_shell_pipeline_vertex_preparation_first_slice_ready="false"
pipeline_vertex_preparation_first_slice_failure_classification="blocked_pending_positive_encoder_envelope"
pipeline_vertex_preparation_first_slice_failure_domain="encoder_not_ready"
pipeline_vertex_probe_exit_code="not_run"
shader_library_created="false"
shader_functions_created="false"
pipeline_descriptor_configured="false"
pipeline_state_created="false"
vertex_buffer_created="false"

if [[ "$stage110_encoder_ready" == "true" &&
      "$stage110_encoder_executed" == "true" &&
      "$render_command_encoder_created" == "true" &&
      "$end_encoding_called" == "true" ]]; then
  bounded_pipeline_vertex_preparation_first_slice_should_execute="true"
elif [[ "$stage110_failure_classification" == "host_metal_device_unavailable" ]]; then
  pipeline_vertex_preparation_first_slice_failure_classification="host_metal_device_unavailable"
  pipeline_vertex_preparation_first_slice_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_pipeline_vertex_preparation_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/pipeline-vertex-probe" zsh "$PIPELINE_VERTEX_PROBE" > "$PIPELINE_VERTEX_PROBE_LOG" 2>&1
  pipeline_vertex_probe_exit_code="$?"
  set -e
  if [[ "$pipeline_vertex_probe_exit_code" == "0" ]]; then
    require_file_fact "$PIPELINE_VERTEX_PROBE_LOG" "bounded_pipeline_vertex_preparation_first_slice_probe=passed"
    bounded_pipeline_vertex_preparation_first_slice_executed="true"
    current_shell_pipeline_vertex_preparation_first_slice_ready="true"
    pipeline_vertex_preparation_first_slice_failure_classification="none"
    pipeline_vertex_preparation_first_slice_failure_domain="none"
    shader_library_created="$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "shader_library_created")"
    shader_functions_created="$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "shader_functions_created")"
    pipeline_descriptor_configured="$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "pipeline_descriptor_configured")"
    pipeline_state_created="$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "pipeline_state_created")"
    vertex_buffer_created="$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "vertex_buffer_created")"
  elif [[ "$pipeline_vertex_probe_exit_code" == "20" &&
          "$(fact_value "$PIPELINE_VERTEX_PROBE_LOG" "pipeline_vertex_preparation_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    pipeline_vertex_preparation_first_slice_failure_classification="host_metal_device_unavailable"
    pipeline_vertex_preparation_first_slice_failure_domain="metal_device_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: pipeline vertex probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: exit=$pipeline_vertex_probe_exit_code log=$PIPELINE_VERTEX_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_pipeline_vertex_preparation_first_slice_ready" == "true" ]]; then
  for fact in \
    "shader_library_created=true" \
    "shader_functions_created=true" \
    "pipeline_descriptor_configured=true" \
    "pipeline_state_created=true" \
    "vertex_buffer_created=true" \
    "pipeline_state_bound=false" \
    "vertex_buffer_bound=false" \
    "draw_called=false" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "render_executed=false" \
    "renderer_state_write=false"; do
    require_file_fact "$PIPELINE_VERTEX_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: protected path modified" >&2
  exit 11
fi

{
  echo "d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice_packet_version=1"
  echo "stage110_input_mode=$stage110_input_mode"
  echo "stage110_suite_packet=$STAGE110_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage110_log=$STAGE110_LOG"
  echo "pipeline_vertex_probe_log=$PIPELINE_VERTEX_PROBE_LOG"
  echo "pipeline_vertex_probe_exit_code=$pipeline_vertex_probe_exit_code"
  echo "render_command_encoder_first_slice_envelope_ready=true"
  echo "pipeline_vertex_preparation_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "stage110_current_shell_render_command_encoder_first_slice_ready=$stage110_encoder_ready"
  echo "stage110_bounded_render_command_encoder_first_slice_executed=$stage110_encoder_executed"
  echo "stage110_render_command_encoder_first_slice_failure_classification=$stage110_failure_classification"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "positive_encoder_envelope_before_preparation_required=true"
  echo "bounded_pipeline_vertex_preparation_first_slice_should_execute=$bounded_pipeline_vertex_preparation_first_slice_should_execute"
  echo "bounded_pipeline_vertex_preparation_first_slice_executed=$bounded_pipeline_vertex_preparation_first_slice_executed"
  echo "current_shell_pipeline_vertex_preparation_first_slice_ready=$current_shell_pipeline_vertex_preparation_first_slice_ready"
  echo "pipeline_vertex_preparation_first_slice_failure_classification=$pipeline_vertex_preparation_first_slice_failure_classification"
  echo "pipeline_vertex_preparation_first_slice_failure_domain=$pipeline_vertex_preparation_first_slice_failure_domain"
  echo "shader_library_created=$shader_library_created"
  echo "shader_functions_created=$shader_functions_created"
  echo "pipeline_descriptor_configured=$pipeline_descriptor_configured"
  echo "pipeline_state_created=$pipeline_state_created"
  echo "vertex_buffer_created=$vertex_buffer_created"
  echo "probe_local_pipeline_vertex_preparation=$bounded_pipeline_vertex_preparation_first_slice_executed"
  echo "production_pipeline_vertex_preparation=false"
  echo "pipeline_state_bound=false"
  echo "vertex_buffer_bound=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$bounded_pipeline_vertex_preparation_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: route_classification=d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: pipeline_vertex_preparation_first_slice_failure_classification=$pipeline_vertex_preparation_first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice packet: renderer_state_write=false"
