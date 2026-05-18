#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage109 color attachment configuration first-slice
# readiness owner。它只检查 Cangjie owner contract，不执行 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_color_attachment_configuration_first_slice.cj"
STAGE108_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice.cj"
RECOVERY_OWNER="$ROOT_DIR/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceDraft"
  "didConsumeDrawableTextureLifetimeFirstSliceReadiness"
  "didConsumeColorAttachmentRecoveryReadiness"
  "didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration"
  "didRequireBoundedIsolatedColorAttachmentConfigurationProbe"
  "didRequireProbeLocalRenderPassDescriptor"
  "didRequireProbeLocalDrawableTextureBinding"
  "didRequireAttachmentLoadStoreClearFacts"
  "didKeepEncoderCreationBlockedAfterColorAttachment"
  "didKeepDrawCommitPresentGpuRenderBlocked"
  "didConfirmNoProductionNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice owner: missing symbol $symbol" >&2
    exit 4
  fi
done

for dependency in "$STAGE108_OWNER" "$RECOVERY_OWNER"; do
  if [[ ! -f "$dependency" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice owner: missing dependency $dependency" >&2
    exit 5
  fi
done

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice owner: forbidden native/AppKit/render token found in owner" >&2
  exit 7
fi

echo "d3_bounded_result_envelope_color_attachment_configuration_first_slice_owner_present=true"
echo "drawable_texture_lifetime_first_slice_input=true"
echo "color_attachment_recovery_input=true"
echo "positive_drawable_texture_envelope_before_configuration_required=true"
echo "bounded_isolated_color_attachment_configuration_probe_required=true"
echo "probe_local_render_pass_descriptor_required=true"
echo "probe_local_drawable_texture_binding_required=true"
echo "attachment_load_store_clear_facts_required=true"
echo "descriptor_drawable_layer_device_cleanup_coownership_required=true"
echo "encoder_creation_blocked_after_color_attachment=true"
echo "draw_commit_present_gpu_render_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
