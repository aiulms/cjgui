#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage139 no-submit draw-call packet。它消费 stage138
# binding suite packet；只有 positive binding envelope 已就绪时才运行 bounded
# draw-call probe，且始终禁止 commit / present。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE139_PACKET_TMPDIR:-/tmp/cjgui-stage139-draw-call-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice_owner.sh"
STAGE138_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_after_preparation_contract_first_slice_suite.sh"
DRAW_CALL_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_draw_call_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE138_LOG="$TMP_DIR/stage138.log"
DRAW_CALL_PROBE_LOG="$TMP_DIR/draw-call-probe.log"
RESULT_PACKET="$TMP_DIR/stage139-draw-call-after-pipeline-vertex-binding-contract.packet"
STAGE138_SUITE_PACKET="${CJGUI_STAGE138_PIPELINE_VERTEX_BINDING_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage138" "$TMP_DIR/probe"
: > "$OWNER_LOG"
: > "$STAGE138_LOG"
: > "$DRAW_CALL_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE138_SUITE_SCRIPT" "$DRAW_CALL_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage139 draw call packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage139 draw call packet: syntax check failed $script" >&2
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
    echo "cjgui stage139 draw call packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage139 draw call packet: owner probe failed" >&2
  echo "cjgui stage139 draw call packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage139_draw_call_after_pipeline_vertex_binding_contract_owner_present=true" \
  "stage138_pipeline_vertex_binding_packet_required=true" \
  "bounded_draw_call_probe_required=true" \
  "probe_local_draw_primitives_call_required=true" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage138_input_mode="generated_stage138_suite_packet"
if [[ -n "$STAGE138_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE138_SUITE_PACKET" ]]; then
    echo "cjgui stage139 draw call packet: provided stage138 suite packet missing $STAGE138_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage138_suite_packet_used=true"
    echo "stage138_suite_packet_path=$STAGE138_SUITE_PACKET"
  } > "$STAGE138_LOG"
  stage138_input_mode="provided_stage138_suite_packet"
else
  if ! env CJGUI_STAGE138_TMPDIR="$TMP_DIR/stage138" zsh "$STAGE138_SUITE_SCRIPT" > "$STAGE138_LOG" 2>&1; then
    echo "cjgui stage139 draw call packet: stage138 suite failed" >&2
    echo "cjgui stage139 draw call packet: log=$STAGE138_LOG" >&2
    exit 8
  fi
  STAGE138_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE138_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE138_SUITE_PACKET" || ! -f "$STAGE138_SUITE_PACKET" ]]; then
  echo "cjgui stage139 draw call packet: missing stage138 suite packet" >&2
  exit 9
fi
for fact in \
  "stage138_pipeline_vertex_binding_after_preparation_contract_first_slice_suite_passed=true" \
  "stage138_pipeline_vertex_binding_packet_passed=true" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE138_SUITE_PACKET" "$fact"
done

stage138_binding_route="$(fact_value "$STAGE138_SUITE_PACKET" "pipeline_vertex_binding_route_classification")"
pipeline_state_bound="$(fact_value "$STAGE138_SUITE_PACKET" "pipeline_state_bound")"
vertex_buffer_bound="$(fact_value "$STAGE138_SUITE_PACKET" "vertex_buffer_bound")"
render_command_encoder_created="false"
end_encoding_called="false"

bounded_draw_call_should_execute="false"
bounded_draw_call_executed="false"
current_shell_draw_call_ready="false"
draw_call_route="blocked_pending_pipeline_vertex_binding_contract"
draw_call_probe_exit_code="not_run"
draw_called="false"

if [[ "$stage138_binding_route" == "pipeline_vertex_binding_after_preparation_contract_ready" &&
      "$pipeline_state_bound" == "true" &&
      "$vertex_buffer_bound" == "true" ]]; then
  bounded_draw_call_should_execute="true"
elif [[ "$stage138_binding_route" == "host_metal_device_unavailable" ]]; then
  draw_call_route="host_metal_device_unavailable"
fi

if [[ "$bounded_draw_call_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/probe" zsh "$DRAW_CALL_PROBE" > "$DRAW_CALL_PROBE_LOG" 2>&1
  draw_call_probe_exit_code="$?"
  set -e
  if [[ "$draw_call_probe_exit_code" == "0" ]]; then
    require_file_fact "$DRAW_CALL_PROBE_LOG" "bounded_draw_call_first_slice_probe=passed"
    bounded_draw_call_executed="true"
    current_shell_draw_call_ready="true"
    draw_call_route="draw_call_after_pipeline_vertex_binding_contract_ready"
    render_command_encoder_created="$(fact_value "$DRAW_CALL_PROBE_LOG" "render_command_encoder_created")"
    end_encoding_called="$(fact_value "$DRAW_CALL_PROBE_LOG" "end_encoding_called")"
    pipeline_state_bound="$(fact_value "$DRAW_CALL_PROBE_LOG" "pipeline_state_bound")"
    vertex_buffer_bound="$(fact_value "$DRAW_CALL_PROBE_LOG" "vertex_buffer_bound")"
    draw_called="$(fact_value "$DRAW_CALL_PROBE_LOG" "draw_called")"
  elif [[ "$draw_call_probe_exit_code" == "20" &&
          "$(fact_value "$DRAW_CALL_PROBE_LOG" "draw_call_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    draw_call_route="host_metal_device_unavailable"
  else
    echo "cjgui stage139 draw call packet: bounded draw-call probe failed" >&2
    echo "cjgui stage139 draw call packet: exit=$draw_call_probe_exit_code log=$DRAW_CALL_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_draw_call_ready" == "true" ]]; then
  for fact in \
    "pipeline_state_bound=true" \
    "vertex_buffer_bound=true" \
    "draw_called=true" \
    "commit_called=false" \
    "present_called=false" \
    "renderer_state_write=false"; do
    require_file_fact "$DRAW_CALL_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage139 draw call packet: protected production bridge/state path modified" >&2
  exit 11
fi

{
  echo "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_packet_version=1"
  echo "stage138_input_mode=$stage138_input_mode"
  echo "stage138_suite_packet=$STAGE138_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage138_log=$STAGE138_LOG"
  echo "draw_call_probe_log=$DRAW_CALL_PROBE_LOG"
  echo "draw_call_probe_exit_code=$draw_call_probe_exit_code"
  echo "stage138_pipeline_vertex_binding_packet_consumed=true"
  echo "stage138_pipeline_vertex_binding_route_classification=$stage138_binding_route"
  echo "positive_pipeline_vertex_binding_before_draw_required=true"
  echo "bounded_draw_call_should_execute=$bounded_draw_call_should_execute"
  echo "bounded_draw_call_executed=$bounded_draw_call_executed"
  echo "current_shell_draw_call_ready=$current_shell_draw_call_ready"
  echo "draw_call_route_classification=$draw_call_route"
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
  echo "next_route=production_next_command_buffer_commit_no_present_after_draw_call_contract"
  echo "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage139 draw call packet: route_classification=$draw_call_route"
echo "cjgui stage139 draw call packet: draw_call_packet_path=$RESULT_PACKET"
echo "cjgui stage139 draw call packet: renderer_state_write=false"
