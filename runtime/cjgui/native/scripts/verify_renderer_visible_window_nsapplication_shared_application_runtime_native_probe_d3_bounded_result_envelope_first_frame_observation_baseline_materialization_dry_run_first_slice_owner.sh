#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 first-frame observation baseline materialization
# dry-run first-slice owner。它只检查 owner truth 与 stop-line，不执行 native
# runtime probe，不读取或持久化真实 frame hash value。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer first-frame baseline materialization dry-run owner: missing owner file $OWNER_FILE" >&2
  exit 3
fi

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer first-frame baseline materialization dry-run owner: missing token $token" >&2
    exit 4
  fi
}

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationBaselineMaterializationDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationBaselineMaterializationDryRunFirstSliceDraft"
require_owner_token "shouldTreatBaselineMaterializationAsDryRunOnly"
require_owner_token "didConfirmBaselineArtifactSourceContractDefined"
require_owner_token "didConfirmBaselineArtifactFreshnessContractDefined"
require_owner_token "didConfirmBaselineHashValueRedactionPolicyDefined"
require_owner_token "didConfirmMissingBaselineArtifactSourceClassified"
require_owner_token "didConfirmBaselineArtifactMaterializedFalse"
require_owner_token "didConfirmBaselineFrameHashValueRedacted"
require_owner_token "didConfirmRendererStateWriteBlockedAfterBaselineMaterialization"
require_owner_token "didConfirmRuntimeStateWriteBlockedAfterBaselineMaterialization"

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline materialization dry-run owner: public or foreign declaration found" >&2
  exit 5
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline materialization dry-run owner: forbidden native/render/capture token found" >&2
  exit 6
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer first-frame baseline materialization dry-run owner: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer first-frame baseline materialization dry-run owner: route_classification=baseline_materialization_dry_run_first_slice_owner"
echo "baseline_materialization_dry_run_first_slice_owner_present=true"
echo "semantic_gate_dry_run_envelope_input=true"
echo "baseline_artifact_source_contract_defined=true"
echo "baseline_artifact_freshness_contract_defined=true"
echo "baseline_hash_value_redaction_policy_defined=true"
echo "missing_baseline_artifact_source_classified=true"
echo "baseline_materialization_dry_run_ready=true"
echo "baseline_materialization_dry_run_only=true"
echo "baseline_artifact_source_available=false"
echo "baseline_artifact_materialized=false"
echo "baseline_artifact_freshness_checked=false"
echo "baseline_artifact_freshness_passed=false"
echo "baseline_frame_hash_value_redacted=true"
echo "baseline_compare_executed=false"
echo "semantic_acceptance_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
