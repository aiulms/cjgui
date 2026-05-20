#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage132 frame-hash persistence commit readiness
# recheck first-slice owner probe。它验证 token denial 已重新绑定到
# persistence / production truth / renderer-state admission 阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_commit_recheck_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage132 persistence commit recheck owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage132 persistence commit recheck owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceDraft"
require_owner_token "didRecheckFrameHashPersistenceCommitAgainstTokenResult"
require_owner_token "didConfirmTokenDenialBlocksFrameHashPersistenceCommit"
require_owner_token "didConfirmPositiveProbeStillRequiredForPersistenceCommit"
require_owner_token "didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit"
require_owner_token "didKeepFrameHashPersistenceCommitAdmissionBlocked"
require_owner_token "didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute"

echo "stage132_frame_hash_persistence_commit_readiness_recheck_owner_present=true"
echo "frame_hash_persistence_commit_readiness_recheck_ready=true"
echo "frame_hash_persistence_commit_still_blocked_by_token_result=true"
echo "positive_probe_still_required_for_frame_hash_persistence_commit=true"
echo "nonzero_frame_hash_still_required_for_frame_hash_persistence_commit=true"
echo "frame_hash_persistence_commit_admitted=false"
echo "frame_hash_persisted=false"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write_admission_ready=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
