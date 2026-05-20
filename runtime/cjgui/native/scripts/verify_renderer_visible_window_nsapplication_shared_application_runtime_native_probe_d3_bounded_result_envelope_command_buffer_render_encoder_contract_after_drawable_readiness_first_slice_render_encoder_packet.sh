#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage136 render encoder contract packet。它消费
# stage136 command buffer contract packet，并执行 bounded visible-window
# render encoder/endEncoding probe；不绑定 pipeline / vertex，不 draw / commit /
# present，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE136_RENDER_ENCODER_TMPDIR:-/tmp/cjgui-stage136-render-encoder-contract-packet-$$}"
COMMAND_BUFFER_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_command_buffer_packet.sh"
ENCODER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_render_command_encoder_first_slice.sh"
COMMAND_BUFFER_PACKET_LOG="$TMP_DIR/command-buffer-packet.log"
ENCODER_PROBE_LOG="$TMP_DIR/render-encoder-probe.log"
RESULT_PACKET="$TMP_DIR/stage136-render-encoder-contract-after-command-buffer.packet"
COMMAND_BUFFER_PACKET="${CJGUI_STAGE136_COMMAND_BUFFER_CONTRACT_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/command-buffer" "$TMP_DIR/render-encoder"
: > "$COMMAND_BUFFER_PACKET_LOG"
: > "$ENCODER_PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$COMMAND_BUFFER_PACKET_SCRIPT" "$ENCODER_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage136 render encoder packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage136 render encoder packet: syntax check failed $script" >&2
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
    echo "cjgui stage136 render encoder packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$COMMAND_BUFFER_PACKET" ]]; then
  if env CJGUI_STAGE136_COMMAND_BUFFER_TMPDIR="$TMP_DIR/command-buffer" zsh "$COMMAND_BUFFER_PACKET_SCRIPT" > "$COMMAND_BUFFER_PACKET_LOG" 2>&1; then
    COMMAND_BUFFER_PACKET="$(grep -Eo 'command_buffer_contract_packet_path=[^[:space:]]+' "$COMMAND_BUFFER_PACKET_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage136 render encoder packet: command buffer packet failed" >&2
    echo "cjgui stage136 render encoder packet: log=$COMMAND_BUFFER_PACKET_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$COMMAND_BUFFER_PACKET" ]]; then
    echo "cjgui stage136 render encoder packet: provided command buffer packet missing $COMMAND_BUFFER_PACKET" >&2
    exit 7
  fi
  echo "provided_command_buffer_contract_packet_used=true" > "$COMMAND_BUFFER_PACKET_LOG"
fi

if [[ -z "$COMMAND_BUFFER_PACKET" || ! -f "$COMMAND_BUFFER_PACKET" ]]; then
  echo "cjgui stage136 render encoder packet: missing command buffer packet" >&2
  exit 8
fi
for fact in \
  "stage136_command_buffer_contract_after_drawable_readiness_first_slice_packet_passed=true" \
  "stage135_command_pipeline_contract_packet_consumed=true" \
  "render_command_encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$COMMAND_BUFFER_PACKET" "$fact"
done

bounded_render_encoder_probe_should_execute="false"
bounded_render_encoder_probe_executed="false"
current_shell_render_encoder_contract_ready="false"
render_encoder_route="blocked_pending_command_buffer_contract"
encoder_probe_exit_code="not_run"
next_drawable_called="false"
drawable_acquired="false"
drawable_texture_observed="false"
command_queue_created="false"
command_buffer_created="$(fact_value "$COMMAND_BUFFER_PACKET" "command_buffer_created")"
render_pass_descriptor_created="false"
color_attachment_configured="false"
render_command_encoder_creation_attempted="false"
render_command_encoder_created="false"
end_encoding_called="false"
cleanup_observed="false"
bridge_table_counts_clean="false"

if [[ "$(fact_value "$COMMAND_BUFFER_PACKET" "command_buffer_create_destroy_probe")" == "passed" &&
      "$command_buffer_created" == "true" ]]; then
  bounded_render_encoder_probe_should_execute="true"
elif [[ "$(fact_value "$COMMAND_BUFFER_PACKET" "command_buffer_contract_route_classification")" == "host_metal_device_unavailable" ]]; then
  render_encoder_route="host_metal_device_unavailable"
fi

if [[ "$bounded_render_encoder_probe_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/render-encoder" zsh "$ENCODER_PROBE" > "$ENCODER_PROBE_LOG" 2>&1
  encoder_probe_exit_code="$?"
  set -e
  if [[ "$encoder_probe_exit_code" == "0" ]]; then
    require_file_fact "$ENCODER_PROBE_LOG" "bounded_render_command_encoder_first_slice_probe=passed"
    bounded_render_encoder_probe_executed="true"
    current_shell_render_encoder_contract_ready="true"
    render_encoder_route="bounded_command_buffer_render_pass_encoder_contract_ready"
    next_drawable_called="$(fact_value "$ENCODER_PROBE_LOG" "next_drawable_called")"
    drawable_acquired="$(fact_value "$ENCODER_PROBE_LOG" "drawable_acquired")"
    drawable_texture_observed="$(fact_value "$ENCODER_PROBE_LOG" "drawable_texture_observed")"
    command_queue_created="$(fact_value "$ENCODER_PROBE_LOG" "command_queue_created")"
    command_buffer_created="$(fact_value "$ENCODER_PROBE_LOG" "command_buffer_created")"
    render_pass_descriptor_created="$(fact_value "$ENCODER_PROBE_LOG" "render_pass_descriptor_created")"
    color_attachment_configured="$(fact_value "$ENCODER_PROBE_LOG" "color_attachment_configured")"
    render_command_encoder_creation_attempted="$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_creation_attempted")"
    render_command_encoder_created="$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_created")"
    end_encoding_called="$(fact_value "$ENCODER_PROBE_LOG" "end_encoding_called")"
    cleanup_observed="$(fact_value "$ENCODER_PROBE_LOG" "cleanup_observed")"
    bridge_table_counts_clean="$(fact_value "$ENCODER_PROBE_LOG" "bridge_table_counts_clean")"
  elif [[ "$encoder_probe_exit_code" == "20" &&
          "$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    render_encoder_route="host_metal_device_unavailable"
  else
    echo "cjgui stage136 render encoder packet: bounded render encoder probe failed" >&2
    echo "cjgui stage136 render encoder packet: exit=$encoder_probe_exit_code log=$ENCODER_PROBE_LOG" >&2
    exit 9
  fi
fi

if [[ "$current_shell_render_encoder_contract_ready" == "true" ]]; then
  for fact in \
    "next_drawable_called=true" \
    "drawable_acquired=true" \
    "drawable_texture_observed=true" \
    "command_queue_created=true" \
    "command_buffer_created=true" \
    "render_pass_descriptor_created=true" \
    "color_attachment_configured=true" \
    "render_command_encoder_created=true" \
    "end_encoding_called=true" \
    "pipeline_state_bound=false" \
    "vertex_buffer_bound=false" \
    "draw_called=false" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "render_executed=false" \
    "renderer_state_write=false"; do
    require_file_fact "$ENCODER_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage136 render encoder packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage136_render_encoder_contract_after_command_buffer_first_slice_packet_version=1"
  echo "command_buffer_contract_packet=$COMMAND_BUFFER_PACKET"
  echo "command_buffer_packet_log=$COMMAND_BUFFER_PACKET_LOG"
  echo "render_encoder_probe_log=$ENCODER_PROBE_LOG"
  echo "encoder_probe_exit_code=$encoder_probe_exit_code"
  echo "command_buffer_contract_packet_consumed=true"
  echo "bounded_render_encoder_probe_should_execute=$bounded_render_encoder_probe_should_execute"
  echo "bounded_render_encoder_probe_executed=$bounded_render_encoder_probe_executed"
  echo "current_shell_render_encoder_contract_ready=$current_shell_render_encoder_contract_ready"
  echo "render_encoder_contract_route_classification=$render_encoder_route"
  echo "next_drawable_called=$next_drawable_called"
  echo "drawable_acquired=$drawable_acquired"
  echo "drawable_texture_observed=$drawable_texture_observed"
  echo "command_queue_created=$command_queue_created"
  echo "command_buffer_created=$command_buffer_created"
  echo "render_pass_descriptor_created=$render_pass_descriptor_created"
  echo "color_attachment_configured=$color_attachment_configured"
  echo "render_command_encoder_creation_attempted=$render_command_encoder_creation_attempted"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "cleanup_observed=$cleanup_observed"
  echo "bridge_table_counts_clean=$bridge_table_counts_clean"
  echo "production_render_command_encoder_creation=false"
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
  echo "next_route=production_next_pipeline_vertex_binding_contract_after_render_encoder"
  echo "stage136_render_encoder_contract_after_command_buffer_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage136 render encoder packet: route_classification=$render_encoder_route"
echo "cjgui stage136 render encoder packet: render_encoder_contract_packet_path=$RESULT_PACKET"
echo "cjgui stage136 render encoder packet: renderer_state_write=false"
