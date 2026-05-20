#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage136 command buffer contract packet。它消费
# stage135 command pipeline packet，并执行 token-backed command buffer
# create/destroy probe；不创建 render encoder，不 draw / commit / present。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE136_COMMAND_BUFFER_TMPDIR:-/tmp/cjgui-stage136-command-buffer-contract-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_owner.sh"
STAGE135_COMMAND_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice_packet.sh"
COMMAND_BUFFER_PROBE="$SCRIPT_DIR/verify_native_bridge_command_buffer_create_destroy.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE135_COMMAND_LOG="$TMP_DIR/stage135-command-packet.log"
COMMAND_BUFFER_LOG="$TMP_DIR/command-buffer-create-destroy.log"
RESULT_PACKET="$TMP_DIR/stage136-command-buffer-contract-after-drawable-readiness.packet"
STAGE135_COMMAND_PACKET="${CJGUI_STAGE135_COMMAND_PIPELINE_CONTRACT_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage135" "$TMP_DIR/command-buffer"
: > "$OWNER_LOG"
: > "$STAGE135_COMMAND_LOG"
: > "$COMMAND_BUFFER_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE135_COMMAND_PACKET_SCRIPT" "$COMMAND_BUFFER_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage136 command buffer packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage136 command buffer packet: syntax check failed $script" >&2
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
    echo "cjgui stage136 command buffer packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage136 command buffer packet: owner probe failed" >&2
  echo "cjgui stage136 command buffer packet: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "command_buffer_create_destroy_contract_required=true"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if [[ -z "$STAGE135_COMMAND_PACKET" ]]; then
  if env CJGUI_STAGE135_COMMAND_TMPDIR="$TMP_DIR/stage135" zsh "$STAGE135_COMMAND_PACKET_SCRIPT" > "$STAGE135_COMMAND_LOG" 2>&1; then
    STAGE135_COMMAND_PACKET="$(grep -Eo 'command_pipeline_contract_packet_path=[^[:space:]]+' "$STAGE135_COMMAND_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage136 command buffer packet: stage135 command packet failed" >&2
    echo "cjgui stage136 command buffer packet: log=$STAGE135_COMMAND_LOG" >&2
    exit 7
  fi
else
  if [[ ! -f "$STAGE135_COMMAND_PACKET" ]]; then
    echo "cjgui stage136 command buffer packet: provided stage135 packet missing $STAGE135_COMMAND_PACKET" >&2
    exit 8
  fi
  echo "provided_stage135_command_pipeline_packet_used=true" > "$STAGE135_COMMAND_LOG"
fi

if [[ -z "$STAGE135_COMMAND_PACKET" || ! -f "$STAGE135_COMMAND_PACKET" ]]; then
  echo "cjgui stage136 command buffer packet: missing stage135 command packet" >&2
  exit 9
fi
for fact in \
  "stage135_command_pipeline_contract_after_drawable_readiness_first_slice_packet_passed=true" \
  "drawable_readiness_packet_consumed=true" \
  "command_queue_contract_probe_executed=true" \
  "render_pass_descriptor_contract_probe_executed=true" \
  "command_buffer_created=false" \
  "render_command_encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE135_COMMAND_PACKET" "$fact"
done

stage135_command_queue_probe="$(fact_value "$STAGE135_COMMAND_PACKET" "command_queue_create_destroy_probe")"
stage135_render_pass_probe="$(fact_value "$STAGE135_COMMAND_PACKET" "render_pass_descriptor_create_destroy_probe")"
stage135_next_drawable_called="$(fact_value "$STAGE135_COMMAND_PACKET" "next_drawable_called")"
stage135_drawable_acquired="$(fact_value "$STAGE135_COMMAND_PACKET" "drawable_acquired")"
bounded_command_buffer_probe_should_execute="true"
bounded_command_buffer_probe_executed="false"
command_buffer_probe="not_run"
command_buffer_created="false"
command_buffer_destroyed="false"
command_buffer_route="blocked_pending_stage135_command_pipeline_contract"

if [[ "$stage135_command_queue_probe" == "skipped_no_device" ]]; then
  command_buffer_route="host_metal_device_unavailable"
fi

if [[ "$bounded_command_buffer_probe_should_execute" == "true" ]]; then
  if ! env TMPDIR="$TMP_DIR/command-buffer" zsh "$COMMAND_BUFFER_PROBE" > "$COMMAND_BUFFER_LOG" 2>&1; then
    echo "cjgui stage136 command buffer packet: command buffer probe failed" >&2
    echo "cjgui stage136 command buffer packet: log=$COMMAND_BUFFER_LOG" >&2
    exit 10
  fi
  command_buffer_probe="$(fact_value "$COMMAND_BUFFER_LOG" "command_buffer_create_destroy_probe")"
  if [[ "$command_buffer_probe" == "passed" ]]; then
    bounded_command_buffer_probe_executed="true"
    command_buffer_created="true"
    command_buffer_destroyed="true"
    if [[ "$stage135_command_queue_probe" == "passed" &&
          "$stage135_render_pass_probe" == "passed" &&
          "$stage135_next_drawable_called" == "true" &&
          "$stage135_drawable_acquired" == "true" ]]; then
      command_buffer_route="command_buffer_create_destroy_contract_ready"
    fi
  elif [[ "$command_buffer_probe" == "skipped_no_device" ]]; then
    bounded_command_buffer_probe_executed="true"
    command_buffer_route="host_metal_device_unavailable"
  else
    echo "cjgui stage136 command buffer packet: unexpected command buffer probe $command_buffer_probe" >&2
    exit 11
  fi
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer packet: protected production bridge/state path modified" >&2
  exit 12
fi

{
  echo "stage136_command_buffer_contract_after_drawable_readiness_first_slice_packet_version=1"
  echo "stage135_command_pipeline_contract_packet=$STAGE135_COMMAND_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage135_command_log=$STAGE135_COMMAND_LOG"
  echo "command_buffer_probe_log=$COMMAND_BUFFER_LOG"
  echo "stage135_command_pipeline_contract_packet_consumed=true"
  echo "stage135_command_queue_create_destroy_probe=$stage135_command_queue_probe"
  echo "stage135_render_pass_descriptor_create_destroy_probe=$stage135_render_pass_probe"
  echo "stage135_next_drawable_called=$stage135_next_drawable_called"
  echo "stage135_drawable_acquired=$stage135_drawable_acquired"
  echo "bounded_command_buffer_probe_should_execute=$bounded_command_buffer_probe_should_execute"
  echo "bounded_command_buffer_probe_executed=$bounded_command_buffer_probe_executed"
  echo "command_buffer_create_destroy_probe=$command_buffer_probe"
  echo "command_buffer_contract_route_classification=$command_buffer_route"
  echo "command_buffer_created=$command_buffer_created"
  echo "command_buffer_destroyed=$command_buffer_destroyed"
  echo "render_command_encoder_created=false"
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
  echo "next_route=production_next_render_encoder_contract_after_command_buffer"
  echo "stage136_command_buffer_contract_after_drawable_readiness_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage136 command buffer packet: route_classification=$command_buffer_route"
echo "cjgui stage136 command buffer packet: command_buffer_contract_packet_path=$RESULT_PACKET"
echo "cjgui stage136 command buffer packet: command_buffer_create_destroy_probe=$command_buffer_probe"
echo "cjgui stage136 command buffer packet: renderer_state_write=false"
