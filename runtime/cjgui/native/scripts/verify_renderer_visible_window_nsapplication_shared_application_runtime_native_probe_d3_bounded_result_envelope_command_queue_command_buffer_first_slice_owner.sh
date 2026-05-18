#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage106 command queue / command buffer first-slice
# owner。它只做 source-level owner probe，不执行 runtime native probe。
# Stop-line: 不调用 application accessor，不扩 native bridge / public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness"
  "didConsumeCommandPipelineReadinessEnvelope"
  "didRequireMetalDeviceForNativeFirstSlice"
  "didAllowCommandQueueCreateDestroyFirstSlice"
  "didAllowCommandBufferCreateDestroyFirstSlice"
  "didKeepEncoderCreationBlocked"
  "didKeepCommitPresentBlocked"
  "didRequireTokenLocalCleanup"
  "didKeepFirstSliceCurrentShellBounded"
  "didRequireProductionWriteAdmissionBeforeRendererStateWrite"
  "didKeepRendererStateWriteBlocked"
  "didConfirmNoProductionTruthUpgrade"
  "didConfirmNoBackendReadyTruth"
  "didConfirmNoNativeBridgeExpansion"
  "didAvoidApprovalRecoveryOrReportWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: command_pipeline_readiness_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: metal_device_for_native_first_slice_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: command_queue_create_destroy_first_slice_allowed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: command_buffer_create_destroy_first_slice_allowed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: encoder_creation_blocked=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: commit_present_blocked=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: token_local_cleanup_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: result_envelope_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: backend_ready_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded command queue command buffer first slice owner probe: approval_recovery_or_report_wrapper=false"
