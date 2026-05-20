#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage130 production-truth promotion predicate map
# first-slice owner probe。它验证 promotion 谓词被显式化，但不提升
# production render truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_predicate_map_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage130 production truth promotion predicate owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage130 production truth promotion predicate owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPredicateMapFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPredicateMapFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPredicateMapFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialProductionTruthPromotionPredicateMapFirstSliceDraft"
require_owner_token "didRequirePersistedFrameHashEvidenceForProductionTruth"
require_owner_token "didRequirePositiveLiveProbeForProductionTruth"
require_owner_token "didKeepResultEnvelopePromotionBlocked"
require_owner_token "didPrepareRendererStateWriteAdmissionRecheckInput"

echo "stage130_production_truth_promotion_predicate_owner_present=true"
echo "frame_hash_persistence_evidence_consumed=true"
echo "production_truth_promotion_predicate_map_ready=true"
echo "persisted_frame_hash_required_for_production_truth=true"
echo "positive_live_probe_required_for_production_truth=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write_admission_recheck_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
