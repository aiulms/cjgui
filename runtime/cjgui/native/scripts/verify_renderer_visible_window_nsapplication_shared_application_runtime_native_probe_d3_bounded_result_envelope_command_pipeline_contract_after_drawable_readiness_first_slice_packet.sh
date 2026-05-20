#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage135 command pipeline contract packet。它消费
# stage135 drawable readiness packet，执行 command queue create-destroy 与
# render-pass descriptor create-destroy contract probes，并保持 command buffer /
# encoder / draw / commit / present 阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE135_COMMAND_TMPDIR:-/tmp/cjgui-stage135-command-pipeline-contract-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice_owner.sh"
DRAWABLE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice_packet.sh"
COMMAND_QUEUE_SCRIPT="$SCRIPT_DIR/verify_native_bridge_command_queue_create_destroy.sh"
RENDER_PASS_DESCRIPTOR_SCRIPT="$SCRIPT_DIR/verify_native_bridge_render_pass_descriptor_create_destroy.sh"
OWNER_LOG="$TMP_DIR/owner.log"
DRAWABLE_PACKET_LOG="$TMP_DIR/drawable-packet.log"
COMMAND_QUEUE_LOG="$TMP_DIR/command-queue.log"
RENDER_PASS_LOG="$TMP_DIR/render-pass-descriptor.log"
RESULT_PACKET="$TMP_DIR/stage135-command-pipeline-contract-after-drawable-readiness.packet"
DRAWABLE_READINESS_PACKET="${CJGUI_STAGE135_DRAWABLE_READINESS_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/drawable" "$TMP_DIR/command-queue" "$TMP_DIR/render-pass"
: > "$OWNER_LOG"
: > "$DRAWABLE_PACKET_LOG"
: > "$COMMAND_QUEUE_LOG"
: > "$RENDER_PASS_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$DRAWABLE_PACKET_SCRIPT" "$COMMAND_QUEUE_SCRIPT" "$RENDER_PASS_DESCRIPTOR_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage135 command pipeline contract packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage135 command pipeline contract packet: syntax check failed $script" >&2
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
    echo "cjgui stage135 command pipeline contract packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage135 command pipeline contract packet: owner probe failed" >&2
  echo "cjgui stage135 command pipeline contract packet: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "command_pipeline_contract_after_drawable_readiness_owner_present=true"

if [[ -z "$DRAWABLE_READINESS_PACKET" ]]; then
  if env CJGUI_STAGE135_TMPDIR="$TMP_DIR/drawable" zsh "$DRAWABLE_PACKET_SCRIPT" > "$DRAWABLE_PACKET_LOG" 2>&1; then
    DRAWABLE_READINESS_PACKET="$(grep -Eo 'drawable_readiness_packet_path=[^[:space:]]+' "$DRAWABLE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage135 command pipeline contract packet: drawable packet failed" >&2
    echo "cjgui stage135 command pipeline contract packet: log=$DRAWABLE_PACKET_LOG" >&2
    exit 7
  fi
else
  if [[ ! -f "$DRAWABLE_READINESS_PACKET" ]]; then
    echo "cjgui stage135 command pipeline contract packet: provided drawable packet missing $DRAWABLE_READINESS_PACKET" >&2
    exit 8
  fi
  echo "provided_drawable_readiness_packet_used=true" > "$DRAWABLE_PACKET_LOG"
fi

if [[ -z "$DRAWABLE_READINESS_PACKET" || ! -f "$DRAWABLE_READINESS_PACKET" ]]; then
  echo "cjgui stage135 command pipeline contract packet: missing drawable readiness packet" >&2
  exit 9
fi
for fact in \
  "stage135_drawable_readiness_after_visible_order_first_slice_packet_passed=true" \
  "command_pipeline_contract_route_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$DRAWABLE_READINESS_PACKET" "$fact"
done

if ! env TMPDIR="$TMP_DIR/command-queue" zsh "$COMMAND_QUEUE_SCRIPT" > "$COMMAND_QUEUE_LOG" 2>&1; then
  echo "cjgui stage135 command pipeline contract packet: command queue contract probe failed" >&2
  echo "cjgui stage135 command pipeline contract packet: log=$COMMAND_QUEUE_LOG" >&2
  exit 10
fi
if ! env TMPDIR="$TMP_DIR/render-pass" zsh "$RENDER_PASS_DESCRIPTOR_SCRIPT" > "$RENDER_PASS_LOG" 2>&1; then
  echo "cjgui stage135 command pipeline contract packet: render pass descriptor probe failed" >&2
  echo "cjgui stage135 command pipeline contract packet: log=$RENDER_PASS_LOG" >&2
  exit 11
fi

command_queue_probe="$(fact_value "$COMMAND_QUEUE_LOG" "command_queue_create_destroy_probe")"
render_pass_descriptor_probe="$(fact_value "$RENDER_PASS_LOG" "render_pass_descriptor_create_destroy_probe")"
if [[ "$command_queue_probe" != "skipped_no_device" && "$command_queue_probe" != "passed" ]]; then
  echo "cjgui stage135 command pipeline contract packet: unexpected command queue probe $command_queue_probe" >&2
  exit 12
fi
if [[ "$render_pass_descriptor_probe" != "passed" ]]; then
  echo "cjgui stage135 command pipeline contract packet: render pass descriptor contract did not pass" >&2
  exit 13
fi

if [[ "$command_queue_probe" == "passed" ]]; then
  command_pipeline_route="command_queue_and_render_pass_descriptor_contract_ready"
else
  command_pipeline_route="command_queue_blocked_by_host_metal_device_unavailable_render_pass_descriptor_ready"
fi

{
  echo "stage135_command_pipeline_contract_after_drawable_readiness_first_slice_packet_version=1"
  echo "drawable_readiness_packet=$DRAWABLE_READINESS_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "command_queue_log=$COMMAND_QUEUE_LOG"
  echo "render_pass_descriptor_log=$RENDER_PASS_LOG"
  echo "drawable_readiness_packet_consumed=true"
  echo "drawable_readiness_route_classification=$(fact_value "$DRAWABLE_READINESS_PACKET" "drawable_readiness_route_classification")"
  echo "command_pipeline_contract_route_classification=$command_pipeline_route"
  echo "command_queue_contract_probe_executed=true"
  echo "command_queue_create_destroy_probe=$command_queue_probe"
  echo "render_pass_descriptor_contract_probe_executed=true"
  echo "render_pass_descriptor_create_destroy_probe=$render_pass_descriptor_probe"
  echo "color_attachment_configured=false"
  echo "next_drawable_called=$(fact_value "$DRAWABLE_READINESS_PACKET" "next_drawable_called")"
  echo "drawable_acquired=$(fact_value "$DRAWABLE_READINESS_PACKET" "drawable_acquired")"
  echo "command_buffer_created=false"
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
  echo "next_route=production_next_command_buffer_render_encoder_contract_after_drawable_readiness"
  echo "stage135_command_pipeline_contract_after_drawable_readiness_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage135 command pipeline contract packet: route_classification=$command_pipeline_route"
echo "cjgui stage135 command pipeline contract packet: command_pipeline_contract_packet_path=$RESULT_PACKET"
echo "cjgui stage135 command pipeline contract packet: command_queue_create_destroy_probe=$command_queue_probe"
echo "cjgui stage135 command pipeline contract packet: renderer_state_write=false"
