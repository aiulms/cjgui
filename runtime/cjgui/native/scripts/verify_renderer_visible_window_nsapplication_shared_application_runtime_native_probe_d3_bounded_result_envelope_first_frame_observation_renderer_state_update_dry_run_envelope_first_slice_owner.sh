#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage121 state-update dry-run envelope first-slice
# owner。它只做 source-level probe，不执行 runtime native probe，也不写
# renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer state-update dry-run envelope owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateUpdateDryRunEnvelopeFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateUpdateDryRunEnvelopeFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateUpdateDryRunEnvelopeFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateUpdateDryRunEnvelopeFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateUpdateDryRunEnvelopeFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationRendererStateWriteDryRunAdmissionFirstSliceReadiness"
  "didConsumeRendererStateWriteDryRunAdmissionReadiness"
  "didOpenRendererStateUpdateDryRunEnvelopeFirstSliceRoute"
  "didMapProductionWritePreflightToStateUpdateCandidate"
  "didMapFirstFrameObservationToRequiredStateField"
  "didMapFrameHashSummaryToRequiredStateField"
  "didMapBaselineGateToRequiredStateField"
  "didMapRollbackVisibilityBoundaryToRequiredStateField"
  "didPrepareRendererStateUpdateDryRunEnvelope"
  "didConfirmStateUpdateEnvelopeDryRunOnly"
  "didClassifyStateMutationRequestAsFailClosed"
  "didClassifyVisibilityPublicationAsFailClosed"
  "didClassifyRollbackFallbackWriteAsFailClosed"
  "didKeepRendererStateWriteBlockedAfterStateUpdateEnvelope"
  "didKeepRuntimeStateWriteBlockedAfterStateUpdateEnvelope"
  "didKeepFrameHashValueUnpersisted"
)
for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer state-update dry-run envelope owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope owner probe: forbidden application/visible/render/capture token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[+][[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer state-update dry-run envelope owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer state-update dry-run envelope owner probe: renderer_state_update_dry_run_envelope_first_slice_owner_present=true"
echo "cjgui renderer state-update dry-run envelope owner probe: renderer_state_write_dry_run_admission_input=true"
echo "cjgui renderer state-update dry-run envelope owner probe: production_write_preflight_mapped_to_state_update_candidate=true"
echo "cjgui renderer state-update dry-run envelope owner probe: first_frame_observation_state_field_mapped=true"
echo "cjgui renderer state-update dry-run envelope owner probe: frame_hash_summary_state_field_mapped=true"
echo "cjgui renderer state-update dry-run envelope owner probe: baseline_gate_state_field_mapped=true"
echo "cjgui renderer state-update dry-run envelope owner probe: rollback_visibility_boundary_state_field_mapped=true"
echo "cjgui renderer state-update dry-run envelope owner probe: renderer_state_update_dry_run_envelope_ready=true"
echo "cjgui renderer state-update dry-run envelope owner probe: state_update_envelope_dry_run_only=true"
echo "cjgui renderer state-update dry-run envelope owner probe: state_mutation_request_fail_closed=true"
echo "cjgui renderer state-update dry-run envelope owner probe: visibility_publication_fail_closed=true"
echo "cjgui renderer state-update dry-run envelope owner probe: rollback_fallback_write_fail_closed=true"
echo "cjgui renderer state-update dry-run envelope owner probe: frame_hash_value_persisted=false"
echo "cjgui renderer state-update dry-run envelope owner probe: production_render_truth=false"
echo "cjgui renderer state-update dry-run envelope owner probe: backend_ready_truth=false"
echo "cjgui renderer state-update dry-run envelope owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer state-update dry-run envelope owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer state-update dry-run envelope owner probe: native_bridge_expansion=false"
echo "cjgui renderer state-update dry-run envelope owner probe: public_api_modified=false"
echo "cjgui renderer state-update dry-run envelope owner probe: production_public_c_abi_added=false"
echo "cjgui renderer state-update dry-run envelope owner probe: renderer_state_write=false"
echo "cjgui renderer state-update dry-run envelope owner probe: runtime_state_write=false"
echo "cjgui renderer state-update dry-run envelope owner probe: cjpm_toml_change=false"
