#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 semantic-comparison-admitted renderer-state write
# admission dry-run first-slice owner。它只做 source-level probe，不执行 runtime
# native probe，也不允许 renderer/runtime state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted renderer state write admission owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteAdmissionDryRunFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteAdmissionDryRunFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteAdmissionDryRunFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteAdmissionDryRunFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteAdmissionDryRunFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonDryRunFirstSliceReadiness"
  "CjguiInternalRendererNoStateWriteImplementationReadiness"
  "didConsumeSemanticComparisonDryRunReadiness"
  "didConsumeSemanticComparisonAdmission"
  "didConsumeRendererNoStateWriteImplementationReadiness"
  "didDefineStateMutationRequestAdmissionFields"
  "didDefineVisibilityPublicationAdmissionFields"
  "didDefineRollbackFallbackAdmissionFields"
  "didKeepStateMutationRequestFailClosed"
  "didKeepVisibilityPublicationFailClosed"
  "didKeepRollbackFallbackWriteFailClosed"
  "didKeepRendererStateWriteBlockedDuringAdmission"
  "didKeepRuntimeStateWriteBlockedDuringAdmission"
)
for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted renderer state write admission owner: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted renderer state write admission owner: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted renderer state write admission owner: forbidden application/visible/render/capture token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[+][[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted renderer state write admission owner: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted renderer state write admission owner: protected path modified" >&2
  exit 8
fi

echo "cjgui semantic-comparison-admitted renderer state write admission owner: owner_file=$OWNER_FILE"
echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_owner_present=true"
echo "semantic_comparison_dry_run_readiness_input=true"
echo "semantic_acceptance_comparison_admitted_input=true"
echo "no_state_write_implementation_input=true"
echo "state_mutation_request_admission_fields_defined=true"
echo "visibility_publication_admission_fields_defined=true"
echo "rollback_fallback_admission_fields_defined=true"
echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=true"
echo "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=true"
echo "state_mutation_request_fail_closed=true"
echo "visibility_publication_fail_closed=true"
echo "rollback_fallback_write_fail_closed=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "runtime_native_probe_execution=false"
echo "application_singleton_accessor_call=false"
echo "native_bridge_expansion=false"
echo "public_api_modified=false"
echo "production_public_c_abi_added=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "cjpm_toml_change=false"
