#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage108 drawable texture lifetime first-slice packet
# 分类为 admitted / host Metal unavailable / pending first-slice admission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage108-drawable-texture-lifetime-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-drawable-texture-lifetime-first-slice-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_TEXTURE_LIFETIME_FIRST_SLICE_PACKET:-}"

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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: missing fact $fact in $file" >&2
    exit 3
  fi
}

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: log=$PACKET_LOG" >&2
    exit 4
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: provided packet missing $READINESS_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: missing readiness packet" >&2
  exit 6
fi

for fact in \
  "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet_passed=true" \
  "drawable_texture_lifetime_first_slice_owner_ready=true" \
  "color_attachment_configured=false" \
  "encoder_created=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

first_slice_ready="$(fact_value "$READINESS_PACKET" "current_shell_drawable_texture_lifetime_first_slice_ready")"
bounded_executed="$(fact_value "$READINESS_PACKET" "bounded_drawable_texture_lifetime_first_slice_executed")"
failure_classification="$(fact_value "$READINESS_PACKET" "drawable_texture_lifetime_failure_classification")"

classifier_route="blocked_pending_drawable_texture_lifetime_first_slice"
if [[ "$first_slice_ready" == "true" && "$bounded_executed" == "true" ]]; then
  classifier_route="admitted_bounded_drawable_texture_lifetime_first_slice"
elif [[ "$failure_classification" == "host_metal_device_unavailable" ]]; then
  classifier_route="host_metal_device_unavailable"
elif [[ "$failure_classification" == "blocked_pending_first_slice_admission" ]]; then
  classifier_route="blocked_pending_first_slice_admission"
fi

{
  echo "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_classifier_version=1"
  echo "readiness_packet=$READINESS_PACKET"
  echo "packet_log=$PACKET_LOG"
  echo "current_shell_drawable_texture_lifetime_first_slice_ready=$first_slice_ready"
  echo "bounded_drawable_texture_lifetime_first_slice_executed=$bounded_executed"
  echo "drawable_texture_lifetime_failure_classification=$failure_classification"
  echo "drawable_texture_lifetime_classifier_route=$classifier_route"
  grep -E '^isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  grep -E '^current_shell_first_slice_admitted=' "$READINESS_PACKET" | tail -1
  grep -E '^next_drawable_called=' "$READINESS_PACKET" | tail -1
  grep -E '^drawable_acquired=' "$READINESS_PACKET" | tail -1
  grep -E '^drawable_texture_observed=' "$READINESS_PACKET" | tail -1
  echo "current_shell_color_attachment_native_execution_ready=false"
  echo "color_attachment_configured=false"
  echo "encoder_created=false"
  echo "draw_called=false"
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
  echo "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_classifier_passed=true"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: route_classification=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice classifier: renderer_state_write=false"
