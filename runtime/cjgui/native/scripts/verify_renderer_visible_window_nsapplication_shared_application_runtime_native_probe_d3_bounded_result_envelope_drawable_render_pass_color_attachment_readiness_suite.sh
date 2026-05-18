#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage107 drawable / render-pass color attachment
# readiness focused suite。它先验证 stage106 first-slice owner，再生成并
# 分类 drawable / color attachment readiness envelope，最后执行 source/build
# guard。Stop-line 保持 renderer state write blocked。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage107-drawable-render-pass-color-attachment-readiness-suite"
FIRST_SLICE_OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner.sh"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_source_build_guard.sh"
FIRST_SLICE_LOG="$TMP_DIR/stage106-first-slice-owner.log"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-drawable-render-pass-color-attachment-readiness-suite.packet"

mkdir -p "$TMP_DIR"
: > "$FIRST_SLICE_LOG"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$FIRST_SLICE_OWNER_PROBE" "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$FIRST_SLICE_OWNER_PROBE" > "$FIRST_SLICE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: stage106 first-slice owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: log=$FIRST_SLICE_LOG" >&2
  exit 5
fi
if ! grep -F "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner_present=true" "$FIRST_SLICE_LOG" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing stage106 owner fact" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: log=$OWNER_LOG" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: readiness packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: log=$PACKET_LOG" >&2
  exit 8
fi
readiness_packet="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$readiness_packet" || ! -f "$readiness_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing readiness packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_RENDER_PASS_COLOR_ATTACHMENT_READINESS_PACKET="$readiness_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: log=$CLASSIFIER_LOG" >&2
  exit 10
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing classifier packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_RENDER_PASS_COLOR_ATTACHMENT_READINESS_PACKET="$readiness_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_RENDER_PASS_COLOR_ATTACHMENT_READINESS_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing source build packet" >&2
  exit 13
fi

required_suite_facts=(
  "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_passed=true"
  "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier_passed=true"
  "source_build_drawable_render_pass_color_attachment_readiness_guard_passed=true"
  "runtime_package_build_passed=true"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$readiness_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: missing fact $fact" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: protected path modified" >&2
  exit 15
fi

isolated_metal_device_available="$(grep -E '^isolated_metal_device_available=' "$readiness_packet" | tail -1 | cut -d= -f2-)"
current_shell_first_slice_admitted="$(grep -E '^current_shell_first_slice_admitted=' "$readiness_packet" | tail -1 | cut -d= -f2-)"
drawable_color_attachment_failure_classification="$(grep -E '^drawable_color_attachment_failure_classification=' "$readiness_packet" | tail -1 | cut -d= -f2-)"

{
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite_version=1"
  echo "stage106_first_slice_log=$FIRST_SLICE_LOG"
  echo "stage106_first_slice_contract_input_ready=true"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "readiness_packet=$readiness_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_passed=true"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_classifier_passed=true"
  echo "source_build_drawable_render_pass_color_attachment_readiness_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite_passed=true"
  echo "drawable_render_pass_color_attachment_readiness_envelope_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
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
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: route_classification=d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: current_shell_drawable_color_attachment_native_execution_ready=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: drawable_color_attachment_failure_classification=$drawable_color_attachment_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness suite: renderer_state_write=false"
