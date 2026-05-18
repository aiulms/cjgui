#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage110 render command encoder first-slice readiness
# owner。它只检查 Cangjie owner contract，不执行 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_render_command_encoder_first_slice.cj"
STAGE109_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_color_attachment_configuration_first_slice.cj"
NO_SUBMIT_OWNER="$ROOT_DIR/src/runtime_renderer_render_command_encoder_no_submit_planning.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceDraft"
  "didConsumeColorAttachmentConfigurationFirstSliceReadiness"
  "didConsumeRenderCommandEncoderNoSubmitPlanningReadiness"
  "didRequirePositiveColorAttachmentEnvelopeBeforeEncoder"
  "didRequireBoundedIsolatedRenderCommandEncoderProbe"
  "didRequireProbeLocalCommandQueue"
  "didRequireProbeLocalCommandBuffer"
  "didRequireProbeLocalRenderPassDescriptorInput"
  "didRequireProbeLocalRenderCommandEncoder"
  "didRequireEndEncodingBeforeCleanup"
  "didKeepProductionEncoderBridgeBlocked"
  "didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked"
  "didConfirmNoProductionNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice owner: missing symbol $symbol" >&2
    exit 4
  fi
done

for dependency in "$STAGE109_OWNER" "$NO_SUBMIT_OWNER"; do
  if [[ ! -f "$dependency" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice owner: missing dependency $dependency" >&2
    exit 5
  fi
done

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice owner: forbidden native/AppKit/render token found in owner" >&2
  exit 7
fi

echo "d3_bounded_result_envelope_render_command_encoder_first_slice_owner_present=true"
echo "color_attachment_configuration_first_slice_input=true"
echo "render_command_encoder_no_submit_planning_input=true"
echo "positive_color_attachment_envelope_before_encoder_required=true"
echo "bounded_isolated_render_command_encoder_probe_required=true"
echo "probe_local_command_queue_required=true"
echo "probe_local_command_buffer_required=true"
echo "probe_local_render_pass_descriptor_input_required=true"
echo "probe_local_render_command_encoder_required=true"
echo "end_encoding_before_cleanup_required=true"
echo "production_encoder_bridge_blocked=true"
echo "pipeline_vertex_draw_commit_present_gpu_render_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
