#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage105 visible-window command-pipeline readiness
# owner。它只做 source-level owner probe，不执行 runtime native probe。
# Stop-line: 不调用 application accessor，不扩 native bridge / public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness"
  "didConsumeBoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness"
  "didOpenVisibleWindowCommandPipelineReadinessRoute"
  "didRequireVisibleWindowEnvironmentEnvelope"
  "didSeparateAppKitHarnessReadinessFromMetalDeviceReadiness"
  "didRequireLayerDeviceBindingBeforeDrawableReadiness"
  "didRequireMetalDeviceBeforeCommandQueueReadiness"
  "didRequireDrawableBeforeRenderPassColorAttachment"
  "didRequireCommandQueueBeforeCommandBuffer"
  "didRequireCommandBufferAndRenderPassBeforeEncoder"
  "didRequirePipelineStateAndVertexBufferBeforeDraw"
  "didRequireCommitPresentAfterEncoding"
  "didRequireProductionWriteAdmissionBeforeRendererStateWrite"
  "didKeepRendererStateWriteBlocked"
  "didConfirmNoProductionTruthUpgrade"
  "didConfirmNoBackendReadyTruth"
  "didConfirmNoProductionApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoRendererStateWrite"
  "didAvoidApprovalRecoveryOrReportWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: d3_bounded_result_envelope_command_pipeline_readiness_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: write_decision_join_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: visible_window_environment_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: appkit_harness_separate_from_metal_device=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: layer_device_binding_before_drawable_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: metal_device_before_command_queue_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: drawable_before_render_pass_color_attachment_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: command_queue_before_command_buffer_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: command_buffer_and_render_pass_before_encoder_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: pipeline_state_and_vertex_buffer_before_draw_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: commit_present_after_encoding_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: production_write_admission_before_renderer_state_write_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: result_envelope_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: backend_ready_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness owner probe: approval_recovery_or_report_wrapper=false"
