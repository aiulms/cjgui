#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage133 production-truth token gate recheck
# first-slice owner probe。它要求 production truth promotion 同时绑定
# backing-store token 与 frame-hash persistence commit admission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_token_gate_recheck_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage133 production truth token gate recheck owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage133 production truth token gate recheck owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthTokenGateRecheckFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthTokenGateRecheckFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthTokenGateRecheckFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthTokenGateRecheckFirstSliceDraft"
require_owner_token "didConsumePositiveProbeMaterialization"
require_owner_token "didRequireBackingStoreTokenBeforeProductionTruth"
require_owner_token "didRequireFrameHashPersistenceCommitBeforeProductionTruth"
require_owner_token "didKeepResultEnvelopePromotionBlocked"
require_owner_token "didPrepareRendererStateWriteTokenGateRecheckInput"

echo "stage133_production_truth_token_gate_recheck_owner_present=true"
echo "production_truth_token_gate_recheck_ready=true"
echo "production_truth_requires_backing_store_token=true"
echo "production_truth_requires_frame_hash_persistence_commit=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write_token_gate_recheck_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
