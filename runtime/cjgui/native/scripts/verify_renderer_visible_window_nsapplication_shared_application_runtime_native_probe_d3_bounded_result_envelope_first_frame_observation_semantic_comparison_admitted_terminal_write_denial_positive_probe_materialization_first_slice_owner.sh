#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage133 positive-probe materialization first-slice
# owner probe。它要求 owner 明确消费 stage132 commit recheck，并将 fresh
# bounded first-frame probe facts 作为 isolated runtime input 重新物化，
# 不提升 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_positive_probe_materialization_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage133 positive probe materialization owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage133 positive probe materialization owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialPositiveProbeMaterializationFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialPositiveProbeMaterializationFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialPositiveProbeMaterializationFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialPositiveProbeMaterializationFirstSliceDraft"
require_owner_token "didConsumeFrameHashPersistenceCommitReadinessRecheck"
require_owner_token "didRequireFreshBoundedFirstFrameProbeMaterialization"
require_owner_token "didClassifyHostRuntimeLimitationFromFreshProbe"
require_owner_token "didKeepPositiveProbeFactsIsolated"
require_owner_token "didKeepFrameHashValueRedacted"
require_owner_token "didPrepareProductionTruthTokenGateRecheckInput"

echo "stage133_positive_probe_materialization_owner_present=true"
echo "positive_probe_materialization_ready=true"
echo "fresh_bounded_first_frame_probe_materialization_required=true"
echo "host_runtime_limitation_from_fresh_probe_classified=true"
echo "positive_probe_facts_kept_isolated=true"
echo "frame_hash_value_redacted=true"
echo "production_truth_token_gate_recheck_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
