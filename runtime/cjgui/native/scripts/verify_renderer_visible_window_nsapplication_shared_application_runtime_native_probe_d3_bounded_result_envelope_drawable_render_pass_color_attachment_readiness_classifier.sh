#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage107 drawable / render-pass color attachment
# readiness packet。它把 host Metal unavailable、pending first-slice admission
# 与 pending drawable texture lifetime support 分开输出；不执行 render。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage107-drawable-render-pass-color-attachment-readiness-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet.sh"
PACKET_LOG="$TMP_DIR/readiness-packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-drawable-render-pass-color-attachment-readiness-classifier.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_RENDER_PASS_COLOR_ATTACHMENT_READINESS_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi

if [[ -n "$READINESS_PACKET" ]]; then
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: readiness packet missing $READINESS_PACKET" >&2
    exit 4
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
    cat "$READINESS_PACKET"
  } > "$PACKET_LOG"
else
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: log=$PACKET_LOG" >&2
    exit 5
  fi
fi

readiness_packet="${READINESS_PACKET:-$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$readiness_packet" || ! -f "$readiness_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: missing readiness packet" >&2
  exit 6
fi

fact_value() {
  local key="$1"
  grep -E "^${key}=" "$readiness_packet" | tail -1 | cut -d= -f2- || true
}

require_fact() {
  local fact="$1"
  if ! grep -F "$fact" "$readiness_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: missing packet fact $fact" >&2
    exit 7
  fi
}

required_facts=(
  "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_passed=true"
  "stage106_first_slice_contract_input_ready=true"
  "render_pass_descriptor_create_destroy_probe_passed=true"
  "drawable_acquisition_planning_probe_passed=true"
  "drawable_texture_lifetime_probe_passed=true"
  "render_pass_descriptor_color_attachment_recovery_probe_passed=true"
  "drawable_render_pass_color_attachment_readiness_envelope_ready=true"
  "first_slice_admission_before_drawable_acquisition_required=true"
  "drawable_texture_lifetime_before_color_attachment_required=true"
  "render_pass_descriptor_before_color_attachment_required=true"
  "descriptor_drawable_layer_device_cleanup_coownership_required=true"
  "production_drawable_texture_lifetime=false"
  "descriptor_drawable_cleanup_coownership=false"
  "current_shell_drawable_color_attachment_native_execution_ready=false"
  "bounded_drawable_render_pass_color_attachment_executed=false"
  "next_drawable_called=false"
  "color_attachment_configured=false"
  "encoder_created=false"
  "draw_called=false"
  "commit_called=false"
  "present_called=false"
  "gpu_work_submitted=false"
  "render_executed=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_facts[@]}"; do
  require_fact "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: protected path modified" >&2
  exit 8
fi

isolated_metal_device_available="$(fact_value "isolated_metal_device_available")"
current_shell_first_slice_admitted="$(fact_value "current_shell_first_slice_admitted")"
first_slice_failure_classification="$(fact_value "first_slice_failure_classification")"
drawable_color_attachment_failure_classification="$(fact_value "drawable_color_attachment_failure_classification")"
current_shell_drawable_color_attachment_native_execution_ready="$(fact_value "current_shell_drawable_color_attachment_native_execution_ready")"

if [[ "$current_shell_drawable_color_attachment_native_execution_ready" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: native execution readiness unexpectedly true before drawable lifetime support" >&2
  exit 9
fi
if [[ "$isolated_metal_device_available" == "false" &&
      "$drawable_color_attachment_failure_classification" != "host_metal_device_unavailable" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: Metal unavailable without host classification" >&2
  exit 10
fi
if [[ "$isolated_metal_device_available" != "false" &&
      "$current_shell_first_slice_admitted" != "true" &&
      "$drawable_color_attachment_failure_classification" != "blocked_pending_first_slice_admission" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: first-slice pending classification mismatch" >&2
  exit 11
fi
if [[ "$current_shell_first_slice_admitted" == "true" &&
      "$drawable_color_attachment_failure_classification" != "blocked_pending_drawable_texture_lifetime_support" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: admitted first-slice must wait for drawable texture lifetime support" >&2
  exit 12
fi

{
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier_packet_version=1"
  echo "readiness_packet=$readiness_packet"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier_passed=true"
  echo "drawable_render_pass_color_attachment_readiness_envelope_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  echo "current_shell_drawable_color_attachment_native_execution_ready=false"
  echo "drawable_color_attachment_failure_classification=$drawable_color_attachment_failure_classification"
  echo "first_slice_admission_before_drawable_acquisition_required=true"
  echo "drawable_texture_lifetime_before_color_attachment_required=true"
  echo "render_pass_descriptor_before_color_attachment_required=true"
  echo "descriptor_drawable_layer_device_cleanup_coownership_required=true"
  echo "production_drawable_texture_lifetime=false"
  echo "descriptor_drawable_cleanup_coownership=false"
  echo "next_drawable_called=false"
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
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: route_classification=d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: current_shell_drawable_color_attachment_native_execution_ready=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: drawable_color_attachment_failure_classification=$drawable_color_attachment_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness classifier: renderer_state_write=false"
