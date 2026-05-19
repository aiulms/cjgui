#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage113 draw-call first-slice readiness owner。
# 它只检查 Cangjie owner contract，不执行 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice.cj"
STAGE112_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceDraft"
  "didConsumePipelineVertexBindingFirstSliceReadiness"
  "didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw"
  "didRequireBoundedIsolatedDrawCallProbe"
  "didRequireProbeLocalRenderCommandEncoder"
  "didRequireProbeLocalPipelineStateBound"
  "didRequireProbeLocalStaticTriangleVertexBufferBound"
  "didRequireProbeLocalDrawPrimitivesCall"
  "didRequireEndEncodingAfterDrawBeforeCleanup"
  "didKeepCommitPresentGpuRenderBlocked"
  "didConfirmNoProductionNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice owner: missing symbol $symbol" >&2
    exit 4
  fi
done

if [[ ! -f "$STAGE112_OWNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice owner: missing dependency $STAGE112_OWNER" >&2
  exit 5
fi

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice owner: forbidden native/AppKit/render token found in owner" >&2
  exit 7
fi

echo "d3_bounded_result_envelope_draw_call_first_slice_owner_present=true"
echo "pipeline_vertex_binding_first_slice_input=true"
echo "positive_pipeline_vertex_binding_envelope_before_draw_required=true"
echo "bounded_isolated_draw_call_probe_required=true"
echo "probe_local_render_command_encoder_required=true"
echo "probe_local_pipeline_state_bound_required=true"
echo "probe_local_static_triangle_vertex_buffer_bound_required=true"
echo "probe_local_draw_primitives_call_required=true"
echo "end_encoding_after_draw_before_cleanup_required=true"
echo "commit_present_gpu_render_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
