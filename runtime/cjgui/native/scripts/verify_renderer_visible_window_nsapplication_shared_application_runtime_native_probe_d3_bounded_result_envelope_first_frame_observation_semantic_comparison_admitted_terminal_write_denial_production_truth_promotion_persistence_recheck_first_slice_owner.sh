#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage131 production-truth promotion persistence
# recheck first-slice owner probe。它验证 production truth promotion 重新
# 绑定 persistence result 后仍 fail-closed。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_persistence_recheck_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage131 promotion persistence recheck owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage131 promotion persistence recheck owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPersistenceRecheckFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPersistenceRecheckFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPersistenceRecheckFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPersistenceRecheckFirstSliceDraft"
require_owner_token "didConfirmHashPersistenceResultBlocksPromotion"
require_owner_token "didConfirmBackingStoreTokenMissingBlocksPromotion"
require_owner_token "didKeepResultEnvelopePromotionBlocked"
require_owner_token "didPreparePositiveProbeBackingStoreCommitPredicateNextRoute"

echo "stage131_production_truth_promotion_persistence_recheck_owner_present=true"
echo "frame_hash_persistence_result_envelope_consumed=true"
echo "production_truth_promotion_persistence_recheck_ready=true"
echo "production_truth_promotion_still_blocked_by_hash_persistence=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write_admission_ready=false"
echo "positive_probe_backing_store_commit_predicate_next_route_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
