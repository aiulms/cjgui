#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage137 pipeline / vertex preparation packet。它消费
# stage136 command-buffer/render-encoder suite packet；只有 positive render
# encoder envelope 已就绪时才运行 bounded preparation probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE137_PACKET_TMPDIR:-/tmp/cjgui-stage137-pipeline-vertex-preparation-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_after_render_encoder_contract_first_slice_owner.sh"
STAGE136_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite.sh"
PIPELINE_VERTEX_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_pipeline_vertex_preparation_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE136_LOG="$TMP_DIR/stage136.log"
PROBE_LOG="$TMP_DIR/pipeline-vertex-preparation-probe.log"
RESULT_PACKET="$TMP_DIR/stage137-pipeline-vertex-preparation-after-render-encoder-contract.packet"
STAGE136_SUITE_PACKET="${CJGUI_STAGE136_COMMAND_BUFFER_RENDER_ENCODER_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage136" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE136_LOG"
: > "$PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE136_SUITE_SCRIPT" "$PIPELINE_VERTEX_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage137 pipeline vertex preparation packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage137 pipeline vertex preparation packet: syntax check failed $script" >&2
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
    echo "cjgui stage137 pipeline vertex preparation packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage137 pipeline vertex preparation packet: owner probe failed" >&2
  echo "cjgui stage137 pipeline vertex preparation packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage137_pipeline_vertex_preparation_after_render_encoder_contract_owner_present=true" \
  "stage136_render_encoder_contract_packet_required=true" \
  "bounded_pipeline_vertex_preparation_probe_required=true" \
  "pipeline_state_binding_blocked=true" \
  "vertex_buffer_binding_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage136_input_mode="generated_stage136_suite_packet"
if [[ -n "$STAGE136_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE136_SUITE_PACKET" ]]; then
    echo "cjgui stage137 pipeline vertex preparation packet: provided stage136 suite packet missing $STAGE136_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage136_suite_packet_used=true"
    echo "stage136_suite_packet_path=$STAGE136_SUITE_PACKET"
  } > "$STAGE136_LOG"
  stage136_input_mode="provided_stage136_suite_packet"
else
  if ! env CJGUI_STAGE136_TMPDIR="$TMP_DIR/stage136" zsh "$STAGE136_SUITE_SCRIPT" > "$STAGE136_LOG" 2>&1; then
    echo "cjgui stage137 pipeline vertex preparation packet: stage136 suite failed" >&2
    echo "cjgui stage137 pipeline vertex preparation packet: log=$STAGE136_LOG" >&2
    exit 8
  fi
  STAGE136_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE136_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE136_SUITE_PACKET" || ! -f "$STAGE136_SUITE_PACKET" ]]; then
  echo "cjgui stage137 pipeline vertex preparation packet: missing stage136 suite packet" >&2
  exit 9
fi
for fact in \
  "stage136_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite_passed=true" \
  "stage136_render_encoder_contract_packet_passed=true" \
  "pipeline_state_bound=false" \
  "vertex_buffer_bound=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE136_SUITE_PACKET" "$fact"
done

stage136_render_encoder_route="$(fact_value "$STAGE136_SUITE_PACKET" "render_encoder_contract_route_classification")"
render_command_encoder_created="$(fact_value "$STAGE136_SUITE_PACKET" "render_command_encoder_created")"
end_encoding_called="$(fact_value "$STAGE136_SUITE_PACKET" "end_encoding_called")"

bounded_pipeline_vertex_preparation_should_execute="false"
bounded_pipeline_vertex_preparation_executed="false"
current_shell_pipeline_vertex_preparation_ready="false"
pipeline_vertex_preparation_route="blocked_pending_render_encoder_contract"
probe_exit_code="not_run"
shader_library_created="false"
shader_functions_created="false"
pipeline_descriptor_configured="false"
pipeline_state_created="false"
vertex_buffer_created="false"

if [[ "$stage136_render_encoder_route" == "bounded_command_buffer_render_pass_encoder_contract_ready" &&
      "$render_command_encoder_created" == "true" &&
      "$end_encoding_called" == "true" ]]; then
  bounded_pipeline_vertex_preparation_should_execute="true"
elif [[ "$stage136_render_encoder_route" == "host_metal_device_unavailable" ]]; then
  pipeline_vertex_preparation_route="host_metal_device_unavailable"
fi

if [[ "$bounded_pipeline_vertex_preparation_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$PIPELINE_VERTEX_PROBE" > "$PROBE_LOG" 2>&1
  probe_exit_code="$?"
  set -e
  if [[ "$probe_exit_code" == "0" ]]; then
    require_file_fact "$PROBE_LOG" "bounded_pipeline_vertex_preparation_first_slice_probe=passed"
    bounded_pipeline_vertex_preparation_executed="true"
    current_shell_pipeline_vertex_preparation_ready="true"
    pipeline_vertex_preparation_route="pipeline_vertex_preparation_after_render_encoder_contract_ready"
    shader_library_created="$(fact_value "$PROBE_LOG" "shader_library_created")"
    shader_functions_created="$(fact_value "$PROBE_LOG" "shader_functions_created")"
    pipeline_descriptor_configured="$(fact_value "$PROBE_LOG" "pipeline_descriptor_configured")"
    pipeline_state_created="$(fact_value "$PROBE_LOG" "pipeline_state_created")"
    vertex_buffer_created="$(fact_value "$PROBE_LOG" "vertex_buffer_created")"
  elif [[ "$probe_exit_code" == "20" &&
          "$(fact_value "$PROBE_LOG" "pipeline_vertex_preparation_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    pipeline_vertex_preparation_route="host_metal_device_unavailable"
  else
    echo "cjgui stage137 pipeline vertex preparation packet: bounded preparation probe failed" >&2
    echo "cjgui stage137 pipeline vertex preparation packet: exit=$probe_exit_code log=$PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_pipeline_vertex_preparation_ready" == "true" ]]; then
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
    "renderer_state_write=false"; do
    require_file_fact "$PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage137 pipeline vertex preparation packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage137_pipeline_vertex_preparation_after_render_encoder_contract_first_slice_packet_version=1"
  echo "stage136_input_mode=$stage136_input_mode"
  echo "stage136_suite_packet=$STAGE136_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage136_log=$STAGE136_LOG"
  echo "pipeline_vertex_preparation_probe_log=$PROBE_LOG"
  echo "pipeline_vertex_preparation_probe_exit_code=$probe_exit_code"
  echo "stage136_render_encoder_contract_packet_consumed=true"
  echo "stage136_render_encoder_contract_route_classification=$stage136_render_encoder_route"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "positive_render_encoder_before_pipeline_vertex_preparation_required=true"
  echo "bounded_pipeline_vertex_preparation_should_execute=$bounded_pipeline_vertex_preparation_should_execute"
  echo "bounded_pipeline_vertex_preparation_executed=$bounded_pipeline_vertex_preparation_executed"
  echo "current_shell_pipeline_vertex_preparation_ready=$current_shell_pipeline_vertex_preparation_ready"
  echo "pipeline_vertex_preparation_route_classification=$pipeline_vertex_preparation_route"
  echo "shader_library_created=$shader_library_created"
  echo "shader_functions_created=$shader_functions_created"
  echo "pipeline_descriptor_configured=$pipeline_descriptor_configured"
  echo "pipeline_state_created=$pipeline_state_created"
  echo "vertex_buffer_created=$vertex_buffer_created"
  echo "production_pipeline_vertex_preparation=false"
  echo "pipeline_state_bound=false"
  echo "vertex_buffer_bound=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "first_frame_observed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_next_pipeline_vertex_binding_after_preparation_contract"
  echo "stage137_pipeline_vertex_preparation_after_render_encoder_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage137 pipeline vertex preparation packet: route_classification=$pipeline_vertex_preparation_route"
echo "cjgui stage137 pipeline vertex preparation packet: pipeline_vertex_preparation_packet_path=$RESULT_PACKET"
echo "cjgui stage137 pipeline vertex preparation packet: renderer_state_write=false"
