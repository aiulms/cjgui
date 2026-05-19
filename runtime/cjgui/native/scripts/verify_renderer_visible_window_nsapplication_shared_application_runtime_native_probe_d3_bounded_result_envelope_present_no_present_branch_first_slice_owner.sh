#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage115 present/no-present branch first-slice
# readiness owner。它只检查 Cangjie owner contract，不执行 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice.cj"
STAGE114_OWNER="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceDraft"
  "didConsumeCommandBufferCommitNoPresentFirstSliceReadiness"
  "didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch"
  "didRequireBoundedIsolatedPresentNoPresentBranchProbe"
  "didRequireProbeLocalDrawablePresentScheduling"
  "didRequirePresentAfterEncodingBeforeCommit"
  "didRequireProbeLocalCommandBufferCommitAfterPresentScheduling"
  "didRequireBoundedPresentCompletionWait"
  "didRequireCommandBufferStatusCompletedClassification"
  "didAllowBoundedDrawablePresentScheduledEnvelope"
  "didRequireNoPresentBranchWhenCommitEnvelopeMissing"
  "didKeepProductionPresentBlocked"
  "didKeepProductionRenderTruthBlocked"
  "didConfirmNoProductionNativeBridgeExpansion"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice owner: missing symbol $symbol" >&2
    exit 4
  fi
done

if [[ ! -f "$STAGE114_OWNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice owner: missing dependency $STAGE114_OWNER" >&2
  exit 5
fi

if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|let|var)|foreign[[:space:]]+func' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice owner: owner must stay internal and foreign-free" >&2
  exit 6
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded present/no-present branch first slice owner: forbidden native/AppKit/render token found in owner" >&2
  exit 7
fi

echo "d3_bounded_result_envelope_present_no_present_branch_first_slice_owner_present=true"
echo "command_buffer_commit_no_present_first_slice_input=true"
echo "positive_command_buffer_commit_no_present_envelope_before_present_branch_required=true"
echo "bounded_isolated_present_no_present_branch_probe_required=true"
echo "probe_local_drawable_present_scheduling_required=true"
echo "present_after_encoding_before_commit_required=true"
echo "probe_local_command_buffer_commit_after_present_scheduling_required=true"
echo "bounded_present_completion_wait_required=true"
echo "command_buffer_status_completed_classification_required=true"
echo "bounded_drawable_present_scheduled_envelope_allowed=true"
echo "no_present_branch_when_commit_envelope_missing_required=true"
echo "production_present_blocked=true"
echo "production_render_truth_blocked=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "backend_ready_truth=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
echo "renderer_state_write=false"
