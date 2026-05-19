#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage113 draw-call first-slice packet 分类为 admitted /
# host Metal unavailable / pending binding envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage113-draw-call-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-draw-call-first-slice-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAW_CALL_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: missing fact $fact in $file" >&2
    exit 3
  fi
}

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: log=$PACKET_LOG" >&2
    exit 4
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: provided packet missing $READINESS_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: missing readiness packet" >&2
  exit 6
fi

for fact in \
  "d3_bounded_result_envelope_draw_call_first_slice_packet_passed=true" \
  "draw_call_first_slice_owner_ready=true" \
  "positive_pipeline_vertex_binding_envelope_before_draw_required=true" \
  "production_draw_call=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

draw_ready="$(fact_value "$READINESS_PACKET" "current_shell_draw_call_first_slice_ready")"
bounded_executed="$(fact_value "$READINESS_PACKET" "bounded_draw_call_first_slice_executed")"
draw_called="$(fact_value "$READINESS_PACKET" "draw_called")"
pipeline_state_bound="$(fact_value "$READINESS_PACKET" "pipeline_state_bound")"
vertex_buffer_bound="$(fact_value "$READINESS_PACKET" "vertex_buffer_bound")"
failure_classification="$(fact_value "$READINESS_PACKET" "draw_call_first_slice_failure_classification")"

classifier_route="blocked_pending_positive_pipeline_vertex_binding_envelope"
if [[ "$draw_ready" == "true" &&
      "$bounded_executed" == "true" &&
      "$draw_called" == "true" &&
      "$pipeline_state_bound" == "true" &&
      "$vertex_buffer_bound" == "true" ]]; then
  classifier_route="admitted_bounded_draw_call_first_slice"
elif [[ "$failure_classification" == "host_metal_device_unavailable" ]]; then
  classifier_route="host_metal_device_unavailable"
fi

{
  echo "d3_bounded_result_envelope_draw_call_first_slice_classifier_version=1"
  echo "readiness_packet=$READINESS_PACKET"
  echo "packet_log=$PACKET_LOG"
  echo "current_shell_draw_call_first_slice_ready=$draw_ready"
  echo "bounded_draw_call_first_slice_executed=$bounded_executed"
  echo "pipeline_state_bound=$pipeline_state_bound"
  echo "vertex_buffer_bound=$vertex_buffer_bound"
  echo "draw_called=$draw_called"
  echo "draw_call_first_slice_failure_classification=$failure_classification"
  echo "draw_call_first_slice_classifier_route=$classifier_route"
  grep -E '^isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  grep -E '^stage112_current_shell_pipeline_vertex_binding_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^stage112_bounded_pipeline_vertex_binding_first_slice_executed=' "$READINESS_PACKET" | tail -1
  grep -E '^render_command_encoder_created=' "$READINESS_PACKET" | tail -1
  grep -E '^end_encoding_called=' "$READINESS_PACKET" | tail -1
  grep -E '^pipeline_state_created=' "$READINESS_PACKET" | tail -1
  grep -E '^vertex_buffer_created=' "$READINESS_PACKET" | tail -1
  echo "production_draw_call=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_draw_call_first_slice_classifier_passed=true"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: route_classification=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice classifier: renderer_state_write=false"
