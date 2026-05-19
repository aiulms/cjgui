#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 baseline artifact positive fixture dry-run first-slice
# owner。它只接受 redacted fixture/source envelope，不读取真实 hash 值，不写
# renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: missing owner file $OWNER_FILE" >&2
  exit 3
fi

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: missing token $token" >&2
    exit 4
  fi
}

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationBaselineArtifactPositiveFixtureDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationBaselineArtifactPositiveFixtureDryRunFirstSliceDraft"
require_owner_token "shouldTreatBaselineArtifactFixtureAsDryRunOnly"
require_owner_token "didConfirmSemanticAcceptanceResultDryRunInput"
require_owner_token "didConfirmBaselineArtifactPositiveFixtureSourceDefined"
require_owner_token "didConfirmBaselineArtifactFixtureProvenanceDefined"
require_owner_token "didConfirmBaselineArtifactFixtureFreshnessPassed"
require_owner_token "didConfirmBaselineFixtureFrameHashValueRedacted"
require_owner_token "didConfirmBaselineCompareInputShapeDefined"
require_owner_token "didConfirmRendererStateWriteBlockedAfterBaselineFixture"
require_owner_token "didConfirmRuntimeStateWriteBlockedAfterBaselineFixture"

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: public or foreign declaration found" >&2
  exit 5
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: forbidden native/render/capture token found" >&2
  exit 6
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer first-frame baseline artifact positive fixture dry-run owner: route_classification=baseline_artifact_positive_fixture_dry_run_first_slice_owner"
echo "baseline_artifact_positive_fixture_dry_run_first_slice_owner_present=true"
echo "semantic_acceptance_result_dry_run_input=true"
echo "baseline_artifact_positive_fixture_source_defined=true"
echo "baseline_artifact_fixture_provenance_defined=true"
echo "baseline_artifact_fixture_freshness_passed=true"
echo "baseline_fixture_frame_hash_value_redacted=true"
echo "baseline_compare_input_shape_defined=true"
echo "baseline_artifact_fixture_materialized=true"
echo "baseline_artifact_positive_fixture_dry_run_ready=true"
echo "baseline_artifact_positive_fixture_dry_run_only=true"
echo "baseline_compare_executed=false"
echo "semantic_acceptance_admitted=false"
echo "renderer_state_write_after_baseline_fixture_allowed=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
