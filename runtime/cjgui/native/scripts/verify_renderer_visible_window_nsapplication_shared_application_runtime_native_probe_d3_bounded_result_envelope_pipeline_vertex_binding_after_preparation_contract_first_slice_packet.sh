#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage138 pipeline / vertex binding packet。它消费
# stage137 preparation suite packet；只有 positive preparation envelope 已就绪
# 时才运行 bounded binding probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE138_PACKET_TMPDIR:-/tmp/cjgui-stage138-pipeline-vertex-binding-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_after_preparation_contract_first_slice_owner.sh"
STAGE137_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_after_render_encoder_contract_first_slice_suite.sh"
PIPELINE_VERTEX_BINDING_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_pipeline_vertex_binding_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE137_LOG="$TMP_DIR/stage137.log"
BINDING_PROBE_LOG="$TMP_DIR/pipeline-vertex-binding-probe.log"
RESULT_PACKET="$TMP_DIR/stage138-pipeline-vertex-binding-after-preparation-contract.packet"
STAGE137_SUITE_PACKET="${CJGUI_STAGE137_PIPELINE_VERTEX_PREPARATION_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage137" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE137_LOG"
: > "$BINDING_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE137_SUITE_SCRIPT" "$PIPELINE_VERTEX_BINDING_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage138 pipeline vertex binding packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage138 pipeline vertex binding packet: syntax check failed $script" >&2
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
    echo "cjgui stage138 pipeline vertex binding packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage138 pipeline vertex binding packet: owner probe failed" >&2
  echo "cjgui stage138 pipeline vertex binding packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage138_pipeline_vertex_binding_after_preparation_contract_owner_present=true" \
  "stage137_pipeline_vertex_preparation_packet_required=true" \
  "bounded_pipeline_vertex_binding_probe_required=true" \
  "probe_local_pipeline_state_binding_required=true" \
  "probe_local_vertex_buffer_binding_required=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage137_input_mode="generated_stage137_suite_packet"
if [[ -n "$STAGE137_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE137_SUITE_PACKET" ]]; then
    echo "cjgui stage138 pipeline vertex binding packet: provided stage137 suite packet missing $STAGE137_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage137_suite_packet_used=true"
    echo "stage137_suite_packet_path=$STAGE137_SUITE_PACKET"
  } > "$STAGE137_LOG"
  stage137_input_mode="provided_stage137_suite_packet"
else
  if ! env CJGUI_STAGE137_TMPDIR="$TMP_DIR/stage137" zsh "$STAGE137_SUITE_SCRIPT" > "$STAGE137_LOG" 2>&1; then
    echo "cjgui stage138 pipeline vertex binding packet: stage137 suite failed" >&2
    echo "cjgui stage138 pipeline vertex binding packet: log=$STAGE137_LOG" >&2
    exit 8
  fi
  STAGE137_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE137_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE137_SUITE_PACKET" || ! -f "$STAGE137_SUITE_PACKET" ]]; then
  echo "cjgui stage138 pipeline vertex binding packet: missing stage137 suite packet" >&2
  exit 9
fi
for fact in \
  "stage137_pipeline_vertex_preparation_after_render_encoder_contract_first_slice_suite_passed=true" \
  "stage137_pipeline_vertex_preparation_packet_passed=true" \
  "pipeline_state_bound=false" \
  "vertex_buffer_bound=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE137_SUITE_PACKET" "$fact"
done

stage137_preparation_route="$(fact_value "$STAGE137_SUITE_PACKET" "pipeline_vertex_preparation_route_classification")"
pipeline_state_created="$(fact_value "$STAGE137_SUITE_PACKET" "pipeline_state_created")"
vertex_buffer_created="$(fact_value "$STAGE137_SUITE_PACKET" "vertex_buffer_created")"
render_command_encoder_created="$(fact_value "$STAGE137_SUITE_PACKET" "render_command_encoder_created")"
end_encoding_called="$(fact_value "$STAGE137_SUITE_PACKET" "end_encoding_called")"

bounded_pipeline_vertex_binding_should_execute="false"
bounded_pipeline_vertex_binding_executed="false"
current_shell_pipeline_vertex_binding_ready="false"
pipeline_vertex_binding_route="blocked_pending_pipeline_vertex_preparation_contract"
binding_probe_exit_code="not_run"
pipeline_state_bound="false"
vertex_buffer_bound="false"

if [[ "$stage137_preparation_route" == "pipeline_vertex_preparation_after_render_encoder_contract_ready" &&
      "$pipeline_state_created" == "true" &&
      "$vertex_buffer_created" == "true" ]]; then
  bounded_pipeline_vertex_binding_should_execute="true"
elif [[ "$stage137_preparation_route" == "host_metal_device_unavailable" ]]; then
  pipeline_vertex_binding_route="host_metal_device_unavailable"
fi

if [[ "$bounded_pipeline_vertex_binding_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$PIPELINE_VERTEX_BINDING_PROBE" > "$BINDING_PROBE_LOG" 2>&1
  binding_probe_exit_code="$?"
  set -e
  if [[ "$binding_probe_exit_code" == "0" ]]; then
    require_file_fact "$BINDING_PROBE_LOG" "bounded_pipeline_vertex_binding_first_slice_probe=passed"
    bounded_pipeline_vertex_binding_executed="true"
    current_shell_pipeline_vertex_binding_ready="true"
    pipeline_vertex_binding_route="pipeline_vertex_binding_after_preparation_contract_ready"
    render_command_encoder_created="$(fact_value "$BINDING_PROBE_LOG" "render_command_encoder_created")"
    end_encoding_called="$(fact_value "$BINDING_PROBE_LOG" "end_encoding_called")"
    pipeline_state_created="$(fact_value "$BINDING_PROBE_LOG" "pipeline_state_created")"
    vertex_buffer_created="$(fact_value "$BINDING_PROBE_LOG" "vertex_buffer_created")"
    pipeline_state_bound="$(fact_value "$BINDING_PROBE_LOG" "pipeline_state_bound")"
    vertex_buffer_bound="$(fact_value "$BINDING_PROBE_LOG" "vertex_buffer_bound")"
  elif [[ "$binding_probe_exit_code" == "20" &&
          "$(fact_value "$BINDING_PROBE_LOG" "pipeline_vertex_binding_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    pipeline_vertex_binding_route="host_metal_device_unavailable"
  else
    echo "cjgui stage138 pipeline vertex binding packet: bounded binding probe failed" >&2
    echo "cjgui stage138 pipeline vertex binding packet: exit=$binding_probe_exit_code log=$BINDING_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_pipeline_vertex_binding_ready" == "true" ]]; then
  for fact in \
    "pipeline_state_bound=true" \
    "vertex_buffer_bound=true" \
    "draw_called=false" \
    "commit_called=false" \
    "present_called=false" \
    "renderer_state_write=false"; do
    require_file_fact "$BINDING_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage138 pipeline vertex binding packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage138_pipeline_vertex_binding_after_preparation_contract_first_slice_packet_version=1"
  echo "stage137_input_mode=$stage137_input_mode"
  echo "stage137_suite_packet=$STAGE137_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage137_log=$STAGE137_LOG"
  echo "pipeline_vertex_binding_probe_log=$BINDING_PROBE_LOG"
  echo "pipeline_vertex_binding_probe_exit_code=$binding_probe_exit_code"
  echo "stage137_pipeline_vertex_preparation_packet_consumed=true"
  echo "stage137_pipeline_vertex_preparation_route_classification=$stage137_preparation_route"
  echo "positive_pipeline_vertex_preparation_before_binding_required=true"
  echo "bounded_pipeline_vertex_binding_should_execute=$bounded_pipeline_vertex_binding_should_execute"
  echo "bounded_pipeline_vertex_binding_executed=$bounded_pipeline_vertex_binding_executed"
  echo "current_shell_pipeline_vertex_binding_ready=$current_shell_pipeline_vertex_binding_ready"
  echo "pipeline_vertex_binding_route_classification=$pipeline_vertex_binding_route"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "pipeline_state_created=$pipeline_state_created"
  echo "vertex_buffer_created=$vertex_buffer_created"
  echo "pipeline_state_bound=$pipeline_state_bound"
  echo "vertex_buffer_bound=$vertex_buffer_bound"
  echo "production_pipeline_vertex_binding=false"
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
  echo "next_route=production_next_draw_call_after_pipeline_vertex_binding_contract"
  echo "stage138_pipeline_vertex_binding_after_preparation_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage138 pipeline vertex binding packet: route_classification=$pipeline_vertex_binding_route"
echo "cjgui stage138 pipeline vertex binding packet: pipeline_vertex_binding_packet_path=$RESULT_PACKET"
echo "cjgui stage138 pipeline vertex binding packet: renderer_state_write=false"
