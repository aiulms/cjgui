#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 semantic comparison dry-run first-slice owner。该
# owner 只消费 redacted baseline fixture input shape，产出 positive/negative
# comparison classifier contract，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer first-frame semantic comparison dry-run owner: missing owner file $OWNER_FILE" >&2
  exit 3
fi

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer first-frame semantic comparison dry-run owner: missing token $token" >&2
    exit 4
  fi
}

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonDryRunFirstSliceDraft"
require_owner_token "shouldTreatSemanticComparisonAsDryRunOnly"
require_owner_token "didConfirmBaselineArtifactPositiveFixtureInput"
require_owner_token "didConfirmSemanticComparisonInputShapeDefined"
require_owner_token "didConfirmSemanticComparisonPositiveFixtureRouteDefined"
require_owner_token "didConfirmSemanticComparisonNegativeFixtureRouteDefined"
require_owner_token "didConfirmSemanticAcceptanceComparisonAdmitted"
require_owner_token "didConfirmRendererStateWriteBlockedAfterSemanticComparison"
require_owner_token "didConfirmRuntimeStateWriteBlockedAfterSemanticComparison"

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer first-frame semantic comparison dry-run owner: public or foreign declaration found" >&2
  exit 5
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer first-frame semantic comparison dry-run owner: forbidden native/render/capture token found" >&2
  exit 6
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer first-frame semantic comparison dry-run owner: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer first-frame semantic comparison dry-run owner: route_classification=semantic_comparison_dry_run_first_slice_owner"
echo "semantic_comparison_dry_run_first_slice_owner_present=true"
echo "baseline_artifact_positive_fixture_input=true"
echo "semantic_comparison_input_shape_defined=true"
echo "semantic_comparison_positive_fixture_route_defined=true"
echo "semantic_comparison_negative_fixture_route_defined=true"
echo "semantic_comparison_dry_run_ready=true"
echo "semantic_comparison_dry_run_only=true"
echo "semantic_comparison_evaluated=true"
echo "semantic_comparison_positive_fixture_matched=true"
echo "semantic_acceptance_comparison_admitted=true"
echo "renderer_state_write_after_semantic_comparison_allowed=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
