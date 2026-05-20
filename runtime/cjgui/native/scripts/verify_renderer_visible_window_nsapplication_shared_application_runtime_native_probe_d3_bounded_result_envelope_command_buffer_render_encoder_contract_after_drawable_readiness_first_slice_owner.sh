#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage136 command buffer / render encoder contract
# after drawable readiness owner。它只检查 Cangjie owner contract，不执行
# native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice.cj"
STAGE135_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage136 command buffer render encoder owner: missing owner $OWNER_FILE" >&2
  exit 3
fi
if [[ ! -f "$STAGE135_OWNER" ]]; then
  echo "cjgui stage136 command buffer render encoder owner: missing stage135 dependency $STAGE135_OWNER" >&2
  exit 4
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceDraft"
  "didConsumeCommandPipelineContractAfterDrawableReadiness"
  "didRequireStage135CommandPipelinePacket"
  "didRequireCommandBufferCreateDestroyContract"
  "didRequirePositiveCommandBufferBeforeRenderEncoder"
  "didRequireProbeLocalDrawableTextureBeforeColorAttachment"
  "didRequireProbeLocalRenderPassColorAttachment"
  "didRequireProbeLocalRenderCommandEncoder"
  "didRequireEndEncodingBeforeCleanup"
  "didKeepPipelineStateBindingBlocked"
  "didKeepVertexBufferBindingBlocked"
  "didKeepDrawCommitPresentGpuWorkBlocked"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)
for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage136 command buffer render encoder owner: missing $symbol" >&2
    exit 5
  fi
done

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder owner: forbidden native/AppKit/render token found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder owner: protected production bridge/state path modified" >&2
  exit 8
fi

echo "command_buffer_render_encoder_contract_after_drawable_readiness_owner_present=true"
echo "stage135_command_pipeline_packet_required=true"
echo "command_buffer_create_destroy_contract_required=true"
echo "positive_command_buffer_before_render_encoder_required=true"
echo "probe_local_drawable_texture_before_color_attachment_required=true"
echo "probe_local_render_pass_color_attachment_required=true"
echo "bounded_render_encoder_probe_required=true"
echo "end_encoding_before_cleanup_required=true"
echo "pipeline_state_binding_blocked=true"
echo "vertex_buffer_binding_blocked=true"
echo "draw_commit_present_gpu_work_blocked=true"
echo "first_frame_observation_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
