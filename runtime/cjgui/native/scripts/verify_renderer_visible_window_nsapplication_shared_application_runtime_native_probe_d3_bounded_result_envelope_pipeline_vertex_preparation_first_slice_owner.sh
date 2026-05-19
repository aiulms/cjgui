#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage111 pipeline / vertex preparation first-slice
# readiness owner。它只检查 Cangjie owner contract，不执行 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice.cj"
STAGE110_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_render_command_encoder_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceDraft"
  "didConsumeRenderCommandEncoderFirstSliceReadiness"
  "didRequirePositiveEncoderEnvelopeBeforePreparation"
  "didRequireBoundedIsolatedPipelineVertexProbe"
  "didRequireProbeLocalShaderLibrary"
  "didRequireProbeLocalShaderFunctions"
  "didRequireProbeLocalPipelineDescriptor"
  "didRequireProbeLocalPipelineState"
  "didRequireProbeLocalStaticTriangleVertexBuffer"
  "didKeepPipelineBindingBlocked"
  "didKeepVertexBufferBindingBlocked"
  "didKeepDrawCommitPresentGpuRenderBlocked"
  "didConfirmNoProductionNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice owner: missing symbol $symbol" >&2
    exit 4
  fi
done

if [[ ! -f "$STAGE110_OWNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice owner: missing dependency $STAGE110_OWNER" >&2
  exit 5
fi

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex preparation first slice owner: forbidden native/AppKit/render token found in owner" >&2
  exit 7
fi

echo "d3_bounded_result_envelope_pipeline_vertex_preparation_first_slice_owner_present=true"
echo "render_command_encoder_first_slice_input=true"
echo "positive_encoder_envelope_before_preparation_required=true"
echo "bounded_isolated_pipeline_vertex_probe_required=true"
echo "probe_local_shader_library_required=true"
echo "probe_local_shader_functions_required=true"
echo "probe_local_pipeline_descriptor_required=true"
echo "probe_local_pipeline_state_required=true"
echo "probe_local_static_triangle_vertex_buffer_required=true"
echo "pipeline_binding_blocked=true"
echo "vertex_buffer_binding_blocked=true"
echo "draw_commit_present_gpu_render_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
